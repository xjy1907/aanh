
#import "SDK.h"

string 异或字符串(uint64_t StrPtr, auto StrLength) {
    string FName(StrLength, '\0');
    kfd.取vreadbuf列表(StrPtr, FName.data(), StrLength);
    uint16_t Key = 0;
    switch (StrLength % 9) {
        case 0:
            Key = ((((StrLength >> 6) && 0x1F) + StrLength) | 0x7F) + 0x80;
            break;
        case 1:
            Key = (((StrLength ^ 0xDF) + StrLength) | 0x7F) + 0x80;
            break;
        case 2:
            Key = (((StrLength | 0xCF) + StrLength) | 0x7F) + 0x80;
            break;
        case 3:
            Key = ((0x21 * StrLength) | 0x7F) + 0x80;
            break;
        case 4:
            Key = ((StrLength + (StrLength >> 8)) | 0x7F) + 0x80;
            break;
        case 5:
            Key = ((3 * StrLength + 5) | 0x7F) + 0x80;
            break;
        case 6:
            Key = ((((4 * StrLength) | 5) + StrLength) | 0x7F) + 0x80;
            break;
        case 7:
            Key = ((((StrLength >> 10) | 7) + StrLength) | 0x7F) + 0x80;
            break;
        case 8:
            Key = (((StrLength ^ 0xC) + StrLength) | 0x7F) + 0x80;
            break;
    };
    
    for (int i = 0; i < StrLength; i++) {
        FName[i] ^= Key;
    };

    return FName;
};

string 解密FName(int ID) {
    auto NameStride = 0x2;
    auto NameEntryToLenBit = 6;
    auto NameEntryToString = 0x2;
    auto NamesToFNamePool = 0xC8;
    auto Block = (ID >> 15) & 0x1FFF8;
    auto Offset = (NameStride * ID) & 0x7FFFE;
    
    auto NamePoolChunk = kfd.取vreadbuf<uint64_t>(绘制类型.模块地址 + SDK::FName + (Block + NamesToFNamePool));
    auto NameEntry = NamePoolChunk + Offset;
    auto NameEntryHeader = kfd.取vreadbuf<uint16_t>(NameEntry);
    auto StrPtr = NameEntry + NameEntryToString;
    auto StrLength = NameEntryHeader >> NameEntryToLenBit;
    return 异或字符串(StrPtr, StrLength);
};

int 取对象类型(string FName) {
    if (FName == "NC_BP_InventoryPickup_C" || FName == "NC_BP_InventoryPickup_Container_C") {
        return 0;
    } else if (FName == "NC_BP_Inventory_DeadBody_C") {
        return 1;
    } else if (FName == "NC_BP_DFMCharacter_AI_DT_C" ||
        FName == "NC_BP_DFMCharacter_C" ||
        FName == "NC_BP_DFMCharacter_AI_DT_RPG_C" ||
        FName == "NC_BP_DFMCharacter_AI_DT_C" ||
        FName == "NC_BP_DFMAICharacter_ShielderLight_C" ||
        FName == "NC_BP_DFMCharacter_AI_AlwaysFall_DTSniper_C" ||
        FName == "NC_BP_DFMAICharacter_HeavyMachineGun_C" ||
        FName == "NC_BP_DFMCharacter_AI_Maurice_C" ||
        FName == "NC_BP_DFMCharacter_AI_HS_C" ||
        FName == "NC_BP_DFMAICharacter_HeavyMachineGun_HS_C" ||
        FName == "NC_BP_DFMAICharacter_HeavyMachineGun_C" ||
        FName == "NC_BP_DFMAICharacter_ShielderLight_HS_C" ||
        FName == "NC_BP_DFMCharacter_AI_AlwaysFall_HSSniper_C" ||
        FName == "NC_BP_DFMAICharacter_Firebat_HS_C" ||
        FName == "BP_RangeTargetCharacter_C" ||
        FName == "NC_BP_DFMAICharacter_Firebat_C" ||
        FName == "NC_BP_DFMAICharacter_Boss03_C" ||
        FName == "NC_BP_DFMCharacter_Boss07_NewGuard_C" ||
        FName == "NC_BP_DFMCharacter_AI_Boss07_C" ||
               
        FName == "NC_BP_DFMCharacter_AI_Boss06_Waden_C" ||
        FName == "NC_BP_DFMCharacter_AI_Shark_C" ||
               
        
        FName == "NC_BP_DFMAICharacter_AI_BossRCV_C") {
        return 2;
    };
    return 3;
};

