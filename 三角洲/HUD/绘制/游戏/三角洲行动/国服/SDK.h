
#import "kfd.h"
#import "设备类型.h"
#import "绘制类型.h"
#import "游戏类型.h"

namespace SDK {
uint64_t Engine = 0x13A79478;
uint64_t FName = 0x135A7e80;
uint64_t GameViewport = 0x910; // UGameViewportClient* GameViewport
uint64_t World = 0x70; // UWorld* World
uint64_t LevelCollections = 0x168; // TArray<struct FLevelCollection> LevelCollections

uint64_t NetDriver = 0x10; // UNetDriver* NetDriver
uint64_t ServerConnection = 0x88; // UNetConnection* ServerConnection
uint64_t PlayerController = 0x30; // APlayerController* PlayerController
uint64_t PlayerCameraManager = 0x408; // PlayerCameraManager* PlayerCameraManager
uint64_t ViewTarget = 0x1780; // FTViewTarget ViewTarget
uint64_t POV = 0x10; // FMinimalViewInfo POV
namespace FMinimalViewInfo {
    uint64_t Location = 0x0; // FEncVector Location
    uint64_t Rotation = 0x10; // FRotator Rotation
    uint64_t FOV = 0x1C; // float FOV
};
uint64_t Pawn = 0x3A0; // APawn* Pawn
uint64_t CHARACTER = 0x3B0; // ACHARACTER* CHARACTER

uint64_t TeamComp = 0x1090; // UGPTeamComponent* TeamComp
uint64_t TeamID = 0x108; // int32_t TeamID
uint64_t HealthComp = 0x1088; // UGPHealthDataComponent* HealthComp
uint64_t HealthSet = 0x270; // UGPAttributeSetHealth* HealthSet
uint64_t Health = 0x30 + 0xC; // FGPGameplayAttributeData Health
uint64_t MaxHealth = 0x48 + 0xC; // FGPGameplayAttributeData MaxHealth
uint64_t ImpendingDeathHealth = 0x108 + 0xC; // FGPGameplayAttributeData ImpendingDeathHealth
uint64_t MaxImpendingDeathHealth = 0x118 + 0xC; // FGPGameplayAttributeData MaxImpendingDeathHealth
uint64_t PlayerState = 0x390; // APlayerState* PlayerState
uint64_t Mesh = 0x3D0; // USkeletalMeshComponent* Mesh
uint64_t bIsDead = 0xD88 + 0x0; // FDeadInfo DeadInfo + bIsDead
uint64_t StaticMesh = 0x718; // UStaticMesh* StaticMesh
uint64_t ComponentToWorld = 0x210; // Transform ComponentToWorld
namespace FTransform {
    uint64_t Rotation = 0x0; // FQuat Rotation
    uint64_t translation = 0x10; // FVector translation
    uint64_t Scale3D = 0x1C; // FVector Scale3D
};
uint64_t CacheCurWeapon = 0x1718; // AWeaponBase* CacheCurWeapon
uint64_t PlayerNamePrivate = 0x470; // FString PlayerNamePrivate
uint64_t HeroId = 0x9E8; // int64_t HeroId
uint64_t CharacterEquipComponent = 0x33E8; // UCharacterEquipComponent* CharacterEquipComponent
uint64_t EquipmentInfoArray = 0x1D8; // TArray<struct FEquipmentInfo> EquipmentInfoArray
namespace FEquipmentInfo {
    uint64_t ItemID = 0x0;
    uint64_t Durability = 0x18;
    uint64_t MaxDurability = 0x1C;
};
uint64_t ExitState = 0xE18; // EExitState ExitState
uint64_t WeaponID = 0x828; // uint64_t WeaponID
uint64_t MyHUD = 0x400; // uint64_t MyHUD
uint64_t Controllers = 0x468; // TArray<struct UBatchUIController*> Controllers
uint64_t ChildControllers = 0xA8;// TArray<struct UBaseUIController*> ChildControllers
uint64_t View = 0x88; // UBaseUIView* View
uint64_t ViewName = 0x328; // FName ViewName
uint64_t preShouldDraw = 0x944; // uint8_t preShouldDraw
uint64_t BigMapWorldRangeInfo = 0x828; // FBigMapWorldRangeInfo BigMapWorldRangeInfo

uint64_t PersistentLevel = 0x20; // ULevel* PersistentLevel
uint64_t Actors = 0x98;

uint64_t RootComponent = 0x180; // USceneComponent* RootComponent

uint64_t CurRow = 0x1130; // FDFMCommonItemRow* CurRow
namespace FDFMCommonItemRow {
    uint64_t ItemID = 0x10; // FText Name
    uint64_t Quality = 0x68; // int32_t Quality
    uint64_t MallRecyclePrice = 0xEC; // int32_t MallRecyclePrice
};

uint64_t PlayerName_Buffer = 0x2308; // FString PlayerName_Buffer
uint64_t KillInfo = 0x2170; // FKillInfo KillInfo
namespace FKillInfo {
uint64_t KillerName = 0xC0; // FText KillerName
uint64_t IsHitHead = 0xA0; // uint8_t IsHitHead
};
uint64_t bLooted = 0x23B0; // uint8_t bLooted
};
