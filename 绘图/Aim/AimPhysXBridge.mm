#import "AimPhysXBridge.h"

#include <atomic>
#include <mutex>
#include <thread>

#include "AanhKFD.hpp"
#include "PhysXRemote.h"
#include "PhysX.h"

uint64_t gAimModuleBase = 0;

static std::atomic<bool> gPhysXReady{false};
static std::once_flag gPhysXInitOnce;
static Vector3 gAimCameraLoc{};

void AimPhysX_SetModuleBase(uint64_t base) {
    gAimModuleBase = base;
    KFD::SetBase(base);
}

void AimPhysX_TickCamera(const Vector3 &camLoc) {
    gAimCameraLoc = camLoc;
    (void)gAimCameraLoc; // range filter currently commented out in PhysX.h LoadShapeByRange
}

bool AimPhysX_IsReady() {
    return gPhysXReady.load(std::memory_order_acquire);
}

bool AimPhysX_IsOccluded(const Vector3 &cam, const Vector3 &bone) {
    if (!gPhysXReady.load(std::memory_order_acquire)) {
        return false;
    }
    // Real LineTrace via Embree VisibleScene (wasd/qwer 漏打 path).
    return LineTrace::LineTraceSingle(cam, bone);
}

static void AimPhysX_InitUnlocked() {
    if (gPhysXReady.load(std::memory_order_relaxed)) {
        return;
    }
    if (gAimModuleBase == 0) {
        return;
    }
    if (kPhysXPtr == 0) {
        PhysXRemote::fetch();
    }
    if (kPhysXPtr == 0) {
        return;
    }
    if (!LineTrace::initPhysX()) {
        return;
    }
    gPhysXReady.store(true, std::memory_order_release);

    // Mirror qwer ImGuiDraw::InitPhysXSystem — three detached scene updaters.
    std::thread([]() { VisibleCheck::UpdateSceneByRange(); }).detach();
    std::thread([]() { VisibleCheck::UpdateDynamicHeightField(); }).detach();
    std::thread([]() { VisibleCheck::UpdateDynamicRigid(); }).detach();
}

void AimPhysX_InitIfNeeded() {
    std::call_once(gPhysXInitOnce, []() { AimPhysX_InitUnlocked(); });
    // Allow retry if first call happened before module base / kPhysXPtr was ready.
    if (!gPhysXReady.load(std::memory_order_acquire)) {
        static std::mutex retryMu;
        std::lock_guard<std::mutex> lock(retryMu);
        if (!gPhysXReady.load(std::memory_order_relaxed)) {
            // Reset once_flag is not possible; call unlocked path directly for retries.
            AimPhysX_InitUnlocked();
        }
    }
}
