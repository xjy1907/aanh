#pragma once

#include <cstdint>
#include <cstddef>
#include <cstring>

// Provided by DrawView.mm (exploit_mach_readbuf wrapper).
extern bool readMemory(uint64_t address, void *buffer, size_t size);

// Module base for PhysX.h `基地址` macro. DrawView / AimPhysXBridge set this.
extern uint64_t gAimModuleBase;

namespace KFD {

inline void SetBase(uint64_t b) { gAimModuleBase = b; }
inline uint64_t Base() { return gAimModuleBase; }

template <typename T>
inline T Read(uint64_t vmAddr, const char *name = nullptr) noexcept {
    (void)name;
    T data{};
    if (vmAddr) {
        readMemory(vmAddr, &data, sizeof(T));
    }
    return data;
}

template <typename T>
inline bool Write(uint64_t vmAddr, const T &value) noexcept {
    // aanh DrawView only exposes readMemory today; Write is a no-op stub
    // so PhysX-adjacent code that expects KFD::Write still links.
    (void)vmAddr;
    (void)value;
    return false;
}

} // namespace KFD

#ifndef 基地址
#define 基地址 (gAimModuleBase)
#endif

// SetBase: use KFD::SetBase(base) (wasd-compatible API). No macro —
// a SetBase(...) macro would recursively expand KFD::SetBase(...).
