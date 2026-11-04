#pragma once

/**
 * PhysX remote / hardcoded offset for aanh Aim bridge.
 * Default matches wasd MainApplicationDelegate: 0x1086DBA0
 */

#include <cstdint>

extern volatile uint64_t kPhysXPtr;

#ifdef __OBJC__
#import <Foundation/Foundation.h>

namespace PhysXRemote {
// Optional remote fetch stub — hardcoded offset is preferred for aanh.
inline bool fetch() {
    if (kPhysXPtr == 0) {
        kPhysXPtr = 0x1086DBA0;
    }
    return kPhysXPtr != 0;
}
} // namespace PhysXRemote

#else
namespace PhysXRemote {
inline bool fetch() {
    if (kPhysXPtr == 0) {
        kPhysXPtr = 0x1086DBA0;
    }
    return kPhysXPtr != 0;
}
} // namespace PhysXRemote
#endif
