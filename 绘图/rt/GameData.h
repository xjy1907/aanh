#ifndef _GAME_DATA_H
#define _GAME_DATA_H
#include "../UE4Tool.hpp"
#include <functional>
#include <iostream>
#include "parallel_hashmap/phmap.h"
namespace Physics {
template <typename T, typename Hash>
class VisibleScene;
}
struct PrunerPayload {
    uintptr_t Shape;
    uintptr_t Actor;

    bool operator==(const PrunerPayload& other) const
    {
        return Shape == other.Shape && Actor == other.Actor;
    }

    bool operator<(const PrunerPayload& other) const
    {
        if (Shape != other.Shape)
            return Shape < other.Shape;
        return Actor < other.Actor;
    }
};

struct PrunerPayloadHash {
    size_t operator()(const PrunerPayload& p) const
    {
        return std::hash<uintptr_t>()(p.Shape) ^ (std::hash<uintptr_t>()(p.Actor) << 1);
    }
};
struct Int64Hash {
    size_t operator()(const uint64_t& p) const
    {
        return std::hash<uint64_t>()(p);
    }
};

struct PxTransformT {
    Vector4 mRotation {};
    Vector3 mPosition {};
    
    PxTransformT() = default;
    
    PxTransformT(const Vector4& rotation, const Vector3& position)
    : mRotation(rotation)
    , mPosition(position)
    {
    }
    
    // Transform a vector using the transform's rotation and translation
    Vector3 transform(const Vector3& input) const
    {
        // return toMatrix().Transform(input);
        return mRotation.rotate(input) + mPosition;
    }
    
    PxTransformT operator*(const PxTransformT& other) const
    {
        Vector4 newRotation = mRotation * other.mRotation;
        Vector3 newPosition = mRotation.rotate(other.mPosition) + mPosition;
        return PxTransformT(newRotation, newPosition);
    }
    
    bool isNearlyZero(float value, float epsilon = 1e-6f)
    {
        return fabs(value) < epsilon;
    }
    
    PxTransformT getInverse() const
    {
        Vector4 invRotation = mRotation.conjugate();
        Vector3 invPosition = mRotation.rotateInv(-mPosition);
        return PxTransformT(invRotation, invPosition);
    }
    
    bool IsNearlyEqual(const PxTransformT& other, float tolerance = 0.1f) const
    {
        return mRotation.IsNearlyEqual(other.mRotation, tolerance) && mPosition.IsNearlyEqual(other.mPosition, tolerance);
    }
};

struct FilterDataT {
    uint32_t word0;
    uint32_t word1;
    uint32_t word2;
    uint32_t word3;
};

enum class PxGeometryType : int32_t {
    
    eSPHERE, // 0
    ePLANE, // 1
    eCAPSULE, // 2
    eBOX, // 3
    eCONVEXMESH, // 4
    eTRIANGLEMESH, // 5
    eHEIGHTFIELD, // 6
    
    eGEOMETRY_COUNT, //!< internal use only!
    eINVALID = -1 //!< internal use only!
};

struct TriangleMeshData {
    std::vector<Vector3> Vertices {};
    std::vector<uint32_t> Indices {};
    uint8_t Flags {};
    FilterDataT QueryFilterData {};
    FilterDataT SimulationFilterData {};
    PrunerPayload UniqueKey1;
    uint64_t UniqueKey2;
    PxGeometryType Type {};
    PxTransformT Transform;
};

struct GameData {
    uint64_t GameBase;
    uint64_t GName;
    uint64_t PhysInstancePtr;
    struct FVector WorldOriginLocation;
    
    FVector cameraLocation;
    FVector forward;
    Physics::VisibleScene<PrunerPayload, PrunerPayloadHash>* DynamicLoadScene;
    Physics::VisibleScene<PrunerPayload, PrunerPayloadHash>* DynamicRigidScene;
    Physics::VisibleScene<uint64_t, Int64Hash>* HeightFieldScene;
    float LoadRadius = 300.f;
};

#endif
