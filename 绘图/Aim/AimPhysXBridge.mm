#import "AimPhysXBridge.h"

// iPadOS15.3 冷启动：不链 Embree/PhysX（静态构造会在 UIApplicationMain 前秒退）。
// 完整实现见 AimPhysXBridge.embree.mm，待首屏稳定后再以 dlopen/条件编译恢复。

uint64_t gAimModuleBase = 0;

void AimPhysX_SetModuleBase(uint64_t base) {
    gAimModuleBase = base;
}

void AimPhysX_TickCamera(const Vector3 &camLoc) {
    (void)camLoc;
}

void AimPhysX_SetLoadRadiusMeters(float meters) {
    (void)meters;
}

void AimPhysX_SetSceneActive(bool active) {
    (void)active;
}

void AimPhysX_SetOcclusionDemand(bool demand) {
    (void)demand;
}

bool AimPhysX_IsReady() {
    return false;
}

bool AimPhysX_IsOccluded(const Vector3 &cam, const Vector3 &bone) {
    (void)cam;
    (void)bone;
    return false;
}

void AimPhysX_InitIfNeeded() {
}
