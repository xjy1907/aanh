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
static BOOL gScanBusy = NO;
static dispatch_source_t gPollTimer = nil;
static void (^gPollLog)(NSString *) = nil;

// 缓存跨页读会话，避免每页重建 proc→task→pmap→ttep
static pid_t gSessPid = -1;
static uint64_t gSessTtep = 0;
static uint64_t gSessVmap = 0;

static void *step18_sym(const char *name) {
  void *p = dlsym(RTLD_DEFAULT, name);
  if (!p) {
    char buf[256];
    snprintf(buf, sizeof(buf), "_%s", name);
    p = dlsym(RTLD_DEFAULT, buf);
  }
  return p;
}

static uint64_t step18_unsign(uint64_t p) {
  if ((p & (1ULL << 55)) != 0) {
    return p | 0xFFFFFF8000000000ULL;
  }
  return p & 0x0000007FFFFFFFFFULL;
}

static struct system_info *step18_gs(void) {
  void *gs = step18_sym("gSystemInfo");
  return (struct system_info *)gs;
}

static BOOL step18_open_session(pid_t pid, NSString *__autoreleasing *errOut) {
  if (pid > 1 && pid == gSessPid && gSessTtep != 0) {
    return YES;
  }
  gSessPid = -1;
  gSessTtep = 0;
  gSessVmap = 0;

  ProcFindFn procFind = (ProcFindFn)step18_sym("proc_find");
  ProcTaskFn procTask = (ProcTaskFn)step18_sym("proc_task");
  KreadbufFn kreadbuf = (KreadbufFn)step18_sym("kreadbuf");
  struct system_info *info = step18_gs();
  if (!procFind || !procTask || !kreadbuf || !info) {
    if (errOut) {
      *errOut = @"缺 proc_find/proc_task/kreadbuf/gSystemInfo";
    }
    return NO;
  }
  uint32_t task_map = info->kernelStruct.task.map;
  uint32_t vm_pmap = info->kernelStruct.vm_map.pmap;
  uint32_t pmap_ttep = info->kernelStruct.pmap.ttep;
  if (task_map == 0 || vm_pmap == 0) {
    if (errOut) {
      *errOut = @"gSystemInfo 偏移未灌入";
    }
    return NO;
  }

  uint64_t proc = procFind(pid);
  if (!proc) {
    if (errOut) {
      *errOut = [NSString stringWithFormat:@"proc_find(%d)=0", (int)pid];
    }
    return NO;
  }
  uint64_t task = procTask(proc);
  if (!task) {
    if (errOut) {
      *errOut = @"proc_task=0";
    }
    return NO;
  }

  uint64_t vmap = 0;
  if (kreadbuf(task + task_map, &vmap, sizeof(vmap)) != 0) {
    if (errOut) {
      *errOut = @"读 task.map 失败";
    }
    return NO;
  }
  vmap = step18_unsign(vmap);
  if (!vmap) {
    if (errOut) {
      *errOut = @"vmap=0";
    }
    return NO;
  }

  uint64_t pmap = 0;
  if (kreadbuf(vmap + vm_pmap, &pmap, sizeof(pmap)) != 0) {
    if (errOut) {
      *errOut = @"读 vm_map.pmap 失败";
    }
    return NO;
  }
  pmap = step18_unsign(pmap);
  if (!pmap) {
    if (errOut) {
      *errOut = @"pmap=0";
    }
    return NO;
  }

  uint64_t ttep = 0;
  if (kreadbuf(pmap + pmap_ttep, &ttep, sizeof(ttep)) != 0) {
    if (errOut) {
      *errOut = @"读 pmap.ttep 失败";
    }
    return NO;
  }
  ttep = step18_unsign(ttep);
  if (!ttep) {
    if (errOut) {
      *errOut = @"ttep=0";
    }
    return NO;
  }

  gSessPid = pid;
  gSessTtep = ttep;
  gSessVmap = vmap;
  return YES;
}

static BOOL step18_vread(uint64_t addr, void *out, size_t size) {
  VreadbufFn vreadbuf = (VreadbufFn)step18_sym("vreadbuf");
  if (!vreadbuf || gSessTtep == 0) {
    return NO;
  }
  return vreadbuf(gSessTtep, addr, out, size) == 0;
}

static uint64_t step18_kread64(uint64_t kaddr) {
  KreadbufFn kreadbuf = (KreadbufFn)step18_sym("kreadbuf");
  uint64_t v = 0;
  if (!kreadbuf || kreadbuf(kaddr, &v, sizeof(v)) != 0) {
    return 0;
  }
  return step18_unsign(v);
}

