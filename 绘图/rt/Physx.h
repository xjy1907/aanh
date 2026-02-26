#ifndef PHYSX_H
#define PHYSX_H
#include "GameData.h"
#include "math.h"
#include <functional>
#include <memory>
#include <numeric>
#include <set>
#include <unordered_map>
#include <vector>
#include "MeshPatcher.h"

GameData gGameData;
bool readMemory(mach_vm_address_t address, void *buffer, size_t size);
namespace MemoryUtils {
bool Read(uint64_t address, void* buffer, size_t cnt){
    return readMemory(address, buffer, cnt);
}
template <typename T>
T Read(uint64_t address){
    T o;
    readMemory(address, &o, sizeof(o));
    return o;
}
}
#define __forceinline

enum class PxConcreteType : uint16_t {
    eUNDEFINED,
    
    eHEIGHTFIELD,
    eCONVEX_MESH,
    eTRIANGLE_MESH_BVH33,
    eTRIANGLE_MESH_BVH34,
    eCLOTH_FABRIC,
    
    eRIGID_DYNAMIC,
    eRIGID_STATIC,
    eSHAPE,
    eMATERIAL,
    eCONSTRAINT,
    eCLOTH,
    ePARTICLE_SYSTEM,
    ePARTICLE_FLUID,
    eAGGREGATE,
    eARTICULATION,
    eARTICULATION_LINK,
    eARTICULATION_JOINT,
    ePRUNING_STRUCTURE,
    
    ePHYSX_CORE_COUNT,
    eFIRST_PHYSX_EXTENSION = 256,
    eFIRST_VEHICLE_EXTENSION = 512,
    eFIRST_USER_EXTENSION = 1024
};

enum class PxBaseFlag : uint16_t {
    eOWNS_MEMORY = (1 << 0),
    eIS_RELEASABLE = (1 << 1)
};

enum class PxRigidBodyFlag : uint8_t {
    
    eKINEMATIC = (1 << 0), //!< Enable kinematic mode for the body.
    
    eUSE_KINEMATIC_TARGET_FOR_SCENE_QUERIES = (1 << 1),
    
    eENABLE_CCD = (1 << 2), //!< Enable CCD for the body.
    
    eENABLE_CCD_FRICTION = (1 << 3),
    
    eENABLE_POSE_INTEGRATION_PREVIEW = (1 << 4),
    
    eENABLE_SPECULATIVE_CCD = (1 << 5),
    
    eENABLE_CCD_MAX_CONTACT_IMPULSE = (1 << 6)
};

struct PxMatrix3x3T {
    
    Vector3 column0 {};
    Vector3 column1 {};
    Vector3 column2 {};
    
    PxMatrix3x3T() = default;
    
    __forceinline PxMatrix3x3T(const Vector4& q)
    {
        const float x = q.x;
        const float y = q.y;
        const float z = q.z;
        const float w = q.w;
        
        const float x2 = x + x;
        const float y2 = y + y;
        const float z2 = z + z;
        
        const float xx = x2 * x;
        const float yy = y2 * y;
        const float zz = z2 * z;
        
        const float xy = x2 * y;
        const float xz = x2 * z;
        const float xw = x2 * w;
        
        const float yz = y2 * z;
        const float yw = y2 * w;
        const float zw = z2 * w;
        
        column0 = Vector3(1.0f - yy - zz, xy + zw, xz - yw);
        column1 = Vector3(xy - zw, 1.0f - xx - zz, yz + xw);
        column2 = Vector3(xz + yw, yz - xw, 1.0f - xx - yy);
    }
    
    PxMatrix3x3T(const Vector3& col0, const Vector3& col1, const Vector3& col2)
    : column0(col0)
    , column1(col1)
    , column2(col2)
    {
    }
    
    __forceinline const PxMatrix3x3T getTranspose() const
    {
        const Vector3 v0(column0.X, column1.X, column2.X);
        const Vector3 v1(column0.Y, column1.Y, column2.Y);
        const Vector3 v2(column0.Z, column1.Z, column2.Z);
        
        return PxMatrix3x3T(v0, v1, v2);
    }
    
    __forceinline const Vector3 transform(const Vector3& other) const
    {
        return column0 * other.X + column1 * other.Y + column2 * other.Z;
    }
    
    __forceinline const PxMatrix3x3T operator*(const PxMatrix3x3T& other) const
    {
        // Rows from this <dot> columns from other
        // column0 = transform(other.column0) etc
        return PxMatrix3x3T(transform(other.column0), transform(other.column1), transform(other.column2));
    }
    
    inline const Vector3 operator*(const Vector3& vec) const
    {
        return transform(vec);
    }
};


struct PxsRigidCoreT {
    
    alignas(16) PxTransformT mBodyToWorld {};
    PxRigidBodyFlag Flags {};
    uint8_t m_idt_body_to_actor {};
    uint16_t m_solver_iteration_counts {};
};

struct BodyCoreT {
    char mPad[0x10] {};
    alignas(16) PxsRigidCoreT mCore {};
    alignas(16) PxTransformT mBodyToActor;
};

// rigid base class
struct BodyT {
    uintptr_t mScene {};
    uintptr_t mControlState {};
    uintptr_t mStreamPtr {};
    BodyCoreT mRigid {};
};

// this is actually PxBase
struct PxActorT {
    
    char mPad[0x8] {};
    PxConcreteType mType {};
    PxBaseFlag mBaseFlags {};
    uintptr_t m_user_data {};
};


struct PxGeometryT {
    PxGeometryType mType {};
};

struct PxBoxGeometry : PxGeometryT {
    
    // Half of the width, height, and depth of the box.
    Vector3 mHalfExtents {};
    
    bool valid()
    {
        
        if (mType != PxGeometryType::eBOX)
            return false;
        // if (!halfExtents.isFinite())
        //    return false;
        if (mHalfExtents.X <= 0.0f || mHalfExtents.Y <= 0.0f || mHalfExtents.Z <= 0.0f)
            return false;
        
        return true;
    }
};

struct PxSphereGeometryT : PxGeometryT {
    
    float mRadius {};
    
    bool valid()
    {
        
        if (mType != PxGeometryType::eSPHERE)
            return false;
        // if (!halfExtents.isFinite())
        //    return false;
        if (mRadius <= 0.f)
            return false;
        
        return true;
    }
};

struct PxCapsuleGeometryT : PxGeometryT {
    
    float mRadius {};
    float mHalfHeight {};
    
    bool valid()
    {
        
        if (mType != PxGeometryType::eCAPSULE)
            return false;
        // if (!halfExtents.isFinite())
        //    return false;
        if (mRadius <= 0.f || mHalfHeight <= 0.f)
            return false;
        
        return true;
    }
};

struct PxMeshScale {
public:
    Vector3 transform(const Vector3& v) const
    {
        return rotation.rotateInv(scale.multiply(rotation.rotate(v)));
    }
    
    Vector3 scale; //!< A nonuniform scaling
    Vector4 rotation; //!< The orientation of the scaling axes
};

