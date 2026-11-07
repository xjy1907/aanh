// Empty FORCE_LOAD stubs so the linker does NOT pull
// libswiftCompatibility51/56/Concurrency from the toolchain.
// Required for iOS 15 launch when Xcode 16 may still emit FORCE_LOAD refs.

.section __DATA,__data
.globl ___swift_FORCE_LOAD_$_swiftCompatibility51
___swift_FORCE_LOAD_$_swiftCompatibility51:
    .long 0

.globl ___swift_FORCE_LOAD_$_swiftCompatibility56
___swift_FORCE_LOAD_$_swiftCompatibility56:
    .long 0

.globl ___swift_FORCE_LOAD_$_swiftCompatibilityConcurrency
___swift_FORCE_LOAD_$_swiftCompatibilityConcurrency:
    .long 0
