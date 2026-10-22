#include "DrawView.hpp"
#include <mutex>
#include <cstdint>
#include <cstdarg>
#include <cerrno>
#include <unistd.h>
#include <mach/mach.h>
#include "BBZGui.h"

#import "DOJailbreaker.h"
#include <libjailbreak/info.h>
#include <libjailbreak/primitives_external.h>

extern "C" uint32_t kread32(uint64_t where);
extern "C" uint64_t kread64(uint64_t where);
extern "C" void kfd_log(const char *format, ...);

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
static float 射线粗细 = 1.0f;
static const float 绘制距离上限 = 400.0f;

#define Colour_红色 0xFF0000FF
#define Colour_绿色 0xFF00FF00
#define Colour_白色 0xFFFFFFFF
#define Colour_黄色 0xFF00FFFF
#define Colour_射线 0xFF00F0F0  // 对标 wasd 默认黄 F0F000 (ABGR)
#define Colour_人机 0xFFFF8000  // 青橙，区分人机

static void DrawDbg(const char *fmt, ...) {
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    // KernelLogLine 内部已同步写 kfd_debug.log，避免重复落盘
    KernelLogLine(buf);
}

static NSString *PrefsPath(void);

// 主 App / HUD 是两个进程：内存开关必须落盘，HUD 才能读到「开始读取」
static void PersistReadingFlag(bool enabled) {
    NSString *path = PrefsPath();
    NSMutableDictionary *cfg = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (!cfg) cfg = [NSMutableDictionary dictionary];
    cfg[@"reading"] = @(enabled);
    [cfg writeToFile:path atomically:YES];
}

static bool LoadReadingFlagFromDisk(void) {
    NSDictionary *cfg = [NSDictionary dictionaryWithContentsOfFile:PrefsPath()];
    return cfg ? [[cfg objectForKey:@"reading"] boolValue] : NO;
}

extern "C" void SetReadingEnabled(bool enabled) {
    gReadingEnabled = enabled;
    PersistReadingFlag(enabled);
    if (!enabled) {
        gamePid = -1;
        模块地址 = 0;
        bOffsetFindDNE = false;
        DrawDbg("[读取] 已停止 (pid=%d) 已写入 plist reading=0", (int)getpid());
    } else {
        DrawDbg("[读取] 已开启 (pid=%d) 已写入 plist reading=1 —— HUD 进程会同步此开关", (int)getpid());
    }
}

extern "C" bool IsReadingEnabled(void) {
    // 跨进程：以磁盘为准
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

bool getbbz(); // 前向声明：供 7s dump 调用

static NSString *PrefsPath(void) {
    return @"/var/mobile/Library/Preferences/com.map.settings.plist";
}

static void RefreshDrawPrefs(void) {
    NSDictionary *cfg = [NSDictionary dictionaryWithContentsOfFile:PrefsPath()];
    // 关键：从磁盘同步「开始读取」，打通主 App ↔ HUD 双进程
    gReadingEnabled = cfg ? [[cfg objectForKey:@"reading"] boolValue] : NO;
    显示人数 = cfg ? [[cfg objectForKey:@"count"] boolValue] : NO;
    显示射线 = cfg ? [[cfg objectForKey:@"line"] boolValue] : NO;
    显示方框 = cfg ? [[cfg objectForKey:@"box"] boolValue] : NO;
    显示血量 = cfg ? [[cfg objectForKey:@"health"] boolValue] : NO;
    显示信息 = cfg ? [[cfg objectForKey:@"info"] boolValue] : NO;
    显示骨骼 = cfg ? [[cfg objectForKey:@"bone"] boolValue] : NO;
}

// 不依赖绘制循环：每 7 秒把整条读取链写进 kfd_debug.log
static void DumpReadPipelineEvery7s(void) {
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
    DrawDbg("[基址] 开始扫描 PID=%d 的 Mach-O magic", pid);
    struct { uint64_t start; uint64_t end; } ranges[] = {
        { 0x10000000ULL, 0x100000000ULL },
        { 0x100000000ULL, 0x200000000ULL },
        { 0x200000000ULL, 0x300000000ULL }
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

    if (!bOffsetFindDNE) {
        gamePid = get_Pid("ShadowTrackerExt");
        if (gamePid > 1) {
            模块地址 = getBaseAddress(gamePid);
            if (模块地址 != 0) {
                bOffsetFindDNE = true;
                DrawDbg("[读取] 就绪 PID=%d Base=0x%llx", gamePid, 模块地址);
            } else {
                DrawDbg("[读取] 已有 PID=%d 但基址未找到，下轮重试", gamePid);
            }
        }
    }
    return (gamePid > 0 && 模块地址 != 0);
}

+ (void)load {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        DrawDbg("[Boot] DrawWindow.load pid=%d 后台轮询+7s诊断启动", (int)getpid());
        int tick = 0;
        while (true) {
            // 每圈从磁盘同步 reading，让 HUD 进程跟上主界面按钮
            gReadingEnabled = LoadReadingFlagFromDisk();
            if (gReadingEnabled && ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess) {
                getbbz();
            }
            // 每 7 秒完整 dump 一次（不依赖 Metal 绘制是否在跑）
            if ((tick % 7) == 0) {
                DumpReadPipelineEvery7s();
            }
            tick++;
            sleep(1);
        }
    });
}