struct CenterExtentsT {
    
    Vector3 mCenter {};
    Vector3 mExtents {};
};

struct PxPlaneT {
    
    Vector3 n {};
    float d {};
};

struct HullPolygonDataT {
    
    PxPlaneT mPlane; //!< Plane equation for this polygon    //Could drop 4th elem as it can be computed from any vertex as: d = - p.dot(n);
    uint16_t mVRef8; //!< Offset of vertex references in hull vertex data (CS: can we assume indices are tightly packed and offsets are ascending?? DrawObjects makes and uses this assumption)
    uint8_t mNbVerts; //!< Number of vertices/edges in the polygon
    uint8_t mMinIndex; //!< Index of the polygon vertex that has minimal projection along this plane's normal.
};

template <typename storageType, storageType bitMask>
class PxBitAndDataT {
public:
    //__forceinline PxBitAndDataT(const PxEMPTY)
    //{
    //}
    __forceinline PxBitAndDataT()
    : mData(0)
    {
    }
    __forceinline PxBitAndDataT(storageType data, bool bit = false)
    {
        mData = bit ? storageType(data | bitMask) : data;
    }
    
    __forceinline operator storageType() const
    {
        return storageType(mData & ~bitMask);
    }
    __forceinline void setBit()
    {
        mData |= bitMask;
    }
    __forceinline void clearBit()
    {
        mData &= ~bitMask;
    }
    __forceinline storageType isBitSet() const
    {
        return storageType(mData & bitMask);
    }
    
protected:
    storageType mData;
};
typedef PxBitAndDataT<unsigned char, 0x80> PxBitAndByte;
typedef PxBitAndDataT<unsigned short, 0x8000> PxBitAndWord;
typedef PxBitAndDataT<unsigned int, 0x80000000> PxBitAndDword;

struct ConvexHullDataT {
    
    CenterExtentsT mAABB {};
    Vector3 m_center_of_mass {};
    PxBitAndWord mNbEdges {};
    uint8_t HullVerticesNb {};
    uint8_t PolygonsNb {};
    HullPolygonDataT* mPolygons {};
    
    __forceinline const Vector3* getHullVertices() const //!< Convex hull vertices
    {
        
        const char* tmp = reinterpret_cast<const char*>(mPolygons);
        tmp += sizeof(HullPolygonDataT) * PolygonsNb;
        return reinterpret_cast<const Vector3*>(tmp);
    }
    
    __forceinline const uint8_t* getVertexData8() const //!< Vertex indices indexed by hull polygons
    {
        const char* tmp = reinterpret_cast<const char*>(mPolygons);
        tmp += sizeof(HullPolygonDataT) * PolygonsNb;
        tmp += sizeof(Vector3) * HullVerticesNb;
        tmp += sizeof(uint8_t) * mNbEdges * 2;
        tmp += sizeof(uint8_t) * HullVerticesNb * 3;
        if (mNbEdges.isBitSet())
            tmp += sizeof(uint16_t) * mNbEdges * 2;
        return reinterpret_cast<const uint8_t*>(tmp);
    }
    
    __forceinline const uint8_t* getIndexBuffer() const
    {
        
        int64_t v1; // r10
        const char* result; // rax
        
        v1 = mNbEdges & 0x7FFF;
        result = reinterpret_cast<const char*>(mPolygons) + 15 * HullVerticesNb + 2 * v1;
        if ((mNbEdges & 0x8000u) != 0)
            result += 4 * v1;
        return reinterpret_cast<const uint8_t*>(result);
    }
    
    __forceinline const uint8_t* getFacesByEdges8() const //!< for each edge, gives 2 adjacent polygons; used by convex-convex code to come up with all the convex' edge normals.
    {
        
        const char* tmp = reinterpret_cast<const char*>(mPolygons);
        tmp += 20 * PolygonsNb;
        tmp += 12 * HullVerticesNb;
        return reinterpret_cast<const uint8_t*>(tmp);
    }
    
    __forceinline const uint8_t* getFacesByVertices8() const //!< for each edge, gives 2 adjacent polygons; used by convex-convex code to come up with all the convex' edge normals.
    {
        
        const char* tmp = reinterpret_cast<const char*>(mPolygons);
        tmp += 20 * PolygonsNb;
        tmp += 12 * HullVerticesNb;
        tmp += 1 * mNbEdges * 2;
        return reinterpret_cast<const uint8_t*>(tmp);
    }
};

struct PxConvexMeshT {
};

struct ConvexMeshT : PxConvexMeshT {
    
    char mPad[0x8] {};
    PxConcreteType mType {};
    PxBaseFlag mBaseFlags {};
    uintptr_t mRefCountableVfptr {};
    int32_t mRefCount {};
    ConvexHullDataT HullData {};
    uint32_t mNb {};
};

struct PxConvexMeshGeometryT : PxGeometryT {
    
    PxMeshScale Scale {};
    ConvexMeshT* ConvexMesh {};
    float mMaxMargin {};
    uint8_t mMeshFlags {};
    char mFlagPad[0x3] {};
};

struct TriangleMeshT {
    
    char mPad[0x8] {};
    PxConcreteType mType {};
    PxBaseFlag mBaseFlags {};
    uintptr_t mRefCountableVfptr {};
    uint32_t mRefCount {};
    uint32_t mNbVertices {};
    uint32_t mNbTriangles {};
    Vector3* Vertices {};
    void* mTriangles {};
    CenterExtentsT mAABB {};
    uint8_t* mExtraTrigData {};
    float mGeomEpsilon {};
    uint8_t Flags {};
};

struct PxTriangleMeshGeometryT : PxGeometryT {
    
    PxMeshScale Scale {};
    uint8_t mMeshFlags {};
    char mFlagPad[0x3] {};
    TriangleMeshT* mTriangleMesh {};
};

struct PxHeightFieldSampleT {
    
    int16_t mHeight {};
    PxBitAndByte mMaterialIndex0 {};
    PxBitAndByte mMaterialIndex1 {};
};

struct HeightFieldDataT {
    CenterExtentsT mAABB {};
    uint32_t Rows {};
    uint32_t Columns {};
    float mRowLimit {};
    float mColumnLimit {};
    float mNbColumns {};
    PxHeightFieldSampleT* mSamples {};
    float mThickness {};
    float mConvexEdgeThreshold {};
    uint16_t mFlags {};
    uint8_t mFormat {};
};

struct HeightFieldT {
    
    char mPad[0x8] {};
    PxConcreteType mType {};
    PxBaseFlag mBaseFlags {};
    uintptr_t mRefCountableVfptr {};
    int64_t mRefCount {};
    HeightFieldDataT mData {};
    uint32_t mSampleStride {};
    uint32_t mNbSamples {};
    float mMinHeight {};
    float mMaxHeight {};
    int32_t mModifyCount {};
    void* mMeshFactory {};
};

struct PxHeightFieldGeometryT : PxGeometryT {
    
