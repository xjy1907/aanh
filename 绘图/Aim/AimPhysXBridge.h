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

/// 写入相机世界坐标，供 PhysX 按半径过滤加载网格。
void AimPhysX_TickCamera(const Vector3 &camLoc);

/// 加载半径（米）；内部转 UE cm 并加余量。建议传漏打距离。
void AimPhysX_SetLoadRadiusMeters(float meters);

/// 模型渲染开关：false 时 VisibleCheck 三线程只 sleep 不扫网格（降 CPU）。
void AimPhysX_SetSceneActive(bool active);

/// 本帧是否有遮挡查询需求（半径内需漏打/头骨遮挡）。
/// false 时三线程与关模型渲染类似只 sleep，避免闲时空扫网格。
void AimPhysX_SetOcclusionDemand(bool demand);

#ifdef __cplusplus
}
#endif
