//
//  绘制算法.h - 无畏契约坐标转换算法
//

#ifndef 绘制算法_h
#define 绘制算法_h

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

static string GetPlayerName(long player) {
    string n = "";
    if (!IsValidAddr(player)) return n;
    uint64_t namePtr = UNSIGN_PTR(vm_read<uint64_t>(player + SDK::PlayerName));
    if (!IsValidAddr(namePtr)) return n;
    
    uint32_t nameLen = vm_read<uint32_t>(namePtr + 0x8);
    if (nameLen <= 0 || nameLen > 64) return n;
    
    uint64_t nameData = namePtr + 0xC;
    char16_t utf16Buf[64] = {0};
    readMemory(nameData, utf16Buf, nameLen * 2);
    
    NSString *str = [[NSString alloc] initWithBytes:utf16Buf length:nameLen * 2 encoding:NSUTF16LittleEndianStringEncoding];
    if (str) n = [str UTF8String];
    return n;
}

#endif