    HeightFieldT* mHeightField {};
    float HeightScale {};
    float RowScale {};
    float ColumnScale {};
    int8_t Flags {};
    char mFlagPad[0x3] {};
};

struct GeometryUnionT {
    
    union {
        void* alignment; // PT: Makes sure the class is at least aligned to pointer size. See DE6803.
        uint8_t box[16];
        uint8_t sphere[8];
        uint8_t capsule[12];
        uint8_t plane[4];
        uint8_t convex[64];
        uint8_t mesh[80];
        uint8_t heightfield[56];
        uint8_t invalid[4];
    } mGeometry;
    
    __forceinline PxGeometryType getType() const { return reinterpret_cast<const PxGeometryT&>(mGeometry).mType; }
};

struct PxShapeCoreT {
    
    alignas(16) PxTransformT transform;
    float contactOffset;
    uint8_t mShapeFlags; // !< API shape flags    // PT: TODO: use PxShapeFlags here. Needs to move flags to separate file.
    uint8_t mOwnsMaterialIdxMemory; // PT: for de-serialization to avoid deallocating material index list. Moved there from Sc::ShapeCore (since one byte was free).
    uint16_t materialIndex;
    GeometryUnionT geometry;
};

struct ShapeCoreT {
    
    FilterDataT QueryFilterData {};
    FilterDataT SimulationFilterData {};
    alignas(16) PxShapeCoreT mCore {};
    float mRestOffset {};
    
    __forceinline PxGeometryType getGeometryType() const { return mCore.geometry.getType(); }
    __forceinline const PxTransformT getShape2Actor() const { return mCore.transform; }
};

struct ShapeT {
    
    uintptr_t mScene {};
    uint32_t mControlState {};
    uintptr_t mStreamPtr {};
    
    ShapeCoreT ShapeCore {};
    
    __forceinline const PxGeometryT& GetGeometry() const { return reinterpret_cast<const PxGeometryT&>(ShapeCore.mCore.geometry.mGeometry); }
};

struct PxBounds3 {
    Vector3 min, max;
};

struct PruningPoolT {
    uint32_t mNbObjects;
    uint32_t mMaxNbObjects;
    PxBounds3* mWorldBoxes;
    PrunerPayload* mObjects;
};

struct PrunerExtT {
    uintptr_t mPruner;
    char mPad[0x24] {};
    uint32_t mTimestamp;
};

struct NpSceneT {
    PrunerExtT exts[2];
};

struct ShapeDataT {
    ShapeT Shape {};
    BodyT Actor {};
    PxGeometryType mType {};
    
    uint8_t m_shape_flags {};
    
    PxMeshScale Scale {};
    
    PrunerPayload UniqueKey;
    
    // ConvexData
    ConvexMeshT ConvexMesh {};
    std::vector<HullPolygonDataT> polygons {};
    std::vector<uint8_t> ConvexIndices {};
    
    // TriangleData
    std::vector<uint32_t> Indices {};
    std::vector<uint16_t> SmallIndices {};
    TriangleMeshT TriangleMesh {};
    
    // ConvexData & TriangleData
    std::vector<Vector3> Vertices {};
    
    // HeightFieldData
    std::vector<PxHeightFieldSampleT> mSamples {};
    HeightFieldT mHeightField {};
};

template <typename T>
void AddReadVecScatter(int hScatter, uintptr_t address, size_t size, std::vector<T>* vec)
{
    if (!size)
        return;
    
    vec->resize(size);
    
    MemoryUtils::Read(address, vec->data(), sizeof(T) * size);
}

template <typename T>
std::vector<T> ReadVec(uintptr_t address, size_t size, size_t custom_type_size = 0)
{
    std::vector<T> temp {};
    
    if (!size)
        return temp;
    
    temp.resize(custom_type_size ? custom_type_size : size);
    
    MemoryUtils::Read(address, &temp[0], custom_type_size ? custom_type_size : sizeof(T) * size);
    
    return temp;
}



