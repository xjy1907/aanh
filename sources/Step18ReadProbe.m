//
//  Step18ReadProbe.m
//

#import "Step18ReadProbe.h"

#include "libjailbreak/info.h"

#import <dlfcn.h>
#import <errno.h>
#import <stdlib.h>
#import <string.h>
#import <sys/sysctl.h>
#import <unistd.h>

__attribute__((used)) static const char kStep18Marker[] = "STEP18-READPROBE";

static NSString *const kReadingDefaultsKey = @"NH.Step18.ReadingEnabled";

typedef uint64_t (*ProcFindFn)(pid_t);
typedef uint64_t (*ProcTaskFn)(uint64_t);
typedef int (*KreadbufFn)(uint64_t, void *, size_t);
typedef int (*VreadbufFn)(uint64_t, uint64_t, void *, size_t);

static BOOL gReadingEnabled = NO;
static pid_t gGamePid = -1;
static uint64_t gModuleBase = 0;
static BOOL gReady = NO;
static dispatch_source_t gPollTimer = nil;
static void (^gPollLog)(NSString *) = nil;

static BOOL step18_read_struct_offsets(uint32_t *task_map, uint32_t *vm_pmap, uint32_t *pmap_ttep,
                                       NSString *__autoreleasing *errOut) {
  void *gs = dlsym(RTLD_DEFAULT, "gSystemInfo");
  if (!gs) {
    gs = dlsym(RTLD_DEFAULT, "_gSystemInfo");
  }
  if (!gs) {
    if (errOut) {
      *errOut = @"无 gSystemInfo（请先初始化内核）";
    }
    return NO;
  }
  struct system_info *info = (struct system_info *)gs;
  *task_map = info->kernelStruct.task.map;
  *vm_pmap = info->kernelStruct.vm_map.pmap;
  *pmap_ttep = (uint32_t)info->kernelStruct.pmap.ttep;
  if (*task_map == 0 || *vm_pmap == 0) {
    if (errOut) {
      *errOut = @"gSystemInfo 偏移未灌入（task.map/vm_map.pmap=0）";
    }
    return NO;
  }
  return YES;
}

@implementation Step18ReadProbe

+ (void *)sym:(const char *)name {
  void *p = dlsym(RTLD_DEFAULT, name);
  if (!p) {
    char buf[256];
    snprintf(buf, sizeof(buf), "_%s", name);
    p = dlsym(RTLD_DEFAULT, buf);
  }
  return p;
}

+ (uint64_t)unsignPtr:(uint64_t)p {
  if ((p & (1ULL << 55)) != 0) {
    return p | 0xFFFFFF8000000000ULL;
  }
  return p & 0x0000007FFFFFFFFFULL;
}

+ (void)setReadingEnabled:(BOOL)enabled {
  volatile const char *keep = kStep18Marker;
  (void)keep[0];
  gReadingEnabled = enabled;
  [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kReadingDefaultsKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
  if (!enabled) {
    gGamePid = -1;
    gModuleBase = 0;
    gReady = NO;
    [self stopPolling];
  }
}

+ (BOOL)isReadingEnabled {
  if (![[NSUserDefaults standardUserDefaults] objectForKey:kReadingDefaultsKey]) {
    return gReadingEnabled;
  }
  gReadingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kReadingDefaultsKey];
  return gReadingEnabled;
}

+ (pid_t)gamePid {
  return gGamePid;
}

+ (uint64_t)moduleBase {
  return gModuleBase;
}

+ (NSString *)statusSummary {
  if (![self isReadingEnabled]) {
    return @"reading=0";
  }
  if (gReady && gGamePid > 0 && gModuleBase != 0) {
    return [NSString stringWithFormat:@"reading=1 pid=%d base=0x%llx", (int)gGamePid,
                                      (unsigned long long)gModuleBase];
  }
  if (gGamePid > 0) {
    return [NSString stringWithFormat:@"reading=1 pid=%d base=pending", (int)gGamePid];
  }
  return @"reading=1 pid=?（游戏未开或未找到）";
}

