#import "SDK.h"
#import "绘图.h"
#import "物品ID.h"
#import "绘制算法.h"

#import "按钮存储.h"
#import "网页雷达服务器.h"

int 骨骼点数组[15] = {1, 30, 31, 6, 7, 8, 34, 35, 36, 58, 59, 60, 62, 63, 64};

UE4类型::FVector 取RelativeLocation(uint64_t RootComponent) {
    if (!kfd.地址判断(RootComponent)) return {0.0f, 0.0f, 0.0f};
    UE4类型::FVector RelativeLocation = kfd.取vreadbuf<UE4类型::FVector>(RootComponent + 0x148);
    if (RelativeLocation.X == 0.0f && RelativeLocation.Y == 0.0f && RelativeLocation.Z == 0.0f) {
        RelativeLocation = kfd.取vreadbuf<UE4类型::FVector>(RootComponent + 0x168);
        if (RelativeLocation.X == 0.0f && RelativeLocation.Y == 0.0f && RelativeLocation.Z == 0.0f) {
            RelativeLocation = kfd.取vreadbuf<UE4类型::FVector>(RootComponent + 0x220);
        };
    };
    return RelativeLocation;
};

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
        };
    };
    return to_string(MallRecyclePrice);
};

string 取人机名字(string FName) {
    if (FName == "NC_BP_DFMCharacter_AI_DT_RPG_C") {
        return "阿莎拉火箭筒兵";
    } else if (FName == "NC_BP_DFMCharacter_AI_DT_C") {
        return "阿莎拉卫队士兵";
    } else if (FName == "NC_BP_DFMAICharacter_ShielderLight_C") {
        return "阿莎拉盾兵";
    } else if (FName == "NC_BP_DFMCharacter_AI_AlwaysFall_DTSniper_C") {
        return "阿莎拉狙击兵";
    } else if (FName == "NC_BP_DFMAICharacter_HeavyMachineGun_C") {
        return "阿莎拉机枪兵";
    } else if (FName == "NC_BP_DFMCharacter_AI_Maurice_C") {
        return "[卫队长官] 赛伊德";
    } else if (FName == "NC_BP_DFMCharacter_AI_HS_C") {
        return "哈夫克士兵";
    } else if (FName == "NC_BP_DFMAICharacter_HeavyMachineGun_HS_C") {
        return "哈夫克机枪兵";
    } else if (FName == "NC_BP_DFMAICharacter_HeavyMachineGun_C") {
        return "阿莎拉机枪兵";
    } else if (FName == "NC_BP_DFMAICharacter_ShielderLight_HS_C") {
        return "哈夫克盾兵";
    } else if (FName == "NC_BP_DFMCharacter_AI_AlwaysFall_HSSniper_C") {
        return "哈夫克狙击兵";
    } else if (FName == "NC_BP_DFMAICharacter_Firebat_HS_C") {
        return "哈夫克喷火兵";
    } else if (FName == "BP_RangeTargetCharacter_C") {
        return "标靶";
    } else if (FName == "NC_BP_DFMAICharacter_Firebat_C") {
        return "阿莎拉喷火兵";
    } else if (FName == "NC_BP_DFMCharacter_AI_BossRCV_C") {
        return "哈夫克战车";
    } else if (FName == "NC_BP_DFMAICharacter_Boss03_C") {
        return "[安全总监] 赛伊德";
    } else if (FName == "NC_BP_DFMCharacter_Boss07_NewGuard_C") {
        return "哈德森护卫队";
    } else if (FName == "NC_BP_DFMCharacter_AI_Boss07_C") {
        return "[安全总监] 哈德森";
    } else if (FName == "NC_BP_DFMCharacter_AI_Boss07RCV_C") {
        return "哈德森护卫队战车";
    } else if (FName == "NC_BP_DFMCharacter_AI_Boss06_Waden_C") {
        return "[格赫罗斯] 典狱长";
    } else if (FName == "NC_BP_DFMCharacter_AI_Shark_C") {
        return "鲨鱼";
    };
    return "";
};

