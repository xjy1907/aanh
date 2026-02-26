#import "SDK.h"

namespace UE4算法 {

UE4类型::FMinimalViewInfo 取POV(uint64_t POV) {
    return {
        kfd.取vreadbuf<UE4类型::FVector>(POV + SDK::FMinimalViewInfo::Location),
        kfd.取vreadbuf<UE4类型::FRotator>(POV + SDK::FMinimalViewInfo::Rotation),
        kfd.取vreadbuf<float>(POV + SDK::FMinimalViewInfo::FOV),
    };
};

UE4类型::FMatrix 取矩阵(UE4类型::FRotator Rotation) {
    UE4类型::FVector2D Pitch = {
        sinf(Rotation.Pitch * M_PI / 180.0f),
        cosf(Rotation.Pitch * M_PI / 180.0f),
    };
    UE4类型::FVector2D Yaw = {
        sinf(Rotation.Yaw * M_PI / 180.0f),
        cosf(Rotation.Yaw * M_PI / 180.0f),
    };
    UE4类型::FVector2D Roll = {
        sinf(Rotation.Roll * M_PI / 180.0f),
        cosf(Rotation.Roll * M_PI / 180.0f),
    };
    
    return {
        Pitch.Y * Yaw.Y,
        Pitch.Y * Yaw.X,
        Pitch.X,
        0.0f,
        
        Pitch.X * Yaw.Y * Roll.X - Yaw.X * Roll.Y,
        Pitch.X * Yaw.X * Roll.X + Yaw.Y * Roll.Y,
        Pitch.Y * -Roll.X,
        0.0f,
        
        - (Pitch.X * Yaw.Y * Roll.Y + Yaw.X * Roll.X),
        Yaw.Y * Roll.X - Pitch.X * Yaw.X * Roll.Y,
        Pitch.Y * Roll.Y,
        0.0f,
        
        0.0f,
        0.0f,
        0.0f,
        1.0f,
    };
};

UE4类型::FVector 取坐标差(UE4类型::FVector 坐标, UE4类型::FVector Location, float 比例) {
    return {
        (坐标.X - Location.X) / 比例,
        (坐标.Y - Location.Y) / 比例,
        (坐标.Z - Location.Z) / 比例,
    };
};

float 取距离(UE4类型::FVector RelativeLocation, UE4类型::FVector Location) {
    UE4类型::FVector 坐标差 = 取坐标差(RelativeLocation, Location, 100.0f);
    return sqrtf(powf(坐标差.X, 2.0f) + powf(坐标差.Y, 2.0f) + powf(坐标差.Z, 2.0f));
};

//float 取距离(UE4类型::FVector RelativeLocation, UE4类型::FMatrix 矩阵) {
//    return fabsf((RelativeLocation.X * 矩阵.XPlane.W + RelativeLocation.Y * 矩阵.YPlane.W + RelativeLocation.Z * 矩阵.ZPlane.W + 矩阵.WPlane.W) / 100.0f);
//};

ImVec2 取屏幕坐标(UE4类型::FVector 世界坐标, UE4类型::FMinimalViewInfo POV, UE4类型::FMatrix 矩阵) {
    UE4类型::FVector 坐标差 = 取坐标差(世界坐标, POV.Location, 1.0f);
    UE4类型::FVector 世界x矩阵 = {
        坐标差.X * 矩阵.YPlane.X + 坐标差.Y * 矩阵.YPlane.Y + 坐标差.Z * 矩阵.YPlane.Z,
        坐标差.X * 矩阵.ZPlane.X + 坐标差.Y * 矩阵.ZPlane.Y + 坐标差.Z * 矩阵.ZPlane.Z,
        坐标差.X * 矩阵.XPlane.X + 坐标差.Y * 矩阵.XPlane.Y + 坐标差.Z * 矩阵.XPlane.Z,
    };
    if (世界x矩阵.Z < 1.0f) 世界x矩阵.Z = 1.0f;
    return {
        (设备类型.设备信息.宽度 * 0.5f) + 世界x矩阵.X * ((设备类型.设备信息.宽度 * 0.5f) / tanf(POV.FOV * M_PI / 360.0f)) / 世界x矩阵.Z,
        (设备类型.设备信息.高度 * 0.5f) - 世界x矩阵.Y * ((设备类型.设备信息.宽度 * 0.5f) / tanf(POV.FOV * M_PI / 360.0f)) / 世界x矩阵.Z,
    };
};

//ImVec2 取屏幕坐标(UE4类型::FVector 世界坐标, UE4类型::FMatrix 矩阵) {
//    float 缩放比例 = 世界坐标.X * 矩阵.XPlane.W + 世界坐标.Y * 矩阵.YPlane.W + 世界坐标.Z * 矩阵.ZPlane.W + 矩阵.WPlane.W;
//    if (缩放比例 < 1.0f) 缩放比例 = 1.0f;
//    return {
//        (设备类型.设备信息.宽度 * 0.5f) + (世界坐标.X * 矩阵.XPlane.X + 世界坐标.Y * 矩阵.YPlane.X + 世界坐标.Z * 矩阵.ZPlane.X + 矩阵.WPlane.X) / 缩放比例 * (设备类型.设备信息.宽度 * 0.5f),
//        (设备类型.设备信息.高度 * 0.5f) - (世界坐标.X * 矩阵.XPlane.Y + 世界坐标.Y * 矩阵.YPlane.Y + 世界坐标.Z * 矩阵.ZPlane.Y + 矩阵.WPlane.Y) / 缩放比例 * (设备类型.设备信息.高度 * 0.5f),
//    };
//};

UE4类型::FTransform 取Transform(uint64_t ComponentToWorld) {
    return {
        kfd.取vreadbuf<UE4类型::FQuat>(ComponentToWorld + SDK::FTransform::Rotation),
        kfd.取vreadbuf<UE4类型::FVector>(ComponentToWorld + SDK::FTransform::translation),
        kfd.取vreadbuf<UE4类型::FVector>(ComponentToWorld + SDK::FTransform::Scale3D),
    };
};

UE4类型::FMatrix 取Transform矩阵(UE4类型::FTransform Transform) {
    return {
        1.0f - (Transform.Rotation.Y * Transform.Rotation.Y * 2.0f + Transform.Rotation.Z * Transform.Rotation.Z * 2.0f) *Transform.Scale3D.X,
        (Transform.Rotation.X * Transform.Rotation.Y * 2.0f + Transform.Rotation.W * Transform.Rotation.Z * 2.0f) * Transform.Scale3D.X,
        (Transform.Rotation.X * Transform.Rotation.Z * 2.0f - Transform.Rotation.W * Transform.Rotation.Y * 2.0f) * Transform.Scale3D.X,
        0.0f,
        
        (Transform.Rotation.X * Transform.Rotation.Y * 2.0f - Transform.Rotation.W * Transform.Rotation.Z * 2.0f) * Transform.Scale3D.Y,
        1.0f - (Transform.Rotation.X * Transform.Rotation.X * 2.0f + Transform.Rotation.Z * Transform.Rotation.Z * 2.0f) * Transform.Scale3D.Y,
        (Transform.Rotation.Y * Transform.Rotation.Z * 2.0f + Transform.Rotation.W * Transform.Rotation.X * 2.0f) * Transform.Scale3D.Y,
        0.0f,
        
        (Transform.Rotation.Y * Transform.Rotation.Z * 2.0f - Transform.Rotation.W * Transform.Rotation.X * 2.0f) * Transform.Scale3D.Z,
        1.0f - (Transform.Rotation.X * Transform.Rotation.X * 2.0f + Transform.Rotation.Y * Transform.Rotation.Y * 2.0f) * Transform.Scale3D.Z,
        0.0f,
        0.0f,
        
        Transform.Translation.X,
        Transform.Translation.Y,
        Transform.Translation.Z,
        1.0f,
    };
};

UE4类型::FVector 取骨骼世界坐标(uint64_t ComponentToWorld, uint64_t StaticMesh, int 骨骼点) {
    UE4类型::FTransform Transform = 取Transform(ComponentToWorld);
    UE4类型::FMatrix Transform矩阵 = 取Transform矩阵(Transform);
    UE4类型::FVector Translation = kfd.取vreadbuf<UE4类型::FVector>(StaticMesh + SDK::FTransform::translation + 骨骼点 * 0x30);
    return {
        Translation.X * Transform矩阵.XPlane.X + Translation.Y * Transform矩阵.YPlane.X + Translation.Z * Transform矩阵.ZPlane.X + Transform矩阵.WPlane.X,
        Translation.X * Transform矩阵.XPlane.Y + Translation.Y * Transform矩阵.YPlane.Y + Translation.Z * Transform矩阵.ZPlane.X + Transform矩阵.WPlane.Y,
        Translation.X * Transform矩阵.XPlane.Z + Translation.Y * Transform矩阵.YPlane.Z + Translation.Z * Transform矩阵.ZPlane.Y + Transform矩阵.WPlane.Z,
    };
};

string 取FString(uint64_t FString) {
    unsigned short UTF_16[28] = {0};
    char UTF_8[448] = {0};
    kfd.取vreadbuf列表(FString, UTF_16, sizeof(UTF_16));
    unsigned short* UTF_16缓冲区 = UTF_16;
    char* UTF_8缓冲区 = UTF_8;
    char *UTF_8缓冲区末尾 = UTF_8 + sizeof(UTF_8);
    while (UTF_16缓冲区 < UTF_16 + 28) {
        unsigned short 转码 = *UTF_16缓冲区;
        if (转码 <= 0x007F && UTF_8缓冲区 + 1 < UTF_8缓冲区末尾) {
            *UTF_8缓冲区++ = (char)转码;
        } else if (转码 >= 0x0080 && 转码 <= 0x07FF && UTF_8缓冲区 + 2 < UTF_8缓冲区末尾) {
            *UTF_8缓冲区++ = (char)((转码 >> 6) | 0xC0);
            *UTF_8缓冲区++ = (char)((转码 & 0x3F) | 0x80);
        } else if (转码 >= 0x0800 && 转码 <= 0xFFFF && UTF_8缓冲区 + 3 < UTF_8缓冲区末尾) {
            *UTF_8缓冲区++ = (char)((转码 >> 12) | 0xE0);
            *UTF_8缓冲区++ = (char)(((转码 >> 6) & 0x3F) | 0x80);
            *UTF_8缓冲区++ = (char)((转码 & 0x3F) | 0x80);
        } else {
            break;
        };
        UTF_16缓冲区++;
    };
    return string(UTF_8);
};

};
