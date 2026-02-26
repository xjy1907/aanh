//
//  SDK.h - 三角洲 SDK 偏移
//

#ifndef SDK_h
#define SDK_h

namespace SDK {
    uint64_t Engine = 0x13A79478;
    uint64_t FName = 0x135A7e80;
    uint64_t GameViewport = 0x910;
    uint64_t World = 0x70;
    uint64_t LevelCollections = 0x168;
    uint64_t NetDriver = 0x10;
    uint64_t ServerConnection = 0x88;
    uint64_t PlayerController = 0x30;
    uint64_t PlayerCameraManager = 0x408;
    uint64_t ViewTarget = 0x1780;
    uint64_t POV = 0x10;
    namespace FMinimalViewInfo {
        uint64_t Location = 0x0;
        uint64_t Rotation = 0x10;
        uint64_t FOV = 0x1C;
    };
    uint64_t Pawn = 0x3A0;
    uint64_t CHARACTER = 0x3B0;
    uint64_t TeamComp = 0x1090;
    uint64_t TeamID = 0x108;
    uint64_t HealthComp = 0x1088;
    uint64_t HealthSet = 0x270;
    uint64_t Health = 0x30 + 0xC;
    uint64_t MaxHealth = 0x48 + 0xC;
    uint64_t ImpendingDeathHealth = 0x108 + 0xC;
    uint64_t MaxImpendingDeathHealth = 0x118 + 0xC;
    uint64_t PlayerState = 0x390;
    uint64_t Mesh = 0x3D0;
    uint64_t bIsDead = 0xD88 + 0x0;
    uint64_t StaticMesh = 0x718;
    uint64_t ComponentToWorld = 0x210;
    namespace FTransform {
        uint64_t Rotation = 0x0;
        uint64_t translation = 0x10;
        uint64_t Scale3D = 0x1C;
    };
    uint64_t CacheCurWeapon = 0x1718;
    uint64_t PlayerNamePrivate = 0x470;
    uint64_t HeroId = 0x9E8;
    uint64_t CharacterEquipComponent = 0x33E8;
    uint64_t EquipmentInfoArray = 0x1D8;
    namespace FEquipmentInfo {
        uint64_t ItemID = 0x0;
        uint64_t Durability = 0x18;
        uint64_t MaxDurability = 0x1C;
    };
    uint64_t ExitState = 0xE18;
    uint64_t WeaponID = 0x828;
    uint64_t RootComponent = 0x180;
    uint64_t CurRow = 0x1130;
    namespace FDFMCommonItemRow {
        uint64_t ItemID = 0x10;
        uint64_t Quality = 0x68;
        uint64_t MallRecyclePrice = 0xEC;
    };
    uint64_t PlayerName_Buffer = 0x2308;
    uint64_t bLooted = 0x23B0;
    uint64_t PersistentLevel = 0x20;
    uint64_t Actors = 0x98;
    uint64_t MyHUD = 0x400;
    uint64_t Controllers = 0x468;
    uint64_t ChildControllers = 0xA8;
    uint64_t View = 0x88;
    uint64_t ViewName = 0x328;
    uint64_t preShouldDraw = 0x944;
    uint64_t BigMapWorldRangeInfo = 0x828;
};

#endif
