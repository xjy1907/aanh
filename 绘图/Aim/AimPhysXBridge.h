#pragma once

#include <cstdint>
#include "../游戏/绘制类型.h"

#ifdef __cplusplus
extern "C" {
#endif

/// Set game module base (same value DrawView keeps as 模块地址).
void AimPhysX_SetModuleBase(uint64_t base);

/// Lazy-init Embree scenes + detach VisibleCheck update threads (qwer/wasd pattern).
void AimPhysX_InitIfNeeded();

/// True after LineTrace::initPhysX() succeeded.
bool AimPhysX_IsReady();

/// True if a wall/mesh is between cam and bone (LineTrace hit).
bool AimPhysX_IsOccluded(const Vector3 &cam, const Vector3 &bone);

/// Store camera location for future range-filtered scene loaders.
void AimPhysX_TickCamera(const Vector3 &camLoc);

#ifdef __cplusplus
}
#endif
