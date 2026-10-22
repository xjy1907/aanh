//
//  绘制类型.h - 无畏契约数据结构
//

#ifndef 绘制类型_h
#define 绘制类型_h

#define PAC_MASK 0x0000FFFFFFFFFFFFULL
#define UNSIGN_PTR(p) ((uint64_t)(p) & PAC_MASK)

static inline bool IsValidAddr(uint64_t address) {
    return address > 0x10000000ULL && address < 0x0000FFFFFFFFFFFFULL;
}

struct Vector2 {
    float X, Y;
    Vector2() : X(0), Y(0) {}
    Vector2(float x, float y) : X(x), Y(y) {}
};

struct Vector3 {
    float X, Y, Z;
    Vector3() : X(0), Y(0), Z(0) {}
    Vector3(float x, float y, float z) : X(x), Y(y), Z(z) {}
    Vector3 operator-(const Vector3 &v) const { return Vector3(X - v.X, Y - v.Y, Z - v.Z); }
};

struct Vector4 { float x, y, z, w; };
struct VectorRect { int x, y, w, h; };
struct FRotator { float Pitch, Yaw, Roll; };

// 对标 wasd CoViewbyo：Location(0x0)+Local(0xC)+Rot(0x18)+ViewTag(0x24,0xC)+FOV(0x30)
struct CoViewInfo {
    Vector3 Location;
    Vector3 LocationLocalSpace;
    FRotator Rotation;
    char ViewTag[0xC];
    float FOV;
};

struct FMatrix {
    float Matrix[4][4];
    float *operator[](int index) { return Matrix[index]; }
};

struct D3DXMATRIX {
    float _11, _12, _13, _14;
    float _21, _22, _23, _24;
    float _31, _32, _33, _34;
    float _41, _42, _43, _44;
};

// 对标 wasd：Rotation(16)+Translation(12)+Padding(4)+Scale3D(12)
struct FTransform {
    Vector4 Rotation;
    Vector3 Translation;
    float Padding;
    Vector3 Scale3D;
};

#endif
