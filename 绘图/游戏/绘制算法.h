//
//  绘制算法.h - UE4 算法（三角洲绘制算法）
//

#ifndef 绘制算法_h
#define 绘制算法_h

#include "SDK.h"
#include "绘制类型.h"
#include "BBZGui.h"

// 需要外部提供的读取函数声明
extern bool readMemory(uint64_t address, void *buffer, size_t size);
extern bool vm_read_list(uint64_t address, void* buffer, size_t size);
template<typename T> inline T vm_read(uint64_t address) {
    T data{}; readMemory(address, &data, sizeof(T)); return data;
}

// 屏幕尺寸（由 DrawView.mm 设置）
static DFType::FVector2D CanvasSize;

DFType::FMinimalViewInfo 取POV(uint64_t POV) {
    return {
        vm_read<DFType::FVector>(POV + SDK::FMinimalViewInfo::Location),
        vm_read<DFType::FRotator>(POV + SDK::FMinimalViewInfo::Rotation),
        vm_read<float>(POV + SDK::FMinimalViewInfo::FOV),
    };
}

DFType::FMatrix 取矩阵(DFType::FRotator Rotation) {
    DFType::FVector2D Pitch = { sinf(Rotation.Pitch * M_PI / 180.0f), cosf(Rotation.Pitch * M_PI / 180.0f) };
    DFType::FVector2D Yaw = { sinf(Rotation.Yaw * M_PI / 180.0f), cosf(Rotation.Yaw * M_PI / 180.0f) };
    DFType::FVector2D Roll = { sinf(Rotation.Roll * M_PI / 180.0f), cosf(Rotation.Roll * M_PI / 180.0f) };
    return {
        Pitch.Y * Yaw.Y, Pitch.Y * Yaw.X, Pitch.X, 0.0f,
        Pitch.X * Yaw.Y * Roll.X - Yaw.X * Roll.Y, Pitch.X * Yaw.X * Roll.X + Yaw.Y * Roll.Y, Pitch.Y * -Roll.X, 0.0f,
        -(Pitch.X * Yaw.Y * Roll.Y + Yaw.X * Roll.X), Yaw.Y * Roll.X - Pitch.X * Yaw.X * Roll.Y, Pitch.Y * Roll.Y, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f,
    };
}

DFType::FVector 取坐标差(DFType::FVector 坐标, DFType::FVector Location, float 比例) {
    return { (坐标.X - Location.X) / 比例, (坐标.Y - Location.Y) / 比例, (坐标.Z - Location.Z) / 比例 };
}

float 取距离(DFType::FVector RelativeLocation, DFType::FVector Location) {
    DFType::FVector d = 取坐标差(RelativeLocation, Location, 100.0f);
    return sqrtf(powf(d.X, 2.0f) + powf(d.Y, 2.0f) + powf(d.Z, 2.0f));
}

ImVec2 取屏幕坐标(DFType::FVector 世界坐标, DFType::FMinimalViewInfo POV, DFType::FMatrix 矩阵) {
    DFType::FVector d = 取坐标差(世界坐标, POV.Location, 1.0f);
    DFType::FVector t = {
        d.X * 矩阵.YPlane.X + d.Y * 矩阵.YPlane.Y + d.Z * 矩阵.YPlane.Z,
        d.X * 矩阵.ZPlane.X + d.Y * 矩阵.ZPlane.Y + d.Z * 矩阵.ZPlane.Z,
        d.X * 矩阵.XPlane.X + d.Y * 矩阵.XPlane.Y + d.Z * 矩阵.XPlane.Z,
    };
    if (t.Z < 1.0f) t.Z = 1.0f;
    return {
        (CanvasSize.X * 0.5f) + t.X * ((CanvasSize.X * 0.5f) / tanf(POV.FOV * M_PI / 360.0f)) / t.Z,
        (CanvasSize.Y * 0.5f) - t.Y * ((CanvasSize.X * 0.5f) / tanf(POV.FOV * M_PI / 360.0f)) / t.Z,
    };
}

