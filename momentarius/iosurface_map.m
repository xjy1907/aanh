#import <Foundation/Foundation.h>
#import <IOSurface/IOSurfaceRef.h>
#import <libjailbreak/primitives.h>
#import <libjailbreak/kernel.h>
#import <libjailbreak/util.h>

#ifndef kIOSurfaceCacheMode
#define kIOSurfaceCacheMode CFSTR("IOSurfaceCacheMode")
#endif

// aanh 预编译 libjailbreak 无 IOSurface_map_withCacheMode，在本 framework 内自备实现。
int IOSurface_map_withCacheMode(uint64_t pa, uint64_t size, void **uaddr, uint32_t cacheMode)
{
	if (!uaddr) return -1;

	NSDictionary *props = nil;
	if (cacheMode != 0) {
		props = @{
			(__bridge NSString *)kIOSurfaceWidth : @120,
			(__bridge NSString *)kIOSurfaceHeight : @120,
			(__bridge NSString *)kIOSurfaceBytesPerElement : @4,
			(__bridge NSString *)kIOSurfaceCacheMode : @(cacheMode),
		};
	} else {
		props = @{
			(__bridge NSString *)kIOSurfaceWidth : @120,
			(__bridge NSString *)kIOSurfaceHeight : @120,
			(__bridge NSString *)kIOSurfaceBytesPerElement : @4,
		};
	}

	IOSurfaceRef surfaceRef = IOSurfaceCreate((__bridge CFDictionaryRef)props);
	if (!surfaceRef) return -1;

	mach_port_t surfaceMachPort = IOSurfaceCreateMachPort(surfaceRef);
	*((uint64_t *)IOSurfaceGetBaseAddress(surfaceRef)) = 1337;
	IOSurfaceDecrementUseCount(surfaceRef);
	CFRelease(surfaceRef);

	uint64_t surfaceSendRight = task_get_ipc_port_kobject(task_self(), surfaceMachPort);
	uint64_t surface = kread_ptr(surfaceSendRight + 0x18);
	uint64_t desc = kread_ptr(surface + 0x38);
	uint64_t ranges = kread_ptr(desc + 0x60);

	kwrite64(ranges, pa);
	kwrite64(ranges + 8, size);
	kwrite64(desc + 0x50, size);
	kwrite64(desc + 0x70, 0);
	kwrite64(desc + 0x18, 0);
	kwrite64(desc + 0x90, 0);
	kwrite8(desc + 0x88, true);

	uint32_t flags = kread32(desc + 0x20);
	kwrite8(desc + 0x20, (flags & ~0x410) | 0x20);
	kwrite64(desc + 0x28, 0);

	IOSurfaceRef mappedSurfaceRef = IOSurfaceLookupFromMachPort(surfaceMachPort);
	if (!mappedSurfaceRef) return -1;
	*uaddr = IOSurfaceGetBaseAddress(mappedSurfaceRef);
	return 0;
}
