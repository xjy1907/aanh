#include "DrawView.hpp"
#include <mutex>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#include <iostream>
#include <cstdint>
#include <mach/mach.h>
#include <unordered_map>
#include <chrono>
#include <atomic>
#include <thread>
#include <sstream>
#include <iomanip>
#include <fstream>

#include "BBZGui.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/IOKitKeys.h>

// 内核符号/偏移与读写（用于 allproc 枚举）
#import "DOJailbreaker.h"
#include <libjailbreak/info.h>
#include <libjailbreak/primitives_external.h>
#include <libproc.h>

extern "C" uint32_t kread32(uint64_t where);
extern "C" uint64_t kread64(uint64_t where);

#ifdef __cplusplus
extern "C" {
#endif
bool exploit_mach_readbuf(pid_t pid, uint64_t base, void* output, size_t size);
bool exploit_mach_kwritebuf(pid_t pid, uint64_t base, const void* input, size_t size);
void exploit_v2p_cache_clear(void);
#ifdef __cplusplus
}
#endif

// ========================================
// 引入拆分的头文件
// ========================================
#include "游戏/SDK.h"
#include "游戏/绘制类型.h"
#include "绘图.h"

// ========================================
// 全局状态
// ========================================
@implementation DrawWindow

static pid_t gamePid = -1;
static uint64_t 模块地址 = 0;
static bool bOffsetFindDNE = false;
static uint64_t g_PlayerCameraManager = 0;
static uint64_t g_Pawn = 0;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;
bool 总开关 = true;

// 设备信息
static string g_设备名 = "";
static string g_序列号 = "";
static bool g_设备信息已初始化 = false;

static void 初始化设备信息() {
    if (g_设备信息已初始化) return;
    g_设备信息已初始化 = true;
    struct utsname sname;
    uname(&sname);
    UIDevice *Device = [UIDevice currentDevice];
    string systemVersion = [Device.systemVersion UTF8String];
    string machine = [[NSString stringWithCString:sname.machine encoding:NSUTF8StringEncoding] UTF8String];
    g_设备名 = machine + " [ " + systemVersion + " ]";
    io_service_t IOPlatformExpertDevice = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    if (IOPlatformExpertDevice) {
        CFTypeRef SerialNumber = IORegistryEntryCreateCFProperty(IOPlatformExpertDevice, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0);
        IOObjectRelease(IOPlatformExpertDevice);
        if (SerialNumber) {
            g_序列号 = [(__bridge NSString *)SerialNumber UTF8String];
            CFRelease(SerialNumber);
        }
    }
}

int 骨骼点数组[15] = {1, 30, 31, 6, 7, 8, 34, 35, 36, 58, 59, 60, 62, 63, 64};

// ========================================
// 基地址扫描
// ========================================
typedef uint64_t vm_map_offset_t;
typedef uint64_t mach_vm_address_t;

static bool IsValidAddr(uint64_t address) {
    return address > 0x100000000ULL && address < 0x3000000000ULL;
}

vm_map_offset_t getBaseAddress(pid_t pid) {
    struct { uint64_t start; uint64_t end; } ranges[] = {
        { 0x100000000ULL, 0x140000000ULL },
        { 0x140000000ULL, 0x200000000ULL },
    };
    const uint64_t step = 0x4000ULL;
    for (unsigned i = 0; i < sizeof(ranges)/sizeof(ranges[0]); ++i) {
        for (uint64_t addr = ranges[i].start; addr < ranges[i].end; addr += step) {
            uint32_t magic = 0;
            if (exploit_mach_readbuf(pid, addr, &magic, sizeof(magic))) {
                if (magic == 0xfeedfacfU || magic == 0xcffaedfeU) return (vm_map_offset_t)addr;
            }
        }
    }
    return 0;
}

// ========================================
// 内核进程遍历
// ========================================
#define BIT(b)    (1ULL << (b))
#define PAC_MASK kconstant(pointer_mask)
#define SIGN(p)          ((p) & BIT(55))
#define UNSIGN_PTR(p)    (SIGN(p) ? ((p) | PAC_MASK) : ((p) & ~PAC_MASK))

uint64_t kread_ptr(uint64_t va) { return UNSIGN_PTR(kread64(va)); }

