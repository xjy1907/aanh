//
//  绘制算法.h - 无畏契约坐标转换算法
//

#ifndef 绘制算法_h
#define 绘制算法_h

#include <string>
#include <unordered_map>
#include "绘制类型.h"
#include "SDK.h"

// 指针解密 (和平精英不需要解密)
static uintptr_t Decrypt_PTR(uintptr_t addr) {
    return addr;
}

static float Dot(Vector3 lhs, Vector3 rhs) {
    return lhs.X * rhs.X + lhs.Y * rhs.Y + lhs.Z * rhs.Z;
}

static float GetDistance(Vector3 a, Vector3 b) {
    Vector3 v = a - b;
    return sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z);
}

static FMatrix RotatorToMatrix(FRotator rotation) {
    float radPitch = rotation.Pitch * (M_PI / 180.0f);
    float radYaw = rotation.Yaw * (M_PI / 180.0f);
    float radRoll = rotation.Roll * (M_PI / 180.0f);
    float SP = sinf(radPitch), CP = cosf(radPitch);
    float SY = sinf(radYaw), CY = cosf(radYaw);
    float SR = sinf(radRoll), CR = cosf(radRoll);
    FMatrix matrix;
    matrix[0][0] = CP * CY; matrix[0][1] = CP * SY; matrix[0][2] = SP; matrix[0][3] = 0;
    matrix[1][0] = SR*SP*CY - CR*SY; matrix[1][1] = SR*SP*SY + CR*CY; matrix[1][2] = -SR*CP; matrix[1][3] = 0;
    matrix[2][0] = -(CR*SP*CY + SR*SY); matrix[2][1] = CY*SR - CR*SP*SY; matrix[2][2] = CR*CP; matrix[2][3] = 0;
    matrix[3][0] = 0; matrix[3][1] = 0; matrix[3][2] = 0; matrix[3][3] = 1;
    return matrix;
}

static Vector2 WorldToScreen(Vector3 worldLocation, CoViewInfo camViewInfo, int width, int height) {
    float fovRadian = camViewInfo.FOV * (M_PI / 360.0f);
    float tanFov = tanf(fovRadian);
    if (tanFov == 0) tanFov = 0.001f;
    float screenCenterX = width / 2.0f;
    float screenCenterY = height / 2.0f;
    FMatrix tempMatrix = RotatorToMatrix(camViewInfo.Rotation);
    Vector3 vAxisX(tempMatrix[0][0], tempMatrix[0][1], tempMatrix[0][2]);
    Vector3 vAxisY(tempMatrix[1][0], tempMatrix[1][1], tempMatrix[1][2]);
    Vector3 vAxisZ(tempMatrix[2][0], tempMatrix[2][1], tempMatrix[2][2]);
    Vector3 vDelta = worldLocation - camViewInfo.Location;
    float transformedX = Dot(vDelta, vAxisY);
    float transformedY = Dot(vDelta, vAxisZ);
    float transformedZ = Dot(vDelta, vAxisX);
    if (transformedZ < 1.0f) transformedZ = 1.0f;
    return Vector2(screenCenterX + transformedX * (screenCenterX / tanFov) / transformedZ,
                   screenCenterY - transformedY * (screenCenterX / tanFov) / transformedZ);
}

static void BoxConversion(Vector3 worldLocation, VectorRect *rect, CoViewInfo camViewInfo, Vector2 canvasSize) {
    Vector3 worldLocationHead = worldLocation;
    worldLocationHead.Z += 85.f;
    Vector3 worldLocationFoot = worldLocation;
    worldLocationFoot.Z -= 85.f;
    Vector2 calculateHead = WorldToScreen(worldLocationHead, camViewInfo, canvasSize.X, canvasSize.Y);
    Vector2 calculateFoot = WorldToScreen(worldLocationFoot, camViewInfo, canvasSize.X, canvasSize.Y);
    rect->h = calculateFoot.Y - calculateHead.Y;
    rect->w = rect->h / 2.0f;
    rect->x = calculateHead.X - rect->w / 2.0f;
    rect->y = calculateHead.Y;
}