void* 子线程(void*) {
    while (true) {
        sleep(5);
        
        // 检查内核状态
        if (!绘制类型.内核) {
            自身数据.清空();
            continue;
        }
        
        // Engine -> GameViewport -> World -> LevelCollections
        uint64_t Engine = kfd.取vreadbuf<uint64_t>(绘制类型.模块地址 + SDK::Engine);
        if (!kfd.地址判断(Engine)) {
            自身数据.清空();
            continue;
        }
        uint64_t GameViewport = kfd.取vreadbuf<uint64_t>(Engine + SDK::GameViewport);
        if (!kfd.地址判断(GameViewport)) {
            自身数据.清空();
            continue;
        }
        uint64_t World = kfd.取vreadbuf<uint64_t>(GameViewport + SDK::World);
        if (!kfd.地址判断(World)) {
            自身数据.清空();
            continue;
        }
        uint64_t LevelCollections = kfd.取vreadbuf<uint64_t>(World + SDK::LevelCollections);
        if (!kfd.地址判断(LevelCollections)) {
            自身数据.清空();
            continue;
        }
        
        // NetDriver -> ServerConnection -> PlayerController
        uint64_t NetDriver = kfd.取vreadbuf<uint64_t>(LevelCollections + SDK::NetDriver);
        if (!kfd.地址判断(NetDriver)) {
            自身数据.清空();
            continue;
        }
        uint64_t ServerConnection = kfd.取vreadbuf<uint64_t>(NetDriver + SDK::ServerConnection);
        if (!kfd.地址判断(ServerConnection)) {
            自身数据.清空();
            continue;
        }
        uint64_t PlayerController = kfd.取vreadbuf<uint64_t>(ServerConnection + SDK::PlayerController);
        if (!kfd.地址判断(PlayerController)) {
            自身数据.清空();
            continue;
        };
        
        uint64_t 新相机 = kfd.取vreadbuf<uint64_t>(PlayerController + SDK::PlayerCameraManager);
        if (kfd.地址判断(新相机)) {
            自身数据.设置相机(新相机);
        }
        
        // PlayerController -> Pawn
        uint64_t Pawn = kfd.取vreadbuf<uint64_t>(PlayerController + SDK::Pawn);
        
        // PlayerController -> CHARACTER -> TeamComp
        uint64_t CHARACTER = kfd.取vreadbuf<uint64_t>(PlayerController + SDK::CHARACTER);
        if (!kfd.地址判断(CHARACTER)) continue;
        uint64_t TeamComp = kfd.取vreadbuf<uint64_t>(CHARACTER + SDK::TeamComp);
        if (!kfd.地址判断(TeamComp)) continue;
        三角洲行动::UGPTeamComponent P_UGPTeamComponent = kfd.取vreadbuf<三角洲行动::UGPTeamComponent>(TeamComp + SDK::TeamID);
        
        // LevelCollections -> PersistentLevel -> Actors
        uint64_t PersistentLevel = kfd.取vreadbuf<uint64_t>(LevelCollections + SDK::PersistentLevel);
        
        if (!kfd.地址判断(PersistentLevel)) continue;
        UE4类型::TArray Actors = kfd.取vreadbuf<UE4类型::TArray>(PersistentLevel + SDK::Actors);
        // 添加数组上限检查，防止异常值导致循环过多
        if (!kfd.地址判断(Actors.AllocatorInstance) || Actors.ArrayNum > Actors.ArrayMax || Actors.ArrayNum > 10000 || Actors.ArrayNum <= 0) continue;
        
//        vector<类名数据> 类名数据数组;
        vector<物品数据> 物品数据数组;
        vector<盒子数据> 盒子数据数组;
        vector<玩家数据> 玩家数据数组;
        vector<类名数据> 类名数据数组;
        
        for (int i = 0; i < Actors.ArrayNum; i++) {
            uint64_t Actor = kfd.取vreadbuf<uint64_t>(Actors.AllocatorInstance + i * 8);
            if (!kfd.地址判断(Actor)) continue;
            
            uint64_t RootComponent = kfd.取vreadbuf<uint64_t>(Actor + SDK::RootComponent);
            if (!kfd.地址判断(RootComponent)) continue;
            string FName = 解密FName(kfd.取vreadbuf<int>(Actor + 0x1C));
            
            // "NC_BP_Inventory_CarryBody_C" 死亡盒子的内存陷阱
            if (FName == "WeaponPhysicsBulletReal_BP_C") continue;
            
            switch (取对象类型(FName)) {
                case 0: {
                    uint64_t FDFMCommonItemRow = kfd.取vreadbuf<uint64_t>(Actor + SDK::CurRow);
                    if (!kfd.地址判断(FDFMCommonItemRow)) continue;
                    物品数据 物品数据;
                    物品数据.RootComponent = RootComponent;
                    物品数据.ItemID = kfd.取vreadbuf<int>(FDFMCommonItemRow + SDK::FDFMCommonItemRow::ItemID);
                    物品数据.Quality = kfd.取vreadbuf<int>(FDFMCommonItemRow + SDK::FDFMCommonItemRow::Quality);
                    物品数据.MallRecyclePrice = kfd.取vreadbuf<int>(FDFMCommonItemRow + SDK::FDFMCommonItemRow::MallRecyclePrice);
                    物品数据数组.push_back(物品数据);
                    break;
                };
                case 1: {
                    盒子数据 盒子数据;
                    盒子数据.RootComponent = RootComponent;
                    盒子数据.PlayerName_Buffer = kfd.取vreadbuf<uint64_t>(Actor + SDK::PlayerName_Buffer);
                    盒子数据.bLooted = kfd.取vreadbuf<bool>(Actor + SDK::bLooted);
//                    盒子数据.KillerName = 取FText(kfd.取vreadbuf<uint64_t>(Actor + SDK::KillInfo + SDK::FKillInfo::KillerName));
//                    盒子数据.IsHitHead = kfd.取vreadbuf<bool>(Actor + SDK::KillInfo + SDK::FKillInfo::IsHitHead);
                    盒子数据数组.push_back(盒子数据);
                    break;
                };
                case 2: {
                    if (Actor == Pawn) continue;
                    uint64_t TeamComp = kfd.取vreadbuf<uint64_t>(Actor + SDK::TeamComp);
                    if (!kfd.地址判断(TeamComp)) continue;
                    三角洲行动::UGPTeamComponent UGPTeamComponent = kfd.取vreadbuf<三角洲行动::UGPTeamComponent>(TeamComp + SDK::TeamID);
                    if (UGPTeamComponent.TeamID == P_UGPTeamComponent.TeamID) continue;
                    uint64_t HealthComp = kfd.取vreadbuf<uint64_t>(Actor + SDK::HealthComp);
                    if (!kfd.地址判断(HealthComp)) continue;
                    uint64_t PlayerState = kfd.取vreadbuf<uint64_t>(Actor + SDK::PlayerState);
                    if (kfd.地址判断(PlayerState)) {
                        if (kfd.取vreadbuf<uint8_t>(PlayerState + SDK::ExitState) == 3) continue;
                    };
                    uint64_t Mesh = kfd.取vreadbuf<uint64_t>(Actor + SDK::Mesh);
                    if (!kfd.地址判断(Mesh)) continue;
                    玩家数据 玩家数据;
                    玩家数据.Actor = Actor;
                    玩家数据.FName = FName;
                    玩家数据.RootComponent = RootComponent;
                    玩家数据.Mesh = Mesh;
                    玩家数据.HealthSet = kfd.取vreadbuf<uint64_t>(HealthComp + SDK::HealthSet);
                    玩家数据.bIsAI = !kfd.地址判断(PlayerState);
                    玩家数据.CacheCurWeapon = kfd.取vreadbuf<uint64_t>(Actor + SDK::CacheCurWeapon);
                    if (kfd.地址判断(PlayerState)) {
                        玩家数据.TeamID = UGPTeamComponent.TeamID;
                        玩家数据.PlayerNamePrivate = kfd.取vreadbuf<uint64_t>(PlayerState + SDK::PlayerNamePrivate);
                        玩家数据.HeroId = kfd.取vreadbuf<uint64_t>(PlayerState + SDK::HeroId);
                        
                        uint64_t CharacterEquipComponent = kfd.取vreadbuf<uint64_t>(Actor + SDK::CharacterEquipComponent);
                        if (kfd.地址判断(CharacterEquipComponent)) {
                            玩家数据.EquipmentInfoArray = kfd.取vreadbuf<UE4类型::TArray>(CharacterEquipComponent + SDK::EquipmentInfoArray);
                        };
                    };
                    玩家数据数组.push_back(玩家数据);
                    break;
                };
                case 3: {
                    类名数据 类名数据;
                    类名数据.RootComponent = kfd.取vreadbuf<uint64_t>(Actor + SDK::RootComponent);
                    类名数据.FName = FName;
                    类名数据数组.push_back(类名数据);
                    break;
                };
            };
        };
        
        绘制类型.更新数据(物品数据数组, 盒子数据数组, 玩家数据数组, 类名数据数组);
        
        // PlayerController -> MyHUD
        uint64_t MyHUD = kfd.取vreadbuf<uint64_t>(PlayerController + SDK::MyHUD);
        if (kfd.地址判断(MyHUD)) {
            UE4类型::TArray Controllers = kfd.取vreadbuf<UE4类型::TArray>(MyHUD + SDK::Controllers);
            if (kfd.地址判断(Controllers.AllocatorInstance) && Controllers.ArrayNum > 0 && Controllers.ArrayNum < 100) {
                for (int a = 0; a < Controllers.ArrayNum; a++) {
                    uint64_t UBatchUIController = kfd.取vreadbuf<uint64_t>(Controllers.AllocatorInstance + a * 8);
                    if (!kfd.地址判断(UBatchUIController)) continue;
                    UE4类型::TArray ChildControllers = kfd.取vreadbuf<UE4类型::TArray>(UBatchUIController + SDK::ChildControllers);
                    if (kfd.地址判断(ChildControllers.AllocatorInstance) && ChildControllers.ArrayNum > 0 && ChildControllers.ArrayNum < 100) {
                        for (int b = 0; b < ChildControllers.ArrayNum; b++) {
                            uint64_t UBaseUIController = kfd.取vreadbuf<uint64_t>(ChildControllers.AllocatorInstance + b * 8);
                            if (!kfd.地址判断(UBaseUIController)) continue;
                            uint64_t View = kfd.取vreadbuf<uint64_t>(UBaseUIController + SDK::View);
                            if (!kfd.地址判断(View)) continue;
                            string ViewName = 解密FName(kfd.取vreadbuf<int>(View + SDK::ViewName));
                            if (ViewName == "MobileHUD_BigMap") {
                                自身数据.设置地图(View);
                                break;
                            };
                            continue;
                        };
                    };
                };
            };
        };
    };
};