void proc_iterate(void (^itBlock)(uint64_t, bool*)) {
    uint64_t proc = ksymbol(allproc);
    while((proc = kread_ptr(proc + koffsetof(proc, list_next)))) {
        bool stop = false; itBlock(proc, &stop); if(stop) return;
    }
}

uint64_t proc_task(uint64_t proc) {
    if (koffsetof(proc, task)) return kread_ptr(proc + koffsetof(proc, task));
    else return proc + ksizeof(proc);
}

static bool KernelReadString(uint64_t kptr, char *out, size_t outsz) {
    if (kptr == 0 || outsz == 0) return false;
    size_t toRead = outsz - 1;
    if (exploit_kreadbuf(kptr, out, toRead) != 0) return false;
    out[toRead] = '\0';
    for (size_t i = 0; i < toRead; i++) { if (out[i] == '\0') break; if (i == toRead - 1) out[i] = '\0'; }
    return true;
}

static uint64_t FindImageBaseForTask(uint64_t task) {
    if (task == 0) return 0;
    uint64_t vm_map = kread_ptr(task + koffsetof(task, map));
    if (!vm_map) return 0;
    uint64_t hdr = vm_map + koffsetof(vm_map, hdr);
    uint64_t header_links = hdr + koffsetof(vm_map_header, links);
    uint64_t entry = kread_ptr(header_links + koffsetof(vm_map_links, next));
    uint64_t bestBase = 0;
    while (entry && entry != header_links) {
        uint64_t start = kread64(entry + koffsetof(vm_map_links, min));
        uint64_t entry_base = entry - koffsetof(vm_map_entry, links);
        uint64_t flags = kread64(entry_base + koffsetof(vm_map_entry, flags));
        uint64_t prot = (flags >> 7) & 0xFULL;
        uint64_t maxprot = (flags >> 11) & 0xFULL;
        if (((prot & 0x4) != 0) && ((maxprot & 0x4) != 0) && start >= 0x100000000ULL) {
            if (bestBase == 0 || start < bestBase) bestBase = start;
        }
        entry = kread_ptr(entry + koffsetof(vm_map_links, next));
    }
    return bestBase;
}

pid_t get_Pid(const char *process_name) {
    if (!process_name) return -1;
    __block pid_t foundPid = -1;
    __block uint64_t foundTask = 0;
    proc_iterate(^(uint64_t proc, bool *stop) {
        pid_t pid = (pid_t)kread32(proc + koffsetof(proc, pid));
        uint64_t textvp = kread_ptr(proc + koffsetof(proc, textvp));
        if (!textvp) return;
        uint64_t v_name_ptr = kread64(textvp + 0xB8);
        if (!v_name_ptr) return;
        char namebuf[256] = {0};
        if (!KernelReadString(v_name_ptr, namebuf, sizeof(namebuf))) return;
        if (strcmp(namebuf, process_name) == 0) { foundPid = pid; foundTask = proc_task(proc); *stop = true; }
    });
    return foundPid;
}

// ========================================
// 内存读写
// ========================================
bool readMemory(uint64_t address, void *buffer, size_t size) {
    if (!IsValidAddr(address) || size == 0) return false;
    if (gamePid <= 0) return false;
    return exploit_mach_readbuf(gamePid, address, buffer, size);
}

bool vm_read_list(uint64_t address, void* buffer, size_t size) {
    return readMemory(address, buffer, size);
}

// ========================================
// 引入算法和物品ID（依赖 vm_read / IsValidAddr）
// ========================================
#include "游戏/绘制算法.h"
#include "游戏/物品ID.h"

// ========================================
// 初始化
// ========================================
bool getbbz() {
    if (!bOffsetFindDNE) {
        const char* cands[] = { "DeltaForceClient" };
        gamePid = -1;
        for (unsigned i = 0; i < sizeof(cands)/sizeof(cands[0]); ++i) {
            pid_t p = get_Pid(cands[i]);
            if (p > 1) { gamePid = p; break; }
        }
        if (gamePid != -1) {
            模块地址 = getBaseAddress(gamePid);
            if (模块地址 != 0) bOffsetFindDNE = true;
        }
    }
    return (gamePid > 0 && 模块地址 != 0);
}

