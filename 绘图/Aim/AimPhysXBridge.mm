#import "AimPhysXBridge.h"

#include <atomic>
#include <cstdio>
#include <mutex>
#include <thread>

#include "AanhKFD.hpp"
#include "PhysXRemote.h"
#include "PhysX.h"

#ifdef __cplusplus
extern "C" {
#endif
void KernelLogLine(const char *line);
#ifdef __cplusplus
}
#endif

uint64_t gAimModuleBase = 0;

static std::atomic<bool> gPhysXReady{false};
static std::atomic<bool> gPhysXThreadsStarted{false};
static std::once_flag gPhysXFetchOnce;
void AimPhysX_SetModuleBase(uint64_t base) {
    gAimModuleBase = base;
    KFD::SetBase(base);
}

void AimPhysX_TickCamera(const Vector3 &camLoc) {
    PhysXLoadFilter::SetCamera(camLoc.X, camLoc.Y, camLoc.Z);
}

void AimPhysX_SetLoadRadiusMeters(float meters) {
    PhysXLoadFilter::SetRadiusMeters(meters);
}

void AimPhysX_SetSceneActive(bool active) {
    VisibleCheck::gPhysXSceneActive.store(active, std::memory_order_release);
}

bool AimPhysX_IsReady() {
    return gPhysXReady.load(std::memory_order_acquire);
}

bool AimPhysX_IsOccluded(const Vector3 &cam, const Vector3 &bone) {
    if (!gPhysXReady.load(std::memory_order_acquire)) {
        return false;
    }
    // 对标 qwer：LineTrace 命中 = 被掩体遮挡
    return LineTrace::LineTraceSingle(cam, bone);
}

static bool AimPhysX_ValidateInstance() {
    if (gAimModuleBase == 0 || kPhysXPtr == 0) return false;
    uint64_t physInst = KFD::Read<uint64_t>(gAimModuleBase + kPhysXPtr);
    // 游戏内堆指针，过小视为错偏移/未进对局
    if (physInst < 0x100000000ULL) return false;
    uint64_t sceneArr = KFD::Read<uint64_t>(physInst + 0x8);
    return sceneArr > 0x100000000ULL;
}

static void AimPhysX_StartThreadsOnce() {
    bool expected = false;
    if (!gPhysXThreadsStarted.compare_exchange_strong(expected, true)) return;
    std::thread([]() { VisibleCheck::UpdateSceneByRange(); }).detach();
    std::thread([]() { VisibleCheck::UpdateDynamicHeightField(); }).detach();
    std::thread([]() { VisibleCheck::UpdateDynamicRigid(); }).detach();
}

static void AimPhysX_InitUnlocked() {
    if (gPhysXReady.load(std::memory_order_relaxed)) {
        return;
    }
    if (gAimModuleBase == 0) {
        return;
    }

    // 对标 qwer：先尝试远程刷新偏移；失败保留本地默认 0x110ADBA0
    std::call_once(gPhysXFetchOnce, []() {
        if (!PhysXRemote::fetch()) {
            // 保持 PhysXRemote.mm 默认值
        }
        if (kPhysXPtr == 0) {
            kPhysXPtr = 0x110ADBA0;
        }
        char buf[96];
        snprintf(buf, sizeof(buf), "[PhysX] kPhysXPtr=0x%llx", (unsigned long long)kPhysXPtr);
        KernelLogLine(buf);
    });

    if (!AimPhysX_ValidateInstance()) {
        // 对局未就绪或偏移仍不对：不置 ready，下帧重试
        return;
    }

    if (!LineTrace::initPhysX()) {
        KernelLogLine("[PhysX] LineTrace::initPhysX 失败");
        return;
    }

    gPhysXReady.store(true, std::memory_order_release);
    VisibleCheck::gPhysXSceneActive.store(true, std::memory_order_release);
    AimPhysX_StartThreadsOnce();
    KernelLogLine("[PhysX] 漏打场景已初始化（掩体遮挡生效）");
}

void AimPhysX_InitIfNeeded() {
    if (gPhysXReady.load(std::memory_order_acquire)) {
        return;
    }
    static std::mutex retryMu;
    std::lock_guard<std::mutex> lock(retryMu);
    if (!gPhysXReady.load(std::memory_order_relaxed)) {
        AimPhysX_InitUnlocked();
    }
}
