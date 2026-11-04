//
//  Ue4Tool.hpp — minimal types for PhysX.h LineTrace (Vector3)
//  Reuses aanh 绘制类型.h Vector3 to avoid duplicate definitions.
//

#ifndef Ue4Tool_hpp
#define Ue4Tool_hpp

#include <cmath>
#include "../游戏/绘制类型.h"

// PhysX.h LineTrace uses Vector3.X/Y/Z; 绘制类型.h already defines Vector3.
// Add Size() if missing (inline to avoid ODR issues in headers).
#ifndef AANH_UE4TOOL_VECTOR3_SIZE
#define AANH_UE4TOOL_VECTOR3_SIZE
inline float Vector3_Size(const Vector3 &v) {
    return std::sqrt((v.X * v.X) + (v.Y * v.Y) + (v.Z * v.Z));
}
#endif

// TArray is defined inside PhysX.h itself; nothing else from wasd Ue4Tool is required.

#endif /* Ue4Tool_hpp */