// ========================================
// FName 解密
// ========================================
string 异或字符串(uint64_t StrPtr, int StrLength) {
    string FName(StrLength, '\0');
    vm_read_list(StrPtr, FName.data(), StrLength);
    uint16_t Key = 0;
    switch (StrLength % 9) {
        case 0: Key = ((((StrLength >> 6) && 0x1F) + StrLength) | 0x7F) + 0x80; break;
        case 1: Key = (((StrLength ^ 0xDF) + StrLength) | 0x7F) + 0x80; break;
        case 2: Key = (((StrLength | 0xCF) + StrLength) | 0x7F) + 0x80; break;
        case 3: Key = ((0x21 * StrLength) | 0x7F) + 0x80; break;
        case 4: Key = ((StrLength + (StrLength >> 8)) | 0x7F) + 0x80; break;
        case 5: Key = ((3 * StrLength + 5) | 0x7F) + 0x80; break;
        case 6: Key = ((((4 * StrLength) | 5) + StrLength) | 0x7F) + 0x80; break;
        case 7: Key = ((((StrLength >> 10) | 7) + StrLength) | 0x7F) + 0x80; break;
        case 8: Key = (((StrLength ^ 0xC) + StrLength) | 0x7F) + 0x80; break;
    }
    for (int i = 0; i < StrLength; i++) FName[i] ^= Key;
    return FName;
}

string 解密FName(int ID) {
    auto NameStride = 0x2;
    auto NameEntryToLenBit = 6;
    auto NameEntryToString = 0x2;
    auto NamesToFNamePool = 0xC8;
    auto Block = (ID >> 15) & 0x1FFF8;
    auto Offset = (NameStride * ID) & 0x7FFFE;
    auto NamePoolChunk = vm_read<uint64_t>(模块地址 + SDK::FName + (Block + NamesToFNamePool));
    auto NameEntry = NamePoolChunk + Offset;
    auto NameEntryHeader = vm_read<uint16_t>(NameEntry);
    auto StrPtr = NameEntry + NameEntryToString;
    auto StrLength = NameEntryHeader >> NameEntryToLenBit;
    return 异或字符串(StrPtr, StrLength);
}

// ========================================
// 辅助函数
// ========================================
string 取物资价值(int MallRecyclePrice) {
    if (MallRecyclePrice > 1000) {
        if (MallRecyclePrice < 1000000) {
            ostringstream OstringStream;
            OstringStream << fixed << setprecision(1) << (MallRecyclePrice / 1000.0f);
            return OstringStream.str() + "K";
        } else {
            ostringstream OstringStream;
            OstringStream << fixed << setprecision(1) << (MallRecyclePrice / 1000000.0f);
            return OstringStream.str() + "M";
        }
    }
    return to_string(MallRecyclePrice);
}

string 取中段String(string String) {
    size_t 开始位置 = String.find('"');
    if (开始位置 == string::npos) return "";
    size_t 结束位置 = String.find('"', 开始位置 + 1);
    if (结束位置 == string::npos) return "";
    return String.substr(开始位置 + 1, 结束位置 - 开始位置 - 1);
}

