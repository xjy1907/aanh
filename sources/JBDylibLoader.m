//
//  JBDylibLoader.m
//  纯 ObjC：验收③用，避免 Books 冷启动再链入 libc++/.mm
//

#import "JBDylibLoader.h"
#import <dlfcn.h>

static void *JBLoadOne(NSArray<NSString *> *dirs, NSArray<NSString *> *names) {
  NSFileManager *fm = [NSFileManager defaultManager];
  for (NSString *dir in dirs) {
    for (NSString *name in names) {
      NSString *path = [dir stringByAppendingPathComponent:name];
      if (![fm fileExistsAtPath:path]) {
        continue;
      }
      dlerror();
      void *h = dlopen(path.fileSystemRepresentation, RTLD_NOW | RTLD_GLOBAL);
      if (h) {
        return h;
      }
    }
  }
  return NULL;
}

BOOL JBEnsureJailbreakDylibsLoaded(void) {
  static BOOL attempted = NO;
  static BOOL ok = NO;
  if (attempted) {
    return ok;
  }
  attempted = YES;

  if (dlopen("libjailbreak.dylib", RTLD_NOLOAD | RTLD_NOW) ||
      dlopen("libNHSupport.dylib", RTLD_NOLOAD | RTLD_NOW) ||
      dlopen("@executable_path/libNHSupport.dylib", RTLD_NOLOAD | RTLD_NOW) ||
      dlopen("@executable_path/libjailbreak.dylib", RTLD_NOLOAD | RTLD_NOW)) {
    ok = YES;
    return ok;
  }

  NSString *root = [NSBundle mainBundle].bundlePath;
  NSArray<NSString *> *dirs = @[
    root,
    [root stringByAppendingPathComponent:@"Frameworks"],
    [root stringByAppendingPathComponent:@"Libraries"],
  ];
  // 依赖顺序：choma ← xpf/jailbreak；打包脚本会改名为 libNH*
  (void)JBLoadOne(dirs, @[ @"libchoma.dylib", @"libNHCodec.dylib" ]);
  void *xpf = JBLoadOne(dirs, @[ @"libxpf.dylib", @"libNHParse.dylib" ]);
  void *jb = JBLoadOne(dirs, @[ @"libjailbreak.dylib", @"libNHSupport.dylib" ]);
  ok = (xpf != NULL && jb != NULL);
  return ok;
}
