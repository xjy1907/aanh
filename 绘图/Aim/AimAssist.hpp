//
//  AimAssist.hpp — 触摸自瞄核心（对标 qwer ImGuiDraw zimiao / 动态圈 / 烟雾）
//  由 DrawView.mm 包含；依赖同编译单元内的 vm_read / readMemory / SDK。
//

#pragma once

#import "touchaa.h"
#include "AimPhysXBridge.h"
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <vector>

namespace AimAssist {

// --- prefs / 运行态 ---
inline bool 开启自瞄 = false;
inline bool 自瞄连线 = false;
inline bool 显示范围 = false;
inline bool 模型渲染 = false;
inline bool 模型按需加载 = false; // 实验：开→射线走廊局部加载；关→完整漏打球
inline float 走廊半宽 = 12.f;     // 米；原写死 12
inline float 近距泡 = 40.f;       // 米；原写死 40
inline float 静态刷新间隔 = 2000.f; // ms；原写死 2000
inline bool 按需保守遮挡 = true;  // 未就绪时当遮挡，降低穿墙锁风险
inline float 漏打距离 = 90.f; // 默认 90（过大则 PhysX 射线/网格负载暴涨；硬上限 150）
inline float 自瞄速度 = 26.f;
inline float 自瞄大小 = 60.f;
inline float 开镜自瞄大小 = 40.f;
inline bool 显示开镜自瞄范围 = false;
inline float 自瞄距离 = 100.f;
inline float 腰射距离 = 30.f;
inline float 压枪力度 = 0.5f;   // 存储 UI/10
inline float 自瞄血量 = 100.f;
inline float 满血距离 = 50.f;
inline bool 烟雾不瞄 = false;
inline float 烟雾范围 = 15.f;
inline bool 开启动态圈 = false;
inline bool 开启开镜动态圈 = false;
inline float 动态圈最小 = 20.f;
inline float 动态圈速度 = 12.f;
// 0=固定步长（对标 qwer acf6bef），1=指数平滑（当前默认）
inline int 动态圈插值方式 = 1;
inline float 内圈大小 = 0.f;
inline bool 显示内圈 = false;
inline bool 显示触摸区域 = false;
inline int 触摸区域宽度 = 120;
inline int 触摸区域高度 = 60;
inline int 触摸区域X = 0;
inline int 触摸区域Y = 0;
inline float 抖动幅度 = 0.5f;  // UI/10
inline float 抖动频率 = 0.1f;  // UI/100（保留字段）
inline float 抖动波动 = 0.01f; // UI/100（保留字段）

// --- 实验：拟人自瞄（外强内柔 + 距离衰减；默认关=旧线性）---
inline bool 吸附曲线 = false;
inline float 外圈速度 = 26.f;   // 偏心大时除数，越小越快
inline float 内圈速度 = 40.f;   // 靠近内圈时除数，越大越柔
inline float 变速过渡宽 = 15.f; // 外→内平滑过渡像素宽
inline bool 距离衰减 = false;
inline float 衰减起点 = 30.f;   // 米；<此距离拉力≈1
inline float 衰减终点 = 100.f;  // 米；≥此距离拉力降到远端拉力
inline float 远端拉力 = 0.35f;  // 存储 UI/100

// --- 实验：贝塞尔曲线（叠在初始线性上；全关=纯线性）---
inline bool 曲线目标冻结 = false;
inline float 冻结段长 = 12.f;       // 帧；实际 duration = 段长 + rand%5
inline bool 曲线缓动 = false;
inline float 前冲强度 = 0.55f;      // UI/100；越大前半越猛
inline bool 曲线惯性 = false;
inline float 惯性强度 = 0.55f;      // UI/100；越大越拖尾
inline bool 曲线弧线 = false;
inline float 弧线幅度 = 0.50f;      // UI/100；缩放法向弧
inline bool 切目标粘滞 = false;
inline float 粘滞时间 = 250.f;      // ms
inline float 粘滞近距阈值 = 20.f;   // px；挑战者须更近出该值
inline float 粘滞确认帧 = 5.f;      // 连续胜出帧数才换人

inline float 当前自瞄大小 = 60.f;
inline float 当前自瞄距离 = 100.f;
inline bool 当前开镜中 = false;
inline bool 当前开火中 = false;
inline float 动态圈当前半径 = 60.f;
inline bool 动态圈上一帧有锁 = false;
inline float 动态圈上一帧偏移 = 0.f;

inline bool kaishchumo = false;
inline Vector2 nextPoint;
inline bool 触摸系统已初始化 = false;

// 贝塞尔主拉枪运行态（与微抖贝塞尔独立）
struct PullCurveState {
    float t;
    float step;
    int duration;
    Vector2 frozenRel;   // 冻结的屏幕误差（目标相对准心）
    Vector2 vel;         // 惯性速度（像素/帧）
    uint64_t frozenActor;
    bool active;
};
inline PullCurveState _pullCurve = {};

inline void ResetPullCurveState() {
    memset(&_pullCurve, 0, sizeof(_pullCurve));
}

inline uint64_t 选中敌人Actor = 0;
inline Vector3 选中敌人瞄准点;
inline Vector2 选中敌人屏幕位置;
inline float 选中敌人血量 = 0;
inline float 选中敌人距离 = 0;
inline float 最小距离 = 0;

// 本帧选人候选（粘滞在 FinalizeTargetSelect 里落到 选中敌人*）
inline uint64_t 本帧最佳Actor = 0;
inline Vector3 本帧最佳瞄准点;
inline Vector2 本帧最佳屏幕位置;
inline float 本帧最佳血量 = 0;
inline float 本帧最佳距离 = 0;
inline float 本帧最佳偏移 = 0;
inline bool 粘滞本帧仍有效 = false;
inline Vector3 粘滞瞄准点;
inline Vector2 粘滞屏幕位置;
inline float 粘滞血量 = 0;
inline float 粘滞距离 = 0;
inline float 粘滞偏移 = 0;
inline uint64_t 粘滞Actor = 0;
inline CFAbsoluteTime 粘滞开始时间 = 0;
inline uint64_t 挑战者Actor = 0;
inline int 挑战者计数 = 0;

inline bool AnyBezierPullFeatureOn() {
    return 曲线目标冻结 || 曲线缓动 || 曲线惯性 || 曲线弧线;
}

struct SmokeInfo { Vector3 smokePos; };
inline std::vector<SmokeInfo> 烟雾数组;

// --- 贝塞尔微动（对标 qwer）---
struct BezierMicroJitter {
    float bx_t, bx_P1, bx_P2, bx_P3, bx_step;
    int bx_duration;
    float by_t, by_P1, by_P2, by_P3, by_step;
    int by_duration;
    int framesUntilReset;
};
inline BezierMicroJitter _jitterState = {};
inline bool _jitterInited = false;

inline void _initJitterState() {
    if (_jitterInited) return;
    memset(&_jitterState, 0, sizeof(_jitterState));
    _jitterState.bx_t = 1.f;
    _jitterState.by_t = 1.f;
    _jitterInited = true;
}

inline float _evalBezier(float t, float P1, float P2, float P3) {
    float u = 1.f - t;
    return 3.f * u * u * t * P1 + 3.f * u * t * t * P2 + t * t * t * P3;
}

inline void _generateNewJitterX(float amp) {
    _jitterState.bx_duration = 8 + (int)(arc4random() % 13);
    _jitterState.bx_t = 0.f;
    _jitterState.bx_step = 1.f / (float)_jitterState.bx_duration;
    float r = (float)arc4random() / UINT32_MAX;
    _jitterState.bx_P1 = (r < 0.5f ? -1.f : 1.f) * amp * (0.3f + ((float)arc4random() / UINT32_MAX) * 0.7f);
    _jitterState.bx_P2 = -_jitterState.bx_P1 * (0.5f + ((float)arc4random() / UINT32_MAX) * 0.5f);
    _jitterState.bx_P3 = amp * (0.05f + ((float)arc4random() / UINT32_MAX) * 0.15f) * ((arc4random() % 2 == 0) ? 1.f : -1.f);
}

inline void _generateNewJitterY(float amp) {
    _jitterState.by_duration = 5 + (int)(arc4random() % 11);
    _jitterState.by_t = 0.f;
    _jitterState.by_step = 1.f / (float)_jitterState.by_duration;
    float r = (float)arc4random() / UINT32_MAX;
    _jitterState.by_P1 = (r < 0.5f ? -1.f : 1.f) * amp * (0.3f + ((float)arc4random() / UINT32_MAX) * 0.7f);
    _jitterState.by_P2 = -_jitterState.by_P1 * (0.5f + ((float)arc4random() / UINT32_MAX) * 0.5f);
    _jitterState.by_P3 = amp * (0.05f + ((float)arc4random() / UINT32_MAX) * 0.15f) * ((arc4random() % 2 == 0) ? 1.f : -1.f);
}

inline Vector2 _updateBezierJitter(float pullSpeed, float baseAmplitude) {
    _initJitterState();
    float speedFactor = 1.f / (1.f + pullSpeed * 0.15f);
    float effectiveAmp = baseAmplitude * speedFactor;
    float minAmp = baseAmplitude * 0.2f;
    if (effectiveAmp < minAmp) effectiveAmp = minAmp;
    float dx = 0.f, dy = 0.f;
    if (_jitterState.bx_t >= 1.f || _jitterState.bx_duration <= 0) _generateNewJitterX(effectiveAmp);
    if (_jitterState.bx_t < 1.f) {
        dx = _evalBezier(_jitterState.bx_t, _jitterState.bx_P1, _jitterState.bx_P2, _jitterState.bx_P3);
        _jitterState.bx_t += _jitterState.bx_step;
        if (_jitterState.bx_t > 1.f) _jitterState.bx_t = 1.f;
    }
    if (_jitterState.by_t >= 1.f || _jitterState.by_duration <= 0) _generateNewJitterY(effectiveAmp);
    if (_jitterState.by_t < 1.f) {
        dy = _evalBezier(_jitterState.by_t, _jitterState.by_P1, _jitterState.by_P2, _jitterState.by_P3);
        _jitterState.by_t += _jitterState.by_step;
        if (_jitterState.by_t > 1.f) _jitterState.by_t = 1.f;
    }
    return Vector2(dx, dy);
}

inline float PrefFloat(NSDictionary *cfg, NSString *key, float def) {
    id v = cfg[key];
    return v ? [v floatValue] : def;
}
inline bool PrefBool(NSDictionary *cfg, NSString *key, bool def) {
    id v = cfg[key];
    return v ? [v boolValue] : def;
}

inline void LoadFromPrefs(NSDictionary *cfg) {
    if (!cfg) return;
    开启自瞄 = PrefBool(cfg, @"开启自瞄", false);
    自瞄连线 = PrefBool(cfg, @"自瞄连线", false);
    显示范围 = PrefBool(cfg, @"显示范围", false);
    模型渲染 = PrefBool(cfg, @"模型渲染", false);
    模型按需加载 = PrefBool(cfg, @"实验-模型按需加载", false);
    走廊半宽 = PrefFloat(cfg, @"走廊半宽", 12.f);
    if (走廊半宽 < 6.f) 走廊半宽 = 6.f;
    if (走廊半宽 > 24.f) 走廊半宽 = 24.f;
    近距泡 = PrefFloat(cfg, @"近距泡", 40.f);
    if (近距泡 < 15.f) 近距泡 = 15.f;
    if (近距泡 > 80.f) 近距泡 = 80.f;
    静态刷新间隔 = PrefFloat(cfg, @"静态刷新间隔", 2000.f);
    if (静态刷新间隔 < 600.f) 静态刷新间隔 = 600.f;
    if (静态刷新间隔 > 5000.f) 静态刷新间隔 = 5000.f;
    按需保守遮挡 = PrefBool(cfg, @"按需保守遮挡", true);
    漏打距离 = PrefFloat(cfg, @"漏打距离", 90.f);
    if (漏打距离 > 150.f) 漏打距离 = 150.f;
    if (漏打距离 > 0.f && 漏打距离 < 50.f) 漏打距离 = 50.f;
    // 触摸标识符：优先 drx 旁路（跨进程），与 qwer plist SID 同角色
    id sidObj = cfg[@"TouchSenderID"];
    if (sidObj != nil) {
        uint64_t sid = 0;
        if ([sidObj respondsToSelector:@selector(unsignedLongLongValue)]) {
            sid = [sidObj unsignedLongLongValue];
        } else if ([sidObj isKindOfClass:[NSString class]]) {
            sid = strtoull([(NSString *)sidObj UTF8String], nullptr, 0);
        }
        if (sid != 0) {
            huoqu(sid);
        }
    }
    自瞄速度 = PrefFloat(cfg, @"自瞄速度", 26.f);
    自瞄大小 = PrefFloat(cfg, @"自瞄大小", 60.f);
    开镜自瞄大小 = PrefFloat(cfg, @"开镜自瞄范围", 40.f);
    显示开镜自瞄范围 = PrefBool(cfg, @"显示开镜自瞄范围", false);
    自瞄距离 = PrefFloat(cfg, @"自瞄距离", 100.f);
    腰射距离 = PrefFloat(cfg, @"腰射距离", 30.f);
    压枪力度 = PrefFloat(cfg, @"压枪力度", 5.f) / 10.f;
    自瞄血量 = PrefFloat(cfg, @"自瞄血量", 100.f);
    满血距离 = PrefFloat(cfg, @"满血距离", 50.f);
    烟雾不瞄 = PrefBool(cfg, @"烟雾不瞄", false);
    烟雾范围 = PrefFloat(cfg, @"烟雾范围", 15.f);
    开启动态圈 = PrefBool(cfg, @"动态圈", false);
    开启开镜动态圈 = PrefBool(cfg, @"开镜动态圈", false);
    动态圈最小 = PrefFloat(cfg, @"动态圈最小", 20.f);
    动态圈速度 = PrefFloat(cfg, @"动态圈速度", 12.f);
    动态圈插值方式 = (int)PrefFloat(cfg, @"动态圈插值方式", 1.f);
    if (动态圈插值方式 < 0 || 动态圈插值方式 > 1) 动态圈插值方式 = 1;
    内圈大小 = PrefFloat(cfg, @"内圈大小", 0.f);
    显示内圈 = PrefBool(cfg, @"显示内圈", false);
    显示触摸区域 = PrefBool(cfg, @"显示触摸区域", false);
    触摸区域宽度 = (int)PrefFloat(cfg, @"触摸区域宽度", 120.f);
    触摸区域高度 = (int)PrefFloat(cfg, @"触摸区域高度", 60.f);
    触摸区域X = (int)PrefFloat(cfg, @"触摸区域X", 0.f);
    触摸区域Y = (int)PrefFloat(cfg, @"触摸区域Y", 0.f);
    抖动幅度 = PrefFloat(cfg, @"抖动幅度", 5.f) / 10.f;
    抖动频率 = PrefFloat(cfg, @"抖动频率", 10.f) / 100.f;
    抖动波动 = PrefFloat(cfg, @"抖动波动", 1.f) / 100.f;
    吸附曲线 = PrefBool(cfg, @"吸附曲线", false);
    外圈速度 = PrefFloat(cfg, @"外圈速度", 26.f);
    内圈速度 = PrefFloat(cfg, @"内圈速度", 40.f);
    变速过渡宽 = PrefFloat(cfg, @"变速过渡宽", 15.f);
    距离衰减 = PrefBool(cfg, @"距离衰减", false);
    衰减起点 = PrefFloat(cfg, @"衰减起点", 30.f);
    衰减终点 = PrefFloat(cfg, @"衰减终点", 100.f);
    远端拉力 = PrefFloat(cfg, @"远端拉力", 35.f) / 100.f;
    曲线目标冻结 = PrefBool(cfg, @"曲线目标冻结", false);
    冻结段长 = PrefFloat(cfg, @"冻结段长", 12.f);
    曲线缓动 = PrefBool(cfg, @"曲线缓动", false);
    前冲强度 = PrefFloat(cfg, @"前冲强度", 55.f) / 100.f;
    曲线惯性 = PrefBool(cfg, @"曲线惯性", false);
    惯性强度 = PrefFloat(cfg, @"惯性强度", 55.f) / 100.f;
    曲线弧线 = PrefBool(cfg, @"曲线弧线", false);
    弧线幅度 = PrefFloat(cfg, @"弧线幅度", 50.f) / 100.f;
    切目标粘滞 = PrefBool(cfg, @"切目标粘滞", false);
    粘滞时间 = PrefFloat(cfg, @"粘滞时间", 250.f);
    粘滞近距阈值 = PrefFloat(cfg, @"粘滞近距阈值", 20.f);
    粘滞确认帧 = PrefFloat(cfg, @"粘滞确认帧", 5.f);
}

// 外强内柔除数：屏幕偏心大→外圈速度；靠近内圈→内圈速度
inline float ComputeAdsorbSpeedDiv(float screenOff) {
    float outerR = fmaxf(当前自瞄大小, 1.f);
    float innerR = fminf(fmaxf(内圈大小, 0.f), outerR);
    // 内圈关闭时用外圈 25% 作软区起点，避免变速失效
    float softStart = (innerR > 0.f) ? innerR : (outerR * 0.25f);
    float softEnd = softStart + fmaxf(变速过渡宽, 0.f);
    if (softEnd > outerR) softEnd = outerR;
    float span = softEnd - softStart;
    float u;
    if (span <= 0.5f) {
        u = (screenOff > softStart) ? 1.f : 0.f;
    } else {
        u = (screenOff - softStart) / span;
        if (u < 0.f) u = 0.f;
        else if (u > 1.f) u = 1.f;
    }
    // u=0 贴内圈→内圈速度；u=1 靠外→外圈速度
    float outSp = fmaxf(外圈速度, 1.f);
    float inSp = fmaxf(内圈速度, 1.f);
    return inSp + (outSp - inSp) * u;
}

// 距离衰减倍率（选中敌人距离单位：米）
inline float ComputeDistancePullScale(float distMeters) {
    float start = fmaxf(衰减起点, 0.f);
    float end = fmaxf(衰减终点, start + 0.1f);
    float farK = fminf(fmaxf(远端拉力, 0.f), 1.f);
    if (distMeters <= start) return 1.f;
    if (distMeters >= end) return farK;
    float t = (distMeters - start) / (end - start);
    return 1.f + (farK - 1.f) * t;
}

inline void EnsureTouchInit(float screenW, float screenH) {
    if (!开启自瞄) return;
    // 每帧可刷新屏幕尺寸；SID 初始化只做一次（initSenderId 内部 once）
    initTouchGetScreenSize(screenW, screenH);
    if (!触摸系统已初始化) {
        initSenderId();
        触摸系统已初始化 = true;
    }
}

inline void EnsurePhysX(uint64_t moduleBase) {
    // 关模型渲染：后台场景线程进入闲置 sleep，避免空转占满 CPU
    AimPhysX_SetSceneActive(模型渲染);
    // 按漏打距离加载附近网格（内部转 UE 单位并加 15% 余量）
    AimPhysX_SetLoadRadiusMeters(漏打距离 > 0.f ? 漏打距离 : 90.f);
    AimPhysX_SetCorridorHalfMeters(走廊半宽);
    AimPhysX_SetNearBubbleMeters(近距泡);
    AimPhysX_SetRangeBaseMs((int)lroundf(静态刷新间隔));
    if (!模型渲染) return;
    if (moduleBase == 0) return;
    AimPhysX_SetModuleBase(moduleBase);
    AimPhysX_InitIfNeeded();
}

inline Vector2 标准化坐标(float width, float height, Vector2 point) {
    Vector2 aa;
    aa.X = fminf(fmaxf((height - point.Y) / height, 0.f), 1.f);
    aa.Y = fminf(fmaxf(point.X / width, 0.f), 1.f);
    return aa;
}

inline float GetCenterOffset(Vector2 point, float sw, float sh) {
    float dx = point.X - sw * 0.5f;
    float dy = point.Y - sh * 0.5f;
    return sqrtf(dx * dx + dy * dy);
}

inline bool smogQuantity(Vector3 targetPos) {
    for (const auto &s : 烟雾数组) {
        float dx = targetPos.X - s.smokePos.X;
        float dy = targetPos.Y - s.smokePos.Y;
        float dz = targetPos.Z - s.smokePos.Z;
        float distance = sqrtf(dx * dx + dy * dy + dz * dz) / 100.f;
        if (distance < 烟雾范围) return true;
    }
    return false;
}

inline bool IsPointOccluded(const Vector3 &cam, const Vector3 &bone) {
    if (!模型渲染) return false;
    if (!AimPhysX_IsReady()) {
        // 按需+保守：未就绪当遮挡，避免空场景穿墙锁；关保守则与旧行为一致（当可见）
        return 模型按需加载 && 按需保守遮挡;
    }
    return AimPhysX_IsOccluded(cam, bone);
}

inline void BeginFrameSelect() {
    本帧最佳Actor = 0;
    本帧最佳血量 = 0;
    本帧最佳距离 = 0;
    本帧最佳偏移 = 0;
    最小距离 = 0;
    粘滞本帧仍有效 = false;
    if (!切目标粘滞) {
        选中敌人Actor = 0;
        选中敌人血量 = 0;
        选中敌人距离 = 0;
        粘滞Actor = 0;
        挑战者Actor = 0;
        挑战者计数 = 0;
    }
}

inline void UpdateAimMode(uint64_t character, float dt) {
    当前自瞄距离 = 自瞄距离;
    if (!开启自瞄 || !character) {
        当前自瞄大小 = 自瞄大小;
        return;
    }
    当前开火中 = vm_read<bool>(character + SDK::bIsWeaponFiring);
    当前开镜中 = vm_read<bool>(character + SDK::bIsGunADS);
    if (当前开火中 && !当前开镜中) {
        当前自瞄距离 = 腰射距离;
    }
    float 最大圈 = 当前开镜中 ? 开镜自瞄大小 : 自瞄大小;
    bool 本模式动态圈 = 当前开镜中 ? 开启开镜动态圈 : 开启动态圈;
    float 最小圈 = fminf(fmaxf(动态圈最小, 0.f), 最大圈);
    if (本模式动态圈) {
        float 目标半径 = 最大圈;
        if (动态圈上一帧有锁) {
            // t=1 在最大圈边沿，t=0 在准心；半径 = 最小 + t*(最大-最小)
            float t = 最大圈 > 0.f ? fminf(fmaxf(动态圈上一帧偏移 / 最大圈, 0.f), 1.f) : 1.f;
            目标半径 = 最小圈 + t * (最大圈 - 最小圈);
        } else {
            目标半径 = 最大圈; // 无锁人：扩回最大，方便从边沿捞人
        }
        if (动态圈插值方式 == 0) {
            // 固定步长（对标 qwer acf6bef）：每帧按像素硬步进
            float step = fmaxf(动态圈速度, 0.1f);
            if (动态圈当前半径 < 目标半径) {
                动态圈当前半径 = fminf(动态圈当前半径 + step, 目标半径);
            } else {
                动态圈当前半径 = fmaxf(动态圈当前半径 - step, 目标半径);
            }
        } else {
            // 指数平滑：跟帧时间，避免固定步长造成一顿一顿
            if (dt <= 0.f || dt > 0.1f) dt = 1.f / 60.f;
            float rate = fmaxf(动态圈速度, 0.5f);
            float alpha = 1.f - expf(-rate * dt);
            alpha = fminf(fmaxf(alpha, 0.f), 1.f);
            动态圈当前半径 = 动态圈当前半径 + (目标半径 - 动态圈当前半径) * alpha;
        }
        动态圈当前半径 = fminf(fmaxf(动态圈当前半径, 最小圈), 最大圈);
        当前自瞄大小 = 动态圈当前半径;
    } else {
        当前自瞄大小 = 最大圈;
        动态圈当前半径 = 最大圈;
    }
}

inline void ConsiderTarget(uint64_t actor, float distance, float Health, bool bIsAI,
                           bool hasVisibleBone, Vector3 aimWorld, Vector2 HeadScreen,
                           Vector3 enemyWorld, float sw, float sh) {
    if (!开启自瞄 || distance > 当前自瞄距离 || Health <= 0 || bIsAI || !hasVisibleBone) return;
    if (烟雾不瞄 && smogQuantity(enemyWorld)) return;
    float offsetToCenter = GetCenterOffset(HeadScreen, sw, sh);
    float 有效内圈 = fminf(fmaxf(内圈大小, 0.f), 当前自瞄大小);
    if (offsetToCenter > 有效内圈 && offsetToCenter <= 当前自瞄大小) {
        if (切目标粘滞 && 粘滞Actor != 0 && actor == 粘滞Actor) {
            粘滞本帧仍有效 = true;
            粘滞瞄准点 = aimWorld;
            粘滞屏幕位置 = HeadScreen;
            粘滞血量 = Health;
            粘滞距离 = distance;
            粘滞偏移 = offsetToCenter;
        }
        if (最小距离 == 0 || offsetToCenter < 最小距离) {
            最小距离 = offsetToCenter;
            本帧最佳Actor = actor;
            本帧最佳瞄准点 = aimWorld;
            本帧最佳屏幕位置 = HeadScreen;
            本帧最佳血量 = Health;
            本帧最佳距离 = distance;
            本帧最佳偏移 = offsetToCenter;
        }
    }
}

inline void ApplySelectedCandidate(uint64_t actor, Vector3 aim, Vector2 screen, float hp, float dist) {
    选中敌人Actor = actor;
    选中敌人瞄准点 = aim;
    选中敌人屏幕位置 = screen;
    选中敌人血量 = hp;
    选中敌人距离 = dist;
}

inline void FinalizeTargetSelect() {
    if (!开启自瞄) {
        选中敌人Actor = 0;
        粘滞Actor = 0;
        挑战者计数 = 0;
        return;
    }
    if (!切目标粘滞) {
        ApplySelectedCandidate(本帧最佳Actor, 本帧最佳瞄准点, 本帧最佳屏幕位置,
                               本帧最佳血量, 本帧最佳距离);
        return;
    }

    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (粘滞Actor == 0 || !粘滞本帧仍有效) {
        ApplySelectedCandidate(本帧最佳Actor, 本帧最佳瞄准点, 本帧最佳屏幕位置,
                               本帧最佳血量, 本帧最佳距离);
        粘滞Actor = 本帧最佳Actor;
        粘滞开始时间 = now;
        挑战者Actor = 0;
        挑战者计数 = 0;
        return;
    }

    // 粘滞目标仍有效：本帧继续跟他
    ApplySelectedCandidate(粘滞Actor, 粘滞瞄准点, 粘滞屏幕位置, 粘滞血量, 粘滞距离);

    if (本帧最佳Actor != 0 && 本帧最佳Actor != 粘滞Actor) {
        float needCloser = fmaxf(粘滞近距阈值, 0.f);
        if (本帧最佳偏移 + needCloser < 粘滞偏移) {
            if (挑战者Actor != 本帧最佳Actor) {
                挑战者Actor = 本帧最佳Actor;
                挑战者计数 = 1;
            } else {
                挑战者计数++;
            }
            double elapsedMs = (now - 粘滞开始时间) * 1000.0;
            int needFrames = (int)fmaxf(粘滞确认帧, 1.f);
            if (elapsedMs >= (double)fmaxf(粘滞时间, 0.f) && 挑战者计数 >= needFrames) {
                ApplySelectedCandidate(本帧最佳Actor, 本帧最佳瞄准点, 本帧最佳屏幕位置,
                                       本帧最佳血量, 本帧最佳距离);
                粘滞Actor = 本帧最佳Actor;
                粘滞开始时间 = now;
                挑战者Actor = 0;
                挑战者计数 = 0;
            }
        } else {
            挑战者Actor = 0;
            挑战者计数 = 0;
        }
    } else {
        挑战者Actor = 0;
        挑战者计数 = 0;
    }
}

inline void EndTouchIfNeeded(float sw, float sh) {
    if (!kaishchumo) return;
    kaishchumo = false;
    ResetPullCurveState();
    Vector2 hha = 标准化坐标(sw, sh, nextPoint);
    touchEnd(10, hha.X, hha.Y);
}

// 贝塞尔主路径组件：按开关叠加；全关时不应调用（zimiao 走线性）
inline Vector2 ComputeBezierPullOffset(Vector2 liveRel, uint64_t actor, float effectiveDiv) {
    Vector2 planRel = liveRel;
    float errLen = sqrtf(liveRel.X * liveRel.X + liveRel.Y * liveRel.Y);

    if (曲线目标冻结) {
        float fdx = liveRel.X - _pullCurve.frozenRel.X;
        float fdy = liveRel.Y - _pullCurve.frozenRel.Y;
        float frozenDrift = sqrtf(fdx * fdx + fdy * fdy);
        bool actorChanged = (_pullCurve.frozenActor != 0 && actor != 0 && _pullCurve.frozenActor != actor);
        bool driftTooFar = (errLen > 1.f && frozenDrift > fmaxf(28.f, errLen * 0.45f));
        bool needReplan = !_pullCurve.active ||
                          _pullCurve.t >= 1.f ||
                          _pullCurve.duration <= 0 ||
                          actorChanged ||
                          driftTooFar;
        if (needReplan) {
            _pullCurve.frozenRel = liveRel;
            _pullCurve.frozenActor = actor;
            int baseDur = (int)fmaxf(冻结段长, 4.f);
            _pullCurve.duration = baseDur + (int)(arc4random() % 5);
            _pullCurve.t = 0.f;
            _pullCurve.step = 1.f / (float)_pullCurve.duration;
            _pullCurve.active = true;
        }
        planRel = _pullCurve.frozenRel;
    } else {
        // 无冻结：仍用短段推进 t，供缓动/弧线相位；每帧刷新目标误差
        if (!_pullCurve.active || _pullCurve.t >= 1.f || _pullCurve.duration <= 0) {
            int baseDur = (int)fmaxf(冻结段长, 4.f);
            _pullCurve.duration = baseDur + (int)(arc4random() % 5);
            _pullCurve.t = 0.f;
            _pullCurve.step = 1.f / (float)_pullCurve.duration;
            _pullCurve.active = true;
            _pullCurve.frozenActor = actor;
        }
        _pullCurve.frozenRel = liveRel;
        planRel = liveRel;
    }

    float t0 = _pullCurve.t;
    float t1 = fminf(t0 + _pullCurve.step, 1.f);
    float de;
    if (曲线缓动) {
        float punch = fminf(fmaxf(前冲强度, 0.05f), 1.f);
        float p1 = 0.15f + punch * 0.35f;   // ~0.15–0.50
        float p2 = 0.55f + punch * 0.40f;   // ~0.55–0.95
        float e0 = _evalBezier(t0, p1, p2, 1.f);
        float e1 = _evalBezier(t1, p1, p2, 1.f);
        de = e1 - e0;
    } else {
        de = _pullCurve.step;
    }

    Vector2 base(planRel.X * de, planRel.Y * de);
    float scale = 1.f / fmaxf(effectiveDiv * 0.08f, 0.35f);
    base.X *= scale;
    base.Y *= scale;

    if (曲线弧线) {
        float fl = sqrtf(planRel.X * planRel.X + planRel.Y * planRel.Y);
        if (fl > 1.f) {
            Vector2 perp(-planRel.Y / fl, planRel.X / fl);
            float ampK = fminf(fmaxf(弧线幅度, 0.f), 1.5f);
            float arcAmp = fminf(7.f, fl * 0.07f) * ampK;
            float arc = sinf(t0 * 3.14159265f) * arcAmp * _pullCurve.step;
            base.X += perp.X * arc;
            base.Y += perp.Y * arc;
        }
    }

    Vector2 out = base;
    if (曲线惯性) {
        float keep = 0.45f + fminf(fmaxf(惯性强度, 0.f), 1.f) * 0.40f; // 0.45–0.85
        float follow = 1.f - keep;
        _pullCurve.vel.X = _pullCurve.vel.X * keep + base.X * follow;
        _pullCurve.vel.Y = _pullCurve.vel.Y * keep + base.Y * follow;
        out = _pullCurve.vel;
    } else {
        _pullCurve.vel = base;
    }

    _pullCurve.t = t1;
    return out;
}

inline void zimiao(Vector3 aimpos, uint64_t player, uint64_t Character, const CoViewInfo &POV,
                   bool bIsWeaponFiring, float sw, float sh) {
    if (!开启自瞄) return;
    if (bIsWeaponFiring) {
        float distance = GetDistance(aimpos, POV.Location);
        float temp = 1.0f, Gravity = 5.0f;
        if (distance < 5000.f) temp = 1.8f;
        else if (distance < 10000.f) temp = 1.72f;
        else if (distance < 15000.f) temp = 1.23f;
        else if (distance < 20000.f) temp = 1.24f;
        else if (distance < 25000.f) temp = 1.25f;
        else if (distance < 30000.f) temp = 1.26f;
        else if (distance < 35000.f) temp = 1.27f;

        uint64_t weaponEnt = UNSIGN_PTR(vm_read<uint64_t>(Character + SDK::WeaponEntity));
        uint64_t weaponComp = UNSIGN_PTR(vm_read<uint64_t>(weaponEnt + SDK::WeaponComponent));
        uint64_t shootComp = UNSIGN_PTR(vm_read<uint64_t>(weaponComp + SDK::ShootWeaponEntityComp));
        float BulletFireSpeed = vm_read<float>(shootComp + SDK::BulletFireSpeed);
        if (BulletFireSpeed < 1.f) BulletFireSpeed = 80000.f;
        float BulletFlyTime = distance / BulletFireSpeed;
        float secFlyTime = BulletFlyTime * temp;
        Vector3 MoveVelocity = vm_read<Vector3>(player + SDK::VelocitySafety);
        Vector3 delta(MoveVelocity.X * secFlyTime, MoveVelocity.Y * secFlyTime, MoveVelocity.Z * secFlyTime);
        if (distance > 10000.f)
            delta.Z += 0.5f * Gravity * BulletFlyTime * BulletFlyTime * 5.0f;
        Vector3 aimtarget(aimpos.X + delta.X, aimpos.Y + delta.Y, aimpos.Z + delta.Z);

        Vector2 lockScreenPoint = WorldToScreen(aimtarget, POV, (int)sw, (int)sh);
        Vector2 relativePoint = lockScreenPoint - Vector2(sw * 0.5f, sh * 0.5f);

        if (!kaishchumo) {
            kaishchumo = true;
            ResetPullCurveState();
            float 区域中心X = sw / 2.f + 触摸区域X;
            float 区域中心Y = sh / 2.f + 触摸区域Y;
            float 随机X偏移 = ((float)rand() / RAND_MAX - 0.5f) * 触摸区域宽度;
            float 随机Y偏移 = ((float)rand() / RAND_MAX - 0.5f) * 触摸区域高度;
            Vector2 startPoint(区域中心X + 随机X偏移, 区域中心Y + 随机Y偏移);
            nextPoint = startPoint;
            Vector2 hha = 标准化坐标(sw, sh, startPoint);
            touchBegin(10, hha.X, hha.Y);
            _jitterState.bx_t = 1.f;
            _jitterState.by_t = 1.f;
        } else {
            Vector2 prevPoint = nextPoint;
            float speedDiv = fmaxf(自瞄速度, 1.f);
            float pullScale = 1.f;
            if (吸附曲线) {
                float screenOff = sqrtf(relativePoint.X * relativePoint.X +
                                        relativePoint.Y * relativePoint.Y);
                speedDiv = ComputeAdsorbSpeedDiv(screenOff);
                if (距离衰减) {
                    pullScale = ComputeDistancePullScale(选中敌人距离);
                }
            }
            // Vector2 仅有 operator/(float)，无 operator*(float)
            float effectiveDiv = (pullScale > 1e-6f) ? (speedDiv / pullScale) : 1e6f;
            Vector2 offset;
            if (AnyBezierPullFeatureOn()) {
                offset = ComputeBezierPullOffset(relativePoint, player, effectiveDiv);
            } else {
                offset = relativePoint / effectiveDiv;
            }
            Vector2 targetPoint = nextPoint + offset;
            nextPoint.X = fminf(fmaxf(nextPoint.X + (targetPoint.X - nextPoint.X), 0.f), sw);
            nextPoint.Y = fminf(fmaxf(nextPoint.Y + (targetPoint.Y - nextPoint.Y), 0.f), sh);
            nextPoint += offset;

            bool isADS = vm_read<bool>(Character + SDK::bIsGunADS);
            uint64_t ownerProxy = UNSIGN_PTR(vm_read<uint64_t>(Character + SDK::WeaponOwnerProxy));
            uint64_t binded = UNSIGN_PTR(vm_read<uint64_t>(ownerProxy + SDK::BindedWeapon));
            uint64_t track = UNSIGN_PTR(vm_read<uint64_t>(binded + SDK::CachedBulletTrackComponent));
            float VerticalRecoil = vm_read<float>(track + SDK::VerticalRecoilTarget);
            float fovFactor = (POV.FOV < 80) ? (1.0f + 140.0f / POV.FOV) : 1.4f;
            float 当前压枪力度 = isADS ? 压枪力度 : 0.5f;
            nextPoint.Y += VerticalRecoil * fovFactor * 当前压枪力度;

            float pullSpeed = sqrtf((nextPoint.X - prevPoint.X) * (nextPoint.X - prevPoint.X) +
                                    (nextPoint.Y - prevPoint.Y) * (nextPoint.Y - prevPoint.Y));
            Vector2 jitterOffset = _updateBezierJitter(pullSpeed, 抖动幅度);
            nextPoint.X += jitterOffset.X;
            nextPoint.Y += jitterOffset.Y;
            nextPoint.X = fminf(fmaxf(nextPoint.X, 0.f), sw);
            nextPoint.Y = fminf(fmaxf(nextPoint.Y, 0.f), sh);
            Vector2 norm = 标准化坐标(sw, sh, nextPoint);
            touchMove(10, norm.X, norm.Y);
        }
    } else {
        EndTouchIfNeeded(sw, sh);
    }
}

inline bool ExecuteAim(uint64_t Character, const CoViewInfo &POV, ImDrawList *dl, float sw, float sh) {
    bool 本帧有效锁人 = false;
    if (!开启自瞄) {
        EndTouchIfNeeded(sw, sh);
        动态圈上一帧有锁 = false;
        粘滞Actor = 0;
        挑战者计数 = 0;
        return false;
    }
    float 执行内圈 = fminf(fmaxf(内圈大小, 0.f), 当前自瞄大小);
    float 选中偏移 = (选中敌人Actor != 0) ? GetCenterOffset(选中敌人屏幕位置, sw, sh) : 0.f;
    bool 在内圈死区 = (执行内圈 > 0.f && 选中偏移 <= 执行内圈);
    if (选中敌人Actor != 0 && !在内圈死区 &&
        (选中敌人距离 <= 满血距离 || 选中敌人血量 <= 自瞄血量)) {
        本帧有效锁人 = true;
        zimiao(选中敌人瞄准点, 选中敌人Actor, Character, POV, 当前开火中, sw, sh);
        if (自瞄连线 && dl) {
            dl->AddLine(ImVec2(sw / 2.f, sh / 2.f),
                        ImVec2(选中敌人屏幕位置.X, 选中敌人屏幕位置.Y),
                        IM_COL32(255, 0, 0, 255), 1.0f);
        }
    } else {
        EndTouchIfNeeded(sw, sh);
    }
    动态圈上一帧有锁 = 本帧有效锁人;
    动态圈上一帧偏移 = 本帧有效锁人 ? GetCenterOffset(选中敌人屏幕位置, sw, sh) : 0.f;
    return 本帧有效锁人;
}

inline void DrawOverlays(ImDrawList *dl, float sw, float sh) {
    if (!dl) return;
    if (显示触摸区域 && 开启自瞄) {
        float cx = sw / 2.f + 触摸区域X;
        float cy = sh / 2.f + 触摸区域Y;
        float hw = 触摸区域宽度 * 0.5f;
        float hh = 触摸区域高度 * 0.5f;
        dl->AddRect(ImVec2(cx - hw, cy - hh), ImVec2(cx + hw, cy + hh),
                    IM_COL32(255, 100, 100, 200), 0, 0, 2.f);
        dl->AddCircleFilled(ImVec2(cx, cy), 4.f, IM_COL32(100, 255, 100, 255));
    }
    if (!开启自瞄) return;
    if (当前开镜中) {
        if (显示开镜自瞄范围) {
            dl->AddCircle(ImVec2(sw / 2.f, sh / 2.f), 当前自瞄大小, IM_COL32(0, 255, 255, 180), 64, 1.f);
        }
    } else if (显示范围) {
        dl->AddCircle(ImVec2(sw / 2.f, sh / 2.f), 当前自瞄大小, IM_COL32(255, 255, 255, 180), 64, 1.f);
    }
    if (显示内圈 && 内圈大小 > 0.f) {
        float 画内圈 = fminf(内圈大小, 当前自瞄大小);
        dl->AddCircle(ImVec2(sw / 2.f, sh / 2.f), 画内圈, IM_COL32(255, 165, 0, 200), 64, 1.5f);
    }
}

} // namespace AimAssist
