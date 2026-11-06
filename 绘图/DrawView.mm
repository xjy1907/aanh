#include "DrawView.hpp"
#include <mutex>
#include <vector>
#include <cstdint>
#include <cstring>
#include <cstdarg>
#include <cerrno>
#include <unistd.h>
#include <mach/mach.h>
#include <mach/thread_act.h>
#include <mach/thread_info.h>
#include "BBZGui.h"
#import "Aim/AimFloatBridge.h"

#import "DOJailbreaker.h"
#import "HUDHelper.h"
#include <libjailbreak/info.h>
#include <libjailbreak/primitives_external.h>

extern "C" uint32_t kread32(uint64_t where);
extern "C" uint64_t kread64(uint64_t where);
extern "C" void kfd_log(const char *format, ...);
extern "C" bool NHDebugLogEnabled(void);

#ifdef __cplusplus
extern "C" {
#endif
bool exploit_mach_readbuf(pid_t pid, uint64_t base, void* output, size_t size);
void exploit_v2p_cache_clear(void);
void KernelLogLine(const char *line);
void SetReadingEnabled(bool enabled);
bool IsReadingEnabled(void);
#ifdef __cplusplus
}
#endif

@implementation DrawWindow

static pid_t gamePid = -1;
static uint64_t 模块地址 = 0;
static bool bOffsetFindDNE = false;
static ImVec2 CanvasSize;
static bool gReadingEnabled = false;
bool 总开关 = true;

// 绘制开关（对标 wasd / BBZView plist key）
static bool 显示人数 = false; // 保留开关；真人/人机条常显，不再门控
static bool 显示射线 = false;
static bool 显示方框 = false;
static bool 显示血量 = false;
static bool 显示信息 = false;
static bool 显示骨骼 = false;
static bool 人机隐藏 = false; // 对标 wasd：静态扫描跳过人机
static bool 显示手持 = false, 显示距离 = false, 显示背敌 = false, 显示物资 = false;
static int 手持样式 = 0; // 0=文字 1=图片（对标 wasd 手持图）
static int 物资大小 = 13;
static int 信息大小 = 12; // 名字/队号/距离/手持/背敌距离字号
static int 背敌样式 = 1; // 0雷达 1箭头 2花祭；默认箭头
static int 背敌模式 = 1; // 0背后模式 1全景模式；默认全景
static int 血量样式 = 1; // 0圆弧 1经典 2花祭；默认经典
static int 物资显示模式 = 0; // 0正常(持枪也显示) 1空手(旧逻辑)；默认正常
static float 背敌距离 = 252.f;
static float 射线粗细 = 1.0f;
static float 骨骼粗细 = 1.0f;
static float 骨骼距离 = 30.0f;
static float 绘制距离上限 = 252.f; // 不含物资；物资用各自配置距离
static float gCurrentCPUUsage = 0.0f;

// —— 静态玩家缓存（对标 wasd readStaticData，~2s 扫一次 ActorArray）——
struct CachedPlayer {
    uint64_t addr;
    int team;
    bool bIsAI;
};
struct CachedMaterial {
    uint64_t addr;
    bool isGrenade;
    bool isSmoke;
    std::string className;
    std::string displayName;
    float minDistance, maxDistance;
    ImU32 color;
    int weaponID;
    bool isBox;
};
static struct {
    uint64_t gWorld = 0;
    uint64_t playerController = 0;
    uint64_t playerCameraManager = 0;
    uint64_t myCharacter = 0;
    int myTeam = 0;
    bool isGameStart = false;
    std::vector<CachedPlayer> players;
    std::vector<CachedMaterial> materials;
} gStatic;

// 对标 wasd/qwer IM_COL32 默认色（可被绘制设置覆盖）
static ImU32 Colour_白色 = IM_COL32(255, 255, 255, 255);
static ImU32 Colour_黄色 = IM_COL32(255, 255, 0, 255);
static ImU32 Colour_绿色 = IM_COL32(0, 200, 0, 255);
static ImU32 Colour_射线 = IM_COL32(240, 240, 0, 255);
static ImU32 Colour_骨骼 = IM_COL32(0, 200, 0, 255);
static ImU32 Colour_人机 = IM_COL32(200, 0, 0, 200);
static ImU32 Colour_名字 = IM_COL32(255, 255, 255, 255);
static ImU32 Colour_距离 = IM_COL32(240, 240, 240, 255);
static ImU32 Colour_队伍 = IM_COL32(255, 223, 0, 255);
static ImU32 Colour_掩体 = IM_COL32(255, 0, 0, 255);