// 主渲染 —— 射线逻辑对标 wasd ImGuiDraw.mm
void Draw::StartBooks() {
    static int frameCount = 0;
    frameCount++;

    ImDrawList* dl = BBZGUI::GetForegroundDrawList();
    if (!dl) {
        if (frameCount % 60 == 0) DrawDbg("[绘制] GetForegroundDrawList=NULL");
        return;
    }

    CanvasSize.x = BBZGUI::GetIO().DisplaySize.x;
    CanvasSize.y = BBZGUI::GetIO().DisplaySize.y;

    // 每帧刷新开关（含 reading），打通主 App ↔ HUD
    RefreshDrawPrefs();

    // 心跳：证明 HUD 绘制帧在跑（绿色小块，不依赖中文字体）
    dl->AddRectFilled(ImVec2(4, 4), ImVec2(24, 24), 0xFF00FF00);

    if (frameCount % 120 == 0) {
        DrawDbg("[绘制] frame=%d canvas=%.0fx%.0f reading=%d krkw=%d gamePid=%d base=0x%llx count=%d line=%d selfPid=%d",
                frameCount, CanvasSize.x, CanvasSize.y,
                (int)gReadingEnabled,
                (int)((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess,
                gamePid, 模块地址, (int)显示人数, (int)显示射线, (int)getpid());
    }

    if (CanvasSize.x <= 0 || CanvasSize.y <= 0) {
        if (frameCount % 120 == 0) DrawDbg("[绘制] CanvasSize 无效");
        return;
    }

    // ASCII 状态条（中文字体失败时仍可见）
    char hudBar[256];
    snprintf(hudBar, sizeof(hudBar), "AB HUD pid=%d read=%d krkw=%d gPid=%d base=%llx",
             (int)getpid(), (int)gReadingEnabled,
             (int)((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess,
             gamePid, 模块地址);
    Draw::DrawText(hudBar, ImVec2(30, 8), false, Colour_黄色, true, 14);

    if (!gReadingEnabled) {
        Draw::DrawText("WAIT StartReading (plist reading=0)", ImVec2(CanvasSize.x / 2, 80), true, Colour_黄色, true, 20);
        return;
    }

    if (!((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess) {
        Draw::DrawText("KRKW not ready in HUD process", ImVec2(CanvasSize.x / 2, 80), true, Colour_红色, true, 20);
        return;
    }

    Draw::DrawText("AB Kernel ON", ImVec2(CanvasSize.x / 2, 40), true, Colour_红色, true, 26);

    char statusBuf[192];
    snprintf(statusBuf, sizeof(statusBuf), "gPid:%d Base:%llx Ray:%d Count:%d", gamePid, 模块地址, (int)显示射线, (int)显示人数);
    Draw::DrawText(statusBuf, ImVec2(20, 70), false, Colour_白色, true, 16);

    if (模块地址 == 0 || !总开关) {
        Draw::DrawText("Searching ShadowTrackerExt...", ImVec2(20, 100), false, Colour_黄色, true, 18);
        return;
    }

    uint64_t GWorld = UNSIGN_PTR(vm_read<uint64_t>(模块地址 + SDK::GWorld));
    if (!IsValidAddr(GWorld)) {
        if (frameCount % 90 == 0) DrawDbg("[绘制] GWorld 无效 raw@base+0x%llx", SDK::GWorld);
        Draw::DrawText("GWorld invalid", ImVec2(20, 100), false, Colour_黄色, true, 16);
        return;
    }

    uint64_t NetDriver = UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::NetDriver));
    if (!IsValidAddr(NetDriver)) {
        if (frameCount % 90 == 0) DrawDbg("[绘制] NetDriver 无效 (未进对局?) GWorld=0x%llx", GWorld);
        Draw::DrawText("Waiting match (NetDriver)...", ImVec2(20, 100), false, Colour_黄色, true, 16);
        return;
    }

    uint64_t ServerConnection = UNSIGN_PTR(vm_read<uint64_t>(NetDriver + SDK::ServerConnection));
    if (!IsValidAddr(ServerConnection)) {
        if (frameCount % 90 == 0) DrawDbg("[绘制] ServerConnection 无效");
        return;
    }

    uint64_t PlayerController = UNSIGN_PTR(vm_read<uint64_t>(ServerConnection + SDK::PlayerController));
    if (!IsValidAddr(PlayerController)) {
        if (frameCount % 90 == 0) DrawDbg("[绘制] PlayerController 无效");
        return;
    }

    uint64_t PlayerCameraManager = UNSIGN_PTR(vm_read<uint64_t>(PlayerController + SDK::PlayerCameraManager));
    if (!IsValidAddr(PlayerCameraManager)) {
        if (frameCount % 90 == 0) DrawDbg("[绘制] PlayerCameraManager 无效");
        return;
    }

    uint64_t MyCharacter = UNSIGN_PTR(vm_read<uint64_t>(PlayerController + SDK::Character));

    int myTeamID = vm_read<int>(PlayerController + SDK::MyTeamID);
    if (myTeamID <= 0 && IsValidAddr(MyCharacter)) {
        myTeamID = vm_read<int>(MyCharacter + SDK::TeamID);
    }

    // 对标 wasd：直接从 ViewTarget(0x14B0) 读 CoView 结构
    CoViewInfo POV = vm_read<CoViewInfo>(PlayerCameraManager + SDK::ViewTarget);
    // FOV 兜底：结构体对齐不对时尝试 0x2C 处的 float（旧 ViewTag[0x8] 布局）
    bool povOk = (POV.FOV > 1.0f && POV.FOV <= 170.0f);
    if (!povOk) {
        float fovAlt = vm_read<float>(PlayerCameraManager + SDK::ViewTarget + 0x2C);
        if (fovAlt > 1.0f && fovAlt <= 170.0f) {
            POV.FOV = fovAlt;
            povOk = true;
            if (frameCount % 120 == 0) DrawDbg("[POV] 使用备用 FOV@+0x2C = %.2f", fovAlt);
        }
    }
    if (frameCount % 120 == 0) {
        DrawDbg("[POV] Loc=(%.1f,%.1f,%.1f) Rot=(%.1f,%.1f,%.1f) FOV=%.2f ok=%d cam=0x%llx",
                POV.Location.X, POV.Location.Y, POV.Location.Z,
                POV.Rotation.Pitch, POV.Rotation.Yaw, POV.Rotation.Roll,
                POV.FOV, (int)povOk, PlayerCameraManager);
    }

    // ===== GameState 人数条（对标 wasd，进对局即显示，不依赖开关）=====
    uint64_t gameStateBase = UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::GameState));
    int 全图人数 = 0, 真实玩家GS = 0, 队伍数量 = 0;
    if (IsValidAddr(gameStateBase)) {
        全图人数 = vm_read<int>(gameStateBase + SDK::TotalPlayerNum);
        真实玩家GS = vm_read<int>(gameStateBase + SDK::PlayerNum);
        队伍数量 = vm_read<int>(gameStateBase + SDK::AliveTeamNum);
    }
    // ASCII + 中文双份，避免字体缺字时完全看不见
    char gameInfo[160];
    snprintf(gameInfo, sizeof(gameInfo), "ALL:%02d HUM:%02d TEAM:%02d | 全图:%02d 真人:%02d 队伍:%02d",
             全图人数, 真实玩家GS, 队伍数量, 全图人数, 真实玩家GS, 队伍数量);
    Draw::DrawText(gameInfo, ImVec2(CanvasSize.x * 0.10f, 28), false, Colour_白色, true, 16);

    uint64_t PersistentLevel = UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::PersistentLevel));
    if (!IsValidAddr(PersistentLevel)) {
        if (frameCount % 90 == 0) DrawDbg("[绘制] PersistentLevel 无效");
        return;
    }

    uint64_t ActorArrayPtr = UNSIGN_PTR(vm_read<uint64_t>(PersistentLevel + SDK::ActorArray));
    int ActorCount = vm_read<int>(PersistentLevel + SDK::ActorCount);

    if (!IsValidAddr(ActorArrayPtr) || ActorCount <= 0 || ActorCount > 10000) {
        if (frameCount % 90 == 0) {
            DrawDbg("[绘制] ActorArray 无效 ptr=0x%llx count=%d", ActorArrayPtr, ActorCount);
        }
        return;
    }

    if (frameCount % 120 == 0) {
        DrawDbg("[绘制] GWorld=0x%llx GS=0x%llx actors=%d team=%d 全图=%d 真人GS=%d 队伍=%d",
                GWorld, gameStateBase, ActorCount, myTeamID, 全图人数, 真实玩家GS, 队伍数量);
    }

    // 对标 wasd：遍历 Actor 统计真人/人机
    int totalEnemies = 0; // 真人
    int aiCounts = 0;     // 人机
    int rayDrawn = 0;
    int filteredSpeed = 0, filteredAction = 0, filteredTeam = 0, filteredHp = 0;

    Vector2 canvasVec(CanvasSize.x, CanvasSize.y);

    for (int i = 0; i < ActorCount; ++i) {
        uint64_t actor = UNSIGN_PTR(vm_read<uint64_t>(ActorArrayPtr + i * 8));
        if (!IsValidAddr(actor) || actor == MyCharacter) continue;

        float defaultSpeed = vm_read<float>(actor + SDK::DefaultSpeedValue);
        if (defaultSpeed != 479.5f) { filteredSpeed++; continue; }

        uint64_t pawnStatePtr = UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::PawnStateRepSyncData));
        int action = IsValidAddr(pawnStatePtr) ? vm_read<int>(pawnStatePtr) : 0;
        if (action == 1048592 || action == 1048576) { filteredAction++; continue; }

        int teamID = vm_read<int>(actor + SDK::TeamID);
        if (teamID == myTeamID || teamID == -1) { filteredTeam++; continue; }

        float health = vm_read<float>(actor + SDK::Health);
        float healthMax = vm_read<float>(actor + SDK::HealthMax);
        float hpPercent = 0.0f;
        if (healthMax > 0) {
            hpPercent = (health / healthMax) * 100.0f;
            if (hpPercent <= 0 || hpPercent > 100.0f) { filteredHp++; continue; }
        }

        // 人数统计不依赖屏幕/FOV（对标 wasd 在绘制循环里先计数）
        bool bIsAI = vm_read<bool>(actor + SDK::bIsAI);
        if (!bIsAI) {
            totalEnemies++;
        } else {
            aiCounts++;
        }

        // 以下绘制依赖合法 POV
        if (!povOk) continue;

        Vector3 loc = GetRelativeLocation(actor);
        if (loc.X == 0 && loc.Y == 0 && loc.Z == 0) continue;

        float distance = GetDistance(loc, POV.Location) / 100.0f;
        Vector2 footScreen = WorldToScreen(loc, POV, (int)CanvasSize.x, (int)CanvasSize.y);
        bool onScreen = isScreenVisible(footScreen, canvasVec);

        Vector2 HeadScreen = footScreen;
        bool gotHead = false;
        uint64_t mesh = UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::Mesh));
        if (IsValidAddr(mesh)) {
            uint64_t staticMesh = UNSIGN_PTR(vm_read<uint64_t>(mesh + SDK::StaticMesh));
            if (IsValidAddr(staticMesh)) {
                FTransform c2w = GetMatrixConversion(mesh + SDK::ComponentToWorld);
                Vector3 headWorld = GetBoneWithRotation((long)staticMesh, 5, c2w);
                headWorld.Z += 20.0f;
                HeadScreen = WorldToScreen(headWorld, POV, (int)CanvasSize.x, (int)CanvasSize.y);
                gotHead = true;
            }
        }
        if (!gotHead) {
            Vector3 approxHead = loc;
            approxHead.Z += 85.0f;
            HeadScreen = WorldToScreen(approxHead, POV, (int)CanvasSize.x, (int)CanvasSize.y);
        }

        // ===== 射线：对标 wasd =====
        if (显示射线 && distance <= 绘制距离上限 && onScreen) {
            Draw::DrawLine(ImVec2(CanvasSize.x / 2.0f, 10.0f),
                           ImVec2(HeadScreen.X, HeadScreen.Y - 70.0f),
                           Colour_射线, 射线粗细);
            rayDrawn++;
        }

        if (显示方框 && distance <= 绘制距离上限 && onScreen) {
            VectorRect rect;
            BoxConversion(loc, &rect, POV, canvasVec);
            Draw::DrawRect(ImVec2(rect.x, rect.y), ImVec2(rect.x + rect.w, rect.y + rect.h), Colour_绿色, 1.0f);
        }

        if (显示血量 && distance <= 绘制距离上限 && onScreen && hpPercent > 0) {
            char hpBuf[32];
            snprintf(hpBuf, sizeof(hpBuf), "%.0f", hpPercent);
            Draw::DrawText(hpBuf, ImVec2(HeadScreen.X, HeadScreen.Y - 10), true, Colour_绿色, true, 12);
        }

        if (显示信息 && distance <= 绘制距离上限 && onScreen) {
            char infoBuf[64];
            snprintf(infoBuf, sizeof(infoBuf), "T%d %.0fm", teamID, distance);
            Draw::DrawText(infoBuf, ImVec2(HeadScreen.X, HeadScreen.Y - 38), true, Colour_白色, true, 12);
        }
    }

    // ===== 显示人数：对标 wasd；同时画 ASCII 兜底 =====
    if (显示人数) {
        char buf1[40], buf2[40], bufA[48];
        snprintf(buf1, sizeof(buf1), "真人:%02d", totalEnemies);
        snprintf(buf2, sizeof(buf2), "人机:%02d", aiCounts);
        snprintf(bufA, sizeof(bufA), "R:%02d  AI:%02d", totalEnemies, aiCounts);
        Draw::DrawText(buf1, ImVec2(CanvasSize.x / 2.0f - 50.0f, 50.0f), true, Colour_绿色, true, 22);
        Draw::DrawText(buf2, ImVec2(CanvasSize.x / 2.0f + 50.0f, 50.0f), true, Colour_人机, true, 22);
        Draw::DrawText(bufA, ImVec2(CanvasSize.x / 2.0f, 78.0f), true, Colour_白色, true, 20);
    }

    if (frameCount % 90 == 0) {
        DrawDbg("[人数] 真人=%d 人机=%d rays=%d actors=%d filter(speed=%d act=%d team=%d hp=%d) countSw=%d lineSw=%d povOk=%d",
                totalEnemies, aiCounts, rayDrawn, ActorCount,
                filteredSpeed, filteredAction, filteredTeam, filteredHp,
                (int)显示人数, (int)显示射线, (int)povOk);
    }

    if (!povOk) {
        Draw::DrawText("POV/FOV invalid (尚未画射线，人数仍统计)", ImVec2(20, 100), false, Colour_黄色, true, 14);
    }
}

@end
