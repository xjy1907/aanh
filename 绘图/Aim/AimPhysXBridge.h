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

/// 写入相机世界坐标，供 PhysX 按半径/射线走廊过滤加载网格。
void AimPhysX_TickCamera(const Vector3 &camLoc);

/// 加载半径（米）；内部转 UE cm 并加余量。建议传漏打距离。
void AimPhysX_SetLoadRadiusMeters(float meters);

/// 模型渲染开关：false 时 VisibleCheck 三线程只 sleep 不扫网格（降 CPU）。
void AimPhysX_SetSceneActive(bool active);

/// 本帧是否有遮挡查询需求（半径内需漏打/头骨遮挡）。
/// false 时三线程与关模型渲染类似只 sleep，避免闲时空扫网格。
void AimPhysX_SetOcclusionDemand(bool demand);

/// 清空本帧射线走廊焦点（无焦点时退回完整漏打球加载）。
void AimPhysX_ClearRayFoci();

/// 追加一条相机→骨骼走廊焦点，驱动局部网格加载。
void AimPhysX_AddRayFocus(const Vector3 &cam, const Vector3 &bone);

/// 走廊半宽（米）；原写死 12。
void AimPhysX_SetCorridorHalfMeters(float meters);

/// 近距泡上限（米）；原写死 40。
void AimPhysX_SetNearBubbleMeters(float meters);

/// 静态 Range 刷新基线（毫秒）；原写死 2000。
void AimPhysX_SetRangeBaseMs(int ms);

#ifdef __cplusplus
}
#endif