ImVec2 取雷达坐标(三角洲行动::FBigMapWorldRangeInfo BigMapWorldRangeInfo, UE4类型::FVector RelativeLocation, bool 判断) {
    ImVec2 地图位置 = {
        判断 ? BigMapWorldRangeInfo.MapX * 1.00675f - RelativeLocation.Y - BigMapWorldRangeInfo.X : BigMapWorldRangeInfo.MapX + RelativeLocation.X - BigMapWorldRangeInfo.X,
        判断 ? BigMapWorldRangeInfo.MapY * 0.99805f + RelativeLocation.X - BigMapWorldRangeInfo.Y : BigMapWorldRangeInfo.MapY + RelativeLocation.Y - BigMapWorldRangeInfo.Y,
    };
    return {
        地图位置.x / BigMapWorldRangeInfo.W * 设备类型.设备信息.宽度,
        地图位置.y / BigMapWorldRangeInfo.H * 设备类型.设备信息.高度,
    };
};

string 取中段String(string String) {
    size_t 开始位置 = String.find('"');
    if (开始位置 == string::npos) {
        return "";
    };

    size_t 结束位置 = String.find('"', 开始位置 + 1);
    if (结束位置 == string::npos) {
        return "";
    }

    return String.substr(开始位置 + 1, 结束位置 - 开始位置 - 1);
};

ImColor 取等级颜色(int 等级) {
    if (等级 < 1 || 等级 > 7) return IM_COL32(0, 0, 0, 128);
    switch (等级) {
        case 1: return IM_COL32_WHITE;
        case 2: return IM_COL32(102, 255, 102, 255);
        case 3: return IM_COL32(102, 255, 255, 255);
        case 4: return IM_COL32(255, 102, 255, 255);
        case 5: return IM_COL32(255, 255, 102, 255);
    };
    return IM_COL32(255, 102, 102, 255);
};

// 网页雷达数据收集
vector<雷达玩家数据> g_网页雷达数据;
vector<雷达物资数据> g_网页物资数据;