static bool isScreenVisible(Vector2 LocationScreen, Vector2 CanvasSize) {
    return LocationScreen.X > 0 && LocationScreen.X < CanvasSize.X &&
           LocationScreen.Y > 0 && LocationScreen.Y < CanvasSize.Y;
}

static D3DXMATRIX ToMatrixWithScale(Vector4 rotation, Vector3 translation, Vector3 scale3D) {
    D3DXMATRIX ret{};
    ret._41 = translation.X;
    ret._42 = translation.Y;
    ret._43 = translation.Z;
    float x2 = rotation.x * 2, y2 = rotation.y * 2, z2 = rotation.z * 2;
    float xx2 = rotation.x * x2, yy2 = rotation.y * y2, zz2 = rotation.z * z2;
    ret._11 = (1 - (yy2 + zz2)) * scale3D.X;
    ret._22 = (1 - (xx2 + zz2)) * scale3D.Y;
    ret._33 = (1 - (xx2 + yy2)) * scale3D.Z;
    float yz2 = rotation.y * z2, wx2 = rotation.w * x2;
    ret._32 = (yz2 - wx2) * scale3D.Z;
    ret._23 = (yz2 + wx2) * scale3D.Y;
    float xy2 = rotation.x * y2, wz2 = rotation.w * z2;
    ret._21 = (xy2 - wz2) * scale3D.Y;
    ret._12 = (xy2 + wz2) * scale3D.X;
    float xz2 = rotation.x * z2, wy2 = rotation.w * y2;
    ret._31 = (xz2 + wy2) * scale3D.Z;
    ret._13 = (xz2 - wy2) * scale3D.X;
    ret._44 = 1.f;
    return ret;
}

static D3DXMATRIX MatrixMultiplication(D3DXMATRIX M1, D3DXMATRIX M2) {
    D3DXMATRIX ret;
    ret._11 = M1._11 * M2._11 + M1._12 * M2._21 + M1._13 * M2._31 + M1._14 * M2._41;
    ret._12 = M1._11 * M2._12 + M1._12 * M2._22 + M1._13 * M2._32 + M1._14 * M2._42;
    ret._13 = M1._11 * M2._13 + M1._12 * M2._23 + M1._13 * M2._33 + M1._14 * M2._43;
    ret._14 = M1._11 * M2._14 + M1._12 * M2._24 + M1._13 * M2._34 + M1._14 * M2._44;
    ret._21 = M1._21 * M2._11 + M1._22 * M2._21 + M1._23 * M2._31 + M1._24 * M2._41;
    ret._22 = M1._21 * M2._12 + M1._22 * M2._22 + M1._23 * M2._32 + M1._24 * M2._42;
    ret._23 = M1._21 * M2._13 + M1._22 * M2._23 + M1._23 * M2._33 + M1._24 * M2._43;
    ret._24 = M1._21 * M2._14 + M1._22 * M2._24 + M1._23 * M2._34 + M1._24 * M2._44;
    ret._31 = M1._31 * M2._11 + M1._32 * M2._21 + M1._33 * M2._31 + M1._34 * M2._41;
    ret._32 = M1._31 * M2._12 + M1._32 * M2._22 + M1._33 * M2._32 + M1._34 * M2._42;
    ret._33 = M1._31 * M2._13 + M1._32 * M2._23 + M1._33 * M2._33 + M1._34 * M2._43;
    ret._34 = M1._31 * M2._14 + M1._32 * M2._24 + M1._33 * M2._34 + M1._34 * M2._44;
    ret._41 = M1._41 * M2._11 + M1._42 * M2._21 + M1._43 * M2._31 + M1._44 * M2._41;
    ret._42 = M1._41 * M2._12 + M1._42 * M2._22 + M1._43 * M2._32 + M1._44 * M2._42;
    ret._43 = M1._41 * M2._13 + M1._42 * M2._23 + M1._43 * M2._33 + M1._44 * M2._43;
    ret._44 = M1._41 * M2._14 + M1._42 * M2._24 + M1._43 * M2._34 + M1._44 * M2._44;
    return ret;
}

