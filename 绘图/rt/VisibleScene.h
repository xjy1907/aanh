#ifndef _SCENE_H
#define _SCENE_H
#include <cmath>
#include <cstring>
#include <memory>
#include <mutex>
#include <set>
#include <unordered_map>
#include <vector>
#include <mutex>
#include "Physx.h"
#include "math.h"

//#include "imgui.h"
#include "nanort.h"

namespace Physics {

using namespace std;

static auto prunerPayloadExtractor = [](const TriangleMeshData& mesh) -> PrunerPayload {
    return mesh.UniqueKey1;
};
static auto int64Extractor = [](const TriangleMeshData& mesh) -> uint64_t {
    return mesh.UniqueKey2;
};
static auto normal64Extractor = [](const TriangleMeshData& mesh) -> uint64_t {
    return (uint64_t)rand();
};

struct RayHit {
    bool hit = false;
    float t = FLT_MAX;
    unsigned int prim_id = 0;
    unsigned int mesh_local_tri = 0;
    TriangleMeshData* mesh = nullptr;
};

template <typename T, typename Hash>
class VisibleScene {
public:
    using KeyExtractor = T (*)(const TriangleMeshData&);

    VisibleScene(KeyExtractor keyExtractor)
        : getKey(keyExtractor)
    {
    }

    ~VisibleScene()
    {
        Clear();
    }

    void UpdateMesh(
        const vector<TriangleMeshData>& willAddMeshs,
                    const phmap::flat_hash_set<T>& RemoveKey)
    {
        std::lock_guard<std::mutex> lock(mutex_);
        
        

        if (!mesh_datas.empty()) {
            mesh_datas.erase(
                remove_if(
                    mesh_datas.begin(), mesh_datas.end(),
                    [this, &RemoveKey](const shared_ptr<TriangleMeshData>& mesh) {
                        return RemoveKey.find(this->getKey(*mesh)) != RemoveKey.end();
                    }),
                mesh_datas.end());
        }

        for (const auto& mesh : willAddMeshs) {
            if (mesh.Vertices.empty() || mesh.Indices.empty())
                continue;
            mesh_datas.push_back(std::make_shared<TriangleMeshData>(mesh));
        }

        RebuildGlobalMeshAndBVH_();
    }
    
    

    RayHit Raycast(FVector& origin, const FVector& target)
    {
        std::lock_guard<std::mutex> lock(mutex_);

        RayHit out {};
        if (global_indices_.empty() || !accel_built_) {
            return out;
        }

        float dirx = (target.X - origin.X);
        float diry = (target.Y - origin.Y);
        float dirz = (target.Z - origin.Z);
        float len = std::sqrt(dirx * dirx + diry * diry + dirz * dirz);
        if (len <= 1e-6f)
            return out;

        dirx /= len;
        diry /= len;
        dirz /= len;

        nanort::Ray<float> ray;
        ray.org[0] = origin.X;
        ray.org[1] = origin.Y;
        ray.org[2] = origin.Z;
        ray.dir[0] = dirx;
        ray.dir[1] = diry;
        ray.dir[2] = dirz;
        ray.min_t = 0.0f;
        ray.max_t = len;

        nanort::TriangleIntersector<> tri_isector(global_vertices_.data(), global_indices_.data(), sizeof(float) * 3);
        nanort::TriangleIntersection<> isect;
        nanort::BVHTraceOptions trace_opt;

        bool hit = accel_.Traverse(ray, tri_isector, &isect, trace_opt);
        if (!hit)
            return out;

        out.hit = true;
        out.t = isect.t;
        out.prim_id = tri_isector.prim_id_;

        if (out.prim_id < prim_to_owner_.size()) {
            const auto& owner = prim_to_owner_[out.prim_id];
            out.mesh = owner.mesh;
            out.mesh_local_tri = owner.local_tri_index;
        }
        return out;
    }

