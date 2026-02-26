
#import <pthread.h>

namespace 三角洲行动 {

struct UGPTeamComponent {
    int TeamID;
    int CampId;
};

struct FBigMapWorldRangeInfo {
    float X;
    float Y;
    float W;
    float H;
    int MapX;
    int MapY;
};

};

struct 类名数据 {
    uint64_t RootComponent;
    string FName;
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
//    uint64_t KillerName;
//    bool IsHitHead;
    bool bLooted;
};

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
    UE4类型::TArray EquipmentInfoArray;
};

struct 装备数据 {
    int 等级;
    float 耐久;
    float 最大耐久;
};

struct {
    uint64_t MobileHUD_BigMap;
    uint64_t PlayerCameraManager;
    pthread_mutex_t 锁 = PTHREAD_MUTEX_INITIALIZER;
    
    void 设置相机(uint64_t 相机) {
        pthread_mutex_lock(&锁);
        PlayerCameraManager = 相机;
        pthread_mutex_unlock(&锁);
    }
    
    void 设置地图(uint64_t 地图) {
        pthread_mutex_lock(&锁);
        MobileHUD_BigMap = 地图;
        pthread_mutex_unlock(&锁);
    }
    
    uint64_t 获取相机() {
        pthread_mutex_lock(&锁);
        uint64_t 结果 = PlayerCameraManager;
        pthread_mutex_unlock(&锁);
        return 结果;
    }
    
    uint64_t 获取地图() {
        pthread_mutex_lock(&锁);
        uint64_t 结果 = MobileHUD_BigMap;
        pthread_mutex_unlock(&锁);
        return 结果;
    }
    
    void 清空() {
        pthread_mutex_lock(&锁);
        PlayerCameraManager = 0;
        MobileHUD_BigMap = 0;
        pthread_mutex_unlock(&锁);
    }
} 自身数据;
