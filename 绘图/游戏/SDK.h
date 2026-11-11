//
//  SDK.h - 无畏契约 SDK 偏移
//  对标 1.39-冰雪阿勒泰-2026-11-11.hpp
//

#ifndef SDK_h
#define SDK_h

namespace SDK {
    // 和平精英偏移 (1.39 冰雪阿勒泰)
    uint64_t GNames = 0x12886D28;
    uint64_t NameEntry = 0xE;
    uint64_t GWorld = 0x11CEA348;
    uint64_t PersistentLevel = 0xB8;
    uint64_t ActorArray = 0xA0;
    uint64_t ActorCount = 0xA8;
    uint64_t NetDriver = 0xC0;
    uint64_t ServerConnection = 0x88;
    uint64_t PlayerController = 0x30; // kbIsLocalPlayerController / Player*
    uint64_t PlayerCameraManager = 0x680;
    uint64_t Character = 0x36d0; // STExtraBaseCharacter
    uint64_t TeamID = 0xB78;
    uint64_t MyTeamID = 0xBA8;
    uint64_t DefaultSpeedValue = 0x10BC;
    uint64_t ViewTarget = 0x14B0; // TViewTarget
    uint64_t POV = 0x10;         // POV within TViewTarget
    uint64_t Mesh = 0x658;
    uint64_t StaticMesh = 0x848;
    uint64_t BoneTransformSize = 0x30;
    uint64_t Health = 0x1060;
    uint64_t HealthMax = 0x1068;
    uint64_t RootComponent = 0x260;
    uint64_t RelativeLocation = 0x200; // ComponentToWorld.Translation = 0x1F0+0x10
    uint64_t ComponentToWorld = 0x1F0;
    uint64_t PlayerName = 0xAF8;
    uint64_t PawnStateRepSyncData = 0x1700;
    uint64_t CurrentUsingWeaponSafety = 0x1170;
    uint64_t RepWeaponID = 0xde8;
    uint64_t bIsAI = 0xB94;
    uint64_t BoxState = 0x260;
    uint64_t ExplosionTime = 0x88C;
    uint64_t GameState = 0xAD8;
    uint64_t PlayerArray = 0x5E8;
    uint64_t ReplicatedWorldTimeSeconds = 0x5FC;
    uint64_t TotalPlayerNum = 0xD98;
    uint64_t PlayerNum = 0xD9C;
    uint64_t AliveTeamNum = 0x148C;

    uint64_t bIsWeaponFiring = 0x27a8;
    uint64_t bIsGunADS = 0x1848;
    uint64_t VelocitySafety = 0x1164;
    uint64_t WeaponOwnerProxy = 0x1350;
    uint64_t BindedWeapon = 0x50;
    uint64_t CachedBulletTrackComponent = 0x20d8;
    uint64_t ShootWeaponEntityComp = 0x20e8;
    uint64_t BulletFireSpeed = 0x15D4;
    uint64_t VerticalRecoilTarget = 0x20C;
    uint64_t WeaponEntity = 0x3ac0;
    uint64_t WeaponComponent = 0x20;
    uint64_t WeaponManagerComponent = 0x3830;
    uint64_t AvatarComponent = 0x4070;
    uint64_t Redundant_AvatarSyncData = 0x5308;
    uint64_t HelmetID = 0x1FC;
    uint64_t ArmorID = 0x234;

    // PhysX 全局实例（模块基址相对）
    uint64_t PhysXPtr = 0x1190A3A0;
};

#endif