template <class _Pr>
__forceinline std::vector<TriangleMeshData> GetMeshData(
                                                        std::vector<PrunerPayload>& objects,
                                                        _Pr filter,
                                                        bool isDynamic = false,
                                                        bool autoTransform = true)
{
    std::vector<ShapeDataT> ShapeDatas {};
    std::vector<TriangleMeshData> TriangleMeshDatas {};
    auto hScatter = 0;
    
    ShapeDatas.resize(objects.size());
    
    // Using index iteration instead of reference
    for (size_t i = 0; i < objects.size(); i++) {
        auto obj = objects[i];
        ShapeDatas[i].UniqueKey = obj;
        MemoryUtils::Read(obj.Shape, &ShapeDatas[i].Shape, sizeof(ShapeT));
        MemoryUtils::Read(obj.Actor, &ShapeDatas[i].Actor, sizeof(BodyT));
    }
    // mem.ExecuteReadScatter(hScatter);
    auto WorldLocation = gGameData.WorldOriginLocation;
    
#ifdef _PHYSX_DEBUG
    Utils::Log(1, "Number of objects: %d", objects.size());
#endif
    
    for (auto& ShapeData : ShapeDatas) {
        ShapeData.m_shape_flags = ShapeData.Shape.ShapeCore.mCore.mShapeFlags;
        ShapeData.mType = ShapeData.Shape.ShapeCore.getGeometryType();
    }
    
    // Filter
    ShapeDatas.erase(
                     std::remove_if(ShapeDatas.begin(), ShapeDatas.end(), filter),
                     ShapeDatas.end());
    
    for (auto& ShapeData : ShapeDatas) {
        if (ShapeData.mType == PxGeometryType::eHEIGHTFIELD) {
            PxHeightFieldGeometryT field_geometry = (PxHeightFieldGeometryT&)ShapeData.Shape.GetGeometry();
            MemoryUtils::Read((uintptr_t)field_geometry.mHeightField, &ShapeData.mHeightField, sizeof(HeightFieldT));
            // mem.AddScatterReadRequest(hScatter, (uintptr_t)field_geometry.mHeightField, &ShapeData.mHeightField, sizeof(HeightFieldT));
        } else if (ShapeData.mType == PxGeometryType::eCONVEXMESH) {
            PxConvexMeshGeometryT convex_geometry = (PxConvexMeshGeometryT&)ShapeData.Shape.GetGeometry();
            MemoryUtils::Read((uintptr_t)convex_geometry.ConvexMesh, &ShapeData.ConvexMesh, sizeof(ConvexMeshT));
            // mem.AddScatterReadRequest(hScatter, (uintptr_t)convex_geometry.ConvexMesh, &ShapeData.ConvexMesh, sizeof(ConvexMeshT));
        }
    }
    
    // mem.ExecuteReadScatter(hScatter);
    
#ifdef _PHYSX_DEBUG
    Utils::Log(1, "Number of ShapeDatas after filtering: %d", ShapeDatas.size());
#endif
    
    for (auto& shapeData : ShapeDatas)
        
    {
        if (shapeData.mType == PxGeometryType::eCONVEXMESH) {
            auto nbPolygons = shapeData.ConvexMesh.HullData.PolygonsNb;
            
            auto mPolygons = (uintptr_t)shapeData.ConvexMesh.HullData.mPolygons;
            auto size = sizeof(HullPolygonDataT);
            shapeData.polygons.resize(nbPolygons);
            
            for (uint32_t i = 0; i < nbPolygons; i++) {
                MemoryUtils::Read(mPolygons + (i * size), &shapeData.polygons[i], sizeof(HullPolygonDataT));
            }
        }
    }
    
    // mem.ExecuteReadScatter(hScatter);
    
    for (auto& ShapeData : ShapeDatas) {
        if (ShapeData.mType == PxGeometryType::eCONVEXMESH) {
            uint32_t indices_number = std::accumulate(ShapeData.polygons.begin(), ShapeData.polygons.end(), 0u,
                                                      [](uint32_t sum, const HullPolygonDataT& polygon) {
                return sum + polygon.mNbVerts;
            });
            ShapeData.ConvexIndices.reserve(indices_number);
            AddReadVecScatter<uint8_t>(hScatter, (uintptr_t)ShapeData.ConvexMesh.HullData.getVertexData8(), indices_number, &ShapeData.ConvexIndices);
        } else if (ShapeData.mType == PxGeometryType::eTRIANGLEMESH) {
            const PxTriangleMeshGeometryT& triangle_geometry = (PxTriangleMeshGeometryT&)ShapeData.Shape.GetGeometry();
            ShapeData.Scale = triangle_geometry.Scale;
            MemoryUtils::Read((uintptr_t)triangle_geometry.mTriangleMesh, &ShapeData.TriangleMesh, sizeof(TriangleMeshT));
        }
    }
    
    for (auto& ShapeData : ShapeDatas) {
        if (ShapeData.mType == PxGeometryType::eTRIANGLEMESH) {
            bool has16BitIndices = (ShapeData.TriangleMesh.Flags & 2U) ? true : false;
            
            AddReadVecScatter(hScatter, (uintptr_t)ShapeData.TriangleMesh.Vertices, ShapeData.TriangleMesh.mNbVertices, &ShapeData.Vertices);
            
            if (has16BitIndices) {
                AddReadVecScatter(hScatter, (uintptr_t)ShapeData.TriangleMesh.mTriangles, ShapeData.TriangleMesh.mNbTriangles * 3, &ShapeData.SmallIndices);
            } else {
                AddReadVecScatter(hScatter, (uintptr_t)ShapeData.TriangleMesh.mTriangles, ShapeData.TriangleMesh.mNbTriangles * 3, &ShapeData.Indices);
            }
        } else if (ShapeData.mType == PxGeometryType::eHEIGHTFIELD) {
            const uint32_t nb = ShapeData.mHeightField.mNbSamples;
            AddReadVecScatter(hScatter, (uintptr_t)ShapeData.mHeightField.mData.mSamples, nb, &ShapeData.mSamples);
        } else if (ShapeData.mType == PxGeometryType::eCONVEXMESH) {
            AddReadVecScatter(hScatter, (uintptr_t)ShapeData.ConvexMesh.HullData.getHullVertices(), (size_t)ShapeData.ConvexMesh.HullData.HullVerticesNb, &ShapeData.Vertices);
        }
    }
    
    // #pragma omp parallel for
    for (int i = 0; i < ShapeDatas.size(); i++) {
        auto& ShapeData = ShapeDatas[i];
        if (ShapeData.mType == PxGeometryType::eTRIANGLEMESH && !ShapeData.SmallIndices.empty()) {
            const size_t size = ShapeData.SmallIndices.size();
            ShapeData.Indices.resize(size);
            
            std::transform(
                           ShapeData.SmallIndices.begin(),
                           ShapeData.SmallIndices.end(),
                           ShapeData.Indices.begin(),
                           [](uint16_t val) { return static_cast<uint32_t>(val); });
            
            ShapeData.SmallIndices.clear();
            ShapeData.SmallIndices.shrink_to_fit();
        }
    }
    
    // #pragma omp parallel for
    for (int i = 0; i < ShapeDatas.size(); i++) {
        const auto& ShapeDataItem = ShapeDatas[i];
        
        PxTransformT GlobalPose {};
        if (isDynamic) {
            GlobalPose = ShapeDataItem.Actor.mRigid.mCore.mBodyToWorld * ShapeDataItem.Actor.mRigid.mBodyToActor.getInverse();
        } else {
            GlobalPose = ShapeDataItem.Actor.mRigid.mCore.mBodyToWorld;
        }
        auto LocalPose = ShapeDataItem.Shape.ShapeCore.mCore.transform;
        auto CombinePose = GlobalPose * LocalPose;
        CombinePose.mPosition = CombinePose.mPosition + WorldLocation;
        auto UniqueKey = ShapeDataItem.UniqueKey;
        
        if (ShapeDataItem.mType == PxGeometryType::eBOX) {
            const PxBoxGeometry& boxGeometry = (PxBoxGeometry&)ShapeDataItem.Shape.GetGeometry();
            
            auto halfExtents = boxGeometry.mHalfExtents;
            
            Vector3 vertices[8];
            
            vertices[0] = Vector3(-halfExtents.X, -halfExtents.Y, -halfExtents.Z);
            vertices[1] = Vector3(halfExtents.X, -halfExtents.Y, -halfExtents.Z);
            vertices[2] = Vector3(halfExtents.X, halfExtents.Y, -halfExtents.Z);
            vertices[3] = Vector3(-halfExtents.X, halfExtents.Y, -halfExtents.Z);
            vertices[4] = Vector3(-halfExtents.X, -halfExtents.Y, halfExtents.Z);
            vertices[5] = Vector3(halfExtents.X, -halfExtents.Y, halfExtents.Z);
            vertices[6] = Vector3(halfExtents.X, halfExtents.Y, halfExtents.Z);
            vertices[7] = Vector3(-halfExtents.X, halfExtents.Y, halfExtents.Z);
            
            if (autoTransform) {
                for (int i = 0; i < 8; i++) {
                    vertices[i] = CombinePose.transform(vertices[i]);
                }
            }
            
            // Box indices for triangles
            uint32_t indices[] = {
                // Front face
                0, 1, 2,
                0, 2, 3,
                // Back face
                4, 6, 5,
                4, 7, 6,
                // Top face
                0, 4, 5,
                0, 5, 1,
                // Bottom face
                2, 6, 7,
                2, 7, 3,
                // Right face
                0, 3, 7,
                0, 7, 4,
                // Left face
                1, 5, 6,
                1, 6, 2
            };
            
            TriangleMeshData mesh_data {};
            mesh_data.Vertices.assign(vertices, vertices + 8);
            mesh_data.Indices.assign(indices, indices + 36);
            mesh_data.Flags = ShapeDataItem.m_shape_flags;
            mesh_data.QueryFilterData = ShapeDataItem.Shape.ShapeCore.QueryFilterData;
            mesh_data.SimulationFilterData = ShapeDataItem.Shape.ShapeCore.SimulationFilterData;
            mesh_data.UniqueKey1 = UniqueKey;
            mesh_data.Type = PxGeometryType::eBOX;
            mesh_data.Transform = CombinePose;
            
            // #pragma omp critical
            {
                TriangleMeshDatas.push_back(mesh_data);
            }
        } else if (ShapeDataItem.mType == PxGeometryType::eTRIANGLEMESH) {
            TriangleMeshData MeshData {};
            PxMeshScale ScaleVal = ShapeDataItem.Scale;
            
            const size_t vertexCount = ShapeDataItem.Vertices.size();
            MeshData.Vertices.resize(vertexCount);
            
            for (size_t i = 0; i < vertexCount; i++) {
                Vector3& vertex = MeshData.Vertices[i];
                vertex = ScaleVal.transform(ShapeDataItem.Vertices[i]);
                if (autoTransform) {
                    vertex = CombinePose.transform(vertex);
                }
            }
            
            MeshData.Indices = ShapeDataItem.Indices;
            MeshData.Flags = ShapeDataItem.m_shape_flags;
            MeshData.QueryFilterData = ShapeDataItem.Shape.ShapeCore.QueryFilterData;
            MeshData.SimulationFilterData = ShapeDataItem.Shape.ShapeCore.SimulationFilterData;
            MeshData.UniqueKey1 = UniqueKey;
            MeshData.Type = PxGeometryType::eTRIANGLEMESH;
            MeshData.Transform = CombinePose;
            
            // #pragma omp critical
            {
                TriangleMeshDatas.push_back(MeshData);
            }
        } else if (ShapeDataItem.mType == PxGeometryType::eHEIGHTFIELD) {
            PxHeightFieldGeometryT field_geometry = (PxHeightFieldGeometryT&)ShapeDataItem.Shape.GetGeometry();
            
            auto NumRows = ShapeDataItem.mHeightField.mData.Rows;
            auto NumColumns = ShapeDataItem.mHeightField.mData.Columns;
            auto ColumnScale = field_geometry.ColumnScale;
            auto RowScale = field_geometry.RowScale;
            auto HeightScale = field_geometry.HeightScale;
            
            TriangleMeshData MeshData {};
            
            if (NumRows == 0 || NumColumns == 0 || ShapeDataItem.mSamples.empty()) {
                // fix unsign int
                continue;
            }
            
            for (uint32_t row = 0; row < NumRows - 1; row++) {
                for (uint32_t col = 0; col < NumColumns - 1; col++) {
                    uint32_t idx00 = row * NumColumns + col;
                    uint32_t idx10 = idx00 + 1;
                    uint32_t idx01 = idx00 + NumColumns;
                    uint32_t idx11 = idx01 + 1;
                    
                    auto sample00 = ShapeDataItem.mSamples[idx00];
                    auto sample10 = ShapeDataItem.mSamples[idx10];
                    auto sample01 = ShapeDataItem.mSamples[idx01];
                    auto sample11 = ShapeDataItem.mSamples[idx11];
                    Vector3 v00, v10, v01, v11;
                    v00 = { row * RowScale, sample00.mHeight * HeightScale, col * ColumnScale };
                    v10 = { row * RowScale, sample10.mHeight * HeightScale, (col + 1) * ColumnScale };
                    v01 = { (row + 1) * RowScale, sample01.mHeight * HeightScale, col * ColumnScale };
                    v11 = { (row + 1) * RowScale, sample11.mHeight * HeightScale, (col + 1) * ColumnScale };
                    
                    if (autoTransform) {
                        v00 = CombinePose.transform(v00);
                        v10 = CombinePose.transform(v10);
                        v01 = CombinePose.transform(v01);
                        v11 = CombinePose.transform(v11);
                    }
                    
                    MeshData.Vertices.push_back(v00);
                    MeshData.Vertices.push_back(v10);
                    MeshData.Vertices.push_back(v01);
                    MeshData.Vertices.push_back(v11);
                    
                    size_t base_idx = (row * (NumColumns - 1) + col) * 4;
                    
                    MeshData.Indices.push_back(base_idx);
                    MeshData.Indices.push_back(base_idx + 1);
                    MeshData.Indices.push_back(base_idx + 2);
                    
                    MeshData.Indices.push_back(base_idx + 1);
                    MeshData.Indices.push_back(base_idx + 3);
                    MeshData.Indices.push_back(base_idx + 2);
                }
            }
            
            MeshData.Flags = ShapeDataItem.m_shape_flags;
            MeshData.QueryFilterData = ShapeDataItem.Shape.ShapeCore.QueryFilterData;
            MeshData.SimulationFilterData = ShapeDataItem.Shape.ShapeCore.SimulationFilterData;
            MeshData.UniqueKey1 = UniqueKey;
            MeshData.UniqueKey2 = (uint64_t)((PxHeightFieldGeometryT&)ShapeDataItem.Shape.GetGeometry()).mHeightField;
            MeshData.Type = PxGeometryType::eHEIGHTFIELD;
            MeshData.Transform = CombinePose;
            
            // #pragma omp critical
            {
                TriangleMeshDatas.push_back(MeshData);
            }
            
        } else if (ShapeDataItem.mType == PxGeometryType::eCONVEXMESH) {
            
            // PxConvexMeshGeometryT convex_geometry = (PxConvexMeshGeometryT&)ShapeDataItem.Shape.GetGeometry();
            const PxMeshScale ScaleVal = ShapeDataItem.Scale;
            // const uint8_t nbVertices = ShapeDataItem.ConvexMesh.HullData.HullVerticesNb;
            // const uint8_t nbPolygons = ShapeDataItem.ConvexMesh.HullData.PolygonsNb;
            TriangleMeshData MeshData {};
            
            MeshData.Vertices = ShapeDataItem.Vertices;
            const size_t vertexCount = MeshData.Vertices.size();
            
            for (size_t i = 0; i < vertexCount; i++) {
                MeshData.Vertices[i] = ScaleVal.transform(MeshData.Vertices[i]);
                if (autoTransform) {
                    MeshData.Vertices[i] = CombinePose.transform(ScaleVal.transform(MeshData.Vertices[i]));
                }
            }
            for (const auto& polygon : ShapeDataItem.polygons) {
                for (uint16_t j = 0; j < polygon.mNbVerts - 2; j++) {
                    
                    uint32_t index_idx0 = polygon.mVRef8 + 0;
                    uint32_t index_idx1 = polygon.mVRef8 + j + 1;
                    uint32_t index_idx2 = polygon.mVRef8 + j + 2;
                    
                    if (index_idx0 >= ShapeDataItem.ConvexIndices.size() || index_idx2 >= ShapeDataItem.ConvexIndices.size()) {
                        continue;
                    }
                    uint32_t idx0 = ShapeDataItem.ConvexIndices[index_idx0];
                    uint32_t idx1 = ShapeDataItem.ConvexIndices[index_idx1];
                    uint32_t idx2 = ShapeDataItem.ConvexIndices[index_idx2];
                    
                    MeshData.Indices.push_back(idx0);
                    MeshData.Indices.push_back(idx1);
                    MeshData.Indices.push_back(idx2);
                }
            }
            
            MeshData.Flags = ShapeDataItem.m_shape_flags;
            MeshData.QueryFilterData = ShapeDataItem.Shape.ShapeCore.QueryFilterData;
            MeshData.SimulationFilterData = ShapeDataItem.Shape.ShapeCore.SimulationFilterData;
            MeshData.UniqueKey1 = UniqueKey;
            MeshData.Type = PxGeometryType::eCONVEXMESH;
            MeshData.Transform = CombinePose;
            
            if (MeshData.QueryFilterData.word3 > 100) {
                // #pragma omp critical
                {
                    TriangleMeshDatas.push_back(MeshData);
                }
            }
        }
    }
    
//    for (auto& meshData : TriangleMeshDatas) {
//        MeshPatcher::GetInstance()->PatchMesh(meshData);
//    }
    
    return TriangleMeshDatas;
}

