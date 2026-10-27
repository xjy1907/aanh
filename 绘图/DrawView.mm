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

#import "DOJailbreaker.h"
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
static bool 显示人数 = false;
static bool 显示射线 = false;
static bool 显示方框 = false;
static bool 显示血量 = false;
static bool 显示信息 = false;
static bool 显示骨骼 = false;
static bool 显示手持 = false, 显示距离 = false, 显示背敌 = false, 显示物资 = false;
static int 手持样式 = 0; // 0=文字 1=图片（对标 wasd 手持图）
static int 物资大小 = 12;
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

// 对标 wasd IM_COL32 默认色
#define Colour_红色 IM_COL32(255, 0, 0, 255)
#define Colour_绿色 IM_COL32(0, 200, 0, 255)
#define Colour_白色 IM_COL32(255, 255, 255, 255)
#define Colour_黄色 IM_COL32(255, 255, 0, 255)
#define Colour_射线 IM_COL32(240, 240, 0, 255)
#define Colour_骨骼 IM_COL32(0, 200, 0, 255)
#define Colour_人机 IM_COL32(200, 0, 0, 200)
#define Colour_名字 IM_COL32(255, 255, 255, 255)

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

    DOJailbreaker *jb = [DOJailbreaker sharedInstance];
    jb.isSuccess = NO;

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JB.KernelReadyBootTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if ([jb respondsToSelector:@selector(finalize)]) {
        [jb finalize];
    }
    DrawDbg("[重置] ResetKernelStatus 完成 (krkw/偏移已清, reading=0)");
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

static void LoadItemConfigsFromFile(void) {
    itemConfigs.clear();
    NSString *path = NHWuziPath();
    if (!path) return;
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
    ImDrawListFlags oldFlags = dl->Flags;
    dl->Flags |= ImDrawListFlags_AntiAliasedLines | ImDrawListFlags_AntiAliasedFill;
    dl->AddPolyline(points, 3, arrowColor, ImDrawFlags_Closed, 2.0f);
    dl->Flags = oldFlags;

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
        ImVec2 textSize = font->CalcTextSizeA(10.0f, MAXFLOAT, 0.0f, distanceText);
        textPos.x -= textSize.x / 2.0f;
        textPos.y -= textSize.y / 2.0f;
    }
    Draw::DrawText(distanceText, textPos, false, arrowColor, true, 10.0f);
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
    ImDrawListFlags oldFlags = dl->Flags;
    dl->Flags |= ImDrawListFlags_AntiAliasedLines | ImDrawListFlags_AntiAliasedFill;
    dl->AddConvexPolyFilled(points, 4, arrowColor);
    dl->AddPolyline(points, 4, IM_COL32(0, 0, 0, 255), ImDrawFlags_Closed, 1.5f);
    dl->Flags = oldFlags;
}

// 屏幕外敌人指示器（箭头）— 背后模式：仅屏幕外，角由屏幕坐标算
static void OffScreenArrow(Vector2 screenPos, bool isOnScreen, float distance, float health) {
    if (health <= 0.f || isOnScreen) return;
    float centerX = CanvasSize.x / 2.0f;
    float centerY = CanvasSize.y / 2.0f;
    DrawBehindArrowAtAngle(atan2f(screenPos.Y - centerY, screenPos.X - centerX), distance, true);
}

// 屏幕外敌人指示器（雷达）— 背后模式
static void OffScreenRadar(Vector2 screenPos, bool isOnScreen, float distance, float health) {
    if (health <= 0.f || isOnScreen) return;
    float centerX = CanvasSize.x / 2.0f;
    float centerY = CanvasSize.y / 2.0f;
    DrawBehindRadarAtAngle(atan2f(screenPos.Y - centerY, screenPos.X - centerX), distance);
}