DFType::FVector 取RelativeLocation(uint64_t RootComponent) {
    if (!IsValidAddr(RootComponent)) return {0, 0, 0};
    DFType::FVector loc = vm_read<DFType::FVector>(RootComponent + 0x148);
    if (loc.X == 0 && loc.Y == 0 && loc.Z == 0) {
        loc = vm_read<DFType::FVector>(RootComponent + 0x168);
        if (loc.X == 0 && loc.Y == 0 && loc.Z == 0) loc = vm_read<DFType::FVector>(RootComponent + 0x220);
    }
    return loc;
}

DFType::FMatrix 取Transform矩阵(DFType::FTransform T) {
    return {
        1.0f - (T.Rotation.Y*T.Rotation.Y*2.0f + T.Rotation.Z*T.Rotation.Z*2.0f)*T.Scale3D.X,
        (T.Rotation.X*T.Rotation.Y*2.0f + T.Rotation.W*T.Rotation.Z*2.0f)*T.Scale3D.X,
        (T.Rotation.X*T.Rotation.Z*2.0f - T.Rotation.W*T.Rotation.Y*2.0f)*T.Scale3D.X,
        0.0f,

        (T.Rotation.X*T.Rotation.Y*2.0f - T.Rotation.W*T.Rotation.Z*2.0f)*T.Scale3D.Y,
        1.0f - (T.Rotation.X*T.Rotation.X*2.0f + T.Rotation.Z*T.Rotation.Z*2.0f)*T.Scale3D.Y,
        (T.Rotation.Y*T.Rotation.Z*2.0f + T.Rotation.W*T.Rotation.X*2.0f)*T.Scale3D.Y,
        0.0f,

        (T.Rotation.Y*T.Rotation.Z*2.0f - T.Rotation.W*T.Rotation.X*2.0f)*T.Scale3D.Z,
        1.0f - (T.Rotation.X*T.Rotation.X*2.0f + T.Rotation.Y*T.Rotation.Y*2.0f)*T.Scale3D.Z,
        0.0f,
        0.0f,

        T.Translation.X, T.Translation.Y, T.Translation.Z, 1.0f,
    };
}

DFType::FVector 取骨骼世界坐标(uint64_t ComponentToWorld, uint64_t StaticMesh, int 骨骼点) {
    DFType::FTransform T = {
        vm_read<DFType::FQuat>(ComponentToWorld + SDK::FTransform::Rotation),
        vm_read<DFType::FVector>(ComponentToWorld + SDK::FTransform::translation),
        vm_read<DFType::FVector>(ComponentToWorld + SDK::FTransform::Scale3D),
    };
    DFType::FMatrix M = 取Transform矩阵(T);
    DFType::FVector Translation = vm_read<DFType::FVector>(StaticMesh + SDK::FTransform::translation + 骨骼点 * 0x30);
    return {
        Translation.X * M.XPlane.X + Translation.Y * M.YPlane.X + Translation.Z * M.ZPlane.X + M.WPlane.X,
        Translation.X * M.XPlane.Y + Translation.Y * M.YPlane.Y + Translation.Z * M.ZPlane.X + M.WPlane.Y,
        Translation.X * M.XPlane.Z + Translation.Y * M.YPlane.Z + Translation.Z * M.ZPlane.Y + M.WPlane.Z,
    };
}

// ========================================
// 取FString（UTF16 -> UTF8）
// ========================================
string 取FString(uint64_t FString) {
    unsigned short UTF_16[28] = {0};
    char UTF_8[448] = {0};
    vm_read_list(FString, UTF_16, sizeof(UTF_16));
    unsigned short* p16 = UTF_16;
    char* p8 = UTF_8;
    char* end8 = UTF_8 + sizeof(UTF_8);
    while (p16 < UTF_16 + 28) {
        unsigned short ch = *p16;
        if (ch <= 0x007F && p8 + 1 < end8) { *p8++ = (char)ch; }
        else if (ch >= 0x0080 && ch <= 0x07FF && p8 + 2 < end8) { *p8++ = (char)((ch >> 6) | 0xC0); *p8++ = (char)((ch & 0x3F) | 0x80); }
        else if (ch >= 0x0800 && ch <= 0xFFFF && p8 + 3 < end8) { *p8++ = (char)((ch >> 12) | 0xE0); *p8++ = (char)(((ch >> 6) & 0x3F) | 0x80); *p8++ = (char)((ch & 0x3F) | 0x80); }
        else break;
        p16++;
    }
    return string(UTF_8);
}

#endif