static Vector3 GetRelativeLocation(long actor) {
    if (!IsValidAddr(actor)) return Vector3();
    long root = UNSIGN_PTR(vm_read<long>(actor + SDK::RootComponent));
    if (!IsValidAddr(root)) return Vector3();
    return vm_read<Vector3>(root + SDK::RelativeLocation);
}

static FTransform GetMatrixConversion(long address) {
    return vm_read<FTransform>(address);
}

// 对标 wasd GetBoneWithRotation：骨索引 5 = 头
static Vector3 GetBoneWithRotation(long staticMesh, int ID, FTransform publicObj) {
    FTransform BoneMatrix = GetMatrixConversion(staticMesh + ID * (int)SDK::BoneTransformSize);
    D3DXMATRIX LocalSkeletonMatrix = ToMatrixWithScale(BoneMatrix.Rotation, BoneMatrix.Translation, BoneMatrix.Scale3D);
    D3DXMATRIX PartTotheWorld = ToMatrixWithScale(publicObj.Rotation, publicObj.Translation, publicObj.Scale3D);
    D3DXMATRIX NewMatrix = MatrixMultiplication(LocalSkeletonMatrix, PartTotheWorld);
    return Vector3(NewMatrix._41, NewMatrix._42, NewMatrix._43);
}

// 对标 wasd Ue4Tool.hpp 骨骼连接表
static const int SkeletonList_61[14][2] = {{6, 5}, {5, 1}, {5, 8}, {8, 9}, {9, 10}, {5, 29}, {29, 30}, {30, 31}, {1, 49}, {49, 50}, {50, 51}, {1, 53}, {53, 54}, {54, 55}};
static const int SkeletonList_63[14][2] = {{6, 5}, {5, 1}, {5, 9}, {9, 10}, {10, 11}, {5, 31}, {31, 32}, {32, 33}, {1, 51}, {51, 52}, {52, 53}, {1, 55}, {55, 56}, {56, 57}};
static const int SkeletonList_64[14][2] = {{6, 5}, {5, 1}, {5, 8}, {8, 9}, {9, 10}, {5, 30}, {30, 31}, {31, 32}, {1, 51}, {51, 52}, {52, 53}, {1, 57}, {57, 58}, {58, 59}};
static const int SkeletonList_65[14][2] = {{6, 5}, {5, 1}, {5, 12}, {12, 13}, {13, 14}, {5, 33}, {33, 34}, {34, 35}, {1, 53}, {53, 54}, {54, 55}, {1, 57}, {57, 58}, {58, 59}};
static const int SkeletonList_70[14][2] = {{28, 5}, {5, 1}, {28, 7}, {7, 8}, {8, 9}, {28, 35}, {35, 36}, {36, 37}, {1, 56}, {56, 57}, {57, 58}, {1, 60}, {60, 61}, {61, 62}};
static const int SkeletonList_72[14][2] = {{6, 5}, {5, 1}, {5, 14}, {14, 15}, {15, 16}, {5, 36}, {36, 37}, {37, 38}, {1, 58}, {58, 59}, {59, 60}, {1, 62}, {62, 63}, {63, 64}};
static const int SkeletonList_95[14][2] = {{6, 5}, {5, 1}, {5, 29}, {29, 30}, {30, 31}, {5, 50}, {50, 51}, {51, 52}, {1, 63}, {63, 64}, {64, 65}, {1, 67}, {67, 68}, {68, 69}};
static const int SkeletonList_73[14][2] = {{6, 5}, {5, 1}, {5, 14}, {14, 15}, {15, 16}, {5, 36}, {36, 37}, {37, 38}, {1, 62}, {62, 63}, {63, 64}, {1, 58}, {58, 59}, {59, 60}};
static const int SkeletonList_Default[14][2] = {{6, 5}, {5, 1}, {5, 12}, {12, 13}, {13, 14}, {5, 34}, {34, 35}, {35, 36}, {1, 56}, {56, 57}, {57, 58}, {1, 60}, {60, 61}, {61, 62}};