// 花祭背敌样式 — 背后模式
static void OffScreenHuaji(Vector2 screenPos, bool isOnScreen, float distance, float health) {
    if (health <= 0.f || isOnScreen) return;
    float centerX = CanvasSize.x / 2.0f;
    float centerY = CanvasSize.y / 2.0f;
    float angle = atan2f(screenPos.Y - centerY, screenPos.X - centerX);
    ImU32 arrowColor;
    if (distance <= 50) arrowColor = IM_COL32(255, 0, 0, 230);
    else if (distance <= 100) arrowColor = IM_COL32(0, 255, 0, 230);
    else if (distance <= 150) arrowColor = IM_COL32(0, 0, 255, 230);
    else arrowColor = IM_COL32(255, 255, 255, 230);
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
    ImDrawListFlags oldFlags = dl->Flags;
    dl->Flags |= ImDrawListFlags_AntiAliasedLines | ImDrawListFlags_AntiAliasedFill;
    dl->AddPolyline(points, 3, arrowColor, ImDrawFlags_Closed, 2.0f);
    dl->Flags = oldFlags;
    char distanceText[16];
    snprintf(distanceText, sizeof(distanceText), "%d", (int)distance);
    ImVec2 textPos(arrowCenterX - arrowWidth / 4.0f, arrowCenterY - 5.0f);
    Draw::DrawText(distanceText, textPos, true, arrowColor, true, 10.0f);
}

