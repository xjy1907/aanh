#include "DrawView.hpp"
#include <mutex>
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
static float 骨骼粗细 = 1.0f;
static float 骨骼距离 = 300.0f;
static const float 绘制距离上限 = 400.0f;
static float gCurrentCPUUsage = 0.0f;

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
        DrawDbg("[Boot] DrawWindow.load pid=%d 后台轮询+7s诊断+CPU启动", (int)getpid());
        int tick = 0;
        while (true) {
            gReadingEnabled = LoadReadingFlagFromDisk();
            if (gReadingEnabled && ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess) {
                getbbz();
            }
            // 对标 wasd：后台刷新 CPU，避免主线程重操作
            gCurrentCPUUsage = GetCurrentProcessCPUUsage();
            if ((tick % 7) == 0) {
                DumpReadPipelineEvery7s();
            }
            tick++;
            sleep(1);
        }
    });
}

// 主渲染 —— 绘制逻辑对标 wasd ImGuiDraw.mm（读取仍走 KFD / exploit_mach_readbuf）
void Draw::StartBooks() {
    static int frameCount = 0;
    frameCount++;

    ImDrawList* dl = BBZGUI::GetForegroundDrawList();
    if (!dl) {
        if (frameCount % 60 == 0) DrawDbg("[绘制] GetForegroundDrawList=NULL");
        return;
    }

    // 对标 wasd：屏幕宽高用 DisplaySize（真机不同分辨率用相对坐标适配）
    const float 屏幕宽度 = BBZGUI::GetIO().DisplaySize.x;
    const float 屏幕高度 = BBZGUI::GetIO().DisplaySize.y;
    CanvasSize.x = 屏幕宽度;
    CanvasSize.y = 屏幕高度;

    RefreshDrawPrefs();

    if (frameCount % 120 == 0) {
        DrawDbg("[绘制] frame=%d canvas=%.0fx%.0f reading=%d krkw=%d gamePid=%d base=0x%llx",
                frameCount, 屏幕宽度, 屏幕高度,
                (int)gReadingEnabled,
                (int)((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess,
                gamePid, 模块地址);
    }

    if (屏幕宽度 <= 0 || 屏幕高度 <= 0) return;
    if (!gReadingEnabled) return;
    if (!((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess) return;
    if (模块地址 == 0 || !总开关) return;

    uint64_t GWorld = UNSIGN_PTR(vm_read<uint64_t>(模块地址 + SDK::GWorld));
    if (!IsValidAddr(GWorld)) return;

    uint64_t NetDriver = UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::NetDriver));
    if (!IsValidAddr(NetDriver)) return;

    uint64_t ServerConnection = UNSIGN_PTR(vm_read<uint64_t>(NetDriver + SDK::ServerConnection));
    if (!IsValidAddr(ServerConnection)) return;

    uint64_t PlayerController = UNSIGN_PTR(vm_read<uint64_t>(ServerConnection + SDK::PlayerController));
    if (!IsValidAddr(PlayerController)) return;

    uint64_t PlayerCameraManager = UNSIGN_PTR(vm_read<uint64_t>(PlayerController + SDK::PlayerCameraManager));
    if (!IsValidAddr(PlayerCameraManager)) return;

    uint64_t MyCharacter = UNSIGN_PTR(vm_read<uint64_t>(PlayerController + SDK::Character));

    int myTeamID = vm_read<int>(PlayerController + SDK::MyTeamID);
    if (myTeamID <= 0 && IsValidAddr(MyCharacter)) {
        myTeamID = vm_read<int>(MyCharacter + SDK::TeamID);
    }

    CoViewInfo POV = vm_read<CoViewInfo>(PlayerCameraManager + SDK::ViewTarget);
    bool povOk = (POV.FOV > 1.0f && POV.FOV <= 170.0f);
    if (!povOk) {
        float fovAlt = vm_read<float>(PlayerCameraManager + SDK::ViewTarget + 0x2C);
        if (fovAlt > 1.0f && fovAlt <= 170.0f) {
            POV.FOV = fovAlt;
            povOk = true;
        }
    }
    if (!povOk) return;

    uint64_t PersistentLevel = UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::PersistentLevel));
    if (!IsValidAddr(PersistentLevel)) return;

    uint64_t ActorArrayPtr = UNSIGN_PTR(vm_read<uint64_t>(PersistentLevel + SDK::ActorArray));
    int ActorCount = vm_read<int>(PersistentLevel + SDK::ActorCount);
    if (!IsValidAddr(ActorArrayPtr) || ActorCount <= 0 || ActorCount > 10000) return;

    int totalEnemies = 0;
    int aiCounts = 0;
    Vector2 canvasVec(屏幕宽度, 屏幕高度);

    for (int i = 0; i < ActorCount; ++i) {
        uint64_t actor = UNSIGN_PTR(vm_read<uint64_t>(ActorArrayPtr + i * 8));
        if (!IsValidAddr(actor) || actor == MyCharacter) continue;

        float defaultSpeed = vm_read<float>(actor + SDK::DefaultSpeedValue);
        if (defaultSpeed != 479.5f) continue;

        uint64_t pawnStatePtr = UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::PawnStateRepSyncData));
        int action = IsValidAddr(pawnStatePtr) ? vm_read<int>(pawnStatePtr) : 0;
        if (action == 1048592 || action == 1048576) continue;

        int teamID = vm_read<int>(actor + SDK::TeamID);
        if (teamID == myTeamID || teamID == -1) continue;

        float healthMax = vm_read<float>(actor + SDK::HealthMax);
        if (healthMax <= 0) continue;
        // 对标 wasd：hp = Health/HealthMax*100，仅过滤 >100
        float Health = (vm_read<float>(actor + SDK::Health) / healthMax) * 100.0f;
        if (Health > 100.0f) continue;

        bool bIsAI = vm_read<bool>(actor + SDK::bIsAI);
        if (!bIsAI) {
            totalEnemies++;
        } else {
            aiCounts++;
        }

        Vector3 loc = GetRelativeLocation(actor);
        if (loc.X == 0 && loc.Y == 0 && loc.Z == 0) continue;

        float distance = GetDistance(loc, POV.Location) / 100.0f;
        Vector2 LocationScreen = WorldToScreen(loc, POV, (int)屏幕宽度, (int)屏幕高度);
        bool onScreen = isScreenVisible(LocationScreen, canvasVec);

        uint64_t mesh = UNSIGN_PTR(vm_read<uint64_t>(actor + SDK::Mesh));
        uint64_t staticMesh = 0;
        FTransform RelativeScale3D{};
        Vector2 HeadScreen = LocationScreen;
        if (IsValidAddr(mesh)) {
            staticMesh = UNSIGN_PTR(vm_read<uint64_t>(mesh + SDK::StaticMesh));
            if (IsValidAddr(staticMesh)) {
                RelativeScale3D = GetMatrixConversion(mesh + SDK::ComponentToWorld);
                Vector3 headWorld = GetBoneWithRotation((long)staticMesh, 5, RelativeScale3D);
                headWorld.Z += 20.0f; // 对标 wasd
                HeadScreen = WorldToScreen(headWorld, POV, (int)屏幕宽度, (int)屏幕高度);
            }
        }
        if (!IsValidAddr(staticMesh)) {
            Vector3 approxHead = loc;
            approxHead.Z += 85.0f;
            HeadScreen = WorldToScreen(approxHead, POV, (int)屏幕宽度, (int)屏幕高度);
        }

        ImU32 NameColor = bIsAI ? Colour_人机 : Colour_名字;
        ImU32 lineColor = bIsAI ? Colour_人机 : Colour_射线;
        ImU32 boneColor = bIsAI ? Colour_人机 : Colour_骨骼;
        ImU32 teamColor = bIsAI ? Colour_人机 : Colour_白色;
        ImU32 distanceColor = bIsAI ? Colour_人机 : Colour_白色;

        if (!onScreen) continue;
        if (distance > 绘制距离上限) continue;

        // ===== 玩家信息：对标 wasd 显示信息(名字) + 显示距离(队伍/米) =====
        // abnh 面板只有「玩家信息」一键，两边逻辑一并打开
        if (显示信息) {
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
            char distBuf[16];
            snprintf(distBuf, sizeof(distBuf), "%d", (int)distance);
            Draw::DrawText(distBuf, ImVec2(HeadScreen.X, HeadScreen.Y - 38.0f + 4.0f), true, distanceColor, false, 10);
        }

        // ===== 射线：对标 wasd (屏幕宽度/2, 10) → (Head.X, Head.Y-70) =====
        if (显示射线) {
            dl->AddLine(ImVec2(屏幕宽度 / 2.0f, 10.0f),
                        ImVec2(HeadScreen.X, HeadScreen.Y - 70.0f),
                        lineColor, 射线粗细);
        }

        // ===== 血量：对标 wasd 默认圆弧样式 =====
        if (显示血量 && Health > 0) {
            ImU32 bloodColor;
            if (Health >= 70) {
                bloodColor = IM_COL32(0, 255, 0, 255);
            } else if (Health >= 35) {
                bloodColor = IM_COL32(255, 255, 0, 255);
            } else {
                bloodColor = IM_COL32(255, 0, 0, 255);
            }
            float healthRatio = fminf(Health / 100.0f, 1.0f);
            float end_angle = healthRatio * 2.0f * IM_PI;
            ImU32 bgColor = IM_COL32(100, 100, 100, 0);
            dl->PathArcTo(ImVec2(HeadScreen.X, HeadScreen.Y - 35), 15.0f, 0.0f, 2.0f * IM_PI, 32);
            dl->PathStroke(bgColor, 0, 2.0f);
            dl->PathArcTo(ImVec2(HeadScreen.X, HeadScreen.Y - 35), 15.0f, 0.0f, end_angle, 32);
            dl->PathStroke(bloodColor, 0, 2.0f);
        }

        // ===== 骨骼：对标 wasd GetSkeletonList + 14 段连线 =====
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
                        boneScreenPos[boneIdx] = WorldToScreen(worldPos, POV, (int)屏幕宽度, (int)屏幕高度);
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

    // ===== 显示人数：对标 wasd 位置 (w/2-50, 50) / (w/2+50, 50) =====
    if (显示人数) {
        char buf1[40], buf2[40];
        snprintf(buf1, sizeof(buf1), "真人:%02d", totalEnemies);
        snprintf(buf2, sizeof(buf2), "人机:%02d", aiCounts);
        Draw::DrawText(buf1, ImVec2(屏幕宽度 / 2.0f - 30.0f - 20.0f, 50.0f), true, Colour_骨骼, true, 22);
        Draw::DrawText(buf2, ImVec2(屏幕宽度 / 2.0f + 30.0f + 20.0f, 50.0f), true, Colour_人机, true, 22);
    }

    // ===== 全图|真人|队伍|CPU：对标 wasd (屏幕宽度*0.14, 25) =====
    uint64_t gameStateBase = UNSIGN_PTR(vm_read<uint64_t>(GWorld + SDK::GameState));
    int 全图人数 = 0, 真实玩家 = 0, 队伍数量 = 0;
    if (IsValidAddr(gameStateBase)) {
        全图人数 = vm_read<int>(gameStateBase + SDK::TotalPlayerNum);
        真实玩家 = vm_read<int>(gameStateBase + SDK::PlayerNum);
        队伍数量 = vm_read<int>(gameStateBase + SDK::AliveTeamNum);
    }
    char gameInfo[160];
    snprintf(gameInfo, sizeof(gameInfo), "全图: %02d | 真人: %02d | 队伍: %02d | CPU: %.1f%% | WwW.ApiBuG.CoM",
             全图人数, 真实玩家, 队伍数量, gCurrentCPUUsage);
    Draw::DrawText(gameInfo, ImVec2(屏幕宽度 * 0.14f, 25.0f), false, Colour_白色, true, 16);

    if (frameCount % 90 == 0) {
        DrawDbg("[人数] 真人=%d 人机=%d actors=%d GS(全图=%d 真人=%d 队伍=%d) CPU=%.1f",
                totalEnemies, aiCounts, ActorCount, 全图人数, 真实玩家, 队伍数量, gCurrentCPUUsage);
    }
}

@end
