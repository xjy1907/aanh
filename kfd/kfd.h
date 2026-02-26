//
//  kfd.h
//  kfd
//
//  Created by 大大 on 2025/7/1.
//

#import <Foundation/Foundation.h>

//! Project version number for kfd.
FOUNDATION_EXPORT double kfdVersionNumber;

//! Project version string for kfd.
FOUNDATION_EXPORT const unsigned char kfdVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <kfd/PublicHeader.h>

#ifdef __cplusplus
extern "C" {
#endif

uint8_t  kread8(uint64_t where);
uint16_t kread16(uint64_t where);
uint32_t kread32(uint64_t where);
uint64_t kread64(uint64_t where);

void kwrite8(uint64_t where, uint8_t what);
void kwrite16(uint64_t where, uint16_t what);
void kwrite32(uint64_t where, uint32_t what);
void kwrite64(uint64_t where, uint64_t what);

int kreadbuf(uint64_t where, void *buf, size_t size);
int kwritebuf(uint64_t where, const void *buf, size_t size);

int exploit_init(const char *flavor);
int exploit_deinit(void);

void kfd_log(const char *format, ...);

#ifdef __cplusplus
}
#endif
