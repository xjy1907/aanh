#import <Foundation/Foundation.h>
#import <IOSurface/IOSurfaceRef.h>
#import <libjailbreak/primitives.h>
#import <libjailbreak/kernel.h>
#import <libjailbreak/util.h>

#ifndef kIOSurfaceCacheMode
#define kIOSurfaceCacheMode CFSTR("IOSurfaceCacheMode")
#endif

// 对齐 Dopamine primitives_IOSurface.m 的 IOSurface_map_withCacheMode。
// aanh 预编译 libjailbreak 无该符号；偏移与 aanh IOSurface_map 一致（iOS16 memoryDescriptor=0x38）。

static mach_port_t IOSurface_map_getSurfacePort(uint64_t magic, uint32_t cacheMode)
{
	IOSurfaceRef surfaceRef = NULL;
	if (cacheMode != 0) {
		surfaceRef = IOSurfaceCreate((__bridge CFDictionaryRef)@{
			(__bridge NSString *)kIOSurfaceWidth : @120,
			(__bridge NSString *)kIOSurfaceHeight : @120,
			(__bridge NSString *)kIOSurfaceBytesPerElement : @4,
			(__bridge NSString *)kIOSurfaceCacheMode : @(cacheMode),
		});
	} else {
		surfaceRef = IOSurfaceCreate((__bridge CFDictionaryRef)@{
			(__bridge NSString *)kIOSurfaceWidth : @120,
			(__bridge NSString *)kIOSurfaceHeight : @120,
			(__bridge NSString *)kIOSurfaceBytesPerElement : @4,
		});
	}
	if (!surfaceRef) return MACH_PORT_NULL;

	mach_port_t port = IOSurfaceCreateMachPort(surfaceRef);
	*((uint64_t *)IOSurfaceGetBaseAddress(surfaceRef)) = magic;
	IOSurfaceDecrementUseCount(surfaceRef);
	CFRelease(surfaceRef);
	return port;
}

int IOSurface_map_withCacheMode(uint64_t pa, uint64_t size, void **uaddr, uint32_t cacheMode)
{
	if (!uaddr || pa == 0 || size == 0) return -1;

	mach_port_t surfaceMachPort = IOSurface_map_getSurfacePort(1337, cacheMode);
	if (!MACH_PORT_VALID(surfaceMachPort)) return -1;

	uint64_t surfaceSendRight = task_get_ipc_port_kobject(task_self(), surfaceMachPort);
	if (!surfaceSendRight) return -1;
	uint64_t surface = kread_ptr(surfaceSendRight + 0x18); // IOSurfaceSendRight_get_surface
	if (!surface) return -1;
	uint64_t desc = kread_ptr(surface + 0x38); // IOSurface_get_memoryDescriptor (iOS16)
	if (!desc) return -1;
	uint64_t ranges = kread_ptr(desc + 0x60); // IOMemoryDescriptor_get_ranges
	if (!ranges) return -1;

	kwrite64(ranges, pa);
	kwrite64(ranges + 8, size);

	kwrite64(desc + 0x50, size); // set_size
	kwrite64(desc + 0x70, 0);
	kwrite64(desc + 0x18, 0);
	kwrite64(desc + 0x90, 0);
	kwrite8(desc + 0x88, true); // set_wired

	uint32_t flags = kread32(desc + 0x20);
	kwrite8(desc + 0x20, (flags & ~0x410) | 0x20); // set_flags
	kwrite64(desc + 0x28, 0); // set_memRef

	IOSurfaceRef mappedSurfaceRef = IOSurfaceLookupFromMachPort(surfaceMachPort);
	if (!mappedSurfaceRef) return -1;
	*uaddr = IOSurfaceGetBaseAddress(mappedSurfaceRef);
	if (!*uaddr) return -1;
	return 0;
}