+ (pid_t)findGamePidWithLog:(void (^)(NSString *))log {
  size_t length = 0;
  int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
  if (sysctl(mib, 3, NULL, &length, NULL, 0) != 0) {
    if (log) {
      log([NSString stringWithFormat:@"[PID] sysctl size 失败 errno=%d", errno]);
    }
    return -1;
  }
  struct kinfo_proc *buf = (struct kinfo_proc *)malloc(length);
  if (!buf) {
    return -1;
  }
  if (sysctl(mib, 3, buf, &length, NULL, 0) != 0) {
    if (log) {
      log([NSString stringWithFormat:@"[PID] sysctl data 失败 errno=%d", errno]);
    }
    free(buf);
    return -1;
  }
  int count = (int)(length / sizeof(struct kinfo_proc));
  pid_t found = -1;
  for (int i = 0; i < count; ++i) {
    const char *comm = buf[i].kp_proc.p_comm;
    if (strncmp(comm, "ShadowTrackerExt", 16) == 0 || strncmp(comm, "ShadowTracker", 13) == 0) {
      found = buf[i].kp_proc.p_pid;
      if (log) {
        log([NSString stringWithFormat:@"[PID] 找到 %s pid=%d", comm, (int)found]);
      }
      break;
    }
  }
  free(buf);
  if (found < 0 && log) {
    log([NSString stringWithFormat:@"[PID] 未找到 ShadowTrackerExt（扫描 %d 个进程）", count]);
  }
  return found;
}

+ (BOOL)machReadPid:(pid_t)pid
                addr:(uint64_t)addr
                 out:(void *)out
                size:(size_t)size
                 log:(void (^)(NSString *))log {
  ProcFindFn procFind = [self sym:"proc_find"];
  ProcTaskFn procTask = [self sym:"proc_task"];
  KreadbufFn kreadbuf = [self sym:"kreadbuf"];
  VreadbufFn vreadbuf = [self sym:"vreadbuf"];
  if (!procFind || !procTask || !kreadbuf || !vreadbuf) {
    if (log) {
      log(@"[读] 缺 proc_find/proc_task/kreadbuf/vreadbuf 符号");
    }
    return NO;
  }

  NSString *offErr = nil;
  uint32_t task_map = 0, vm_pmap = 0, pmap_ttep = 0;
  if (!step18_read_struct_offsets(&task_map, &vm_pmap, &pmap_ttep, &offErr)) {
    if (log) {
      log(offErr ?: @"偏移失败");
    }
    return NO;
  }

  uint64_t proc = procFind(pid);
  if (!proc) {
    if (log) {
      log([NSString stringWithFormat:@"[读] proc_find(%d)=0", (int)pid]);
    }
    return NO;
  }
  uint64_t task = procTask(proc);
  if (!task) {
    return NO;
  }

  uint64_t vmap = 0;
  if (kreadbuf(task + task_map, &vmap, sizeof(vmap)) != 0) {
    return NO;
  }
  vmap = [self unsignPtr:vmap];
  if (!vmap) {
    return NO;
  }

  uint64_t pmap = 0;
  if (kreadbuf(vmap + vm_pmap, &pmap, sizeof(pmap)) != 0) {
    return NO;
  }
  pmap = [self unsignPtr:pmap];
  if (!pmap) {
    return NO;
  }

  uint64_t ttep = 0;
  if (kreadbuf(pmap + pmap_ttep, &ttep, sizeof(ttep)) != 0) {
    return NO;
  }
  ttep = [self unsignPtr:ttep];
  if (!ttep) {
    return NO;
  }

  return vreadbuf(ttep, addr, out, size) == 0;
}