__forceinline std::vector<TriangleMeshData> LoadDynamicRigidShape(
                                                                  phmap::flat_hash_set<PrunerPayload>& currentSceneObjects,
                                                                  phmap::flat_hash_map<PrunerPayload, PxTransformT, PrunerPayloadHash>& cache,
                                                                  phmap::flat_hash_map<PrunerPayload, uint64_t, PrunerPayloadHash>& ptrCache,
                                                                  phmap::flat_hash_set<PrunerPayload>& willRemoveObjects,
                                                                  Vector3 currentPosition,
                                                                  double radius)
{
    auto px_scene_arr_ptr = MemoryUtils::Read<uint64_t>(gGameData.PhysInstancePtr + 0x8);
    auto px_scene_ptr = MemoryUtils::Read<uint64_t>(px_scene_arr_ptr);
    auto scene = MemoryUtils::Read<NpSceneT>(px_scene_ptr + 0x2430);
    auto pruner = MemoryUtils::Read<PruningPoolT>(scene.exts[1].mPruner + 0x1F90);
    std::vector<PrunerPayload> mObjects = ReadVec<PrunerPayload>((uintptr_t)pruner.mObjects, pruner.mNbObjects);
    
    phmap::flat_hash_set<uint64_t> queryActor {};
    for (const auto& obj : mObjects) {
        queryActor.insert(obj.Actor);
    }
    
    phmap::flat_hash_map<uint64_t, BodyT> actorPos {};
    phmap::flat_hash_map<uint64_t, ShapeT> shapePos {};
    actorPos.reserve(queryActor.size());
    shapePos.reserve(mObjects.size());
    
    for (const auto& actor : queryActor) {
        actorPos[actor] = {};
        MemoryUtils::Read(actor, &actorPos[actor], sizeof(BodyT));
        // mem.AddScatterReadRequest(hScatter, actor, &actorPos[actor], sizeof(BodyT));
    }
    for (const auto& obj : mObjects) {
        shapePos[obj.Shape] = {};
        MemoryUtils::Read(obj.Shape, &shapePos[obj.Shape], sizeof(ShapeT));
        // mem.AddScatterReadRequest(hScatter, obj.Shape, &shapePos[obj.Shape], sizeof(ShapeT));
    }
    // mem.ExecuteReadScatter(hScatter);
    // mem.CloseScatterHandle(hScatter);
    
    phmap::flat_hash_set<PrunerPayload> removeObjects {};
    std::vector<PrunerPayload> addObjects {};
    for (const auto& obj : mObjects) {
        auto& body = actorPos[obj.Actor];
        auto& shape = shapePos[obj.Shape];
        PxTransformT GlobalPose = (body.mRigid.mCore.mBodyToWorld * body.mRigid.mBodyToActor.getInverse()) * shape.ShapeCore.mCore.transform;
        GlobalPose.mPosition = GlobalPose.mPosition + gGameData.WorldOriginLocation;
        auto it = cache.find(obj);
        if (it != cache.end()) {
            if (!it->second.IsNearlyEqual(GlobalPose)) {
                // Transform change, remove it;
                currentSceneObjects.erase(obj);
                willRemoveObjects.insert(obj);
            }
        }
        cache[obj] = GlobalPose;
        auto ptrIt = ptrCache.find(obj);
        auto trianglePtr = (uint64_t)((PxTriangleMeshGeometryT&)shape.GetGeometry()).mTriangleMesh;
        if (ptrIt != ptrCache.end()) {
            if (ptrIt->second != trianglePtr) {
                // ptr change, remove it.
                currentSceneObjects.erase(obj);
                willRemoveObjects.insert(obj);
            }
        }
        ptrCache[obj] = trianglePtr;
    }
    
    // delete cache expire shape
    phmap::flat_hash_set<PrunerPayload> mObjectsSet(mObjects.begin(), mObjects.end());
    for (auto it = cache.begin(); it != cache.end();) {
        if (mObjectsSet.find(it->first) == mObjectsSet.end()) {
            it = cache.erase(it);
        } else {
            ++it;
        }
    }
    for (auto it = ptrCache.begin(); it != ptrCache.end();) {
        if (mObjectsSet.find(it->first) == mObjectsSet.end()) {
            it = ptrCache.erase(it);
        } else {
            ++it;
        }
    }
    
    double radiusSquare = radius * radius;
    
    phmap::flat_hash_set<PrunerPayload> result;
    for (const auto& [obj, pos] : cache) {
        if ((pos.mPosition - currentPosition).Length2DSquare() < radiusSquare) {
            result.insert(obj);
        }
    }
    
    std::copy_if(currentSceneObjects.begin(), currentSceneObjects.end(), std::inserter(removeObjects, removeObjects.begin()),
                 [&result](const PrunerPayload& obj) { return result.find(obj) == result.end(); });
    
    std::copy_if(
                 result.begin(), result.end(), std::back_inserter(addObjects),
                 [&currentSceneObjects](const PrunerPayload& obj) {
                     return currentSceneObjects.find(obj) == currentSceneObjects.end();
                 });
    
    for (const auto& obj : removeObjects) {
        currentSceneObjects.erase(obj);
        willRemoveObjects.insert(obj);
    }
    
    for (const auto& obj : addObjects) {
        currentSceneObjects.insert(obj);
    }
    
    return GetMeshData(
                       addObjects,
                       [](const ShapeDataT& shape_data) {
                           PxGeometryType type = shape_data.mType;
                           return type != PxGeometryType::eTRIANGLEMESH;
                       },
                       true);
}
/// <summary>
/// Refresh current Game Height Field and compare with history ptr
/// Note: Don't filter HeightField ptr, because HeightField edit internal ptr not recreate HeightField
/// </summary>
/// <param name="lastTimestamp"></param>
/// <param name="UniqueKeySet"></param>
/// <param name="HeightFieldSet">Height field shape ptr</param>
/// <param name="HeightFieldSamplePtrSet">Internal ptr for filtering in height field</param>
/// <param name="RemoveHeightFieldKey">Should Remove Height Field</param>
/// <returns></returns>
__forceinline std::vector<TriangleMeshData> RefreshDynamicLoadHeightField(
                                                                          uint32_t& lastTimestamp,
                                                                          phmap::flat_hash_set<PrunerPayload>& UniqueKeySet,
                                                                          phmap::flat_hash_set<PrunerPayload>& HeightFieldSet,
                                                                          phmap::flat_hash_set<uint64_t>& HeightFieldSamplePtrSet,
                                                                          phmap::flat_hash_set<uint64_t>& RemoveHeightFieldKey)
{
    auto px_scene_arr_ptr = MemoryUtils::Read<uint64_t>(gGameData.PhysInstancePtr + 0x8);
    auto px_scene_ptr = MemoryUtils::Read<uint64_t>(px_scene_arr_ptr);
    auto scene = MemoryUtils::Read<NpSceneT>(px_scene_ptr + 0x2430);
    
    if (lastTimestamp - scene.exts->mTimestamp < 1000) {
        return std::vector<TriangleMeshData> {};
    }
    lastTimestamp = scene.exts->mTimestamp;
    
    auto pruner = MemoryUtils::Read<PruningPoolT>(scene.exts[0].mPruner + 0x1F90);
    //auto dynamicPruner = MemoryUtils::Read<PruningPoolT>(scene.exts[1].mPruner + 0x1F90);
    std::vector<PrunerPayload> mObjects = ReadVec<PrunerPayload>((uintptr_t)pruner.mObjects, pruner.mNbObjects);
    phmap::flat_hash_set<PrunerPayload> newUnionKeySet(mObjects.begin(), mObjects.end());
    std::vector<PrunerPayload> newObjects;
    
    std::copy_if(mObjects.begin(), mObjects.end(), std::back_inserter(newObjects),
                 [&UniqueKeySet, &HeightFieldSet](const PrunerPayload& obj) {
        // if current ptr not contains or current ptr is height field, load it data!
        return UniqueKeySet.find(obj) == UniqueKeySet.end() || HeightFieldSet.find(obj) != HeightFieldSet.end();
    });
    //NSLog(@"DH666 newObjects %zu", newObjects.size());
    if (newObjects.size() < 1000) {
        return std::vector<TriangleMeshData>{};
    }
    
    UniqueKeySet.insert(newObjects.begin(), newObjects.end());
    
    phmap::flat_hash_set<PrunerPayload> RemoveKey {};
    
    std::set_difference(UniqueKeySet.begin(), UniqueKeySet.end(),
                        newUnionKeySet.begin(), newUnionKeySet.end(),
                        std::inserter(RemoveKey, RemoveKey.begin()));
    
    for (const auto& key : RemoveKey) {
        UniqueKeySet.erase(key);
    }

    
    phmap::flat_hash_set<uint64_t> currentHeightFieldPtrSet {};
    
    auto result = GetMeshData(
                              newObjects,
                              [&HeightFieldSamplePtrSet, &currentHeightFieldPtrSet, &HeightFieldSet](const ShapeDataT& shape_data) {
                                  PxGeometryType type = shape_data.mType;
                                  if (type == PxGeometryType::eHEIGHTFIELD)
                                  {
                                      PxHeightFieldGeometryT field_geometry = (PxHeightFieldGeometryT&)shape_data.Shape.GetGeometry();
                                      HeightFieldSet.insert(shape_data.UniqueKey);
                                      //NSLog(@"RowScale %f", field_geometry.RowScale);
                                      // vaild height field, add current height field
                                      //NSLog(@"DH666 RowScale %f", field_geometry.RowScale);
                                      if (field_geometry.RowScale == 200.f) {
                                          auto ptr = (uintptr_t)field_geometry.mHeightField;
                                          currentHeightFieldPtrSet.insert(ptr);
                                          return !HeightFieldSamplePtrSet.insert(ptr).second;
                                      }
                                      // filter fuzzy height field
                                      return true;
                                  }
                                  return true;
                              }
                              );
    
    std::set_difference(HeightFieldSamplePtrSet.begin(), HeightFieldSamplePtrSet.end(),
                        currentHeightFieldPtrSet.begin(), currentHeightFieldPtrSet.end(),
                        std::inserter(RemoveHeightFieldKey, RemoveHeightFieldKey.begin()));
    
    for (const auto& key : RemoveHeightFieldKey) {
        HeightFieldSamplePtrSet.erase(key);
    }
    
    return result;
}

