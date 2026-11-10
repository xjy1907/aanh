//
//  KernelcacheLocator.m
//

#import "KernelcacheLocator.h"
#import <libgrabkernel2/libgrabkernel2.h>
#import <IOKit/IOKitLib.h>
#import <mach/mach.h>
#import <stdio.h>

// iOS SDK 将 kIOMasterPortDefault 标为 unavailable；#ifndef 挡不住 const 符号，
// 误宏成 kIOMasterPortDefault 会在 Xcode 16 / iPhoneOS18 SDK 上编译失败。
// MACH_PORT_NULL 对 IORegistryEntryFromPath 等价于默认主端口。
#ifndef kIOMainPortDefault
#define kIOMainPortDefault MACH_PORT_NULL
#endif

@implementation KernelcacheLocator

+ (NSString *)hexString:(NSData *)data {
  const unsigned char *buf = data.bytes;
  if (!buf) return @"";
  NSMutableString *hex = [NSMutableString stringWithCapacity:data.length * 2];
  for (NSUInteger i = 0; i < data.length; i++) {
    [hex appendFormat:@"%02lX", (unsigned long)buf[i]];
  }
  return hex;
}

+ (nullable NSData *)bootManifestHash {
  io_registry_entry_t entry =
      IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/chosen");
  if (!entry) return nil;
  CFTypeRef prop =
      IORegistryEntryCreateCFProperty(entry, CFSTR("boot-manifest-hash"), kCFAllocatorDefault, 0);
  IOObjectRelease(entry);
  if (!prop) return nil;
  if (CFGetTypeID(prop) != CFDataGetTypeID()) {
    CFRelease(prop);
    return nil;
  }
  return CFBridgingRelease(prop);
}

+ (BOOL)isInstalledThroughTrollStore {
  static BOOL cached = NO;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    NSString *marker =
        [[[NSBundle mainBundle].bundlePath stringByDeletingLastPathComponent]
            stringByAppendingPathComponent:@"_TrollStore"];
    cached = [[NSFileManager defaultManager] fileExistsAtPath:marker];
  });
  return cached;
}

+ (BOOL)canOpenPath:(NSString *)path {
  if (path.length == 0) return NO;
  NSFileManager *fm = [NSFileManager defaultManager];
  if (![fm isReadableFileAtPath:path]) return NO;
  // 与 DOEnvironmentManager 一致：存在/可读不够，必须以 open 为准
  FILE *fp = fopen(path.fileSystemRepresentation, "rb");
  if (!fp) return NO;
  fclose(fp);
  return YES;
}

+ (nullable NSString *)accessibleKernelPathWithLog:(void (^)(NSString *))logBlock {
  void (^log)(NSString *) = ^(NSString *line) {
    if (logBlock) logBlock(line);
  };

  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL troll = [self isInstalledThroughTrollStore];
  log([NSString stringWithFormat:@"TrollStore=%d", troll ? 1 : 0]);

  NSMutableArray<NSString *> *candidates = [NSMutableArray array];

  NSData *hash = [self bootManifestHash];
  if (hash.length > 0) {
    NSString *preboot =
        [@"/private/preboot" stringByAppendingPathComponent:[self hexString:hash]];
    NSString *prebootKernel = [preboot
        stringByAppendingPathComponent:@"System/Library/Caches/com.apple.kernelcaches/kernelcache"];
    [candidates addObject:prebootKernel];
    log([NSString stringWithFormat:@"preboot=%@", preboot]);
  } else {
    log(@"boot-manifest-hash 获取失败");
  }

  [candidates addObject:@"/System/Library/Caches/com.apple.kernelcaches/kernelcache"];
  [candidates
      addObject:[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"kernelcache"]];
  [candidates
      addObject:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/kernelcache"]];

  for (NSString *path in candidates) {
    BOOL exists = [fm fileExistsAtPath:path];
    BOOL readable = [fm isReadableFileAtPath:path];
    BOOL openable = [self canOpenPath:path];
    log([NSString stringWithFormat:@"候选 %@ exists=%d readable=%d openable=%d", path, exists ? 1 : 0,
                                   readable ? 1 : 0, openable ? 1 : 0]);
    if (openable) {
      log([NSString stringWithFormat:@"选用可读 kernelcache: %@", path]);
      return path;
    }
  }

  // 系统路径都不可 open：下载到沙盒 Documents（对齐 Dopamine）
  NSString *downloadPath =
      [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/kernelcache"];
  log([NSString stringWithFormat:@"开始 grab_kernelcache -> %@", downloadPath]);
  if (grab_kernelcache(downloadPath)) {
    if ([self canOpenPath:downloadPath]) {
      log(@"grab_kernelcache 成功且可 open");
      return downloadPath;
    }
    log(@"grab_kernelcache 返回成功但无法 open");
  } else {
    log(@"grab_kernelcache 失败");
  }
  return nil;
}

@end