static ImU32 ParseHexColorString(NSString *hexString) {
    if (!hexString || hexString.length == 0) {
        return IM_COL32(255, 255, 255, 255);
    }
    NSString *cleanHex = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    unsigned int r = 255, g = 255, b = 255, a = 255;
    if (cleanHex.length == 8) {
        // 对标 qwer：8 位按 RRGGBBAA；人机默认 C8FF0000 实际为兼容存储，回落用固定默认
        [[NSScanner scannerWithString:[cleanHex substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&r];
        [[NSScanner scannerWithString:[cleanHex substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&g];
        [[NSScanner scannerWithString:[cleanHex substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&b];
        [[NSScanner scannerWithString:[cleanHex substringWithRange:NSMakeRange(6, 2)]] scanHexInt:&a];
    } else if (cleanHex.length == 6) {
        [[NSScanner scannerWithString:[cleanHex substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&r];
        [[NSScanner scannerWithString:[cleanHex substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&g];
        [[NSScanner scannerWithString:[cleanHex substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&b];
    }
    return IM_COL32(r, g, b, a);
}

static ImU32 PrefColor(NSDictionary *cfg, NSString *key, ImU32 fallback) {
    id v = cfg[key];
    if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0) {
        // qwer 人机默认串 C8FF0000 按 RGBA 会变成透明绿，保持历史视觉
        if ([key isEqualToString:@"人机颜色"] && [v isEqualToString:@"C8FF0000"]) {
            return IM_COL32(200, 0, 0, 200);
        }
        return ParseHexColorString((NSString *)v);
    }
    return fallback;
}

static float GetCurrentProcessCPUUsage(void) {
    kern_return_t kr;
    thread_array_t thread_list = nullptr;
    mach_msg_type_number_t thread_count = 0;
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) return 0.0f;

    float total_cpu = 0.0f;
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        thread_info_data_t thinfo;
        mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[i], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) continue;
        thread_basic_info_t basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            total_cpu += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0f;
        }
    }
    vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    return total_cpu;
}

static void DrawDbg(const char *fmt, ...) {
    if (!NHDebugLogEnabled()) return;
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    // KernelLogLine 内部已同步写 kfd_debug.log，避免重复落盘
    KernelLogLine(buf);
}

static NSString *PrefsPath(void);

// 主 App / HUD：优先 notify 同步；配置落盘开时才写文件
static void PersistReadingFlag(bool enabled) {
    NSMutableDictionary *cfg = [NSMutableDictionary dictionary];
    NSDictionary *cur = NHPrefsRead();
    if (cur) [cfg addEntriesFromDictionary:cur];
    cfg[@"reading"] = @(enabled);
    NHPrefsWrite(cfg);
}

static bool LoadReadingFlagFromDisk(void) {
    NSDictionary *cfg = NHPrefsRead();
    if (!cfg) {
        // 无文件且 notify 未发布：保持内存态
        return gReadingEnabled;
    }
    return [[cfg objectForKey:@"reading"] boolValue];
}

extern "C" void SetReadingEnabled(bool enabled) {
    gReadingEnabled = enabled;
    PersistReadingFlag(enabled);
    if (!enabled) {
        gamePid = -1;
        模块地址 = 0;
        bOffsetFindDNE = false;
        DrawDbg("[读取] 已停止 (pid=%d) persist=%d", (int)getpid(), (int)NHPersistFilesEnabled());
    } else {
        DrawDbg("[读取] 已开启 (pid=%d) persist=%d —— HUD 经 notify/磁盘同步", (int)getpid(), (int)NHPersistFilesEnabled());
    }
}

extern "C" bool IsReadingEnabled(void) {
    gReadingEnabled = LoadReadingFlagFromDisk();
    return gReadingEnabled;
}

extern "C" void ResetKernelStatus() {
    DrawDbg("[重置] ResetKernelStatus 开始 pid=%d", (int)getpid());
    gReadingEnabled = false;
    PersistReadingFlag(false);
    gamePid = -1;
    模块地址 = 0;
    bOffsetFindDNE = false;
    gStatic.isGameStart = false;
    gStatic.players.clear();
    gStatic.materials.clear();
    exploit_v2p_cache_clear();
    exploit_mach_cleanup();

    DOJailbreaker *jb = [DOJailbreaker sharedInstance];
    jb.isSuccess = NO;

    // 清掉「同开机周期自动恢复」标记，下次需再点「初始化内核」
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JB.KernelReadyBootTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // 必须拆掉旧 HUD（persist=0 时 IsHUDEnabled 常误判为关，仍要发 dismiss+kill）：
    // 残留叠层占 PhysRW 时再 spawn 新 HUD，二次 kopen 会卡死且无水印。
    DrawDbg("[重置] 强制关闭 HUD 叠层（dismiss+kill）");
    SetHUDEnabled(NO);

    // 软重置：只清应用层状态。禁止调用 finalize→rebootUserspace。
    // 主进程 PhysRW 原语保留；下次初始化 probe 恢复 isSuccess。
    DrawDbg("[重置] ResetKernelStatus 完成 (软重置: 已关HUD, reading/偏移已清, 主进程原语保留)");
}

extern "C" void ResetKernelStatusHard(void) {
    DrawDbg("[硬重置] ResetKernelStatusHard 开始 pid=%d", (int)getpid());
    ResetKernelStatus();
    [[DOJailbreaker sharedInstance] hardTeardownKernelPrimitives];
    DrawDbg("[硬重置] ResetKernelStatusHard 完成（软重置+硬拆除原语）");
}

bool readMemory(uint64_t address, void *buffer, size_t size) {
    if (!IsValidAddr(address) || size == 0 || gamePid <= 0) return false;
    return exploit_mach_readbuf(gamePid, address, buffer, size);
}

template<typename T> T vm_read(uint64_t address) {
    T data{}; readMemory(address, &data, sizeof(T)); return data;
}

#include "游戏/绘制类型.h"
#include "游戏/SDK.h"
#include "游戏/绘制算法.h"
#include "游戏/武器名称.h"
#include "游戏/WeaponTextures.h"
#include "Aim/AimAssist.hpp"
#include <sstream>
#include <map>
#include <unordered_map>

bool getbbz(); // 前向声明：供 7s dump 调用

// —— 物资配置（对标 wasd LoadItemConfigs）——
struct ItemConfig {
    std::string className;
    std::string displayName;
    float minDistance;
    float maxDistance;
    ImU32 color;
    int weaponID;
    bool isBox;
};
static std::vector<ItemConfig> itemConfigs;

static bool IsBoxType(const std::string &className) {
    return className.find("BP_AirdropChipBox_C") != std::string::npos ||
           className.find("SupplyBox") != std::string::npos ||
           className.find("SafeBox") != std::string::npos ||
           className.find("HardRadiationBox") != std::string::npos ||
           className.find("PeakRadiationBox") != std::string::npos ||
           className.find("MilitarySupp") != std::string::npos;
}

static ImU32 ParseHexColor(const std::string &hex) {
    unsigned int r = 255, g = 255, b = 255, a = 255;
    if (hex.length() == 8) {
        sscanf(hex.c_str(), "%02x%02x%02x%02x", &r, &g, &b, &a);
    } else if (hex.length() == 6) {
        sscanf(hex.c_str(), "%02x%02x%02x", &r, &g, &b);
    }
    return IM_COL32(r, g, b, a);
}

static NSTimeInterval sWuziMtime = -1.0;

static void LoadItemConfigsFromFile(void) {
    NSString *path = NHWuziPath();
    if (!path) return;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    NSDate *mod = attrs[NSFileModificationDate];
    NSTimeInterval mt = mod ? mod.timeIntervalSince1970 : 0;
    // mtime 未变且已有缓存：跳过整文件解析
    if (mt > 0 && mt == sWuziMtime && !itemConfigs.empty()) return;

    itemConfigs.clear();
    NSError *err = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (!fileContent) return;
    std::string configText([fileContent UTF8String]);
    std::istringstream stream(configText);
    std::string line;
    while (std::getline(stream, line)) {
        if (line.empty() || line[0] == '#') continue;
        std::istringstream lineStream(line);
        std::string className, displayName, hexColor;
        float minDist = 0, maxDist = 0;
        int weaponID = 1;
        if (std::getline(lineStream, className, '|') &&
            std::getline(lineStream, displayName, '|') &&
            (lineStream >> minDist) && lineStream.ignore(1) &&
            (lineStream >> maxDist) && lineStream.ignore(1) &&
            std::getline(lineStream, hexColor, '|')) {
            if (!(lineStream >> weaponID)) weaponID = 1;
            ItemConfig config;
            config.className = className;
            config.displayName = displayName;
            config.minDistance = minDist;
            config.maxDistance = maxDist;
            config.color = ParseHexColor(hexColor);
            config.weaponID = weaponID;
            config.isBox = IsBoxType(className);
            itemConfigs.push_back(config);
        }
    }
    sWuziMtime = mt;
}

static const ItemConfig *FindItemConfig(const std::string &className) {
    for (const auto &config : itemConfigs) {
        if (className.find(config.className) != std::string::npos) {
            return &config;
        }
    }
    return nullptr;
}

// 背敌箭头本体（angle 已算好；固定半径环绕屏幕中心）
static void DrawBehindArrowAtAngle(float angle, float distance, bool withDistanceText) {
    ImU32 arrowColor;
    if (distance <= 50) arrowColor = IM_COL32(255, 0, 0, 230);
    else if (distance <= 100) arrowColor = IM_COL32(0, 255, 0, 230);
    else if (distance <= 150) arrowColor = IM_COL32(0, 0, 255, 230);
    else arrowColor = IM_COL32(255, 255, 255, 230);

    float centerX = CanvasSize.x / 2.0f;
    float centerY = CanvasSize.y / 2.0f;
    float radius = 20.0f;
    float arrowHeight = radius * 0.6f;
    float arrowWidth = radius * 1.8f;
    float circleRadius = 45.0f + 20.0f + 55.0f;
    float arrowCenterX = centerX + circleRadius * cosf(angle);
    float arrowCenterY = centerY + circleRadius * sinf(angle);

    ImVec2 points[3] = {
        ImVec2(-arrowWidth / 2, -arrowHeight / 2),
        ImVec2(arrowWidth / 2, 0),
        ImVec2(-arrowWidth / 2, arrowHeight / 2)
    };
    for (int i = 0; i < 3; i++) {
        float x = points[i].x, y = points[i].y;
        points[i].x = arrowCenterX + x * cosf(angle) - y * sinf(angle);
        points[i].y = arrowCenterY + x * sinf(angle) + y * cosf(angle);
    }
    ImDrawList *dl = BBZGUI::GetForegroundDrawList();
    if (!dl) return;
    dl->AddPolyline(points, 3, arrowColor, ImDrawFlags_Closed, 2.0f);

    if (!withDistanceText) return;
    char distanceText[16];
    snprintf(distanceText, sizeof(distanceText), "%d", (int)distance);
    float textOffsetX = -arrowWidth / 4;
    float textOffsetY = -5.0f;
    ImVec2 textPos;
    textPos.x = arrowCenterX + textOffsetX * cosf(angle) - textOffsetY * sinf(angle);
    textPos.y = arrowCenterY + textOffsetX * sinf(angle) + textOffsetY * cosf(angle);
    ImFont *font = BBZGUI::GetFont();
    if (font) {
        float fs = (float)信息大小;
        ImVec2 textSize = font->CalcTextSizeA(fs, MAXFLOAT, 0.0f, distanceText);
        textPos.x -= textSize.x / 2.0f;
        textPos.y -= textSize.y / 2.0f;
    }
    Draw::DrawText(distanceText, textPos, false, arrowColor, true, (float)信息大小);
}

static void DrawBehindRadarAtAngle(float angle, float distance) {
    ImU32 arrowColor;
    if (distance < 75.0f) arrowColor = IM_COL32(255, 0, 0, 255);
    else if (distance < 150.0f) arrowColor = IM_COL32(255, 255, 0, 255);
    else arrowColor = IM_COL32(0, 255, 0, 255);

    float centerX = CanvasSize.x / 2.0f;
    float centerY = CanvasSize.y / 2.0f;
    float circleRadius = fminf(80.0f + distance * 0.5f, 150.0f);
    float arrowCenterX = centerX + circleRadius * cosf(angle);
    float arrowCenterY = centerY + circleRadius * sinf(angle);

    ImVec2 points[4] = {
        ImVec2(0.0f, 0.0f),
        ImVec2(-22.0f, -8.6f),
        ImVec2(-18.0f, 0.0f),
        ImVec2(-22.0f, 8.6f)
    };
    float scale = 0.5f;
    for (int i = 0; i < 4; i++) {
        float x = points[i].x * scale, y = points[i].y * scale;
        points[i].x = arrowCenterX + x * cosf(angle) - y * sinf(angle);
        points[i].y = arrowCenterY + x * sinf(angle) + y * cosf(angle);
    }
    ImDrawList *dl = BBZGUI::GetForegroundDrawList();
    if (!dl) return;
    dl->AddConvexPolyFilled(points, 4, arrowColor);
    dl->AddPolyline(points, 4, IM_COL32(0, 0, 0, 255), ImDrawFlags_Closed, 1.5f);
}

// 按样式绘制背敌（angle 必须是 BehindAimAngle，顶角朝向敌人）
static void DrawBehindByStyle(float aimAngle, float distance) {
    if (背敌样式 == 0) {
        DrawBehindRadarAtAngle(aimAngle, distance);
    } else {
        // 箭头 / 花祭：同一套空心三角 + 距离（旋转与花祭一致）
        DrawBehindArrowAtAngle(aimAngle, distance, true);
    }
}

// 背后模式：仅屏幕外（对标花祭 isOutOfView）
static void OffScreenBehindMode(Vector3 worldPos, CoViewInfo pov, bool isOnScreen, float distance, float health) {
    if (health <= 0.f || isOnScreen) return;
    DrawBehindByStyle(BehindAimAngle(worldPos, pov), distance);
}

// 全景模式：始终指示；角度与花祭相同（屏心→敌人），身后也能对准
static void OffScreenPanorama(Vector3 worldPos, CoViewInfo pov, float distance, float health) {
    if (health <= 0.f) return;
    DrawBehindByStyle(BehindAimAngle(worldPos, pov), distance);
}

static NSString *PrefsPath(void) {
    return NHPrefsPath();
}

// 对标 wasd：prefs 不进热路径；后台/节流刷新即可
static void RefreshDrawPrefs(void) {
    NSDictionary *cfg = NHPrefsRead();
    if (!cfg) {
        // 无源：用内存态发布；仅落盘模式才写文件
        if (gReadingEnabled || 显示人数 || 显示射线 || 显示方框 || 显示血量 || 显示信息 || 显示骨骼 ||
            人机隐藏 || 显示手持 || 显示距离 || 显示背敌 || 显示物资) {
            NSMutableDictionary *restore = [NSMutableDictionary dictionary];
            restore[@"reading"] = @(gReadingEnabled);
            restore[@"count"] = @(显示人数);
            restore[@"line"] = @(显示射线);
            restore[@"box"] = @(显示方框);
            restore[@"health"] = @(显示血量);
            restore[@"info"] = @(显示信息);
            restore[@"bone"] = @(显示骨骼);
            restore[@"hideAi"] = @(人机隐藏);
            restore[@"weapon"] = @(显示手持);
            restore[@"weaponStyle"] = @(手持样式);
            restore[@"dist"] = @(显示距离);
            restore[@"behind"] = @(显示背敌);
            restore[@"loot"] = @(显示物资);
            restore[@"lootSize"] = @(物资大小);
            restore[@"infoSize"] = @(信息大小);
            restore[@"behindStyle"] = @(背敌样式);
            restore[@"behindMode"] = @(背敌模式);
            restore[@"behindDist"] = @(背敌距离);
            restore[@"healthStyle"] = @(血量样式);
            restore[@"lootMode"] = @(物资显示模式);
            restore[@"drawDist"] = @(绘制距离上限);
            restore[@"boneDist"] = @(骨骼距离);
            restore[@"boneThick"] = @(骨骼粗细);
            restore[@"rayThick"] = @(射线粗细);
            restore[@"persist"] = @(NHPersistFilesEnabled());
            NHPrefsWrite(restore);
        }
        return;
    }
    gReadingEnabled = [[cfg objectForKey:@"reading"] boolValue];
    显示人数 = [[cfg objectForKey:@"count"] boolValue];
    显示射线 = [[cfg objectForKey:@"line"] boolValue];
    显示方框 = [[cfg objectForKey:@"box"] boolValue];
    显示血量 = [[cfg objectForKey:@"health"] boolValue];
    显示信息 = [[cfg objectForKey:@"info"] boolValue];
    显示骨骼 = [[cfg objectForKey:@"bone"] boolValue];
    人机隐藏 = [[cfg objectForKey:@"hideAi"] boolValue];
    显示手持 = [[cfg objectForKey:@"weapon"] boolValue];
    显示距离 = [[cfg objectForKey:@"dist"] boolValue];
    显示背敌 = [[cfg objectForKey:@"behind"] boolValue];
    显示物资 = [[cfg objectForKey:@"loot"] boolValue];
    if (cfg[@"weaponStyle"] != nil) 手持样式 = [cfg[@"weaponStyle"] intValue];
    if (cfg[@"lootSize"] != nil) 物资大小 = [cfg[@"lootSize"] intValue];
    else 物资大小 = 13;
    if (cfg[@"infoSize"] != nil) 信息大小 = [cfg[@"infoSize"] intValue];
    else 信息大小 = 12;
    if (cfg[@"behindStyle"] != nil) 背敌样式 = [cfg[@"behindStyle"] intValue];
    else 背敌样式 = 1;
    if (cfg[@"behindMode"] != nil) 背敌模式 = [cfg[@"behindMode"] intValue];
    else 背敌模式 = 1;
    if (cfg[@"behindDist"] != nil) 背敌距离 = [cfg[@"behindDist"] floatValue];
    else 背敌距离 = 252.f;
    if (cfg[@"healthStyle"] != nil) 血量样式 = [cfg[@"healthStyle"] intValue];
    else 血量样式 = 1;
    if (cfg[@"lootMode"] != nil) 物资显示模式 = [cfg[@"lootMode"] intValue];
    else 物资显示模式 = 0;
    if (cfg[@"drawDist"] != nil) 绘制距离上限 = [cfg[@"drawDist"] floatValue];
    else 绘制距离上限 = 252.f;
    if (cfg[@"boneDist"] != nil) 骨骼距离 = [cfg[@"boneDist"] floatValue];
    else 骨骼距离 = 30.f;
    if (cfg[@"boneThick"] != nil) 骨骼粗细 = [cfg[@"boneThick"] floatValue];
    if (cfg[@"rayThick"] != nil) 射线粗细 = [cfg[@"rayThick"] floatValue];
    Colour_名字 = PrefColor(cfg, @"名字颜色", IM_COL32(255, 255, 255, 255));
    Colour_射线 = PrefColor(cfg, @"射线颜色", IM_COL32(240, 240, 0, 255));
    Colour_距离 = PrefColor(cfg, @"距离颜色", IM_COL32(240, 240, 240, 255));
    Colour_骨骼 = PrefColor(cfg, @"骨骼颜色", IM_COL32(0, 200, 0, 255));
    Colour_队伍 = PrefColor(cfg, @"队伍颜色", IM_COL32(255, 223, 0, 255));
    Colour_人机 = PrefColor(cfg, @"人机颜色", IM_COL32(200, 0, 0, 200));
    Colour_掩体 = PrefColor(cfg, @"掩体颜色", IM_COL32(255, 0, 0, 255));
    AimAssist::LoadFromPrefs(cfg);
}

// 不依赖绘制循环：每 7 秒把整条读取链写进 kfd_debug.log
static void DumpReadPipelineEvery7s(void) {
    // 先刷新/写回：清软件删掉 plist 时把内存态落回 Downloads
    RefreshDrawPrefs();
    bool readingDisk = LoadReadingFlagFromDisk();
    bool krkw = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
    DrawDbg("[7s] ===== dump pid=%d argvHUD? readingMem=%d readingDisk=%d krkw=%d gamePid=%d base=0x%llx =====",
            (int)getpid(), (int)gReadingEnabled, (int)readingDisk, (int)krkw, gamePid, 模块地址);

    gReadingEnabled = readingDisk; // 与磁盘对齐，供 getbbz 使用
    if (!readingDisk) {
        DrawDbg("[7s] reading=OFF —— 主界面点「开始读取」后 HUD 才会进对局读取");
        return;
    }
    if (!krkw) {
        DrawDbg("[7s] krkw=NO —— HUD 进程需自行完成内核初始化");
        return;
    }

    if (gamePid <= 0 || 模块地址 == 0) {
        getbbz();
        DrawDbg("[7s] after getbbz pid=%d base=0x%llx", gamePid, 模块地址);
        if (gamePid <= 0 || 模块地址 == 0) {
            DrawDbg("[7s] 仍无游戏进程/基址，确认 ShadowTrackerExt 已开");
            return;
        }
    }

    uint64_t GWorld = UNSIGN_PTR(vm_read<uint64_t>(模块地址 + SDK::GWorld));
    uint64_t NetDriver = IsValidAddr(GWorld) ? UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::NetDriver)) : 0;
    uint64_t GS = IsValidAddr(GWorld) ? UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::GameState)) : 0;
    int allN = 0, humN = 0, teamN = 0;
    if (IsValidAddr(GS)) {
        allN = vm_read<int>(GS + SDK::TotalPlayerNum);
        humN = vm_read<int>(GS + SDK::PlayerNum);
        teamN = vm_read<int>(GS + SDK::AliveTeamNum);
    }

    uint64_t Level = IsValidAddr(GWorld) ? UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::PersistentLevel)) : 0;
    uint64_t actors = IsValidAddr(Level) ? UNSIGN_PTR(vm_read<uint64_t>(Level + SDK::ActorArray)) : 0;
    int actorCount = IsValidAddr(Level) ? vm_read<int>(Level + SDK::ActorCount) : -1;

    int realCnt = 0, aiCnt = 0, speedHit = 0;
    if (IsValidAddr(actors) && actorCount > 0 && actorCount < 50000) {
        for (int i = 0; i < actorCount; ++i) {
            uint64_t actor = UNSIGN_PTR(vm_read<uint64_t>(actors + i * 8));
            if (!IsValidAddr(actor)) continue;
            if (vm_read<float>(actor + SDK::DefaultSpeedValue) != 479.5f) continue;
            speedHit++;
            if (vm_read<bool>(actor + SDK::bIsAI)) aiCnt++;
            else realCnt++;
        }
    }

    DrawDbg("[7s] GWorld=0x%llx NetDriver=0x%llx GS=0x%llx", GWorld, NetDriver, GS);
    DrawDbg("[7s] GameState ALL=%d HUM=%d TEAM=%d | actors=%d speed479=%d REAL=%d AI=%d",
            allN, humN, teamN, actorCount, speedHit, realCnt, aiCnt);
    // 对照绘制缓存：区分「dump 能扫到」与「RefreshStaticPlayers 缓存」是否脱节
    int cacheReal = 0, cacheAi = 0;
    for (const CachedPlayer &p : gStatic.players) {
        if (p.bIsAI) cacheAi++;
        else cacheReal++;
    }
    DrawDbg("[7s] cache isGame=%d pcm=0x%llx myTeam=%d players=%zu REAL=%d AI=%d",
            (int)gStatic.isGameStart, gStatic.playerCameraManager, gStatic.myTeam,
            gStatic.players.size(), cacheReal, cacheAi);
    if (!IsValidAddr(NetDriver)) {
        DrawDbg("[7s] NetDriver=0 —— 多半还在大厅，进对局后再看人数");
    }
}

static uint64_t getBaseAddress(pid_t pid) {
    // 已缓存则直接返回，避免重复全表扫描
    if (模块地址 != 0) return 模块地址;

    DrawDbg("[基址] 开始扫描 PID=%d 的 Mach-O magic", pid);
    // 优先常见主模块区间，命中即停；末档仅作兜底
    struct { uint64_t start; uint64_t end; } ranges[] = {
        { 0x100000000ULL, 0x200000000ULL },
        { 0x10000000ULL, 0x100000000ULL },
        { 0x200000000ULL, 0x280000000ULL }
    };
    for (unsigned i = 0; i < 3; ++i) {
        for (uint64_t addr = ranges[i].start; addr < ranges[i].end; addr += 0x4000ULL) {
            uint32_t magic = 0;
            if (exploit_mach_readbuf(pid, addr, &magic, sizeof(magic))) {
                if (magic == 0xfeedfacfU || magic == 0xcffaedfeU) {
                    DrawDbg("[基址] 命中 magic=0x%x @ 0x%llx (range[%u])", magic, addr, i);
                    return addr;
                }
            }
        }
    }
    DrawDbg("[基址] 扫描失败，未找到 feedfacf");
    return 0;
}

#define BIT(b) (1ULL << (b))

uint64_t kread_ptr(uint64_t va) { return UNSIGN_PTR(kread64(va)); }

#include <sys/sysctl.h>
#include <vector>

pid_t get_Pid(const char *targetName) {
    if (!targetName || !*targetName) return -1;

    size_t length = 0;
    int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    if (sysctl(mib, 3, nullptr, &length, nullptr, 0) != 0) {
        DrawDbg("[PID] sysctl size 失败 errno=%d", errno);
        return -1;
    }

    std::vector<struct kinfo_proc> procBuffer(length / sizeof(struct kinfo_proc));
    if (sysctl(mib, 3, procBuffer.data(), &length, nullptr, 0) != 0) {
        DrawDbg("[PID] sysctl data 失败 errno=%d", errno);
        return -1;
    }

    int count = (int)(length / sizeof(struct kinfo_proc));
    for (int i = 0; i < count; ++i) {
        const char *comm = procBuffer[i].kp_proc.p_comm;
        if (strncmp(comm, "ShadowTrackerExt", 16) == 0 ||
            strncmp(comm, "ShadowTracker", 16) == 0) {
            DrawDbg("[PID] 找到游戏进程 %s pid=%d", comm, procBuffer[i].kp_proc.p_pid);
            return procBuffer[i].kp_proc.p_pid;
        }
    }
    DrawDbg("[PID] 未找到 ShadowTrackerExt（共扫描 %d 个进程）", count);
    return -1;
}

bool getbbz() {
    if (!gReadingEnabled) return false;
    if (!((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess) {
        static int missKernel = 0;
        if ((missKernel++ % 30) == 0) {
            DrawDbg("[读取] krkw 未就绪 (isSuccess=NO)，跳过");
        }
        return false;
    }

    if (gamePid > 0) {
        if (kill(gamePid, 0) != 0) {
            DrawDbg("[读取] 游戏进程 pid=%d 已退出，重置偏移", gamePid);
            gamePid = -1;
            模块地址 = 0;
            bOffsetFindDNE = false;
        }
    }

    // 已就绪：只做轻量存活检查，不再扫进程/基址
    if (bOffsetFindDNE && gamePid > 0 && 模块地址 != 0) {
        return true;
    }

    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    static CFAbsoluteTime lastPidScan = 0.0;
    static CFAbsoluteTime lastBaseScan = 0.0;
    static const CFTimeInterval kPidScanInterval = 5.0;
    static const CFTimeInterval kBaseScanInterval = 8.0;

    if (gamePid <= 0) {
        if (lastPidScan > 0.0 && (now - lastPidScan) < kPidScanInterval) return false;
        lastPidScan = now;
        gamePid = get_Pid("ShadowTrackerExt");
        if (gamePid <= 1) return false;
    }

    if (模块地址 == 0) {
        if (lastBaseScan > 0.0 && (now - lastBaseScan) < kBaseScanInterval) return false;
        lastBaseScan = now;
        模块地址 = getBaseAddress(gamePid);
        if (模块地址 != 0) {
            bOffsetFindDNE = true;
            DrawDbg("[读取] 就绪 PID=%d Base=0x%llx", gamePid, 模块地址);
        } else {
            DrawDbg("[读取] 已有 PID=%d 但基址未找到，%gs 后重试", gamePid, kBaseScanInterval);
        }
    }
    return (gamePid > 0 && 模块地址 != 0);
}

+ (void)load {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        DrawDbg("[Boot] DrawWindow.load pid=%d 后台轮询+7s诊断+CPU启动", (int)getpid());
        int tick = 0;
        while (true) {
            // prefs 每 1s 刷新（含 drx 扩展项：手持/血量/物资模式等）
            RefreshDrawPrefs();
            if (gReadingEnabled && ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess) {
                getbbz(); // 内部已对 pid/基址扫描节流
            }
            if ((tick % 2) == 0) {
                gCurrentCPUUsage = GetCurrentProcessCPUUsage();
            }
            if ((tick % 7) == 0 && NHDebugLogEnabled()) {
                DumpReadPipelineEvery7s();
            }
            tick++;
            sleep(1);
        }
    });
}

// 严格同构 wasd ImGuiDraw.mm::readStaticData（含 3s 节流与分支，去掉 aanh 额外门控）
static void RefreshStaticPlayers(void) {
    static CFAbsoluteTime lastReadTime = 0.0;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (lastReadTime > 0.0 && (now - lastReadTime) < 3.0) {
        return;
    }
    lastReadTime = now;

    if (模块地址 == 0) {
        gStatic.isGameStart = false;
        gStatic.gWorld = 0;
        gStatic.players.clear();
        gStatic.materials.clear();
        return;
    }

    // wasd: KFD::Read<uint64_t>(基地址 + kGWorld); if (!gWorld)
    uint64_t gWorld = UNSIGN_PTR(vm_read<uint64_t>(模块地址 + SDK::GWorld));
    if (!gWorld) {
        gStatic.isGameStart = false;
        gStatic.gWorld = 0;
        gStatic.players.clear();
        gStatic.materials.clear();
        return;
    }

    // wasd: bool isStart = KFD::Read<long>(gWorld + kNetDriver); if (!isStart)
    uint64_t netDriver = UNSIGN_PTR(vm_read<uint64_t>(gWorld + SDK::NetDriver));
    if (!netDriver) {
        gStatic.isGameStart = false;
        gStatic.gWorld = gWorld;
        gStatic.players.clear();
        gStatic.materials.clear();
        return;
    }

    if (显示物资) LoadItemConfigsFromFile();

    // wasd: GetPointer(gWorld, kNetDriver, kServerConnection, kbIsLocalPlayerController) —— 无中间校验
    uint64_t playerController = UNSIGN_PTR(vm_read<uint64_t>(netDriver + SDK::ServerConnection));
    playerController = UNSIGN_PTR(vm_read<uint64_t>(playerController + SDK::PlayerController));
    uint64_t playerCameraManager = UNSIGN_PTR(vm_read<uint64_t>(playerController + SDK::PlayerCameraManager));
    uint64_t character = UNSIGN_PTR(vm_read<uint64_t>(playerController + SDK::Character));
    int myTeam = vm_read<int>(playerController + SDK::MyTeamID);

    uint64_t persistentLevel = UNSIGN_PTR(vm_read<uint64_t>(gWorld + SDK::PersistentLevel));
    uint64_t actorArray = UNSIGN_PTR(vm_read<uint64_t>(persistentLevel + SDK::ActorArray));
    int actorCount = vm_read<int>(persistentLevel + SDK::ActorCount);

    std::vector<CachedPlayer> tmpPlayers;
    std::vector<CachedMaterial> tmpMaterials;

    // wasd: if (actorCount > 0 && actorCount < 50000) 全表扫，无 IsValidAddr(actorArray) 门控
    if (actorCount > 0 && actorCount < 50000) {
        tmpPlayers.reserve(64);
        tmpMaterials.reserve(64);
        for (int i = 0; i < actorCount; i++) {
            uint64_t actor = UNSIGN_PTR(vm_read<uint64_t>(actorArray + i * 8));

            // 玩家过滤（DefaultSpeedValue == 479.5）
            if (vm_read<float>(actor + SDK::DefaultSpeedValue) == 479.5f) {
                if (actor == character) continue;
                // wasd: Read<int>(Read<uintptr_t>(actor + PawnState))
                int action = vm_read<int>(UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::PawnStateRepSyncData)));
                if (action == 1048592 || action == 1048576) continue;
                int teamID = vm_read<int>(actor + SDK::TeamID);
                if (teamID == myTeam || teamID == -1) continue;
                bool isAI = vm_read<bool>(actor + SDK::bIsAI);
                if (人机隐藏 && isAI) continue;

                CachedPlayer sp;
                sp.addr = actor;
                sp.team = teamID;
                sp.bIsAI = isAI;
                tmpPlayers.push_back(sp);
            } else {
                // wasd：非玩家一律走类名（物资开关仅影响绘制，不挡扫描收录）
                string className = GetClassName(模块地址, actor, 0x18);
                if (className.find("ojGrenade_BP_C") != std::string::npos) {
                    CachedMaterial sm{};
                    sm.addr = actor;
                    sm.isGrenade = true;
                    sm.isSmoke = false;
                    sm.className = className;
                    sm.displayName = "手雷";
                    sm.minDistance = 0;
                    sm.maxDistance = 9999;
                    sm.color = IM_COL32(255, 0, 0, 255);
                    sm.weaponID = 1;
                    sm.isBox = false;
                    tmpMaterials.push_back(sm);
                } else if (className.find("ProjSmoke") != std::string::npos) {
                    CachedMaterial sm{};
                    sm.addr = actor;
                    sm.isGrenade = false;
                    sm.isSmoke = true;
                    sm.className = className;
                    tmpMaterials.push_back(sm);
                } else if (className.length() >= 6 && className.length() < 45) {
                    const ItemConfig *cfg = FindItemConfig(className);
                    if (cfg) {
                        CachedMaterial sm{};
                        sm.addr = actor;
                        sm.isGrenade = false;
                        sm.isSmoke = false;
                        sm.className = className;
                        sm.displayName = cfg->displayName;
                        sm.minDistance = cfg->minDistance;
                        sm.maxDistance = cfg->maxDistance;
                        sm.color = cfg->color;
                        sm.weaponID = cfg->weaponID;
                        sm.isBox = cfg->isBox;
                        tmpMaterials.push_back(sm);
                    }
                }
            }
        }
    }

    gStatic.gWorld = gWorld;
    gStatic.playerController = playerController;
    gStatic.playerCameraManager = playerCameraManager;
    gStatic.myCharacter = character;
    gStatic.myTeam = myTeam;
    gStatic.isGameStart = true;
    gStatic.players.swap(tmpPlayers);
    gStatic.materials.swap(tmpMaterials);
}