// ========================================
// 子线程（后台数据收集）
// ========================================
void* 子线程(void*) {
    while (true) {
        sleep(5);
        getbbz();
        if (!IsValidAddr(模块地址)) continue;

        uint64_t Engine = vm_read<uint64_t>(模块地址 + SDK::Engine);
        if (!IsValidAddr(Engine)) continue;
        uint64_t GameViewport = vm_read<uint64_t>(Engine + SDK::GameViewport);
        if (!IsValidAddr(GameViewport)) continue;
        uint64_t World = vm_read<uint64_t>(GameViewport + SDK::World);
        if (!IsValidAddr(World)) continue;
        uint64_t LevelCollections = vm_read<uint64_t>(World + SDK::LevelCollections);
        if (!IsValidAddr(LevelCollections)) continue;

        uint64_t NetDriver = vm_read<uint64_t>(LevelCollections + SDK::NetDriver);
        if (!IsValidAddr(NetDriver)) continue;
        uint64_t ServerConnection = vm_read<uint64_t>(NetDriver + SDK::ServerConnection);
        if (!IsValidAddr(ServerConnection)) continue;
        uint64_t PlayerController = vm_read<uint64_t>(ServerConnection + SDK::PlayerController);
        if (!IsValidAddr(PlayerController)) continue;

        uint64_t cam = vm_read<uint64_t>(PlayerController + SDK::PlayerCameraManager);
        if (IsValidAddr(cam)) { pthread_mutex_lock(&g_lock); g_PlayerCameraManager = cam; pthread_mutex_unlock(&g_lock); }

        uint64_t Pawn = vm_read<uint64_t>(PlayerController + SDK::Pawn);
        pthread_mutex_lock(&g_lock); g_Pawn = Pawn; pthread_mutex_unlock(&g_lock);

        uint64_t CHARACTER = vm_read<uint64_t>(PlayerController + SDK::CHARACTER);
        if (!IsValidAddr(CHARACTER)) continue;
        uint64_t TeamComp = vm_read<uint64_t>(CHARACTER + SDK::TeamComp);
        if (!IsValidAddr(TeamComp)) continue;
        DFType::UGPTeamComponent MyTeam = vm_read<DFType::UGPTeamComponent>(TeamComp + SDK::TeamID);

        uint64_t PersistentLevel = vm_read<uint64_t>(LevelCollections + SDK::PersistentLevel);
        if (!IsValidAddr(PersistentLevel)) continue;
        DFType::TArray Actors = vm_read<DFType::TArray>(PersistentLevel + SDK::Actors);
        if (!IsValidAddr(Actors.AllocatorInstance) || Actors.ArrayNum > Actors.ArrayMax || Actors.ArrayNum > 10000 || Actors.ArrayNum <= 0) continue;

        vector<物品数据> 物品数据数组;
        vector<盒子数据> 盒子数据数组;
        vector<玩家数据> 玩家数据数组;

        for (int i = 0; i < Actors.ArrayNum; i++) {
            uint64_t Actor = vm_read<uint64_t>(Actors.AllocatorInstance + i * 8);
            if (!IsValidAddr(Actor)) continue;
            uint64_t RootComponent = vm_read<uint64_t>(Actor + SDK::RootComponent);
            if (!IsValidAddr(RootComponent)) continue;
            string FName = 解密FName(vm_read<int>(Actor + 0x1C));
            if (FName == "WeaponPhysicsBulletReal_BP_C") continue;

            switch (取对象类型(FName)) {
                case 0: {
                    uint64_t Row = vm_read<uint64_t>(Actor + SDK::CurRow);
                    if (!IsValidAddr(Row)) continue;
                    物品数据 d;
                    d.RootComponent = RootComponent;
                    d.ItemID = vm_read<int>(Row + SDK::FDFMCommonItemRow::ItemID);
                    d.Quality = vm_read<int>(Row + SDK::FDFMCommonItemRow::Quality);
                    d.MallRecyclePrice = vm_read<int>(Row + SDK::FDFMCommonItemRow::MallRecyclePrice);
                    物品数据数组.push_back(d);
                    break;
                }
                case 1: {
                    盒子数据 d;
                    d.RootComponent = RootComponent;
                    d.PlayerName_Buffer = vm_read<uint64_t>(Actor + SDK::PlayerName_Buffer);
                    d.bLooted = vm_read<bool>(Actor + SDK::bLooted);
                    盒子数据数组.push_back(d);
                    break;
                }
                case 2: {
                    if (Actor == Pawn) continue;
                    uint64_t TC = vm_read<uint64_t>(Actor + SDK::TeamComp);
                    if (!IsValidAddr(TC)) continue;
                    DFType::UGPTeamComponent team = vm_read<DFType::UGPTeamComponent>(TC + SDK::TeamID);
                    if (team.TeamID == MyTeam.TeamID) continue;
                    uint64_t HC = vm_read<uint64_t>(Actor + SDK::HealthComp);
                    if (!IsValidAddr(HC)) continue;
                    uint64_t PS = vm_read<uint64_t>(Actor + SDK::PlayerState);
                    if (IsValidAddr(PS) && vm_read<uint8_t>(PS + SDK::ExitState) == 3) continue;
                    uint64_t Mesh = vm_read<uint64_t>(Actor + SDK::Mesh);
                    if (!IsValidAddr(Mesh)) continue;

                    玩家数据 d;
                    d.Actor = Actor;
                    d.FName = FName;
                    d.RootComponent = RootComponent;
                    d.Mesh = Mesh;
                    d.HealthSet = vm_read<uint64_t>(HC + SDK::HealthSet);
                    d.bIsAI = !IsValidAddr(PS);
                    d.CacheCurWeapon = vm_read<uint64_t>(Actor + SDK::CacheCurWeapon);
                    if (IsValidAddr(PS)) {
                        d.TeamID = team.TeamID;
                        d.PlayerNamePrivate = vm_read<uint64_t>(PS + SDK::PlayerNamePrivate);
                        d.HeroId = vm_read<uint64_t>(PS + SDK::HeroId);
                        uint64_t EqComp = vm_read<uint64_t>(Actor + SDK::CharacterEquipComponent);
                        if (IsValidAddr(EqComp)) d.EquipmentInfoArray = vm_read<DFType::TArray>(EqComp + SDK::EquipmentInfoArray);
                    }
                    玩家数据数组.push_back(d);
                    break;
                }
                default: break;
            }
        }
        绘制类型.更新数据(物品数据数组, 盒子数据数组, 玩家数据数组);
    }
    return nullptr;
}

