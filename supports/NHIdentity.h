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
    static char hudteardown[96];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        const char *t = NHDeviceToken().UTF8String;
        snprintf(launched, sizeof(launched), "com.%s.n.L", t);
        snprintf(dismissal, sizeof(dismissal), "com.%s.n.D", t);
        snprintf(reload, sizeof(reload), "com.%s.n.R", t);
        snprintf(appreload, sizeof(appreload), "com.%s.n.A", t);
        snprintf(state, sizeof(state), "com.%s.n.S", t);
        snprintf(pidch, sizeof(pidch), "com.%s.n.P", t);
        snprintf(hudteardown, sizeof(hudteardown), "com.%s.n.T", t);
    });
    if (kind && strcmp(kind, "launched") == 0) return launched;
    if (kind && strcmp(kind, "dismissal") == 0) return dismissal;
    if (kind && strcmp(kind, "reload") == 0) return reload;
    if (kind && strcmp(kind, "appreload") == 0) return appreload;
    if (kind && strcmp(kind, "state") == 0) return state;
    if (kind && strcmp(kind, "pid") == 0) return pidch;
    if (kind && strcmp(kind, "hudteardown") == 0) return hudteardown;
    return dismissal;
}

/// 叠层进程角色：用每机派生 env，替代 Helium 同源 argv（-hud / -check / -exit）
static inline const char *NHRoleEnvKey(void) {
    static char key[64];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        snprintf(key, sizeof(key), "_C%s_R", NHDeviceToken().UTF8String);
    });
    return key;
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

// ---- 跨进程开关：notify_set_state（可无文件）----
// bit0 reading 1 count 2 line 3 box 4 health 5 info 6 bone 7 overlay 8 dbglog 9 persist
// bit10-11 drawFps：0=跟屏刷 1=60 2=90 3=120（30 与样式等精确值走 drx extras）
// bit12 weapon 13 dist 14 behind 15 loot
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
    NHBitWeapon  = 12,
    NHBitDist    = 13,
    NHBitBehind  = 14,
    NHBitLoot    = 15,
    NHBitValid   = 63,
};

/// 物资配置路径（短前缀 wzi_；兼容旧 wuzi_）
static inline NSString *NHWuziPath(void) {
    static NSString *path = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *token = NHDeviceToken();
        path = [NHConfigDirectory() stringByAppendingPathComponent:
                [NSString stringWithFormat:@"wzi_%@.txt", token]];
        NHMigrateFile([NHConfigDirectory() stringByAppendingPathComponent:
                       [NSString stringWithFormat:@"wuzi_%@.txt", token]], path);
    });
    return path;
}

/// 绘制扩展项（短前缀 drx_；兼容旧 drawx_）：跨进程，不受「配置落盘」影响
static inline NSString *NHDrawExtrasPath(void) {
    static NSString *path = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *token = NHDeviceToken();
        path = [NHConfigDirectory() stringByAppendingPathComponent:
                [NSString stringWithFormat:@"drx_%@.plist", token]];
        NHMigrateFile([NHConfigDirectory() stringByAppendingPathComponent:
                       [NSString stringWithFormat:@"drawx_%@.plist", token]], path);
    });
    return path;
}