// 全景模式：360° 水平环绕——前方敌人箭头在上、后方在下（不因「在屏内」跳过）
static void OffScreenPanorama(Vector3 worldPos, CoViewInfo pov, float distance, float health) {
    if (health <= 0.f) return;
    float angle = PanoramaBehindAngle(worldPos, pov);
    if (背敌样式 == 0) {
        DrawBehindRadarAtAngle(angle, distance);
    } else if (背敌样式 == 2) {
        // 花祭空心三角配色
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
        ImDrawListFlags oldFlags = dl->Flags;
        dl->Flags |= ImDrawListFlags_AntiAliasedLines | ImDrawListFlags_AntiAliasedFill;
        dl->AddPolyline(points, 3, arrowColor, ImDrawFlags_Closed, 2.0f);
        dl->Flags = oldFlags;
        char distanceText[16];
        snprintf(distanceText, sizeof(distanceText), "%d", (int)distance);
        Draw::DrawText(distanceText, ImVec2(arrowCenterX - arrowWidth / 4.0f, arrowCenterY - 5.0f),
                       true, arrowColor, true, 10.0f);
    } else {
        DrawBehindArrowAtAngle(angle, distance, true);
    }
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
            显示手持 || 显示距离 || 显示背敌 || 显示物资) {
            NSMutableDictionary *restore = [NSMutableDictionary dictionary];
            restore[@"reading"] = @(gReadingEnabled);
            restore[@"count"] = @(显示人数);
            restore[@"line"] = @(显示射线);
            restore[@"box"] = @(显示方框);
            restore[@"health"] = @(显示血量);
            restore[@"info"] = @(显示信息);
            restore[@"bone"] = @(显示骨骼);
            restore[@"weapon"] = @(显示手持);
            restore[@"weaponStyle"] = @(手持样式);
            restore[@"dist"] = @(显示距离);
            restore[@"behind"] = @(显示背敌);
            restore[@"loot"] = @(显示物资);
            restore[@"lootSize"] = @(物资大小);
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
    显示手持 = [[cfg objectForKey:@"weapon"] boolValue];
    显示距离 = [[cfg objectForKey:@"dist"] boolValue];
    显示背敌 = [[cfg objectForKey:@"behind"] boolValue];
    显示物资 = [[cfg objectForKey:@"loot"] boolValue];
    if (cfg[@"weaponStyle"] != nil) 手持样式 = [cfg[@"weaponStyle"] intValue];
    if (cfg[@"lootSize"] != nil) 物资大小 = [cfg[@"lootSize"] intValue];
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
    if (IsValidAddr(actors) && actorCount > 0 && actorCount < 10000) {
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

// 对标 wasd：3s 扫一次 ActorArray，缓存玩家/物资；每帧只读缓存列表的位置/血量
static void RefreshStaticPlayers(void) {
    static CFAbsoluteTime lastRead = 0.0;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (lastRead > 0.0 && (now - lastRead) < 3.0) return;
    lastRead = now;

    // 与扫描同节奏刷新物资配置；物资开启且列表空时也强制重载
    LoadItemConfigsFromFile();

    auto clearLists = []() {
        gStatic.players.clear();
        gStatic.materials.clear();
    };

    if (模块地址 == 0) {
        gStatic.isGameStart = false;
        clearLists();
        return;
    }

    uint64_t GWorld = UNSIGN_PTR(vm_read<uint64_t>(模块地址 + SDK::GWorld));
    if (!IsValidAddr(GWorld)) {
        gStatic.isGameStart = false;
        clearLists();
        return;
    }

    uint64_t NetDriver = UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::NetDriver));
    if (!IsValidAddr(NetDriver)) {
        gStatic.isGameStart = false;
        gStatic.gWorld = GWorld;
        clearLists();
        return;
    }

    uint64_t ServerConnection = UNSIGN_PTR(vm_read<uint64_t>(NetDriver + SDK::ServerConnection));
    if (!IsValidAddr(ServerConnection)) {
        gStatic.isGameStart = false;
        clearLists();
        return;
    }

    uint64_t PlayerController = UNSIGN_PTR(vm_read<uint64_t>(ServerConnection + SDK::PlayerController));
    if (!IsValidAddr(PlayerController)) {
        gStatic.isGameStart = false;
        clearLists();
        return;
    }

    uint64_t PlayerCameraManager = UNSIGN_PTR(vm_read<uint64_t>(PlayerController + SDK::PlayerCameraManager));
    uint64_t MyCharacter = UNSIGN_PTR(vm_read<uint64_t>(PlayerController + SDK::Character));
    int myTeamID = vm_read<int>(PlayerController + SDK::MyTeamID);
    if (myTeamID <= 0 && IsValidAddr(MyCharacter)) {
        myTeamID = vm_read<int>(MyCharacter + SDK::TeamID);
    }

    uint64_t PersistentLevel = UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::PersistentLevel));
    if (!IsValidAddr(PersistentLevel)) {
        gStatic.isGameStart = false;
        clearLists();
        return;
    }

    uint64_t ActorArrayPtr = UNSIGN_PTR(vm_read<uint64_t>(PersistentLevel + SDK::ActorArray));
    int ActorCount = vm_read<int>(PersistentLevel + SDK::ActorCount);
    std::vector<CachedPlayer> tmp;
    std::vector<CachedMaterial> tmpMat;
    if (IsValidAddr(ActorArrayPtr) && ActorCount > 0 && ActorCount <= 10000) {
        tmp.reserve(64);
        tmpMat.reserve(64);
        for (int i = 0; i < ActorCount; ++i) {
            uint64_t actor = UNSIGN_PTR(vm_read<uint64_t>(ActorArrayPtr + i * 8));
            if (!IsValidAddr(actor) || actor == MyCharacter) continue;

            if (vm_read<float>(actor + SDK::DefaultSpeedValue) == 479.5f) {
                uint64_t pawnStatePtr = UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::PawnStateRepSyncData));
                int action = IsValidAddr(pawnStatePtr) ? vm_read<int>(pawnStatePtr) : 0;
                if (action == 1048592 || action == 1048576) continue;

                int teamID = vm_read<int>(actor + SDK::TeamID);
                if (teamID == myTeamID || teamID == -1) continue;

                CachedPlayer cp;
                cp.addr = actor;
                cp.team = teamID;
                cp.bIsAI = vm_read<bool>(actor + SDK::bIsAI);
                tmp.push_back(cp);
            } else {
                // 物资 / 手雷 / 烟雾
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
                    tmpMat.push_back(sm);
                } else if (className.find("ProjSmoke") != std::string::npos) {
                    CachedMaterial sm{};
                    sm.addr = actor;
                    sm.isGrenade = false;
                    sm.isSmoke = true;
                    sm.className = className;
                    tmpMat.push_back(sm);
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
                        tmpMat.push_back(sm);
                    }
                }
            }
        }
    }

    gStatic.gWorld = GWorld;
    gStatic.playerController = PlayerController;
    gStatic.playerCameraManager = PlayerCameraManager;
    gStatic.myCharacter = MyCharacter;
    gStatic.myTeam = myTeamID;
    gStatic.isGameStart = true;
    gStatic.players.swap(tmp);
    gStatic.materials.swap(tmpMat);
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

    RefreshStaticPlayers();
    if (!gStatic.isGameStart || !IsValidAddr(gStatic.playerCameraManager)) return;

    CoViewInfo POV = vm_read<CoViewInfo>(gStatic.playerCameraManager + SDK::ViewTarget);
    bool povOk = (POV.FOV > 1.0f && POV.FOV <= 170.0f);
    if (!povOk) {
        float fovAlt = vm_read<float>(gStatic.playerCameraManager + SDK::ViewTarget + 0x2C);
        if (fovAlt > 1.0f && fovAlt <= 170.0f) {
            POV.FOV = fovAlt;
            povOk = true;
        }
    }
    if (!povOk) return;

    // 自身手持：每帧读一次（物资 weaponID==0 过滤 + 可选显示）
    int 自身手持 = 0;
    if (IsValidAddr(gStatic.myCharacter)) {
        uint64_t myWeapon = UNSIGN_PTR(vm_read<uint64_t>(gStatic.myCharacter + SDK::CurrentUsingWeaponSafety));
        if (IsValidAddr(myWeapon)) {
            自身手持 = vm_read<int>(myWeapon + SDK::RepWeaponID);
        }
    }

    int totalEnemies = 0;
    int aiCounts = 0;
    Vector2 canvasVec(屏幕宽度, 屏幕高度);
    const int sw = (int)屏幕宽度;
    const int sh = (int)屏幕高度;

    for (const CachedPlayer &sp : gStatic.players) {
        uint64_t actor = sp.addr;
        if (!IsValidAddr(actor)) continue;

        uint64_t pawnStatePtr = UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::PawnStateRepSyncData));
        int action = IsValidAddr(pawnStatePtr) ? vm_read<int>(pawnStatePtr) : 0;
        if (action == 1048592 || action == 1048576) continue;

        float healthMax = vm_read<float>(actor + SDK::HealthMax);
        if (healthMax <= 0) continue;
        float Health = (vm_read<float>(actor + SDK::Health) / healthMax) * 100.0f;
        if (Health > 100.0f) continue;

        bool bIsAI = sp.bIsAI;
        if (!bIsAI) totalEnemies++;
        else aiCounts++;

        Vector3 loc = GetRelativeLocation((long)actor);
        if (loc.X == 0 && loc.Y == 0 && loc.Z == 0) continue;

        float distance = GetDistance(loc, POV.Location) / 100.0f;
        Vector2 LocationScreen = WorldToScreen(loc, POV, sw, sh);
        bool onScreen = isScreenVisible(LocationScreen, canvasVec);
        if (distance > 绘制距离上限 && !(显示背敌 && distance <= 背敌距离)) continue;

        uint64_t mesh = 0;
        uint64_t staticMesh = 0;
        FTransform RelativeScale3D{};
        Vector2 HeadScreen = LocationScreen;
        if (onScreen) {
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
            if (!IsValidAddr(staticMesh)) {
                Vector3 approxHead = loc;
                approxHead.Z += 85.0f;
                HeadScreen = WorldToScreen(approxHead, POV, sw, sh);
            }
        }

        ImU32 NameColor = bIsAI ? Colour_人机 : Colour_名字;
        ImU32 lineColor = bIsAI ? Colour_人机 : Colour_射线;
        ImU32 boneColor = bIsAI ? Colour_人机 : Colour_骨骼;
        ImU32 teamColor = bIsAI ? Colour_人机 : Colour_白色;
        ImU32 distanceColor = bIsAI ? Colour_人机 : Colour_白色;
        int teamID = sp.team;

        if (显示信息 && onScreen && distance <= 绘制距离上限) {
            if (!bIsAI) {
                string name = GetPlayerName((long)actor);
                if (!name.empty()) {
                    Draw::DrawText(name, ImVec2(HeadScreen.X, HeadScreen.Y - 20), true, NameColor, false, 10);
                }
            } else {
                char buf[32];
                snprintf(buf, sizeof(buf), "人机%d", aiCounts);
                Draw::DrawText(buf, ImVec2(HeadScreen.X, HeadScreen.Y - 20), true, NameColor, false, 10);
            }
            char teamBuf[16];
            snprintf(teamBuf, sizeof(teamBuf), "%d", teamID);
            Draw::DrawText(teamBuf, ImVec2(HeadScreen.X, HeadScreen.Y - 38.0f - 6.0f), true, teamColor, false, 10);
        }

        if (显示距离 && onScreen && distance <= 绘制距离上限) {
            char distBuf[16];
            snprintf(distBuf, sizeof(distBuf), "%d", (int)distance);
            Draw::DrawText(distBuf, ImVec2(HeadScreen.X, HeadScreen.Y - 38.0f + 4.0f), true, distanceColor, false, 10);
        }

        uint64_t weaponPtr = UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::CurrentUsingWeaponSafety));
        int weapon = IsValidAddr(weaponPtr) ? vm_read<int>(weaponPtr + SDK::RepWeaponID) : 0;

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
                        Draw::DrawText(wname, ImVec2(HeadScreen.X, HeadScreen.Y - 55.0f), true, Colour_黄色, false, 10);
                    }
                }
            } else {
                std::string wname = GetWeaponDisplayName(weapon);
                if (!wname.empty()) {
                    Draw::DrawText(wname, ImVec2(HeadScreen.X, HeadScreen.Y - 55.0f), true, Colour_黄色, false, 10);
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

            if (显示骨骼 && distance <= 骨骼距离 && IsValidAddr(mesh) && IsValidAddr(staticMesh)) {
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
                    Draw::DrawLine(ImVec2(boneScreenPos[idxSta].X, boneScreenPos[idxSta].Y),
                                   ImVec2(boneScreenPos[idxEnd].X, boneScreenPos[idxEnd].Y),
                                   boneColor, 骨骼粗细);
                }
            }

            if (显示方框) {
                VectorRect rect;
                BoxConversion(loc, &rect, POV, canvasVec);
                Draw::DrawRect(ImVec2(rect.x, rect.y), ImVec2(rect.x + rect.w, rect.y + rect.h), Colour_绿色, 1.0f);
            }
        }

        if (显示背敌 && !bIsAI && distance <= 背敌距离) {
            if (背敌模式 == 1) {
                // 全景：前方箭头在上、后方在下（水平 360）
                OffScreenPanorama(loc, POV, distance, Health);
            } else if (背敌样式 == 1) {
                OffScreenArrow(LocationScreen, onScreen, distance, Health);
            } else if (背敌样式 == 2) {
                OffScreenHuaji(LocationScreen, onScreen, distance, Health);
            } else {
                OffScreenRadar(LocationScreen, onScreen, distance, Health);
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

    if (显示人数) {
        char buf1[40], buf2[40];
        snprintf(buf1, sizeof(buf1), "真人:%02d", totalEnemies);
        snprintf(buf2, sizeof(buf2), "人机:%02d", aiCounts);
        Draw::DrawText(buf1, ImVec2(屏幕宽度 / 2.0f - 50.0f, 50.0f), true, Colour_骨骼, true, 22);
        Draw::DrawText(buf2, ImVec2(屏幕宽度 / 2.0f + 50.0f, 50.0f), true, Colour_人机, true, 22);
    }

    // GameState 人数：1s 读一次即可，HUD 字不必每帧读
    static int s全图 = 0, s真人 = 0, s队伍 = 0;
    static CFAbsoluteTime sGsLast = 0.0;
    CFAbsoluteTime gsNow = CFAbsoluteTimeGetCurrent();
    if (gsNow - sGsLast >= 1.0) {
        sGsLast = gsNow;
        uint64_t gameStateBase = UNSIGN_PTR(vm_read<uint64_t>(gStatic.gWorld + SDK::GameState));
        if (IsValidAddr(gameStateBase)) {
            s全图 = vm_read<int>(gameStateBase + SDK::TotalPlayerNum);
            s真人 = vm_read<int>(gameStateBase + SDK::PlayerNum);
            s队伍 = vm_read<int>(gameStateBase + SDK::AliveTeamNum);
        }
    }
    char gameInfo[128];
    snprintf(gameInfo, sizeof(gameInfo), "全图: %02d | 真人: %02d | 队伍: %02d | CPU: %.1f%%",
             s全图, s真人, s队伍, gCurrentCPUUsage);
    Draw::DrawText(gameInfo, ImVec2(屏幕宽度 * 0.14f, 25.0f), false, Colour_白色, true, 16);
}

@end