static inline const int (*GetSkeletonList(int boneCount))[2] {
    switch (boneCount) {
        case 61: return SkeletonList_61;
        case 63: return SkeletonList_63;
        case 64: return SkeletonList_64;
        case 65: case 66: return SkeletonList_65;
        case 70: case 71: return SkeletonList_70;
        case 72: return SkeletonList_72;
        case 73: return SkeletonList_73;
        case 95: return SkeletonList_95;
        default: return SkeletonList_Default;
    }
}

// 对标 wasd：FString 布局为 Data*(+0) + ArrayNum(+8)；从 Data 读 UTF16
static string GetPlayerName(long player) {
    static std::unordered_map<long, string> nameCache;
    static const size_t kMaxNameCache = 300;
    if (!IsValidAddr(player)) return "";
    auto it = nameCache.find(player);
    if (it != nameCache.end()) return it->second;

    uint64_t data = UNSIGN_PTR(vm_read<uint64_t>(player + SDK::PlayerName));
    if (!IsValidAddr(data)) return "";

    int32_t nameLen = vm_read<int32_t>(player + SDK::PlayerName + 0x8);
    if (nameLen <= 0 || nameLen > 32) nameLen = 16; // wasd 固定读 16 wchar

    char16_t utf16Buf[33] = {0};
    size_t bytes = (size_t)nameLen * sizeof(char16_t);
    if (bytes > sizeof(utf16Buf) - sizeof(char16_t)) bytes = sizeof(utf16Buf) - sizeof(char16_t);
    if (!readMemory(data, utf16Buf, bytes)) return "";

    NSString *str = [[NSString alloc] initWithBytes:utf16Buf
                                             length:bytes
                                           encoding:NSUTF16LittleEndianStringEncoding];
    string n = (str.length > 0) ? string([str UTF8String]) : "";
    if (!n.empty()) {
        if (nameCache.size() > kMaxNameCache) nameCache.clear();
        nameCache[player] = n;
    }
    return n;
}

// 对标 wasd GetClassName：经 GNames 取 Actor 类名（Number 通常为 0x18）
static string GetClassName(uint64_t moduleBase, uintptr_t address, uintptr_t number) {
    static std::unordered_map<uintptr_t, string> cache;
    static const size_t kMaxCache = 300;
    if (!IsValidAddr(moduleBase) || !IsValidAddr(address)) return "";
    auto it = cache.find(address);
    if (it != cache.end()) return it->second;

    char className[256] = {};
    unsigned int index = vm_read<int>(address + number);
    unsigned int block = (index / 0x4000) * 0x8;
    unsigned int offset = (index % 0x4000) * 0x8;
    uintptr_t namePool = UNSIGN_PTR(vm_read<uint64_t>(moduleBase + SDK::GNames));
    if (!IsValidAddr(namePool)) return "";
    uintptr_t namePoolChunk = UNSIGN_PTR(vm_read<uint64_t>(namePool + block));
    if (!IsValidAddr(namePoolChunk)) return "";
    uintptr_t nameEntry = UNSIGN_PTR(vm_read<uint64_t>(namePoolChunk + offset));
    if (!IsValidAddr(nameEntry)) return "";
    if (!readMemory(nameEntry + SDK::NameEntry, className, sizeof(className) - 1)) return "";
    className[sizeof(className) - 1] = '\0';
    string result(className);
    if (!result.empty()) {
        if (cache.size() > kMaxCache) cache.clear();
        cache[address] = result;
    }
    return result;
}

#endif
