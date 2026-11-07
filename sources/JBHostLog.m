//
//  JBHostLog.m
//  主 App 需要的日志符号（原在 NHKit/kfd.m）。NH* 仅 Embed+dlopen，故在主程序内提供实现。
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <notify.h>
#import <stdarg.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <sys/sysctl.h>
#import <unistd.h>

static bool g_dbglog_cached = false;
static CFAbsoluteTime g_dbglog_last = 0;
static FILE *kfd_log_file = NULL;

void NHDebugLogInvalidateCache(void) {
  g_dbglog_last = 0;
}

static NSString *JBHostDeviceToken(void) {
  static NSString *token = nil;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    char uuid[256] = {0};
    size_t len = sizeof(uuid);
    if (sysctlbyname("kern.uuid", uuid, &len, NULL, 0) != 0 || uuid[0] == '\0') {
      strncpy(uuid, "unknown-device", sizeof(uuid) - 1);
    }
    NSString *material = [NSString stringWithFormat:@"ab.v1.%s.q9xm", uuid];
    NSData *data = [material dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t dig[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, dig);
    token = [NSString stringWithFormat:@"%02x%02x%02x%02x", dig[0], dig[1], dig[2], dig[3]];
  });
  return token;
}

bool NHDebugLogEnabled(void) {
  CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
  if (g_dbglog_last > 0 && (now - g_dbglog_last) < 1.0) {
    return g_dbglog_cached;
  }
  g_dbglog_last = now;
  g_dbglog_cached = false;
  @autoreleasepool {
    NSString *tok = JBHostDeviceToken();
    char stateName[96];
    snprintf(stateName, sizeof(stateName), "com.%s.n.S", tok.UTF8String);
    int st = 0;
    if (notify_register_check(stateName, &st) == NOTIFY_STATUS_OK) {
      uint64_t v = 0;
      notify_get_state(st, &v);
      if (v & (1ULL << 63)) {
        g_dbglog_cached = (v & (1ULL << 8)) != 0;
        return g_dbglog_cached;
      }
    }
    NSString *dl = @"/var/mobile/Media/Downloads";
    if (access("/var/LIY", F_OK) == 0) {
      dl = [@"/var/jb" stringByAppendingString:dl];
    }
    NSString *prefs = [dl stringByAppendingPathComponent:
                       [NSString stringWithFormat:@"cfg_%@.plist", tok]];
    NSDictionary *cfg = [NSDictionary dictionaryWithContentsOfFile:prefs];
    if (!cfg) {
      cfg = [NSDictionary dictionaryWithContentsOfFile:
             [NSString stringWithFormat:@"/var/mobile/Library/Preferences/com.%@.cfg.plist", tok]];
    }
    if (!cfg) {
      cfg = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.nh.cfg.plist"];
    }
    if (cfg) {
      g_dbglog_cached = [[cfg objectForKey:@"dbglog"] boolValue];
    }
  }
  return g_dbglog_cached;
}

void kfd_log(const char *format, ...) {
  if (!NHDebugLogEnabled()) {
    return;
  }
  if (kfd_log_file == NULL) {
    const char *home = getenv("HOME");
    if (home) {
      char log_path[512];
      snprintf(log_path, sizeof(log_path), "%s/Documents/kfd_debug.log", home);
      kfd_log_file = fopen(log_path, "a");
    }
  }
  if (!kfd_log_file) {
    return;
  }
  va_list args;
  va_start(args, format);
  vfprintf(kfd_log_file, format, args);
  va_end(args);
  fflush(kfd_log_file);
}