// 主渲染 —— 对标 wasd：静态列表节流 + 每帧轻量更新
void Draw::StartBooks() {
    ImDrawList* dl = BBZGUI::GetForegroundDrawList();
    if (!dl) return;

    const float 屏幕宽度 = BBZGUI::GetIO().DisplaySize.x;
    const float 屏幕高度 = BBZGUI::GetIO().DisplaySize.y;
    CanvasSize.x = 屏幕宽度;
    CanvasSize.y = 屏幕高度;
    if (屏幕宽度 <= 0 || 屏幕高度 <= 0) return;
    if (!gReadingEnabled) {
        if (gStatic.isGameStart) {
            gStatic.isGameStart = false;
            gStatic.players.clear();
            gStatic.materials.clear();
        }
        return;
    }
    if (!((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess) return;
    if (模块地址 == 0 || !总开关) return;

    // wasd: readStaticData(); if (!isGameStart) return;
    RefreshStaticPlayers();

    // 顶部 GameState + 中间真人/人机：常显
    static int s全图 = 0, s真人 = 0, s队伍 = 0;
    auto drawHud = [&](int totalEnemies, int aiCounts) {
        char buf1[40], buf2[40];
        snprintf(buf1, sizeof(buf1), "真人:%02d", totalEnemies);
        snprintf(buf2, sizeof(buf2), "人机:%02d", aiCounts);
        Draw::DrawText(buf1, ImVec2(屏幕宽度 / 2.0f - 50.0f, 50.0f), true, Colour_骨骼, true, 22);
        Draw::DrawText(buf2, ImVec2(屏幕宽度 / 2.0f + 50.0f, 50.0f), true, Colour_人机, true, 22);

        static CFAbsoluteTime sGsLast = 0.0;
        CFAbsoluteTime gsNow = CFAbsoluteTimeGetCurrent();
        if (gsNow - sGsLast >= 1.0) {
            sGsLast = gsNow;
            uint64_t gw = gStatic.gWorld;
            if (模块地址 != 0) {
                uint64_t live = UNSIGN_PTR(vm_read<uint64_t>(模块地址 + SDK::GWorld));
                if (live) gw = live;
            }
            if (gw) {
                uint64_t gameStateBase = UNSIGN_PTR(vm_read<uint64_t>(gw + SDK::GameState));
                if (gameStateBase) {
                    int n全图 = vm_read<int>(gameStateBase + SDK::TotalPlayerNum);
                    int n真人 = vm_read<int>(gameStateBase + SDK::PlayerNum);
                    int n队伍 = vm_read<int>(gameStateBase + SDK::AliveTeamNum);
                    if (n全图 >= 0 && n全图 <= 200) s全图 = n全图;
                    if (n真人 >= 0 && n真人 <= 200) s真人 = n真人;
                    if (n队伍 >= 0 && n队伍 <= 100) s队伍 = n队伍;
                }
            }
        }
        char gameInfo[128];
        snprintf(gameInfo, sizeof(gameInfo), "全图: %02d | 真人: %02d | 队伍: %02d | CPU: %.1f%%",
                 s全图, s真人, s队伍, gCurrentCPUUsage);
        Draw::DrawText(gameInfo, ImVec2(屏幕宽度 * 0.14f, 25.0f), false, Colour_白色, true, 16);
    };

    // 对标 wasd：只判断 isGameStart，不因 PCM 无效整帧放弃
    if (!gStatic.isGameStart) {
        drawHud(0, 0);
        return;
    }

    // wasd: POV = Read<CoViewbyo>(playerCameraManager + kViewTarget); PCM 为 0 也照读
    CoViewInfo POV = vm_read<CoViewInfo>(gStatic.playerCameraManager + SDK::ViewTarget);
    bool povOk = (POV.FOV > 1.0f && POV.FOV <= 170.0f);
    if (!povOk) {
        float fovAlt = vm_read<float>(gStatic.playerCameraManager + SDK::ViewTarget + 0x2C);
        if (fovAlt > 1.0f && fovAlt <= 170.0f) {
            POV.FOV = fovAlt;
            povOk = true;
        }
    }
    // FOV 异常：默认 90 继续画；禁止 Invalidate+全表重扫（失败版 CPU 主因）
    if (!povOk) POV.FOV = 90.0f;

    // 自身手持：仅物资「空手模式」需要
    int 自身手持 = 0;
    if (显示物资 && 物资显示模式 == 1 && IsValidAddr(gStatic.myCharacter)) {
        uint64_t myWeapon = UNSIGN_PTR(vm_read<uint64_t>(gStatic.myCharacter + SDK::CurrentUsingWeaponSafety));
        if (IsValidAddr(myWeapon)) {
            自身手持 = vm_read<int>(myWeapon + SDK::RepWeaponID);
        }
    }

    const bool needHeadESP = 显示信息 || 显示距离 || 显示射线 || 显示血量 || 显示手持 || 显示方框 || AimAssist::开启自瞄;
    const bool needBoneMesh = 显示骨骼 || AimAssist::开启自瞄 || AimAssist::模型渲染;

    AimAssist::EnsureTouchInit(屏幕宽度, 屏幕高度);
    AimAssist::EnsurePhysX(模块地址);
    AimPhysX_TickCamera(POV.Location);
    // 遮挡隔帧采样用帧号（每进一次 StartBooks +1）
    static int sAimOccFrame = 0;
    sAimOccFrame++;
    const int aimOccFrame = sAimOccFrame;
    AimAssist::BeginFrameSelect();
    AimAssist::UpdateAimMode(gStatic.myCharacter, 1.f / 60.f);
    AimAssist::烟雾数组.clear();
    if (AimAssist::烟雾不瞄) {
        for (const CachedMaterial &m : gStatic.materials) {
            if (!m.isSmoke || !IsValidAddr(m.addr)) continue;
            Vector3 sp = GetRelativeLocation((long)m.addr);
            if (sp.X == 0 && sp.Y == 0 && sp.Z == 0) continue;
            AimAssist::烟雾数组.push_back({sp});
        }
    }

    int totalEnemies = 0;
    int aiCounts = 0;
    Vector2 canvasVec(屏幕宽度, 屏幕高度);
    const int sw = (int)屏幕宽度;
    const int sh = (int)屏幕高度;
    const ImU32 掩体颜色 = Colour_掩体;

    for (const CachedPlayer &sp : gStatic.players) {
        uint64_t actor = sp.addr;
        if (!actor) continue;

        // wasd readFrameData：PawnState / 血量同序
        int action = vm_read<int>(UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::PawnStateRepSyncData)));
        if (action == 1048592 || action == 1048576) continue;

        float Health = (vm_read<float>(actor + SDK::Health) / vm_read<float>(actor + SDK::HealthMax) * 100.f);
        if (Health > 100.f) continue;

        Vector3 loc = GetRelativeLocation((long)actor);

        bool bIsAI = sp.bIsAI;
        if (!bIsAI) totalEnemies++;
        else aiCounts++;

        float distance = GetDistance(loc, POV.Location) / 100.0f;
        Vector2 LocationScreen = WorldToScreen(loc, POV, sw, sh);
        bool onScreen = isScreenVisible(LocationScreen, canvasVec);
        if (distance > 绘制距离上限 && !(显示背敌 && distance <= 背敌距离)) continue;

        uint64_t mesh = 0;
        uint64_t staticMesh = 0;
        FTransform RelativeScale3D{};
        Vector2 HeadScreen = LocationScreen;
        // 骨骼才读 mesh；其余头顶 ESP 用近似头点，少一轮骨矩阵读
        if (onScreen && distance <= 绘制距离上限 && (needBoneMesh || needHeadESP)) {
            if (needBoneMesh) {
                mesh = UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::Mesh));
                if (IsValidAddr(mesh)) {
                    staticMesh = UNSIGN_PTR(vm_read<uint64_t>(mesh + SDK::StaticMesh));
                    if (IsValidAddr(staticMesh)) {
                        RelativeScale3D = GetMatrixConversion(mesh + SDK::ComponentToWorld);
                        Vector3 headWorld = GetBoneWithRotation((long)staticMesh, 5, RelativeScale3D);
                        headWorld.Z += 20.0f;
                        HeadScreen = WorldToScreen(headWorld, POV, sw, sh);
                    }
                }
            }
            if (!IsValidAddr(staticMesh)) {
                Vector3 approxHead = loc;
                approxHead.Z += 85.0f;
                HeadScreen = WorldToScreen(approxHead, POV, sw, sh);
            }
        }

        ImU32 NameColor = bIsAI ? Colour_人机 : Colour_名字;
        ImU32 lineColor = bIsAI ? Colour_人机 : Colour_射线;
        ImU32 boneColor = bIsAI ? Colour_人机 : Colour_骨骼;
        ImU32 teamColor = bIsAI ? Colour_人机 : Colour_队伍;
        ImU32 distanceColor = bIsAI ? Colour_人机 : Colour_距离;
        int teamID = sp.team;

        if (显示信息 && onScreen && distance <= 绘制距离上限) {
            if (!bIsAI) {
                string name = GetPlayerName((long)actor);
                if (!name.empty()) {
                    Draw::DrawText(name, ImVec2(HeadScreen.X, HeadScreen.Y - 20), true, NameColor, false, (float)信息大小);
                }
            } else {
                char buf[32];
                snprintf(buf, sizeof(buf), "人机%d", aiCounts);
                Draw::DrawText(buf, ImVec2(HeadScreen.X, HeadScreen.Y - 20), true, NameColor, false, (float)信息大小);
            }
            char teamBuf[16];
            snprintf(teamBuf, sizeof(teamBuf), "%d", teamID);
            Draw::DrawText(teamBuf, ImVec2(HeadScreen.X, HeadScreen.Y - 38.0f - 6.0f), true, teamColor, false, (float)信息大小);
        }

        if (显示距离 && onScreen && distance <= 绘制距离上限) {
            char distBuf[16];
            snprintf(distBuf, sizeof(distBuf), "%d", (int)distance);
            Draw::DrawText(distBuf, ImVec2(HeadScreen.X, HeadScreen.Y - 38.0f + 4.0f), true, distanceColor, false, (float)信息大小);
        }

        // 手持显示或屏内雷计时才读武器，避免关功能仍每帧读
        int weapon = 0;
        if (显示手持 || onScreen) {
            uint64_t weaponPtr = UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::CurrentUsingWeaponSafety));
            weapon = IsValidAddr(weaponPtr) ? vm_read<int>(weaponPtr + SDK::RepWeaponID) : 0;
        }

        // 敌人持雷倒计时（对标 wasd enemyGrenadeTimers，约 7.25s）
        static std::unordered_map<uint64_t, CFAbsoluteTime> enemyGrenadeTimers;
        if (weapon == 602004 || weapon == 9825004) {
            if (action >= 10000 && action <= 99999) {
                if (enemyGrenadeTimers.find(actor) == enemyGrenadeTimers.end()) {
                    enemyGrenadeTimers[actor] = CFAbsoluteTimeGetCurrent();
                }
            } else {
                enemyGrenadeTimers.erase(actor);
            }
        } else {
            enemyGrenadeTimers.erase(actor);
        }

        if (显示手持 && onScreen && distance <= 绘制距离上限 && weapon > 0) {
            if (手持样式 == 1) {
                id<MTLTexture> weaponTexture = nil;
                if (GetWeaponTexture(weapon, &weaponTexture) && weaponTexture) {
                    // 对标 wasd：ImTextureID = (__bridge void *)MTLTexture
                    ImVec2 sz(40, 20);
                    ImVec2 p0(HeadScreen.X - sz.x * 0.5f, HeadScreen.Y - 75.0f);
                    ImVec2 p1(p0.x + sz.x, p0.y + sz.y);
                    dl->AddImage((ImTextureID)(__bridge void *)weaponTexture, p0, p1,
                                 ImVec2(0, 0), ImVec2(1, 1), IM_COL32_WHITE);
                } else {
                    std::string wname = GetWeaponDisplayName(weapon);
                    if (!wname.empty()) {
                        Draw::DrawText(wname, ImVec2(HeadScreen.X, HeadScreen.Y - 55.0f), true, Colour_黄色, false, (float)信息大小);
                    }
                }
            } else {
                std::string wname = GetWeaponDisplayName(weapon);
                if (!wname.empty()) {
                    Draw::DrawText(wname, ImVec2(HeadScreen.X, HeadScreen.Y - 55.0f), true, Colour_黄色, false, (float)信息大小);
                }
            }
        }

        if (onScreen && distance <= 绘制距离上限) {
            auto git = enemyGrenadeTimers.find(actor);
            if (git != enemyGrenadeTimers.end()) {
                float enemyGrenadeTime = 7.25f - (float)(CFAbsoluteTimeGetCurrent() - git->second);
                if (enemyGrenadeTime > 0.0f) {
                    char gb[16];
                    snprintf(gb, sizeof(gb), "%d", (int)enemyGrenadeTime);
                    Draw::DrawText(gb, ImVec2(HeadScreen.X, HeadScreen.Y - 110.0f), true,
                                   IM_COL32(255, 255, 0, 255), true, 20);
                }
            }

            if (显示射线) {
                dl->AddLine(ImVec2(屏幕宽度 / 2.0f, 10.0f),
                            ImVec2(HeadScreen.X, HeadScreen.Y - 70.0f),
                            lineColor, 射线粗细);
            }

            if (显示血量 && Health > 0) {
                ImU32 bloodColor;
                if (Health >= 70) bloodColor = IM_COL32(0, 255, 0, 255);
                else if (Health >= 35) bloodColor = IM_COL32(255, 255, 0, 255);
                else bloodColor = IM_COL32(255, 0, 0, 255);
                float healthRatio = fminf(Health / 100.0f, 1.0f);
                if (血量样式 == 1) {
                    // 经典矩形血条（wasd）
                    const float barWidth = 50.0f;
                    ImVec2 barPos(HeadScreen.X - barWidth / 2.0f, HeadScreen.Y - 10.0f);
                    float healthWidth = barWidth * healthRatio;
                    dl->AddRectFilled(barPos, ImVec2(barPos.x + healthWidth, barPos.y + 7.0f), bloodColor, 3.5f);
                    dl->AddRect(barPos, ImVec2(barPos.x + barWidth, barPos.y + 7.0f), IM_COL32(0, 0, 0, 200), 3.5f, 0, 1.0f);
                } else if (血量样式 == 2) {
                    // 花祭分段血条：剩余空心框，已损红/白填充
                    const float barWidth = 8.0f, barHeight = 3.0f, segmentGap = 0.6f;
                    const int segments = 6;
                    int fullSegments = (int)(healthRatio * segments);
                    float totalWidth = segments * (barWidth + segmentGap) - segmentGap;
                    float startX = HeadScreen.X - totalWidth / 2.0f;
                    float y = HeadScreen.Y - 20.0f;
                    ImU32 fillCol = bIsAI ? IM_COL32(255, 255, 255, 255) : IM_COL32(255, 0, 0, 255);
                    for (int i = 0; i < segments; i++) {
                        float x = startX + i * (barWidth + segmentGap);
                        ImVec2 a(x, y), b(x + barWidth, y + barHeight);
                        if (i >= fullSegments) dl->AddRectFilled(a, b, fillCol);
                        dl->AddRect(a, b, IM_COL32(0, 0, 0, 255), 0.0f, 0, 1.0f);
                    }
                } else {
                    // 圆弧（默认）
                    float end_angle = healthRatio * 2.0f * IM_PI;
                    dl->PathArcTo(ImVec2(HeadScreen.X, HeadScreen.Y - 35), 15.0f, 0.0f, end_angle, 16);
                    dl->PathStroke(bloodColor, 0, 2.0f);
                }
            }

            // 骨骼可见性（对标 qwer 掩体漏打）
            // doOcclusion：模型渲染 + PhysX 就绪 + 距离≤漏打距离
            // 降 CPU：只测头骨(index 5)；隔帧复用缓存；骨骼绘制距离不再跟漏打距离绑死
            bool hasVisibleBone = false;
            Vector3 firstVisibleBoneWorld = {};
            bool doOcclusion = AimAssist::模型渲染 && AimPhysX_IsReady() && distance <= AimAssist::漏打距离;
            Vector3 cachedBoneWorld = {};
            bool boneCalculatedForOcclusion = false;
            if ((doOcclusion || AimAssist::开启自瞄) && IsValidAddr(staticMesh)) {
                cachedBoneWorld = GetBoneWithRotation((long)staticMesh, 5, RelativeScale3D);
                boneCalculatedForOcclusion = true;
            }

            // 头骨遮挡：隔帧采样，奇数帧复用上次结果（自瞄+骨骼着色共用）
            static std::unordered_map<uint64_t, bool> sHeadOccCache;
            if ((aimOccFrame & 1) != 0 && sHeadOccCache.size() > 256) sHeadOccCache.clear();
            const bool sampleOccThisFrame = (aimOccFrame & 1) != 0;
            bool headOccluded = false;
            if (doOcclusion && boneCalculatedForOcclusion) {
                if (sampleOccThisFrame) {
                    headOccluded = AimAssist::IsPointOccluded(POV.Location, cachedBoneWorld);
                    sHeadOccCache[actor] = headOccluded;
                } else {
                    auto it = sHeadOccCache.find(actor);
                    headOccluded = (it != sHeadOccCache.end()) ? it->second : false;
                }
            }

            // 骨骼绘制严格用「骨骼距离」，不再被漏打距离拉长
            float boneDrawLimit = 骨骼距离;
            if (显示骨骼 && distance <= boneDrawLimit && IsValidAddr(mesh) && IsValidAddr(staticMesh)) {
                int boneCount = vm_read<int>(mesh + SDK::StaticMesh + 0x8);
                const int(*skeletonList)[2] = GetSkeletonList(boneCount);
                static constexpr int kMaxBoneIdx = 128;
                Vector2 boneScreenPos[kMaxBoneIdx];
                bool boneCalculated[kMaxBoneIdx];
                memset(boneCalculated, 0, sizeof(boneCalculated));

                for (int bi = 0; bi < 14; bi++) {
                    for (int j = 0; j < 2; j++) {
                        int boneIdx = skeletonList[bi][j];
                        if (boneIdx < 0 || boneIdx >= kMaxBoneIdx) continue;
                        if (!boneCalculated[boneIdx]) {
                            Vector3 worldPos = GetBoneWithRotation((long)staticMesh, boneIdx, RelativeScale3D);
                            boneScreenPos[boneIdx] = WorldToScreen(worldPos, POV, sw, sh);
                            boneCalculated[boneIdx] = true;
                        }
                    }
                    int idxSta = skeletonList[bi][0];
                    int idxEnd = skeletonList[bi][1];
                    if (idxSta < 0 || idxSta >= kMaxBoneIdx || idxEnd < 0 || idxEnd >= kMaxBoneIdx) continue;
                    if (!boneCalculated[idxSta] || !boneCalculated[idxEnd]) continue;
                    // 整副骨架用头骨一次遮挡结果着色，不再对每节骨头 LineTrace
                    ImU32 segColor = (doOcclusion && headOccluded) ? 掩体颜色 : boneColor;
                    Draw::DrawLine(ImVec2(boneScreenPos[idxSta].X, boneScreenPos[idxSta].Y),
                                   ImVec2(boneScreenPos[idxEnd].X, boneScreenPos[idxEnd].Y),
                                   segColor, 骨骼粗细);
                }
            }

            if (AimAssist::开启自瞄) {
                if (doOcclusion && boneCalculatedForOcclusion) {
                    hasVisibleBone = !headOccluded;
                    firstVisibleBoneWorld = cachedBoneWorld;
                } else if (boneCalculatedForOcclusion) {
                    hasVisibleBone = true;
                    firstVisibleBoneWorld = cachedBoneWorld;
                } else if (IsValidAddr(staticMesh)) {
                    hasVisibleBone = true;
                    firstVisibleBoneWorld = GetBoneWithRotation((long)staticMesh, 5, RelativeScale3D);
                } else {
                    hasVisibleBone = true;
                    firstVisibleBoneWorld = loc;
                    firstVisibleBoneWorld.Z += 85.f;
                }
            }

            if (AimAssist::开启自瞄 && onScreen) {
                AimAssist::ConsiderTarget(actor, distance, Health, bIsAI, hasVisibleBone,
                                          firstVisibleBoneWorld, HeadScreen, loc,
                                          屏幕宽度, 屏幕高度);
            }

            if (显示方框) {
                VectorRect rect;
                BoxConversion(loc, &rect, POV, canvasVec);
                Draw::DrawRect(ImVec2(rect.x, rect.y), ImVec2(rect.x + rect.w, rect.y + rect.h), Colour_绿色, 1.0f);
            }
        }

        if (显示背敌 && !bIsAI && distance <= 背敌距离) {
            if (背敌模式 == 1) {
                OffScreenPanorama(loc, POV, distance, Health);
            } else {
                OffScreenBehindMode(loc, POV, onScreen, distance, Health);
            }
        }
    }

    // ========== 物资 / 手雷（对标 wasd：整块在 显示物资 下）==========
    if (显示物资) {
        uint64_t gameState = UNSIGN_PTR(vm_read<uint64_t>(gStatic.gWorld + SDK::GameState));
        float worldTime = IsValidAddr(gameState)
            ? vm_read<float>(gameState + SDK::ReplicatedWorldTimeSeconds) : 0.f;

        for (const CachedMaterial &m : gStatic.materials) {
            if (!IsValidAddr(m.addr) || m.isSmoke) continue;

            Vector3 worldPos = GetRelativeLocation((long)m.addr);
            if (worldPos.X == 0 && worldPos.Y == 0 && worldPos.Z == 0) continue;
            Vector2 screen = WorldToScreen(worldPos, POV, sw, sh);
            float dist = GetDistance(worldPos, POV.Location) / 100.0f;
            bool visible = isScreenVisible(screen, canvasVec);

            if (m.isGrenade) {
                float explosionTime = vm_read<float>(m.addr + SDK::ExplosionTime);
                float countdown = explosionTime - worldTime;
                if (countdown <= 0.f) continue;
                if (!visible) continue;
                char grenadeBuf[48];
                snprintf(grenadeBuf, sizeof(grenadeBuf), "%d 手雷", (int)countdown);
                Draw::DrawText(grenadeBuf, ImVec2(screen.X, screen.Y), true, IM_COL32(255, 0, 0, 255), true, 12);
            } else {
                if (m.isBox) {
                    int boxState = vm_read<int>(m.addr + SDK::BoxState);
                    if (boxState != 0) continue;
                }
                // 物资显示模式：0正常=持枪也显示；1空手=旧逻辑（weaponID==0 仅空手显示）
                bool shouldShow = (物资显示模式 == 0)
                    ? true
                    : ((m.weaponID == 1) || (m.weaponID == 0 && 自身手持 == 0));
                if (!shouldShow) continue;
                if (dist < m.minDistance || dist > m.maxDistance) continue;
                if (!visible) continue;
                char itemBuf[128];
                snprintf(itemBuf, sizeof(itemBuf), "%s   %d", m.displayName.c_str(), (int)dist);
                Draw::DrawText(itemBuf, ImVec2(screen.X, screen.Y), true, (int)m.color, true, (float)物资大小);
            }
        }
    }

    AimAssist::FinalizeTargetSelect();
    AimAssist::ExecuteAim(gStatic.myCharacter, POV, dl, 屏幕宽度, 屏幕高度);
    AimAssist::DrawOverlays(dl, 屏幕宽度, 屏幕高度);

    // 模型漏打状态（对标 qwer：遮挡段骨骼=掩体红；仅可见骨骼可被自瞄）
    if (AimAssist::模型渲染) {
        const char *st = AimPhysX_IsReady() ? "漏打:就绪(遮挡=红/可见才瞄)" : "漏打:加载中…";
        Draw::DrawText(st, ImVec2(屏幕宽度 * 0.5f, 72.0f), true,
                       AimPhysX_IsReady() ? IM_COL32(0, 255, 128, 255) : IM_COL32(255, 200, 0, 255),
                       true, 14);
    }

    drawHud(totalEnemies, aiCounts);
}

@end

@implementation AimFloatBridge

+ (BOOL)isAimEnabled {
    return AimAssist::开启自瞄 ? YES : NO;
}

+ (BOOL)toggleAimEnabled {
    AimAssist::开启自瞄 = !AimAssist::开启自瞄;
    NSMutableDictionary *cfg = [NSMutableDictionary dictionaryWithDictionary:NHPrefsRead() ?: @{}];
    cfg[@"开启自瞄"] = @(AimAssist::开启自瞄);
    NHPrefsWrite(cfg);
    return AimAssist::开启自瞄 ? YES : NO;
}

@end