void 主线程(ImDrawList* ImDrawList, int &玩家数量, int &人机数量, int &盒子数量) {
    uint64_t 相机地址 = 自身数据.获取相机();
    if (!kfd.地址判断(相机地址)) return;
    
    UE4类型::FMinimalViewInfo POV = UE4算法::取POV(相机地址 + SDK::ViewTarget + SDK::POV);
    // 检查POV是否有效
    if (POV.FOV <= 0.0f || POV.FOV > 180.0f) return;
    UE4类型::FMatrix 矩阵 = UE4算法::取矩阵(POV.Rotation);
    // UE4类型::FMatrix 矩阵 = kfd.取vreadbuf<UE4类型::FMatrix>(自身数据.矩阵特征 + 0x280);
    
    uint64_t 地图地址 = 自身数据.获取地图();
    bool preShouldDraw = false;
    三角洲行动::FBigMapWorldRangeInfo BigMapWorldRangeInfo = {};
    static 三角洲行动::FBigMapWorldRangeInfo 缓存地图信息 = {}; // 缓存地图信息
    
    if (kfd.地址判断(地图地址)) {
        preShouldDraw = kfd.取vreadbuf<bool>(地图地址 + SDK::preShouldDraw);
        BigMapWorldRangeInfo = kfd.取vreadbuf<三角洲行动::FBigMapWorldRangeInfo>(地图地址 + SDK::BigMapWorldRangeInfo);
        
        // 如果打开了大地图且数据有效，缓存地图信息
        if (preShouldDraw && BigMapWorldRangeInfo.W > 0 && BigMapWorldRangeInfo.H > 0) {
            缓存地图信息 = BigMapWorldRangeInfo;
        }
    }
    
    // 如果当前地图信息无效，使用缓存的
    if (BigMapWorldRangeInfo.W <= 0 || BigMapWorldRangeInfo.H <= 0) {
        BigMapWorldRangeInfo = 缓存地图信息;
    }
    // 清空网页雷达数据
    g_网页雷达数据.clear();
    g_网页物资数据.clear();
    
    // 跨进程读取设置 - 从共享plist文件读取
    NSDictionary *配置 = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.map.settings.plist"];
    BOOL 人机显示开关 = [[配置 objectForKey:@"人机密钥"] boolValue];
    BOOL 骨骼显示开关 = [[配置 objectForKey:@"骨骼密钥"] boolValue];
    BOOL 血条显示开关 = [[配置 objectForKey:@"血条密钥"] boolValue];
    BOOL 信息显示开关 = [[配置 objectForKey:@"信息密钥"] boolValue];
    BOOL 头甲显示开关 = [[配置 objectForKey:@"头甲密钥"] boolValue];
    BOOL 装备显示开关 = [[配置 objectForKey:@"装备密钥"] boolValue];
    BOOL 距离显示开关 = [[配置 objectForKey:@"距离密钥"] boolValue];
    BOOL 雷达显示开关 = [[配置 objectForKey:@"雷达密钥"] boolValue];
    BOOL 物资显示开关 = [[配置 objectForKey:@"物资密钥"] boolValue];
    BOOL 盒子显示开关 = [[配置 objectForKey:@"盒子密钥"] boolValue];
    BOOL 射线显示开关 = [[配置 objectForKey:@"射线密钥"] boolValue];
    BOOL 类名显示开关 = [[配置 objectForKey:@"类名密钥"] boolValue];
    
    // 线程安全地获取数据副本
    vector<物品数据> 本地物品数据数组;
    vector<盒子数据> 本地盒子数据数组;
    vector<玩家数据> 本地玩家数据数组;
    vector<类名数据> 本地类名数据数组;
    绘制类型.获取数据(本地物品数据数组, 本地盒子数据数组, 本地玩家数据数组, 本地类名数据数组);
    
    for (类名数据 类名数据 : 本地类名数据数组) {
        if (!preShouldDraw && 类名显示开关) {
            UE4类型::FVector RelativeLocation = 取RelativeLocation(类名数据.RootComponent);
            if (RelativeLocation.X == 0.0f && RelativeLocation.Y == 0.0f && RelativeLocation.Z == 0.0f) continue;
            float 距离 = UE4算法::取距离(RelativeLocation, POV.Location);
            if (距离 < 0.0f || 距离 > 200.0f) continue;
            ImVec2 屏幕坐标 = UE4算法::取屏幕坐标(RelativeLocation, POV, 矩阵);
            if (屏幕坐标.x > 0.0f && 屏幕坐标.y > 0.0f && 屏幕坐标.x < 设备类型.设备信息.宽度 && 屏幕坐标.y < 设备类型.设备信息.高度) {
                绘制文字(ImDrawList, 类名数据.FName, 20.0f, 屏幕坐标, IM_COL32_WHITE, 0, true);
            };
        };
    };
    
    for (物品数据 物品数据 : 本地物品数据数组) {
        UE4类型::FVector RelativeLocation = 取RelativeLocation(物品数据.RootComponent);
        if (RelativeLocation.X == 0.0f && RelativeLocation.Y == 0.0f && RelativeLocation.Z == 0.0f) continue;
        float 距离 = UE4算法::取距离(RelativeLocation, POV.Location);
        
        // 网页雷达物资数据收集 - 只收集4级及以上物资
        if (g_网页雷达.是否运行中() && 物品数据.Quality >= 4 && 物品数据.Quality < 7) {
            uint64_t ItemID = [[NSString stringWithFormat:@"%s", 解密FName(物品数据.ItemID).c_str()] longLongValue];
            雷达物资数据 物资;
            物资.x = RelativeLocation.X;
            物资.y = RelativeLocation.Y;
            物资.name = 取物品名(ItemID);
            物资.quality = 物品数据.Quality;
            物资.price = 物品数据.MallRecyclePrice;
            g_网页物资数据.push_back(物资);
        }
        
        // 手机端绘制
        if (!preShouldDraw && 物资显示开关) {
            if (距离 < 0.0f || 距离 > 80.0f) continue;
            ImVec2 屏幕坐标 = UE4算法::取屏幕坐标(RelativeLocation, POV, 矩阵);
            if (屏幕坐标.x > 0.0f && 屏幕坐标.y > 0.0f && 屏幕坐标.x < 设备类型.设备信息.宽度 && 屏幕坐标.y < 设备类型.设备信息.高度) {
                if (物品数据.Quality == 0 && 物品数据.MallRecyclePrice == 0) {
                    绘制文字(ImDrawList, "未知物品 [ " + to_string((int)距离) + " m ]", 20.0f, 屏幕坐标, IM_COL32_WHITE, 0, true, true);
                } else if (物品数据.Quality >= 4 && 物品数据.Quality < 7) {
                    uint64_t ItemID = [[NSString stringWithFormat:@"%s", 解密FName(物品数据.ItemID).c_str()] longLongValue];
                    绘制文字(ImDrawList, 取物品名(ItemID) + " (价格: " + 取物资价值(物品数据.MallRecyclePrice) + ") [ " + to_string((int)距离) + " m ]", 20.0f, 屏幕坐标, 取等级颜色(物品数据.Quality), 0, true, true);
                };
            };
        }; 
    };
    
    for (盒子数据 盒子数据 : 本地盒子数据数组) {
        if (!preShouldDraw && 盒子显示开关) {
            UE4类型::FVector RelativeLocation = 取RelativeLocation(盒子数据.RootComponent);
            if (RelativeLocation.X == 0.0f && RelativeLocation.Y == 0.0f && RelativeLocation.Z == 0.0f) continue;
            float 距离 = UE4算法::取距离(RelativeLocation, POV.Location);
            if (距离 < 0.0f || 距离 > 80.0f) continue;
            ImVec2 屏幕坐标 = UE4算法::取屏幕坐标(RelativeLocation, POV, 矩阵);
            if (屏幕坐标.x > 0.0f && 屏幕坐标.y > 0.0f && 屏幕坐标.x < 设备类型.设备信息.宽度 && 屏幕坐标.y < 设备类型.设备信息.高度) {
                绘制文字(ImDrawList, 盒子数据.bLooted ? "[已开启] " : "[未开启] ", 20.0f, ImVec2(屏幕坐标.x - 5.0f, 屏幕坐标.y), 盒子数据.bLooted ? IM_COL32(102, 255, 102, 255) : IM_COL32(255, 102, 102, 255), 2, true);
                绘制文字(ImDrawList, (strstr(UE4算法::取FString(盒子数据.PlayerName_Buffer).c_str(), "INVTEXT") ?  取中段String(UE4算法::取FString(盒子数据.PlayerName_Buffer)) : "AI") + "的盒子 [ " + to_string((int)距离) + " m ]", 20.0f, ImVec2(屏幕坐标.x - 30.0f, 屏幕坐标.y), strstr(UE4算法::取FString(盒子数据.PlayerName_Buffer).c_str(), "INVTEXT") ? IM_COL32(255, 255, 102, 255) : IM_COL32_WHITE, 1, true);
            };
        };
    };
    
    for (玩家数据 玩家数据 : 本地玩家数据数组) {
        if (!kfd.地址判断(玩家数据.Actor) || !kfd.地址判断(玩家数据.Mesh)) continue;
        if (!kfd.地址判断(玩家数据.RootComponent)) continue;
        if (!kfd.地址判断(玩家数据.HealthSet)) continue;
        
        bool bIsDead = kfd.取vreadbuf<bool>(玩家数据.Actor + SDK::bIsDead);
        if (bIsDead) continue;
        
        UE4类型::FVector RelativeLocation = 取RelativeLocation(玩家数据.RootComponent);
        if (RelativeLocation.X == 0.0f && RelativeLocation.Y == 0.0f && RelativeLocation.Z == 0.0f) continue;
        float 距离 = UE4算法::取距离(RelativeLocation, POV.Location);
        
        // 网页雷达数据收集 - 不受距离和大地图限制
        if (g_网页雷达.是否运行中()) {
            float MaxHealth = kfd.取vreadbuf<float>(玩家数据.HealthSet + SDK::MaxHealth);
            float 当前血量 = MaxHealth > 0.0f ? 100.0f * kfd.取vreadbuf<float>(玩家数据.HealthSet + SDK::Health) / MaxHealth : 0.0f;
            
            雷达玩家数据 网页数据;
            // 直接用世界坐标
            网页数据.x = RelativeLocation.X;
            网页数据.y = RelativeLocation.Y;
            网页数据.teamId = 玩家数据.TeamID;
            网页数据.name = 玩家数据.bIsAI ? 取人机名字(玩家数据.FName) : UE4算法::取FString(玩家数据.PlayerNamePrivate);
            网页数据.health = 当前血量;
            网页数据.direction = 0;
            网页数据.isAI = 玩家数据.bIsAI;
            
            // 获取武器名称
            uint64_t WeaponID = kfd.取vreadbuf<uint64_t>(玩家数据.CacheCurWeapon + SDK::WeaponID);
            网页数据.weapon = WeaponID > 0 ? 取物品名(WeaponID) : "";
            
            // 获取头盔和护甲信息
            网页数据.helmetLevel = "none";
            网页数据.helmetDurability = 0;
            网页数据.armorLevel = "none";
            网页数据.armorDurability = 0;
            
            if (!玩家数据.bIsAI && kfd.地址判断(玩家数据.EquipmentInfoArray.AllocatorInstance)) {
                int 头盔等级 = 取装备等级(取物品名(kfd.取vreadbuf<uint64_t>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 1)));
                float 头盔耐久 = kfd.取vreadbuf<float>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::Durability + 0x30 * 1);
                float 头盔最大耐久 = kfd.取vreadbuf<float>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::MaxDurability + 0x30 * 1);
                if (头盔等级 > 0) {
                    const char* 等级颜色[] = {"none", "white", "white", "blue", "purple", "gold", "red"};
                    网页数据.helmetLevel = 头盔等级 < 7 ? 等级颜色[头盔等级] : "red";
                    网页数据.helmetDurability = 头盔耐久;
                    网页数据.helmetMaxDurability = 头盔最大耐久;
                }
                
                int 护甲等级 = 取装备等级(取物品名(kfd.取vreadbuf<uint64_t>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 5)));
                float 护甲耐久 = kfd.取vreadbuf<float>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::Durability + 0x30 * 5);
                float 护甲最大耐久 = kfd.取vreadbuf<float>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::MaxDurability + 0x30 * 5);
                if (护甲等级 > 0) {
                    const char* 等级颜色[] = {"none", "white", "white", "blue", "purple", "gold", "red"};
                    网页数据.armorLevel = 护甲等级 < 7 ? 等级颜色[护甲等级] : "red";
                    网页数据.armorDurability = 护甲耐久;
                    网页数据.armorMaxDurability = 护甲最大耐久;
                }
            }
            
            g_网页雷达数据.push_back(网页数据);
        }
        
        // 如果是人机且人机显示关闭，跳过本地绘制
        if (玩家数据.bIsAI && !人机显示开关) continue;
        if (fabsf(距离) > 200.0f) continue;
        UE4类型::TArray StaticMesh = kfd.取vreadbuf<UE4类型::TArray>(玩家数据.Mesh + SDK::StaticMesh);
        if (!kfd.地址判断(StaticMesh.AllocatorInstance) || StaticMesh.ArrayNum > StaticMesh.ArrayMax || StaticMesh.ArrayNum <= 0) {
            StaticMesh = kfd.取vreadbuf<UE4类型::TArray>(玩家数据.Mesh + SDK::StaticMesh + 0x10);
            if (!kfd.地址判断(StaticMesh.AllocatorInstance) || StaticMesh.ArrayNum > StaticMesh.ArrayMax || StaticMesh.ArrayNum <= 0) {
                continue;
            }
        };
        
        UE4类型::FVector 头世界坐标 = UE4算法::取骨骼世界坐标(玩家数据.Mesh + SDK::ComponentToWorld, StaticMesh.AllocatorInstance, 骨骼点数组[2]);
        ImVec2 头屏幕坐标 =  UE4算法::取屏幕坐标(头世界坐标, POV, 矩阵);
        
        if (玩家数据.bIsAI) 人机数量++; else 玩家数量++;
        
        float MaxHealth = kfd.取vreadbuf<float>(玩家数据.HealthSet + SDK::MaxHealth);
        float MaxImpendingDeathHealth = kfd.取vreadbuf<float>(玩家数据.HealthSet + SDK::MaxImpendingDeathHealth);
        // 防止除以0
        float Health = MaxHealth > 0.0f ? 100.0f * kfd.取vreadbuf<float>(玩家数据.HealthSet + SDK::Health) / MaxHealth : 0.0f;
        float ImpendingDeathHealth = MaxImpendingDeathHealth > 0.0f ? 100.0f * kfd.取vreadbuf<float>(玩家数据.HealthSet + SDK::ImpendingDeathHealth) / MaxImpendingDeathHealth : 0.0f;
        
        if (!preShouldDraw) {
            if (头屏幕坐标.x > 0.0f && 头屏幕坐标.y > 0.0f && 头屏幕坐标.x < 设备类型.设备信息.宽度 && 头屏幕坐标.y < 设备类型.设备信息.高度) {
                ImVec2 骨骼屏幕坐标[15];
                for (int i = 0; i < 15; i++) {
                    if (i == 2) continue;
                    UE4类型::FVector 骨骼世界坐标 = UE4算法::取骨骼世界坐标(玩家数据.Mesh + SDK::ComponentToWorld, StaticMesh.AllocatorInstance, 骨骼点数组[i]);
                    骨骼屏幕坐标[i] = UE4算法::取屏幕坐标(骨骼世界坐标, POV, 矩阵);
                };
                
    #pragma mark -- 未倒地前绘制部分
                if (Health > 0.0f) {
                    // 头甲显示 - 独立开关
                    if (!玩家数据.bIsAI && 头甲显示开关) {
                        if (kfd.地址判断(玩家数据.EquipmentInfoArray.AllocatorInstance)) {
                            装备数据 头盔 = {
                                取装备等级(取物品名(kfd.取vreadbuf<uint64_t>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 1))),
                                kfd.取vreadbuf<float>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::Durability + 0x30  * 1),
                                kfd.取vreadbuf<float>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::MaxDurability + 0x30  * 1),
                            };
                            装备数据 防弹衣 = {
                                取装备等级(取物品名(kfd.取vreadbuf<uint64_t>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 5))),
                                kfd.取vreadbuf<float>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::Durability + 0x30  * 5),
                                kfd.取vreadbuf<float>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::MaxDurability + 0x30  * 5),
                            };
                            
                            if (!(头盔.等级 == 0 && 防弹衣.等级 == 0)) {
                                // 取较高等级的颜色
                                int 最高等级 = 头盔.等级 > 防弹衣.等级 ? 头盔.等级 : 防弹衣.等级;
                                ImU32 颜色 = 最高等级 == 0 ? IM_COL32_WHITE : (ImU32)取等级颜色(最高等级);
                                绘制文字(ImDrawList, (头盔.等级 == 0 ? "无头 / " : (to_string(头盔.等级) + "头 [ " + to_string((int)头盔.耐久) + "/" + to_string((int)头盔.最大耐久) + " ] ")) + (防弹衣.等级 == 0 ? "无甲" : (to_string(防弹衣.等级) + "甲 [ " + to_string((int)防弹衣.耐久) + "/" + to_string((int)防弹衣.最大耐久) + " ] ")), 20.0f, ImVec2(头屏幕坐标.x, 头屏幕坐标.y - 70.0f), 颜色, 0, true);
                            };
                        };
                    };
                    // 装备显示 - 胸挂/背包/保险箱
                    if (!玩家数据.bIsAI && 装备显示开关) {
                        if (kfd.地址判断(玩家数据.EquipmentInfoArray.AllocatorInstance)) {
                            int 胸挂 = 取装备等级(取物品名(kfd.取vreadbuf<uint64_t>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 7)));
                            int 背包 = 取装备等级(取物品名(kfd.取vreadbuf<uint64_t>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 8)));
                            int 安全箱 = 取装备等级(取物品名(kfd.取vreadbuf<uint64_t>(玩家数据.EquipmentInfoArray.AllocatorInstance + SDK::FEquipmentInfo::ItemID + 0x30 * 9)));
                            if (!(胸挂 == 0 && 背包 == 0 && 安全箱 == 0)) {
                                绘制文字(ImDrawList, (胸挂 == 0 ? "" : to_string(胸挂) + "级胸挂 / ") + (背包 == 0 ? "" : 背包 > 0 && 安全箱 == 0 ? to_string(背包) + "级背包" : to_string(背包) + "级背包 / ") + (安全箱 == 0 ? "" : to_string(安全箱) + "级安全箱"), 20.0f, ImVec2(头屏幕坐标.x, (骨骼屏幕坐标[13].y > 骨骼屏幕坐标[14].y ? 骨骼屏幕坐标[13].y : 骨骼屏幕坐标[14].y) + 20.0f), IM_COL32_WHITE, 0, true);
                            };
                        };
                    };
                    // 距离显示 - 独立开关
                    if (距离显示开关) {
                        绘制文字(ImDrawList, "[ " + to_string((int)距离) + " m ]", 20.0f, ImVec2(头屏幕坐标.x, (骨骼屏幕坐标[13].y > 骨骼屏幕坐标[14].y ? 骨骼屏幕坐标[13].y : 骨骼屏幕坐标[14].y) + (装备显示开关 ? 40.0f : 20.0f)), IM_COL32_WHITE, 0, true);
                    };
                    if (信息显示开关) {
                        uint64_t WeaponID = kfd.取vreadbuf<uint64_t>(玩家数据.CacheCurWeapon + SDK::WeaponID);
                        if (WeaponID > 0) {
                            绘制文字(ImDrawList, 取物品名(WeaponID), 20.0f, ImVec2(头屏幕坐标.x, 头屏幕坐标.y - 50.0f), IM_COL32_WHITE, 0, true);
                        };
                    };
                };
    #pragma mark -- 全局绘制部分
                if (信息显示开关) {
                    绘制文字(ImDrawList, 玩家数据.bIsAI ? 取人机名字(玩家数据.FName) : "(" + to_string(玩家数据.TeamID) + ") " + UE4算法::取FString(玩家数据.PlayerNamePrivate) + 取英雄名(玩家数据.HeroId), 20.0f, ImVec2(头屏幕坐标.x, 头屏幕坐标.y - 30.0f), 玩家数据.bIsAI ? IM_COL32_WHITE : IM_COL32(255, 255, 102, 255), 0, true);
                };
                
                if (血条显示开关) {
                    绘制血条(ImDrawList, 头屏幕坐标, Health, ImpendingDeathHealth, 玩家数据.bIsAI);
                };
                if (骨骼显示开关) {
                    ImDrawList->AddLine(头屏幕坐标, 骨骼屏幕坐标[1], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    ImDrawList->AddLine(骨骼屏幕坐标[1], 骨骼屏幕坐标[0], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    
                    ImDrawList->AddLine(骨骼屏幕坐标[1], 骨骼屏幕坐标[3], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    ImDrawList->AddLine(骨骼屏幕坐标[3], 骨骼屏幕坐标[4], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    ImDrawList->AddLine(骨骼屏幕坐标[4], 骨骼屏幕坐标[5], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    
                    ImDrawList->AddLine(骨骼屏幕坐标[1], 骨骼屏幕坐标[6], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    ImDrawList->AddLine(骨骼屏幕坐标[6], 骨骼屏幕坐标[7], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    ImDrawList->AddLine(骨骼屏幕坐标[7], 骨骼屏幕坐标[8], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    
                    ImDrawList->AddLine(骨骼屏幕坐标[0], 骨骼屏幕坐标[9], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    ImDrawList->AddLine(骨骼屏幕坐标[9], 骨骼屏幕坐标[10], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    ImDrawList->AddLine(骨骼屏幕坐标[10], 骨骼屏幕坐标[11], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    
                    ImDrawList->AddLine(骨骼屏幕坐标[0], 骨骼屏幕坐标[12], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    ImDrawList->AddLine(骨骼屏幕坐标[12], 骨骼屏幕坐标[13], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                    ImDrawList->AddLine(骨骼屏幕坐标[13], 骨骼屏幕坐标[14], 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                };
                // 射线绘制 - 从屏幕中心到目标头部的白色线条
                if (射线显示开关) {
                    ImVec2 屏幕中心 = ImVec2(设备类型.设备信息.宽度 * 0.5f, 设备类型.设备信息.高度 * 0.5f);
                    ImDrawList->AddLine(屏幕中心, 头屏幕坐标, IM_COL32_WHITE);
                };
            };
        } else {
            if (!玩家数据.bIsAI && 雷达显示开关) {
                ImVec2 雷达坐标 = 取雷达坐标(BigMapWorldRangeInfo, RelativeLocation, BigMapWorldRangeInfo.MapX == 330062 ? true : false);
                绘制圆形(ImDrawList, 9, 雷达坐标, 玩家数据.bIsAI && Health ? IM_COL32(102, 255, 102, 255) : !玩家数据.bIsAI && Health ? IM_COL32(255, 102, 102, 255) : IM_COL32(255, 255, 102, 255));
                绘制圆形(ImDrawList, 9, 雷达坐标, IM_COL32_BLACK, true);
                绘制文字(ImDrawList, "(" + to_string(玩家数据.TeamID) + ") " + UE4算法::取FString(玩家数据.PlayerNamePrivate) + 取英雄名(玩家数据.HeroId), 20.0f, ImVec2(雷达坐标.x, 雷达坐标.y + 20.0f), IM_COL32_WHITE, 0, true);
            };
        };
    };
    
    // 更新网页雷达数据
    if (g_网页雷达.是否运行中()) {
        g_网页雷达.更新玩家数据(g_网页雷达数据);
        g_网页雷达.更新物资数据(g_网页物资数据);
    }
};
