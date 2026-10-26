//
//  NHIdentity.h — 每机派生路径 / notify，避免固定 com.nh.* IOC
//  主 App 与 HUD 用同一算法，算出同一路径。
//

#ifndef NHIdentity_h
#define NHIdentity_h

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <sys/sysctl.h>
#import <unistd.h>
#import <stdlib.h>
#import <string.h>
#import <notify.h>

#ifdef __cplusplus
extern "C" {
#endif

/// 8 位 hex，由 kern.uuid + 盐派生（同机稳定）
static inline NSString *NHDeviceToken(void) {
    static NSString *token = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        char uuid[256] = {0};
        size_t len = sizeof(uuid);
        if (sysctlbyname("kern.uuid", uuid, &len, NULL, 0) != 0 || uuid[0] == '\0') {
            const char *fallback = "unknown-device";
            strncpy(uuid, fallback, sizeof(uuid) - 1);
        }
        // 盐勿改：改了会导致同机路径全部换新
        NSString *material = [NSString stringWithFormat:@"ab.v1.%s.q9xm", uuid];
        NSData *data = [material dataUsingEncoding:NSUTF8StringEncoding];
        uint8_t dig[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256(data.bytes, (CC_LONG)data.length, dig);
        token = [NSString stringWithFormat:@"%02x%02x%02x%02x", dig[0], dig[1], dig[2], dig[3]];
    });
    return token;
}

static inline NSString *NHRootifyPath(NSString *path) {
    if (!path.length) return path;
    if (access("/var/LIY", F_OK) == 0) {
        if ([path hasPrefix:@"/var/jb"]) return path;
        return [@"/var/jb" stringByAppendingString:path];
    }
    return path;
}

static inline void NHMigrateFile(NSString *legacy, NSString *neu) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:neu]) return;
    if (![fm fileExistsAtPath:legacy]) return;
    [fm moveItemAtPath:legacy toPath:neu error:nil];
}

/// 配置目录：对标 wasd → /var/mobile/Media/Downloads（清理软件很少扫这里）
static inline NSString *NHConfigDirectory(void) {
    static NSString *dir = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *raw = @"/var/mobile/Media/Downloads";
        dir = NHRootifyPath(raw);
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:dir]) {
            [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
    });
    return dir;
}

/// 配置 plist（对标 wasd DuckPro_settings.plist 放 Downloads，避免 Preferences 被清软件干掉）
static inline NSString *NHPrefsPath(void) {
    static NSString *path = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        path = [NHConfigDirectory() stringByAppendingPathComponent:
                [NSString stringWithFormat:@"cfg_%@.plist", NHDeviceToken()]];
        // 从旧位置迁过来（Preferences / 固定名）
        NHMigrateFile(NHRootifyPath(
            [NSString stringWithFormat:@"/var/mobile/Library/Preferences/com.%@.cfg.plist", NHDeviceToken()]), path);
        NHMigrateFile(NHRootifyPath(@"/var/mobile/Library/Preferences/com.nh.cfg.plist"), path);
        NHMigrateFile(NHRootifyPath(@"/var/mobile/Library/Preferences/com.map.settings.plist"), path);
    });
    return path;
}

/// HUD pid 文件（原 com.nh.hud.pid）
static inline NSString *NHPidPath(void) {
    static NSString *path = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *raw = [NSString stringWithFormat:
                         @"/var/mobile/Library/Caches/com.%@.run", NHDeviceToken()];
        path = NHRootifyPath(raw);
        NHMigrateFile(NHRootifyPath(@"/var/mobile/Library/Caches/com.nh.hud.pid"), path);
    });
    return path;
}

/// Darwin notify 名（原 com.nh.notification.*）
static inline const char *NHNotifyName(const char *kind) {
    static char launched[96];
    static char dismissal[96];
    static char reload[96];
    static char appreload[96];
    static char state[96];
    static char pidch[96];
    static char pauseHud[96];
    static char resumeHud[96];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        const char *t = NHDeviceToken().UTF8String;
        snprintf(launched, sizeof(launched), "com.%s.n.L", t);
        snprintf(dismissal, sizeof(dismissal), "com.%s.n.D", t);
        snprintf(reload, sizeof(reload), "com.%s.n.R", t);
        snprintf(appreload, sizeof(appreload), "com.%s.n.A", t);
        snprintf(state, sizeof(state), "com.%s.n.S", t);
        snprintf(pidch, sizeof(pidch), "com.%s.n.P", t);
        snprintf(pauseHud, sizeof(pauseHud), "com.%s.n.H", t);   // hide overlay, keep process
        snprintf(resumeHud, sizeof(resumeHud), "com.%s.n.V", t); // show overlay again
    });
    if (kind && strcmp(kind, "launched") == 0) return launched;
    if (kind && strcmp(kind, "dismissal") == 0) return dismissal;
    if (kind && strcmp(kind, "reload") == 0) return reload;
    if (kind && strcmp(kind, "appreload") == 0) return appreload;
    if (kind && strcmp(kind, "state") == 0) return state;
    if (kind && strcmp(kind, "pid") == 0) return pidch;
    if (kind && strcmp(kind, "pause") == 0) return pauseHud;
    if (kind && strcmp(kind, "resume") == 0) return resumeHud;
    return dismissal;
}