// ========================================
// +load 入口
// ========================================
+ (void)load {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        初始化设备信息();
        pthread_t tid;
        pthread_create(&tid, NULL, 子线程, NULL);
        pthread_detach(tid);
    });
}

// ========================================
// 主渲染循环
// ========================================
void Draw::StartBooks() {
    ImDrawList* dl = BBZGUI::GetBackgroundDrawList();
    if (!dl) return;

    CanvasSize.X = BBZGUI::GetIO().DisplaySize.x;
    CanvasSize.Y = BBZGUI::GetIO().DisplaySize.y;
    if (CanvasSize.X <= 0 || CanvasSize.Y <= 0) return;

    pthread_mutex_lock(&g_lock);
    uint64_t cam = g_PlayerCameraManager;
    uint64_t pawn = g_Pawn;
    pthread_mutex_unlock(&g_lock);

    // 返回大厅检测：相机无效时清空缓冲区
    if (!IsValidAddr(cam)) {
        for (int i = 0; i < 3; i++) {
            绘制类型.缓冲区[i].玩家.clear();
            绘制类型.缓冲区[i].物品.clear();
            绘制类型.缓冲区[i].盒子.clear();
        }

        return;
    }

    DFType::FMinimalViewInfo POV = 取POV(cam + SDK::ViewTarget + SDK::POV);
    if (POV.FOV <= 0.0f || POV.FOV > 180.0f) {
        for (int i = 0; i < 3; i++) {
            绘制类型.缓冲区[i].玩家.clear();
            绘制类型.缓冲区[i].物品.clear();
            绘制类型.缓冲区[i].盒子.clear();
        }

        return;
    }
    DFType::FMatrix 矩阵 = 取矩阵(POV.Rotation);

    if (!总开关) return;

    绘制帧& 帧 = 绘制类型.获取最新帧();
    int 玩家数量 = 0, 人机数量 = 0, 盒子数量 = (int)帧.盒子.size();

    // ========== 物品绘制 ==========
    for (auto& 物品 : 帧.物品) {
        DFType::FVector RelativeLocation = 取RelativeLocation(物品.RootComponent);
        if (RelativeLocation.X == 0.0f && RelativeLocation.Y == 0.0f && RelativeLocation.Z == 0.0f) continue;
        float 距离 = 取距离(RelativeLocation, POV.Location);
        if (距离 < 0.0f || 距离 > 80.0f) continue;
        ImVec2 屏幕坐标 = 取屏幕坐标(RelativeLocation, POV, 矩阵);
        if (屏幕坐标.x <= 0.0f || 屏幕坐标.y <= 0.0f || 屏幕坐标.x >= CanvasSize.X || 屏幕坐标.y >= CanvasSize.Y) continue;
        if (物品.Quality == 0 && 物品.MallRecyclePrice == 0) {
            绘制文字(dl, "未知物品 [ " + to_string((int)距离) + " m ]", 20.0f, 屏幕坐标, IM_COL32_WHITE, 0, true, true);
        } else if (物品.Quality >= 4 && 物品.Quality < 7) {
            uint64_t ItemID = [[NSString stringWithFormat:@"%s", 解密FName(物品.ItemID).c_str()] longLongValue];
            绘制文字(dl, 取物品名(ItemID) + " (价格: " + 取物资价值(物品.MallRecyclePrice) + ") [ " + to_string((int)距离) + " m ]", 20.0f, 屏幕坐标, 取等级颜色(物品.Quality), 0, true, true);
        }
    }

    // ========== 盒子绘制 ==========
    for (auto& 盒子 : 帧.盒子) {
        DFType::FVector RelativeLocation = 取RelativeLocation(盒子.RootComponent);
        if (RelativeLocation.X == 0.0f && RelativeLocation.Y == 0.0f && RelativeLocation.Z == 0.0f) continue;
        float 距离 = 取距离(RelativeLocation, POV.Location);
        if (距离 < 0.0f || 距离 > 80.0f) continue;
        ImVec2 屏幕坐标 = 取屏幕坐标(RelativeLocation, POV, 矩阵);
        if (屏幕坐标.x <= 0.0f || 屏幕坐标.y <= 0.0f || 屏幕坐标.x >= CanvasSize.X || 屏幕坐标.y >= CanvasSize.Y) continue;
        绘制文字(dl, 盒子.bLooted ? "[已开启] " : "[未开启] ", 20.0f, ImVec2(屏幕坐标.x - 5.0f, 屏幕坐标.y), 盒子.bLooted ? IM_COL32(102,255,102,255) : IM_COL32(255,102,102,255), 2, true);
        string boxName = strstr(取FString(盒子.PlayerName_Buffer).c_str(), "INVTEXT") ? 取中段String(取FString(盒子.PlayerName_Buffer)) : "AI";
        绘制文字(dl, boxName + "的盒子 [ " + to_string((int)距离) + " m ]", 20.0f, ImVec2(屏幕坐标.x - 30.0f, 屏幕坐标.y), strstr(取FString(盒子.PlayerName_Buffer).c_str(), "INVTEXT") ? IM_COL32(255,255,102,255) : IM_COL32_WHITE, 1, true);
    }

    // ========== 玩家绘制 ==========
    for (auto& 玩家 : 帧.玩家) {
        if (!IsValidAddr(玩家.Actor) || !IsValidAddr(玩家.Mesh)) continue;
        if (!IsValidAddr(玩家.RootComponent)) continue;
        if (!IsValidAddr(玩家.HealthSet)) continue;

        bool bIsDead = vm_read<bool>(玩家.Actor + SDK::bIsDead);
        if (bIsDead) continue;

        DFType::FVector RelativeLocation = 取RelativeLocation(玩家.RootComponent);
        if (RelativeLocation.X == 0.0f && RelativeLocation.Y == 0.0f && RelativeLocation.Z == 0.0f) continue;
        float 距离 = 取距离(RelativeLocation, POV.Location);
        if (fabsf(距离) > 200.0f) continue;

        DFType::TArray StaticMesh = vm_read<DFType::TArray>(玩家.Mesh + SDK::StaticMesh);
        if (!IsValidAddr(StaticMesh.AllocatorInstance) || StaticMesh.ArrayNum > StaticMesh.ArrayMax || StaticMesh.ArrayNum <= 0) {
            StaticMesh = vm_read<DFType::TArray>(玩家.Mesh + SDK::StaticMesh + 0x10);
            if (!IsValidAddr(StaticMesh.AllocatorInstance) || StaticMesh.ArrayNum > StaticMesh.ArrayMax || StaticMesh.ArrayNum <= 0) continue;
        }

        DFType::FVector 头世界坐标 = 取骨骼世界坐标(玩家.Mesh + SDK::ComponentToWorld, StaticMesh.AllocatorInstance, 骨骼点数组[2]);
        ImVec2 头屏幕坐标 = 取屏幕坐标(头世界坐标, POV, 矩阵);

        if (玩家.bIsAI) 人机数量++; else 玩家数量++;

        float MaxHealth = vm_read<float>(玩家.HealthSet + SDK::MaxHealth);
        float MaxImpendingDeathHealth = vm_read<float>(玩家.HealthSet + SDK::MaxImpendingDeathHealth);
        float Health = MaxHealth > 0.0f ? 100.0f * vm_read<float>(玩家.HealthSet + SDK::Health) / MaxHealth : 0.0f;
        float ImpendingDeathHealth = MaxImpendingDeathHealth > 0.0f ? 100.0f * vm_read<float>(玩家.HealthSet + SDK::ImpendingDeathHealth) / MaxImpendingDeathHealth : 0.0f;

        if (头屏幕坐标.x <= 0.0f || 头屏幕坐标.y <= 0.0f || 头屏幕坐标.x >= CanvasSize.X || 头屏幕坐标.y >= CanvasSize.Y) continue;

        // 骨骼屏幕坐标
        ImVec2 骨骼屏幕坐标[15];
        for (int i = 0; i < 15; i++) {
            if (i == 2) continue;
            DFType::FVector 骨骼世界坐标 = 取骨骼世界坐标(玩家.Mesh + SDK::ComponentToWorld, StaticMesh.AllocatorInstance, 骨骼点数组[i]);
            骨骼屏幕坐标[i] = 取屏幕坐标(骨骼世界坐标, POV, 矩阵);
        }

        ImU32 骨骼颜色 = 玩家.bIsAI && Health > 0 ? IM_COL32(102,255,102,255) : !玩家.bIsAI && Health > 0 ? IM_COL32(255,102,102,255) : IM_COL32(255,255,102,255);

        // ---- 未倒地绘制 ----
        if (Health > 0.0f) {
            // 头甲显示
            if (!玩家.bIsAI && IsValidAddr(玩家.EquipmentInfoArray.AllocatorInstance)) {
                装备数据 头盔 = {
                    取装备等级(取物品名(vm_read<uint64_t>(玩家.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 1))),
                    vm_read<float>(玩家.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::Durability + 0x30 * 1),
                    vm_read<float>(玩家.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::MaxDurability + 0x30 * 1),
                };
                装备数据 防弹衣 = {
                    取装备等级(取物品名(vm_read<uint64_t>(玩家.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 5))),
                    vm_read<float>(玩家.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::Durability + 0x30 * 5),
                    vm_read<float>(玩家.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::MaxDurability + 0x30 * 5),
                };
                if (!(头盔.等级 == 0 && 防弹衣.等级 == 0)) {
                    int 最高等级 = 头盔.等级 > 防弹衣.等级 ? 头盔.等级 : 防弹衣.等级;
                    ImU32 颜色 = 最高等级 == 0 ? IM_COL32_WHITE : (ImU32)取等级颜色(最高等级);
                    绘制文字(dl, (头盔.等级 == 0 ? "无头 / " : (to_string(头盔.等级) + "头 [ " + to_string((int)头盔.耐久) + "/" + to_string((int)头盔.最大耐久) + " ] ")) + (防弹衣.等级 == 0 ? "无甲" : (to_string(防弹衣.等级) + "甲 [ " + to_string((int)防弹衣.耐久) + "/" + to_string((int)防弹衣.最大耐久) + " ] ")), 20.0f, ImVec2(头屏幕坐标.x, 头屏幕坐标.y - 70.0f), 颜色, 0, true);
                }
            }
            // 胸挂/背包/安全箱
            if (!玩家.bIsAI && IsValidAddr(玩家.EquipmentInfoArray.AllocatorInstance)) {
                int 胸挂 = 取装备等级(取物品名(vm_read<uint64_t>(玩家.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 7)));
                int 背包 = 取装备等级(取物品名(vm_read<uint64_t>(玩家.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 8)));
                int 安全箱 = 取装备等级(取物品名(vm_read<uint64_t>(玩家.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 9)));
                if (!(胸挂 == 0 && 背包 == 0 && 安全箱 == 0)) {
                    float footY = 骨骼屏幕坐标[13].y > 骨骼屏幕坐标[14].y ? 骨骼屏幕坐标[13].y : 骨骼屏幕坐标[14].y;
                    绘制文字(dl, (胸挂 == 0 ? "" : to_string(胸挂) + "级胸挂 / ") + (背包 == 0 ? "" : 背包 > 0 && 安全箱 == 0 ? to_string(背包) + "级背包" : to_string(背包) + "级背包 / ") + (安全箱 == 0 ? "" : to_string(安全箱) + "级安全箱"), 20.0f, ImVec2(头屏幕坐标.x, footY + 20.0f), IM_COL32_WHITE, 0, true);
                }
            }
            // 距离
            {
                float footY = 骨骼屏幕坐标[13].y > 骨骼屏幕坐标[14].y ? 骨骼屏幕坐标[13].y : 骨骼屏幕坐标[14].y;
                绘制文字(dl, "[ " + to_string((int)距离) + " m ]", 20.0f, ImVec2(头屏幕坐标.x, footY + 40.0f), IM_COL32_WHITE, 0, true);
            }
            // 武器
            {
                uint64_t WeaponID = vm_read<uint64_t>(玩家.CacheCurWeapon + SDK::WeaponID);
                if (WeaponID > 0) {
                    绘制文字(dl, 取物品名(WeaponID), 20.0f, ImVec2(头屏幕坐标.x, 头屏幕坐标.y - 50.0f), IM_COL32_WHITE, 0, true);
                }
            }
        }

        // ---- 全局绘制 ----
        // 名字
        绘制文字(dl, 玩家.bIsAI ? 取人机名字(玩家.FName) : "(" + to_string(玩家.TeamID) + ") " + 取FString(玩家.PlayerNamePrivate) + 取英雄名(玩家.HeroId), 20.0f, ImVec2(头屏幕坐标.x, 头屏幕坐标.y - 30.0f), 玩家.bIsAI ? IM_COL32_WHITE : IM_COL32(255,255,102,255), 0, true);
        // 血条
        绘制血条(dl, 头屏幕坐标, Health, ImpendingDeathHealth, 玩家.bIsAI);
        // 骨骼
        dl->AddLine(头屏幕坐标, 骨骼屏幕坐标[1], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[1], 骨骼屏幕坐标[0], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[1], 骨骼屏幕坐标[3], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[3], 骨骼屏幕坐标[4], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[4], 骨骼屏幕坐标[5], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[1], 骨骼屏幕坐标[6], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[6], 骨骼屏幕坐标[7], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[7], 骨骼屏幕坐标[8], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[0], 骨骼屏幕坐标[9], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[9], 骨骼屏幕坐标[10], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[10], 骨骼屏幕坐标[11], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[0], 骨骼屏幕坐标[12], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[12], 骨骼屏幕坐标[13], 骨骼颜色);
        dl->AddLine(骨骼屏幕坐标[13], 骨骼屏幕坐标[14], 骨骼颜色);
    }

    // ========== 顶部统计 ==========
    {
        float cx = CanvasSize.X * 0.5f;
        float cy = 30.0f;
        string s1 = "玩家:" + to_string(玩家数量) + "  ";
        string s2 = "NPC:" + to_string(人机数量) + "  ";
        string s3 = "盒子:" + to_string(盒子数量);
        float w1 = BBZGUI::CalcTextSize(s1.c_str()).x * 0.35f;
        float w2 = BBZGUI::CalcTextSize(s2.c_str()).x * 0.35f;
        float total = w1 + w2 + BBZGUI::CalcTextSize(s3.c_str()).x * 0.35f;
        float startX = cx - total * 0.5f;
        绘制文字(dl, s1, 20.0f, ImVec2(startX, cy), IM_COL32(255, 102, 102, 255), 1, true);
        绘制文字(dl, s2, 20.0f, ImVec2(startX + w1, cy), IM_COL32(102, 255, 102, 255), 1, true);
        绘制文字(dl, s3, 20.0f, ImVec2(startX + w1 + w2, cy), IM_COL32(255, 255, 102, 255), 1, true);
    }

    // ========== FPS & 时间 ==========
    {
        int fps = (int)(1.0f / BBZGUI::GetIO().DeltaTime);
        time_t now = time(nullptr);
        struct tm bj;
        now += 8 * 3600; // UTC+8 北京时间
        gmtime_r(&now, &bj);
        char timeBuf[32];
        snprintf(timeBuf, sizeof(timeBuf), "%02d:%02d:%02d", bj.tm_hour, bj.tm_min, bj.tm_sec);
        绘制文字(dl, "FPS:" + to_string(fps) + "  " + string(timeBuf), 20.0f, ImVec2(10.0f, CanvasSize.Y - 20.0f), IM_COL32(102, 255, 102, 255), 1, true);
    }
}

@end