static inline NSArray<NSString *> *NHDrawExtrasKeys(void) {
    // 始终写 drx 旁路：默认不落盘时 HUD 仍能读到（对标 hideAi / drawDist）
    // 自瞄 / 模型漏打键必须在此，否则开关在 UI 显示开、绘制进程仍读到关
    return @[
        @"weaponStyle", @"healthStyle", @"behindStyle", @"behindMode", @"lootMode",
        @"lootSize", @"infoSize", @"drawDist", @"behindDist", @"boneDist",
        @"boneThick", @"rayThick", @"drawFps", @"hideAi",
        // —— 绘制颜色（对标 qwer 绘制设置）——
        @"人机颜色", @"名字颜色", @"射线颜色", @"掩体颜色",
        @"距离颜色", @"队伍颜色", @"骨骼颜色",
        // —— 模型漏打（对标 qwer 绘制功能/绘制设置）——
        @"模型渲染", @"漏打距离",
        // —— 自瞄功能（对标 qwer 自瞄页全部项）——
        @"开启自瞄", @"自瞄连线", @"显示范围",
        @"悬浮球", @"悬浮球大小", @"自瞄速度",
        @"抖动幅度", @"抖动频率", @"抖动波动",
        @"显示触摸区域", @"触摸区域宽度", @"触摸区域高度", @"触摸区域X", @"触摸区域Y",
        @"自瞄大小", @"动态圈", @"动态圈最小", @"动态圈速度", @"动态圈插值方式",
        @"开镜自瞄范围", @"开镜动态圈", @"显示开镜自瞄范围",
        @"内圈大小", @"显示内圈",
        @"烟雾不瞄", @"烟雾范围",
        @"自瞄距离", @"腰射距离", @"压枪力度",
        @"自瞄血量", @"满血距离",
        // —— 实验-拟人自瞄（外强内柔 / 距离衰减）——
        @"吸附曲线", @"外圈速度", @"内圈速度", @"变速过渡宽",
        @"距离衰减", @"衰减起点", @"衰减终点", @"远端拉力",
        @"TouchSenderID", @"TouchSenderIDHex",
    ];
}

