#include "VisibleScene.h"


namespace SceneLoader {
void UpdateSceneByRange()
{
    static uint32_t lastUpdateTimestamp = 0;
    static phmap::flat_hash_map<PrunerPayload, PxTransformT, PrunerPayloadHash> cache {};
    static phmap::flat_hash_set<PrunerPayload> currentSceneObjects {};
    FVector currentPosition = gGameData.cameraLocation + gGameData.WorldOriginLocation;
    static phmap::flat_hash_map<PrunerPayload, uint64_t, PrunerPayloadHash> alwaysCheckShape {};
    std::vector<TriangleMeshData> meshs;
    phmap::flat_hash_set<PrunerPayload> willRemoveObjects {};
    meshs = LoadShapeByRange(
        lastUpdateTimestamp,
        cache,
        currentSceneObjects,
        willRemoveObjects,
        alwaysCheckShape,
        { currentPosition.X, currentPosition.Y, currentPosition.Z },
        300 * 100.f,
        0);

    if (!meshs.empty() || !willRemoveObjects.empty()) {
        gGameData.DynamicLoadScene->UpdateMesh(meshs, willRemoveObjects);
    }
}

void UpdateDynamicRigid()
{
    static phmap::flat_hash_map<PrunerPayload, PxTransformT, PrunerPayloadHash> cache {};
    static phmap::flat_hash_map<PrunerPayload, uint64_t, PrunerPayloadHash> ptrCache {};
    static phmap::flat_hash_set<PrunerPayload> currentSceneObjects {};
    // while (true) {
    // Throttlered.executeTaskWithSleep("DynamicRigidUpdateSleep", std::chrono::milliseconds(300), [&currentSceneObjects, &cache, &ptrCache] {
    FVector currentPosition = gGameData.cameraLocation + gGameData.WorldOriginLocation;
    if (currentPosition.IsNearlyZero()) {
        return;
    }
    phmap::flat_hash_set<PrunerPayload> willRemoveShape {};
#ifdef _PHYSX_DEBUG
    auto start = std::chrono::high_resolution_clock::now();
#endif
    std::vector<TriangleMeshData> Meshs;
    Meshs = LoadDynamicRigidShape(
        currentSceneObjects,
        cache,
        ptrCache,
        willRemoveShape,
        { currentPosition.X, currentPosition.Y, currentPosition.Z },
        gGameData.LoadRadius * 100.f);

    // ImGui::Text("willRemoveShape: %d", (int)willRemoveShape.size());

    // static int n = 0;
    // if (n == 0) {
    //     dynMeshes = Meshs;
    //     n++;
    // }
    if (!Meshs.empty() || !willRemoveShape.empty()) {
#ifdef _PHYSX_DEBUG
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        Utils::Log(1, "Dynamic: Load %d meshs cost %d ms", Meshs.size(), duration.count());
#endif
        gGameData.DynamicRigidScene->UpdateMesh(Meshs, willRemoveShape);
    }
};
// }
void UpdateDynamicHeightField()
{
    static phmap::flat_hash_set<PrunerPayload> UniqueSet {};
    static phmap::flat_hash_set<PrunerPayload> HeightFieldSet {};
    static phmap::flat_hash_set<uint64_t> HeightFieldSamplePtrSet {};
    static uint32_t lastUpdateTimestamp = 0;
    phmap::flat_hash_set<uint64_t> RemoveHeightFieldKey {};
#ifdef _PHYSX_DEBUG
    auto start = std::chrono::high_resolution_clock::now();
#endif
    std::vector<TriangleMeshData> Meshs;
    Meshs = RefreshDynamicLoadHeightField(
        lastUpdateTimestamp, UniqueSet,
        HeightFieldSet,
        HeightFieldSamplePtrSet,
        RemoveHeightFieldKey);

    if (!Meshs.empty() || !RemoveHeightFieldKey.empty()) {
#ifdef _PHYSX_DEBUG
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        Utils::Log(1, "Load %d meshs cost %d ms", Meshs.size(), duration.count());
#endif
        //try {
            gGameData.HeightFieldScene->UpdateMesh(Meshs, RemoveHeightFieldKey);
       // } catch (...) {
       // }

#ifdef _PHYSX_DEBUG
        end = std::chrono::high_resolution_clock::now();
        duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        Utils::Log(3, "Update embree scene cost %d ms", duration.count());
#endif
    }
}
}