/// 叠层进程角色：每机派生 env + argv（不用 Helium 同源 -hud/-check/-exit）
/// persona spawn 下自定义 env 可能丢，故 argv 为可靠主通道，env 作辅。
static inline const char *NHRoleEnvKey(void) {
    static char key[64];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        snprintf(key, sizeof(key), "_C%s_R", NHDeviceToken().UTF8String);
    });
    return key;
}

/// 形如 --a1b2c3d4，非 -hud 明文
static inline const char *NHRoleArgValue(void) {
    static char arg[72];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        snprintf(arg, sizeof(arg), "--%s", NHDeviceToken().UTF8String);
    });
    return arg;
}

static inline void NHMarkOverlayRole(void) {
    setenv(NHRoleEnvKey(), "1", 1);
}

static inline void NHClearOverlayRole(void) {
    unsetenv(NHRoleEnvKey());
}

static inline BOOL NHIsOverlayRole(void) {
    const char *v = getenv(NHRoleEnvKey());
    return (v && v[0] == '1' && v[1] == '\0') ? YES : NO;
}

static inline BOOL NHIsOverlayArgv(int argc, char *argv[]) {
    if (argc <= 1 || !argv || !argv[1]) return NO;
    return strcmp(argv[1], NHRoleArgValue()) == 0 ? YES : NO;
}

static inline BOOL NHShouldRunAsOverlay(int argc, char *argv[]) {
    return NHIsOverlayRole() || NHIsOverlayArgv(argc, argv);
}

// ---- 跨进程开关：notify_set_state（可无文件）----
// bit0 reading 1 count 2 line 3 box 4 health 5 info 6 bone 7 overlay 8 dbglog 9 persist
// bit10-11 drawFps：0=跟屏刷 1=60 2=90 3=120
// bit63 = 有效标记（曾发布过）
enum {
    NHBitReading = 0,
    NHBitCount   = 1,
    NHBitLine    = 2,
    NHBitBox     = 3,
    NHBitHealth  = 4,
    NHBitInfo    = 5,
    NHBitBone    = 6,
    NHBitOverlay = 7,
    NHBitDbglog  = 8,
    NHBitPersist = 9, // 1=写配置文件，0=不生成文件（仅内存+notify）
    NHBitFps0    = 10,
    NHBitFps1    = 11,
    NHBitValid   = 63,
};

/// prefs drawFps：0=跟屏刷，60/90/120=限帧
static inline int NHFpsModeFromValue(NSInteger fps) {
    if (fps == 60) return 1;
    if (fps == 90) return 2;
    if (fps == 120) return 3;
    return 0;
}

static inline NSInteger NHFpsValueFromMode(int mode) {
    switch (mode & 3) {
        case 1: return 60;
        case 2: return 90;
        case 3: return 120;
        default: return 0;
    }
}

static inline int NHStateToken(void) {
    static int token = -1;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        notify_register_check(NHNotifyName("state"), &token);
    });
    return token;
}

static inline int NHPidToken(void) {
    static int token = -1;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        notify_register_check(NHNotifyName("pid"), &token);
    });
    return token;
}

static inline uint64_t NHStateGet(void) {
    uint64_t v = 0;
    notify_get_state(NHStateToken(), &v);
    return v;
}

static inline void NHStateSet(uint64_t v) {
    v |= (1ULL << NHBitValid);
    notify_set_state(NHStateToken(), v);
    notify_post(NHNotifyName("state"));
}

static inline bool NHStateValid(uint64_t v) {
    return (v & (1ULL << NHBitValid)) != 0;
}

static inline bool NHStateBit(uint64_t v, int bit) {
    return (v & (1ULL << bit)) != 0;
}

static inline uint64_t NHStateWithBit(uint64_t v, int bit, bool on) {
    if (on) return v | (1ULL << bit);
    return v & ~(1ULL << bit);
}

/// 默认落盘；仅当 state 有效且 persist=0 时关闭落盘
static inline bool NHPersistFilesEnabled(void) {
    uint64_t v = NHStateGet();
    if (!NHStateValid(v)) return YES;
    return NHStateBit(v, NHBitPersist);
}

static inline void NHPublishPid(pid_t pid) {
    notify_set_state(NHPidToken(), (uint64_t)(uint32_t)pid);
    notify_post(NHNotifyName("pid"));
}

static inline pid_t NHReadPid(void) {
    uint64_t v = 0;
    notify_get_state(NHPidToken(), &v);
    return (pid_t)(uint32_t)v;
}

static inline void NHClearPid(void) {
    notify_set_state(NHPidToken(), 0);
}