static inline void NHDrawExtrasWriteFromDict(NSDictionary *cfg) {
    if (!cfg) return;
    NSMutableDictionary *patch = [NSMutableDictionary dictionary];
    for (NSString *k in NHDrawExtrasKeys()) {
        id v = cfg[k];
        if (v != nil) patch[k] = v;
    }
    if (patch.count == 0) return;
    NSString *path = NHDrawExtrasPath();
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = [path stringByDeletingLastPathComponent];
    if (![fm fileExistsAtPath:dir]) {
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSMutableDictionary *merged = [NSMutableDictionary dictionaryWithContentsOfFile:path] ?: [NSMutableDictionary dictionary];
    [merged addEntriesFromDictionary:patch];
    [merged writeToFile:path atomically:YES];
}

static inline NSDictionary *NHDrawExtrasRead(void) {
    return [NSDictionary dictionaryWithContentsOfFile:NHDrawExtrasPath()] ?: @{};
}

/// prefs drawFps：notify 仅编码 60/90/120；0/30 以 drx extras 为准（未配置时业务层默认 60）
static inline int NHFpsModeFromValue(NSInteger fps) {
    if (fps == 60) return 1;
    if (fps == 90) return 2;
    if (fps == 120) return 3;
    return 0; // 跟屏刷或 30（精确值写 extras）
}

static inline NSInteger NHFpsValueFromMode(int mode) {
    switch (mode & 3) {
        case 1: return 60;
        case 2: return 90;
        case 3: return 120;
        default: return 0; // 未编码：由 extras / 业务默认 60 决定
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

/// 默认不落盘；仅当 state 有效且 persist=1 时开启落盘
static inline bool NHPersistFilesEnabled(void) {
    uint64_t v = NHStateGet();
    if (!NHStateValid(v)) return NO;
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

/// 从字典发布状态：只更新 cfg 里出现的键，避免稀疏写入把其它开关清零
static inline void NHPrefsPublishDict(NSDictionary *cfg) {
    if (!cfg) return;
    uint64_t cur = NHStateGet();
    uint64_t v = NHStateValid(cur) ? cur : 0;
    if (cfg[@"reading"] != nil) v = NHStateWithBit(v, NHBitReading, [cfg[@"reading"] boolValue]);
    if (cfg[@"count"]   != nil) v = NHStateWithBit(v, NHBitCount,   [cfg[@"count"] boolValue]);
    if (cfg[@"line"]    != nil) v = NHStateWithBit(v, NHBitLine,    [cfg[@"line"] boolValue]);
    if (cfg[@"box"]     != nil) v = NHStateWithBit(v, NHBitBox,     [cfg[@"box"] boolValue]);
    if (cfg[@"health"]  != nil) v = NHStateWithBit(v, NHBitHealth,  [cfg[@"health"] boolValue]);
    if (cfg[@"info"]    != nil) v = NHStateWithBit(v, NHBitInfo,    [cfg[@"info"] boolValue]);
    if (cfg[@"bone"]    != nil) v = NHStateWithBit(v, NHBitBone,    [cfg[@"bone"] boolValue]);
    if (cfg[@"overlay"] != nil) v = NHStateWithBit(v, NHBitOverlay, [cfg[@"overlay"] boolValue]);
    if (cfg[@"dbglog"]  != nil) v = NHStateWithBit(v, NHBitDbglog,  [cfg[@"dbglog"] boolValue]);
    if (cfg[@"weapon"]  != nil) v = NHStateWithBit(v, NHBitWeapon,  [cfg[@"weapon"] boolValue]);
    if (cfg[@"dist"]    != nil) v = NHStateWithBit(v, NHBitDist,    [cfg[@"dist"] boolValue]);
    if (cfg[@"behind"]  != nil) v = NHStateWithBit(v, NHBitBehind,  [cfg[@"behind"] boolValue]);
    if (cfg[@"loot"]    != nil) v = NHStateWithBit(v, NHBitLoot,    [cfg[@"loot"] boolValue]);
    if (cfg[@"persist"] != nil) {
        v = NHStateWithBit(v, NHBitPersist, [cfg[@"persist"] boolValue]);
    } else if (!NHStateValid(cur)) {
        v = NHStateWithBit(v, NHBitPersist, NO); // 默认关
    }
    if (cfg[@"drawFps"] != nil) {
        int mode = NHFpsModeFromValue([cfg[@"drawFps"] integerValue]);
        v = NHStateWithBit(v, NHBitFps0, (mode & 1) != 0);
        v = NHStateWithBit(v, NHBitFps1, (mode & 2) != 0);
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
    d[@"weapon"]  = @(NHStateBit(v, NHBitWeapon));
    d[@"dist"]    = @(NHStateBit(v, NHBitDist));
    d[@"behind"]  = @(NHStateBit(v, NHBitBehind));
    d[@"loot"]    = @(NHStateBit(v, NHBitLoot));
    {
        int mode = (NHStateBit(v, NHBitFps0) ? 1 : 0) | (NHStateBit(v, NHBitFps1) ? 2 : 0);
        d[@"drawFps"] = @(NHFpsValueFromMode(mode));
    }
    return d;
}

/// 写配置：扩展项始终写入 drx 旁路；开关仍走 notify；落盘开时再写 cfg
static inline void NHPrefsWrite(NSDictionary *cfg) {
    if (!cfg) return;
    NHDrawExtrasWriteFromDict(cfg);
    NHPrefsPublishDict(cfg);
    if (!NHPersistFilesEnabled()) {
        NSString *path = NHPrefsPath();
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
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

/// 读配置：notify/磁盘开关 + 始终合并 drx 扩展项（样式/距离/fps）
static inline NSDictionary *NHPrefsRead(void) {
    NSMutableDictionary *out = nil;
    if (NHPersistFilesEnabled()) {
        NSDictionary *disk = [NSDictionary dictionaryWithContentsOfFile:NHPrefsPath()];
        if (disk) {
            NHPrefsPublishDict(disk);
            out = [NSMutableDictionary dictionaryWithDictionary:disk];
        }
    }
    if (!out) {
        NSDictionary *st = NHPrefsDictFromState();
        out = st ? [NSMutableDictionary dictionaryWithDictionary:st] : [NSMutableDictionary dictionary];
    }
    NSDictionary *extras = NHDrawExtrasRead();
    if (extras.count > 0) {
        [out addEntriesFromDictionary:extras];
    }
    return out.count > 0 ? out : nil;
}

#ifdef __cplusplus
}
#endif

#endif /* NHIdentity_h */
