//
//  绘制类型.h - UE4 类型定义 + 数据结构 + 三缓冲
//

#ifndef 绘制类型_h
#define 绘制类型_h

#include <vector>
#include <string>
#include <atomic>

using namespace std;

// ========================================
// UE4 类型定义
// ========================================
namespace DFType {
    struct TArray {
        uint64_t AllocatorInstance;
        int ArrayNum;
        int ArrayMax;
    };
    struct FVector { float X, Y, Z; };
    struct FRotator { float Pitch, Yaw, Roll; };
    struct FMinimalViewInfo { FVector Location; FRotator Rotation; float FOV; };
    struct FPlane : FVector { float W; };
    struct FMatrix { FPlane XPlane, YPlane, ZPlane, WPlane; };
    struct FVector2D { float X, Y; FVector2D(float X=0,float Y=0):X(X),Y(Y){} };
    struct FQuat { float X, Y, Z, W; };
    struct FTransform { FQuat Rotation; FVector Translation; FVector Scale3D; };
    struct FBigMapWorldRangeInfo { float X, Y, W, H; int MapX, MapY; };
    struct UGPTeamComponent { int TeamID; int CampId; };
};

// ========================================
// 数据结构
// ========================================
struct 玩家数据 {
    uint64_t Actor;
    string FName;
    int TeamID;
    uint64_t RootComponent;
    uint64_t Mesh;
    uint64_t PlayerNamePrivate;
    bool bIsAI;
    uint64_t CacheCurWeapon;
    uint64_t HeroId;
    uint64_t HealthSet;
    DFType::TArray EquipmentInfoArray;
};

struct 物品数据 {
    uint64_t Actor;
    uint64_t RootComponent;
    int ItemID;
    int Quality;
    int MallRecyclePrice;
};

struct 盒子数据 {
    uint64_t RootComponent;
    uint64_t PlayerName_Buffer;
    bool bLooted;
};

struct 装备数据 {
    int 等级;
    float 耐久;
    float 最大耐久;
};

// ========================================
// 三缓冲
// ========================================
struct 绘制帧 {
    vector<物品数据> 物品;
    vector<盒子数据> 盒子;
    vector<玩家数据> 玩家;
};

static struct {
    绘制帧 缓冲区[3];
    atomic<int> 读取索引{0};
    atomic<int> 最新索引{0};
    int 写入索引 = 1;

    void 更新数据(vector<物品数据>& 物品, vector<盒子数据>& 盒子, vector<玩家数据>& 玩家) {
        缓冲区[写入索引].物品.swap(物品);
        缓冲区[写入索引].盒子.swap(盒子);
        缓冲区[写入索引].玩家.swap(玩家);
        int 旧最新 = 最新索引.exchange(写入索引);
        int 当前读取 = 读取索引.load();
        if (旧最新 != 当前读取) { 写入索引 = 旧最新; }
        else { for (int i=0;i<3;i++) { if (i!=当前读取 && i!=最新索引.load()) { 写入索引=i; break; } } }
    }

    绘制帧& 获取最新帧() {
        读取索引.store(最新索引.load());
        return 缓冲区[读取索引.load()];
    }
} 绘制类型;

#endif