    TriangleMeshData* GetGeometryDataByPrim(unsigned int prim_id)
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (prim_id < prim_to_owner_.size()) {
            return prim_to_owner_[prim_id].mesh;
        }
        return nullptr;
    }

    vector<TriangleMeshData*> GetNearMesh(FVector Position, double RadiusSquare) const
    {
        std::lock_guard<std::mutex> lock(mutex_);
        vector<TriangleMeshData*> result;
        for (const auto& m : mesh_datas) {
            auto meshCenter = m->Transform.mPosition;
            Vector3 position { Position.X, Position.Y, Position.Z };
            auto distance = (meshCenter - position).Length2DSquare();
            if (distance <= RadiusSquare)
                result.push_back(m.get());
        }
        return result;
    }

    bool IsBVHReady() const
    {
        std::lock_guard<std::mutex> lock(mutex_);
        return accel_built_;
    }

private:
    struct PrimOwner {
        TriangleMeshData* mesh = nullptr;
        uint32_t local_tri_index = 0;
    };

    void Clear()
    {
        std::lock_guard<std::mutex> lock(mutex_);
        mesh_datas.clear();
        global_vertices_.clear();
        global_indices_.clear();
        prim_to_owner_.clear();
        accel_ = nanort::BVHAccel<float>();
        accel_built_ = false;
    }

    void RebuildGlobalMeshAndBVH_()
    {
        global_vertices_.clear();
        global_indices_.clear();
        prim_to_owner_.clear();
        accel_ = nanort::BVHAccel<float>();
        accel_built_ = false;

        size_t totalVerts = 0, totalIndices = 0;
        for (const auto& m : mesh_datas) {
            totalVerts += m->Vertices.size();
            totalIndices += m->Indices.size();
        }
        global_vertices_.reserve(totalVerts * 3);
        global_indices_.reserve(totalIndices);

        uint32_t baseVertex = 0;
        for (const auto& m : mesh_datas) {
            for (const auto& v : m->Vertices) {
                global_vertices_.push_back(v.X);
                global_vertices_.push_back(v.Y);
                global_vertices_.push_back(v.Z);
            }

            const auto triCount = static_cast<uint32_t>(m->Indices.size() / 3);
            for (size_t i = 0; i < m->Indices.size(); i += 3) {
                global_indices_.push_back(baseVertex + static_cast<uint32_t>(m->Indices[i + 0]));
                global_indices_.push_back(baseVertex + static_cast<uint32_t>(m->Indices[i + 1]));
                global_indices_.push_back(baseVertex + static_cast<uint32_t>(m->Indices[i + 2]));
            }

            uint32_t startPrim = static_cast<uint32_t>(prim_to_owner_.size());
            prim_to_owner_.resize(startPrim + triCount);
            for (uint32_t t = 0; t < triCount; ++t) {
                prim_to_owner_[startPrim + t] = PrimOwner { m.get(), t };
            }
            baseVertex += static_cast<uint32_t>(m->Vertices.size());
        }

        const size_t numFaces = global_indices_.size() / 3;
        if (numFaces == 0) {
            accel_built_ = false;
            return;
        }

        nanort::TriangleMesh<float> triMesh(global_vertices_.data(), global_indices_.data(), sizeof(float) * 3);
        nanort::TriangleSAHPred<float> triPred(global_vertices_.data(), global_indices_.data(), sizeof(float) * 3);
        nanort::BVHBuildOptions<float> options;

        bool ok = accel_.Build(static_cast<unsigned int>(numFaces), triMesh, triPred, options);
        accel_built_ = ok;
    }

private:
    vector<shared_ptr<TriangleMeshData>> mesh_datas;
    vector<float> global_vertices_;
    vector<uint32_t> global_indices_;
    vector<PrimOwner> prim_to_owner_;

    nanort::BVHAccel<float> accel_;
    bool accel_built_ = false;

    KeyExtractor getKey;
    mutable std::mutex mutex_;
};

}
#endif