+ (uint64_t)scanModuleBaseForPid:(pid_t)pid log:(void (^)(NSString *))log {
  if (log) {
    log([NSString stringWithFormat:@"[基址] 扫描 PID=%d Mach-O magic", (int)pid]);
  }
  struct {
    uint64_t start;
    uint64_t end;
  } ranges[] = {
      {0x100000000ULL, 0x200000000ULL},
      {0x10000000ULL, 0x100000000ULL},
      {0x200000000ULL, 0x280000000ULL},
  };
  for (unsigned r = 0; r < 3; ++r) {
    for (uint64_t addr = ranges[r].start; addr < ranges[r].end; addr += 0x4000ULL) {
      uint32_t magic = 0;
      if ([self machReadPid:pid addr:addr out:&magic size:sizeof(magic) log:nil]) {
        if (magic == 0xfeedfacfU || magic == 0xcffaedfeU) {
          if (log) {
            log([NSString stringWithFormat:@"[基址] 命中 magic=0x%x @ 0x%llx (range[%u])", magic,
                                           (unsigned long long)addr, r]);
          }
          return addr;
        }
      }
    }
  }
  if (log) {
    log(@"[基址] 扫描失败，未找到 feedfacf");
  }
  return 0;
}

+ (BOOL)probeOnceWithLog:(void (^)(NSString *))logBlock {
  void (^log)(NSString *) = ^(NSString *line) {
    if (logBlock) {
      logBlock(line);
    }
  };
  volatile const char *keep = kStep18Marker;
  (void)keep[0];

  if (![self isReadingEnabled]) {
    log(@"[探针] reading=0，跳过");
    return NO;
  }

  if (gGamePid > 0) {
    if (kill(gGamePid, 0) != 0) {
      log([NSString stringWithFormat:@"[探针] 旧 pid=%d 已退出，重置", (int)gGamePid]);
      gGamePid = -1;
      gModuleBase = 0;
      gReady = NO;
    }
  }

  if (gReady && gGamePid > 0 && gModuleBase != 0) {
    log([NSString stringWithFormat:@"[探针] 已就绪 pid=%d base=0x%llx", (int)gGamePid,
                                   (unsigned long long)gModuleBase]);
    return YES;
  }

  if (gGamePid <= 0) {
    gGamePid = [self findGamePidWithLog:log];
    if (gGamePid <= 1) {
      gModuleBase = 0;
      gReady = NO;
      log(@"验收⑱：读取已开，游戏进程未找到（可稍后重试）");
      return YES;
    }
  }

  if (gModuleBase == 0) {
    gModuleBase = [self scanModuleBaseForPid:gGamePid log:log];
    if (gModuleBase == 0) {
      gReady = NO;
      log([NSString stringWithFormat:@"验收⑱：已找到 pid=%d，基址未命中（将重试）", (int)gGamePid]);
      return YES;
    }
  }

  gReady = YES;
  log([NSString stringWithFormat:@"验收⑱：就绪 PID=%d Base=0x%llx（未链 PhysX/DrawView.mm）",
                                 (int)gGamePid, (unsigned long long)gModuleBase]);
  return YES;
}

+ (void)startPollingWithLog:(void (^)(NSString *))logBlock {
  [self stopPolling];
  gPollLog = [logBlock copy];
  dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  gPollTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
  dispatch_source_set_timer(gPollTimer, dispatch_time(DISPATCH_TIME_NOW, 0),
                            (uint64_t)(5.0 * NSEC_PER_SEC), (uint64_t)(0.5 * NSEC_PER_SEC));
  dispatch_source_set_event_handler(gPollTimer, ^{
    if (![Step18ReadProbe isReadingEnabled]) {
      return;
    }
    [Step18ReadProbe probeOnceWithLog:gPollLog];
  });
  dispatch_resume(gPollTimer);
}

+ (void)stopPolling {
  if (gPollTimer) {
    dispatch_source_cancel(gPollTimer);
    gPollTimer = nil;
  }
  gPollLog = nil;
}

@end
