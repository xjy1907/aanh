//
//  SDK.h - 无畏契约 SDK 偏移
//

#ifndef SDK_h
#define SDK_h

namespace SDK {
    // 和平精英偏移 (1.38.12) —— 对标 wasd OffsetsTool.hpp
    uint64_t GNames = 0x11FBA198;
    uint64_t NameEntry = 0xE;
    uint64_t GWorld = 0x1148B608;
    uint64_t PersistentLevel = 0xB8;
    uint64_t ActorArray = 0xA0;
    uint64_t ActorCount = 0xA8;
    uint64_t NetDriver = 0xC0;
    uint64_t ServerConnection = 0x88;
    uint64_t PlayerController = 0x30;
    uint64_t PlayerCameraManager = 0x680;
    uint64_t Character = 0x3540; // STExtraBaseCharacter
    uint64_t TeamID = 0xB78;
    uint64_t MyTeamID = 0xBA8;
    uint64_t DefaultSpeedValue = 0x10BC; // 用于玩家过滤
    uint64_t ViewTarget = 0x14B0; // TViewTarget
    uint64_t POV = 0x10; // POV within TViewTarget (Offset 0x14B0 + 0x10)
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
    uint64_t RepWeaponID = 0xDD0;
    uint64_t bIsAI = 0xB94;
    uint64_t BoxState = 0x260; // 物资箱开箱状态
    uint64_t ExplosionTime = 0x88C; // EliteProjectile.ExplosionTime
    // GameState（对标 wasd OffsetsTool）
    uint64_t GameState = 0xAD8;
    uint64_t ReplicatedWorldTimeSeconds = 0x5FC;
    uint64_t TotalPlayerNum = 0xD98;
    uint64_t PlayerNum = 0xD9C;
    uint64_t AliveTeamNum = 0x148C;

    // —— 自瞄 / 压枪（对标 wasd OffsetsTool.hpp）——
    uint64_t bIsWeaponFiring = 0x2750;
    uint64_t bIsGunADS = 0x1848;
    uint64_t VelocitySafety = 0x1164;
    uint64_t WeaponOwnerProxy = 0x1350;
    uint64_t BindedWeapon = 0x50;
    uint64_t CachedBulletTrackComponent = 0x2038;
    uint64_t ShootWeaponEntityComp = 0x2048;
    uint64_t BulletFireSpeed = 0x15D4;
    uint64_t VerticalRecoilTarget = 0x20C;
    uint64_t WeaponEntity = 0x3A30;
    uint64_t WeaponComponent = 0x20;
};

#endif