static uint64_t step18_base_via_vm_map(void (^log)(NSString *)) {
  struct system_info *info = step18_gs();
  if (!info || gSessVmap == 0) {
    return 0;
  }
  uint32_t hdr_off = info->kernelStruct.vm_map.hdr;
  uint32_t hdr_links = info->kernelStruct.vm_map_header.links;
  uint32_t entry_links = info->kernelStruct.vm_map_entry.links;
  uint32_t link_next = info->kernelStruct.vm_map_links.next;
  uint32_t link_min = info->kernelStruct.vm_map_links.min;
  uint32_t link_max = info->kernelStruct.vm_map_links.max;
  if (log) {
    log([NSString stringWithFormat:@"[基址] vm_map 走表 hdr=0x%x links=0x%x/0x%x", hdr_off, hdr_links,
                                   entry_links]);
  }

  uint64_t hdr = gSessVmap + hdr_off;
  uint64_t links_base = hdr + hdr_links;
  uint64_t entry = step18_kread64(links_base + link_next);
  uint64_t sentinel = links_base;

  for (int i = 0; i < 4096 && entry && entry != sentinel; ++i) {
    uint64_t elinks = entry + entry_links;
    uint64_t start = 0, end = 0;
    KreadbufFn kreadbuf = (KreadbufFn)step18_sym("kreadbuf");
    if (!kreadbuf) {
      break;
    }
    if (kreadbuf(elinks + link_min, &start, sizeof(start)) != 0 ||
        kreadbuf(elinks + link_max, &end, sizeof(end)) != 0) {
      break;
    }
    start = step18_unsign(start);
    end = step18_unsign(end);
    uint64_t next = step18_kread64(elinks + link_next);

    if (end > start && start >= 0x100000000ULL && start < 0x300000000ULL) {
      uint32_t magic = 0;
      if (step18_vread(start, &magic, sizeof(magic))) {
        if (magic == 0xfeedfacfU || magic == 0xcffaedfeU) {
          if (log) {
            log([NSString stringWithFormat:@"[基址] vm_map 命中 magic=0x%x @ 0x%llx", magic,
                                           (unsigned long long)start]);
          }
          return start;
        }
      }
    }
    if (!next || next == entry) {
      break;
    }
    entry = next;
  }
  if (log) {
    log(@"[基址] vm_map 走表未命中 feedfacf，改短扫兜底");
  }
  return 0;
}

static uint64_t step18_base_via_short_scan(void (^log)(NSString *)) {
  // 粗扫：1MB 步进，命中附近再 16KB 精扫；整段限时 6s
  CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();
  const CFTimeInterval budget = 6.0;
  struct {
    uint64_t start;
    uint64_t end;
  } ranges[] = {
      {0x100000000ULL, 0x180000000ULL},
      {0x180000000ULL, 0x200000000ULL},
      {0x200000000ULL, 0x280000000ULL},
  };
  uint64_t checked = 0;
  for (unsigned r = 0; r < 3; ++r) {
    for (uint64_t addr = ranges[r].start; addr < ranges[r].end; addr += 0x100000ULL) {
      if ((CFAbsoluteTimeGetCurrent() - t0) > budget) {
        if (log) {
          log([NSString stringWithFormat:@"[基址] 短扫超时(%.0fs) checked=%llu", budget,
                                         (unsigned long long)checked]);
        }
        return 0;
      }
      checked++;
      if ((checked % 64) == 0 && log) {
        log([NSString stringWithFormat:@"[基址] 短扫中… @0x%llx", (unsigned long long)addr]);
      }
      uint32_t magic = 0;
      if (!step18_vread(addr, &magic, sizeof(magic))) {
        continue;
      }
      if (magic == 0xfeedfacfU || magic == 0xcffaedfeU) {
        if (log) {
          log([NSString stringWithFormat:@"[基址] 粗扫命中 @0x%llx", (unsigned long long)addr]);
        }
        return addr;
      }
    }
  }
  if (log) {
    log(@"[基址] 短扫失败");
  }
  return 0;
}

@implementation Step18ReadProbe

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
    gSessPid = -1;
    gSessTtep = 0;
    gSessVmap = 0;
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

+ (BOOL)readGameAt:(uint64_t)address size:(size_t)size into:(void *)buffer {
  if (gGamePid <= 1 || !buffer || size == 0) {
    return NO;
  }
  NSString *err = nil;
  if (!step18_open_session(gGamePid, &err)) {
    return NO;
  }
  return step18_vread(address, buffer, size);
}

+ (NSString *)statusSummary {
  if (![self isReadingEnabled]) {
    return @"reading=0";
  }
  if (gReady && gGamePid > 0 && gModuleBase != 0) {
    return [NSString stringWithFormat:@"reading=1 pid=%d base=0x%llx", (int)gGamePid,
                                      (unsigned long long)gModuleBase];
  }
  if (gScanBusy) {
    return [NSString stringWithFormat:@"reading=1 pid=%d base=scanning", (int)gGamePid];
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

+ (uint64_t)resolveModuleBaseForPid:(pid_t)pid log:(void (^)(NSString *))log {
  NSString *err = nil;
  if (!step18_open_session(pid, &err)) {
    if (log) {
      log([NSString stringWithFormat:@"[基址] 会话失败：%@", err ?: @"?"]);
    }
    return 0;
  }
  if (log) {
    log([NSString stringWithFormat:@"[基址] 会话 OK pid=%d ttep=0x%llx", (int)pid,
                                   (unsigned long long)gSessTtep]);
  }
  uint64_t base = step18_base_via_vm_map(log);
  if (base != 0) {
    return base;
  }
  return step18_base_via_short_scan(log);
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
  if (gScanBusy) {
    return YES;
  }

  if (gGamePid > 0) {
    if (kill(gGamePid, 0) != 0) {
      log([NSString stringWithFormat:@"[探针] 旧 pid=%d 已退出，重置", (int)gGamePid]);
      gGamePid = -1;
      gModuleBase = 0;
      gReady = NO;
      gSessPid = -1;
      gSessTtep = 0;
      gSessVmap = 0;
    }
  }

  if (gReady && gGamePid > 0 && gModuleBase != 0) {
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
    gScanBusy = YES;
    gModuleBase = [self resolveModuleBaseForPid:gGamePid log:log];
    gScanBusy = NO;
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
