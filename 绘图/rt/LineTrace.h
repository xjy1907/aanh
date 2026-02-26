#include "GameData.h"
#include "VisibleScene.h"
namespace LineTrace{
    enum TraceFlags{
        QUICK_TRACE,
        CLOSEST_TRACE
    };

//Physics::RayHit Raycast(FVector &origin, const FVector &target){
//    Physics::RayHit hit1, hit2, hit3;
//    hit1 = gGameData.DynamicRigidScene->Raycast(origin, target);
//    hit2 = gGameData.DynamicLoadScene->Raycast(origin, target);
//    hit3 = gGameData.HeightFieldScene->Raycast(origin, target);
//    Physics::RayHit& best = hit1.t < hit2.t ? hit1:hit2;
//    best = best.t < hit3.t ? best : hit3;
//    return best;
//}

Physics::RayHit Raycast(FVector &origin, const FVector &target) {
    Physics::RayHit hit1, hit2;
    hit1 = gGameData.DynamicRigidScene->Raycast(origin, target);
    hit2 = gGameData.DynamicLoadScene->Raycast(origin, target);

    // 取 t 值较小的那个命中结果
    return (hit1.t < hit2.t) ? hit1 : hit2;
}

//Physics::RayHit Raycast(FVector &origin, const FVector &target){
//    Physics::RayHit hit1, hit2, hit3;
//    //hit1 = gGameData.DynamicRigidScene->Raycast(origin, target);
//    //hit2 = gGameData.DynamicLoadScene->Raycast(origin, target);
//    hit3 = gGameData.HeightFieldScene->Raycast(origin, target);
//    //Physics::RayHit& best = hit1.t < hit2.t ? hit1:hit2;
//    //best = best.t < hit3.t ? best : hit3;
//    return hit3;
//}

    Physics::RayHit RaycastQuick(FVector &origin, const FVector &target){
        Physics::RayHit hit;
        hit = gGameData.DynamicLoadScene->Raycast(origin, target);
        if (hit.hit) {
            return hit;
        }
        hit = gGameData.HeightFieldScene->Raycast(origin, target);
        if (hit.hit) {
            return hit;
        }
        hit = gGameData.DynamicRigidScene->Raycast(origin, target);
        if (hit.hit) {
            return hit;
        }
        return hit;
    }



};