/// 从字典发布整表状态（persist 缺省时保持当前/默认开）
static inline void NHPrefsPublishDict(NSDictionary *cfg) {
    if (!cfg) return;
    uint64_t cur = NHStateGet();
    bool persist = NHStateValid(cur) ? NHStateBit(cur, NHBitPersist) : YES;
    if (cfg[@"persist"] != nil) persist = [cfg[@"persist"] boolValue];
    uint64_t v = 0;
    if ([[cfg objectForKey:@"reading"] boolValue]) v = NHStateWithBit(v, NHBitReading, YES);
    if ([[cfg objectForKey:@"count"] boolValue])   v = NHStateWithBit(v, NHBitCount, YES);
    if ([[cfg objectForKey:@"line"] boolValue])    v = NHStateWithBit(v, NHBitLine, YES);
    if ([[cfg objectForKey:@"box"] boolValue])     v = NHStateWithBit(v, NHBitBox, YES);
    if ([[cfg objectForKey:@"health"] boolValue])  v = NHStateWithBit(v, NHBitHealth, YES);
    if ([[cfg objectForKey:@"info"] boolValue])    v = NHStateWithBit(v, NHBitInfo, YES);
    if ([[cfg objectForKey:@"bone"] boolValue])    v = NHStateWithBit(v, NHBitBone, YES);
    if ([[cfg objectForKey:@"overlay"] boolValue]) v = NHStateWithBit(v, NHBitOverlay, YES);
    if ([[cfg objectForKey:@"dbglog"] boolValue])  v = NHStateWithBit(v, NHBitDbglog, YES);
    if (persist) v = NHStateWithBit(v, NHBitPersist, YES);
    {
        NSInteger fpsVal = 0;
        if (cfg[@"drawFps"] != nil) fpsVal = [cfg[@"drawFps"] integerValue];
        else if (NHStateValid(cur)) {
            int oldMode = (NHStateBit(cur, NHBitFps0) ? 1 : 0) | (NHStateBit(cur, NHBitFps1) ? 2 : 0);
            fpsVal = NHFpsValueFromMode(oldMode);
        }
        int mode = NHFpsModeFromValue(fpsVal);
        if (mode & 1) v = NHStateWithBit(v, NHBitFps0, YES);
        if (mode & 2) v = NHStateWithBit(v, NHBitFps1, YES);
    }
    NHStateSet(v);
}

static inline NSMutableDictionary *NHPrefsDictFromState(void) {
    uint64_t v = NHStateGet();
    if (!NHStateValid(v)) return nil;
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    d[@"reading"] = @(NHStateBit(v, NHBitReading));
    d[@"count"]   = @(NHStateBit(v, NHBitCount));
    d[@"line"]    = @(NHStateBit(v, NHBitLine));
    d[@"box"]     = @(NHStateBit(v, NHBitBox));
    d[@"health"]  = @(NHStateBit(v, NHBitHealth));
    d[@"info"]    = @(NHStateBit(v, NHBitInfo));
    d[@"bone"]    = @(NHStateBit(v, NHBitBone));
    d[@"overlay"] = @(NHStateBit(v, NHBitOverlay));
    d[@"dbglog"]  = @(NHStateBit(v, NHBitDbglog));
    d[@"persist"] = @(NHStateBit(v, NHBitPersist));
    {
        int mode = (NHStateBit(v, NHBitFps0) ? 1 : 0) | (NHStateBit(v, NHBitFps1) ? 2 : 0);
        d[@"drawFps"] = @(NHFpsValueFromMode(mode));
    }
    return d;
}

/// 写配置（persist=0 时只走 notify，并尽量删掉已有文件）
static inline void NHPrefsWrite(NSDictionary *cfg) {
    if (!cfg) return;
    NHPrefsPublishDict(cfg);
    if (!NHPersistFilesEnabled()) {
        NSString *path = NHPrefsPath();
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        // pid 文件也不留
        [[NSFileManager defaultManager] removeItemAtPath:NHPidPath() error:nil];
        return;
    }
    NSString *path = NHPrefsPath();
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = [path stringByDeletingLastPathComponent];
    if (![fm fileExistsAtPath:dir]) {
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSMutableDictionary *merged = [NSMutableDictionary dictionaryWithContentsOfFile:path] ?: [NSMutableDictionary dictionary];
    [merged addEntriesFromDictionary:cfg];
    [merged writeToFile:path atomically:YES];
}

/// 读配置：优先磁盘（落盘模式）；无文件则用 notify；再无则 nil
static inline NSDictionary *NHPrefsRead(void) {
    if (NHPersistFilesEnabled()) {
        NSDictionary *disk = [NSDictionary dictionaryWithContentsOfFile:NHPrefsPath()];
        if (disk) {
            // 同步到 notify，方便无落盘切换瞬间 HUD 仍可读
            NHPrefsPublishDict(disk);
            return disk;
        }
    }
    return NHPrefsDictFromState();
}

#ifdef __cplusplus
}
#endif

#endif /* NHIdentity_h */