/// <summary>
/// Load shape by range
/// </summary>
/// <param name="cache">Cache of shape position</param>
/// <param name="currentSceneObjects">Current embree scene objects</param>
/// <param name="willRemoveObjects">Will remove objects from embree scene</param>
/// <param name="currentPosition">Current position</param>
/// <param name="radius">Radius</param>
/// <param name="limit">Limit</param>
/// <param name="isDynamic">Is dynamic rigid</param>
// 函数功能：
// 通过当前位置与半径范围动态加载场景中的 Shape（形状/网格数据），并根据时间戳和缓存机制优化性能。
// 同时更新缓存对象、需要移除的对象、需要重新加载的对象。
// 返回需要新加载的 TriangleMeshData 网格数据。
__forceinline std::vector<TriangleMeshData> LoadShapeByRange(
                                                             uint32_t& lastTimestamp,   // 上一次的场景时间戳
                                                             phmap::flat_hash_map<PrunerPayload, PxTransformT, PrunerPayloadHash>& cache, // 缓存的对象及其位姿
                                                             phmap::flat_hash_set<PrunerPayload>& currentSceneObjects, // 当前加载在场景中的对象集合
                                                             phmap::flat_hash_set<PrunerPayload>& willRemoveObjects,   // 即将被移除的对象集合
                                                             phmap::flat_hash_map<PrunerPayload, uint64_t, PrunerPayloadHash>& alwaysCheckShape, // 需要持续检测变化的形状缓存
                                                             Vector3 currentPosition,   // 当前加载中心坐标
                                                             double radius,             // 加载半径范围
                                                             uint32_t limit = 200       // 阈值限制（变化数量小于该值时不更新）
)
{
    // 获取 PxScene 实例（物理场景的指针）
    auto px_scene_arr_ptr = MemoryUtils::Read<uint64_t>(gGameData.PhysInstancePtr + 0x8);
    auto px_scene_ptr = MemoryUtils::Read<uint64_t>(px_scene_arr_ptr);
    
    // 读取 NpScene 结构体（用于访问物理场景的扩展信息）
    auto scene = MemoryUtils::Read<NpSceneT>(px_scene_ptr + 0x2430);  //PxScene::addActors(): Actor already assigned to a scene. Call will be ignored。搜看  (*(void (__fastcall **)(_QWORD, __int64 *))(**(_QWORD **)(a1 + 0x2430) + 40LL))(*(_QWORD *)(a1 + 0x2430), &v52);
    
    // 防止频繁更新：
    // 如果当前场景的时间戳与上次更新时间戳差值小于 1000（单位可视为毫秒），则跳过更新。
    if (lastTimestamp - scene.exts->mTimestamp < 1000) {
        return std::vector<TriangleMeshData> {};
    }
    
    lastTimestamp = scene.exts->mTimestamp;
    
    // 读取 PruningPool（物理裁剪池，存放当前物理世界中的对象）
    auto pruner = MemoryUtils::Read<PruningPoolT>(scene.exts[0].mPruner + 0x1F90);////SqAABBPruner 搜 第二个
    
    // 读取物理对象数组（所有被管理的物理对象）
    std::vector<PrunerPayload> mObjects = ReadVec<PrunerPayload>((uintptr_t)pruner.mObjects, pruner.mNbObjects);
    
    // 计算需要查询的新对象（缓存中没有的对象）
    phmap::flat_hash_set<PrunerPayload> queryObjects {};
    phmap::flat_hash_set<PrunerPayload> mObjectsSet(mObjects.begin(), mObjects.end());
    for (const auto& obj : mObjectsSet) {
        if (cache.find(obj) == cache.end()) {
            queryObjects.insert(obj);
        }
    }
    
    // 收集这些新对象对应的 Actor 指针（物理实体）
    phmap::flat_hash_set<uint64_t> queryActor {};
    for (const auto& obj : queryObjects) {
        queryActor.insert(obj.Actor);
    }
    
    // 为所有 actor 和 shape 分配内存并读取对应的结构体数据
    phmap::flat_hash_map<uint64_t, BodyT> actorPos {};
    phmap::flat_hash_map<uint64_t, ShapeT> shapePos {};
    actorPos.reserve(queryActor.size());
    shapePos.reserve(queryObjects.size());
    
    // 读取 Actor 的物理数据（BodyT）
    for (const auto& actor : queryActor) {
        actorPos[actor] = {};
        MemoryUtils::Read(actor, &actorPos[actor], sizeof(BodyT));
    }
    
    // 读取 Shape 的物理数据（ShapeT）
    for (const auto& obj : queryObjects) {
        shapePos[obj.Shape] = {};
        MemoryUtils::Read(obj.Shape, &shapePos[obj.Shape], sizeof(ShapeT));
    }
    
    // 根据 Actor + Shape 的信息计算全局位置（变换矩阵）
    for (const auto& obj : queryObjects) {
        auto& body = actorPos[obj.Actor];
        auto& shape = shapePos[obj.Shape];
        PxTransformT GlobalPose = body.mRigid.mCore.mBodyToWorld * shape.ShapeCore.mCore.transform;
        GlobalPose.mPosition = GlobalPose.mPosition + gGameData.WorldOriginLocation; // 加上世界偏移量
        cache[obj] = GlobalPose; // 缓存结果
    }
    
    // 清除已不存在于场景中的对象
    for (auto it = cache.begin(); it != cache.end();) {
        if (mObjectsSet.find(it->first) == mObjectsSet.end()) {
            it = cache.erase(it);
        } else {
            ++it;
        }
    }
    
    // 计算范围内的对象（距离当前坐标小于加载半径）
    double radiusSquare = radius * radius;
    phmap::flat_hash_set<PrunerPayload> result;
    for (const auto& [obj, pos] : cache) {
        if ((pos.mPosition - currentPosition).Length2DSquare() < radiusSquare) {
            result.insert(obj);
        }
    }
    
    // 计算需要移除的对象（之前有，现在不在范围内）
    phmap::flat_hash_set<PrunerPayload> removeObjects {};
    std::copy_if(currentSceneObjects.begin(), currentSceneObjects.end(), std::inserter(removeObjects, removeObjects.begin()),
                 [&result](const PrunerPayload& obj) {
        return result.find(obj) == result.end();
    });
    
    // 计算需要新增的对象（范围内但之前没有加载）
    std::vector<PrunerPayload> addObjects {};
    std::copy_if(result.begin(), result.end(), std::back_inserter(addObjects),
                 [&currentSceneObjects, &alwaysCheckShape](const PrunerPayload& obj) {
        // 如果是新出现的对象，或者是需要持续检查的对象，则加入加载列表
        return currentSceneObjects.find(obj) == currentSceneObjects.end() || alwaysCheckShape.find(obj) != alwaysCheckShape.end();
    });
    
    // 如果变化数量太少（小于 limit），则不更新
    if (removeObjects.size() + addObjects.size() < limit) {
        return std::vector<TriangleMeshData> {};
    }
    
    // 更新场景集合：移除无效对象
    for (const auto& obj : removeObjects) {
        currentSceneObjects.erase(obj);
        alwaysCheckShape.erase(obj);
        willRemoveObjects.insert(obj);
    }
    
    // 加入新对象
    for (const auto& obj : addObjects) {
        currentSceneObjects.insert(obj);
    }
    
    // 生成这些新增对象的网格数据
    auto res = GetMeshData(
                           addObjects,
                           [&alwaysCheckShape, &willRemoveObjects, &currentSceneObjects](const ShapeDataT& shape_data) {
                               PxGeometryType type = shape_data.mType;
                               uint8_t Flags = shape_data.m_shape_flags;
                               auto queryFlag = shape_data.Shape.ShapeCore.QueryFilterData;
                               
                               // 过滤掉非 TRIANGLEMESH 类型或无效物体
                               if (queryFlag.word0 > 0uLL && queryFlag.word2 > 0uLL) {
                                   if (type != PxGeometryType::eTRIANGLEMESH) {
                                       willRemoveObjects.insert(shape_data.UniqueKey);
                                       currentSceneObjects.erase(shape_data.UniqueKey);
                                       return true;
                                   }
                                   
                                   // 检查是否为可破坏的墙体（breakable wall）
                                   auto findRes = alwaysCheckShape.find(shape_data.UniqueKey);
                                   auto trianglePtr = (uint64_t)((PxTriangleMeshGeometryT&)shape_data.Shape.GetGeometry()).mTriangleMesh;
                                   
                                   // 第一次记录形状指针
                                   if (findRes == alwaysCheckShape.end()) {
                                       alwaysCheckShape.insert({ shape_data.UniqueKey, trianglePtr });
                                   } else {
                                       // 如果三角形网格未变化，则过滤掉（无需更新）
                                       if (findRes->second == trianglePtr) {
                                           return true;
                                       } else {
                                           // 如果变化了，则更新并标记重新加载
                                           alwaysCheckShape[shape_data.UniqueKey] = trianglePtr;
                                           willRemoveObjects.insert(shape_data.UniqueKey);
                                           currentSceneObjects.erase(shape_data.UniqueKey);
                                           return false;
                                       }
                                   }
                               }
                               
                               // 排除非 TRIANGLEMESH 类型或禁用标志的物体
                               return type != PxGeometryType::eTRIANGLEMESH || ((Flags & 2) == 0 && (Flags & 1) == 0);
                           });
    
    // 返回生成的网格数据
    return res;
}
#endif
