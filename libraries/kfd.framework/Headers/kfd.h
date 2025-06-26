//
//  kfd.h
//  kfd
//
//  Created by Lars Fröder on 11.01.24.
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

/**
 * 初始化 exploit: 这是进行任何内核读写操作前的必要步骤
 *
 * @param flavor flavor: 一个 C 字符串，指定 exploit 的类型。根据 kfd.m 的实现，目前支持的flavor 包括： * "physpuppet" * "smith" * "landa"
 *
 * @return 0：表示初始化成功。-1：表示初始化失败（例如， flavor 参数无效）
 */
int exploit_init(const char *flavor);

/**
 * @brief 去初始化 exploit:  释放相关资源。在完成所有内核操作后，应调用此函数
 *
 * @return 0：表示去初始化成功。-1：表示去初始化失败（例如， gKfd 未初始化）
 */
int exploit_deinit(void);

/**
 * @brief 从内核内存中读取一个8位无符号整数值。
 *
 * 此函数用于从指定的内核地址处读取一个8位无符号整数。通常在进行内核漏洞利用时，用于检查或操作内核空间的数据。
 *
 * @param where 指定要读取的内核地址。
 *
 * @return 返回从内核地址读取到的8位无符号整数值。
 */
uint8_t kread8(uint64_t where);

/**
 * @brief 从内核内存中读取一个16位无符号整数值。
 *
 * @param where 指定要读取的内核地址。
 *
 * @return 返回从内核地址读取到的16位无符号整数值。
 */
uint16_t kread16(uint64_t where);

/**
 * @brief 从内核内存中读取一个32位无符号整数值。
 *
 * @param where 指定要读取的内核地址。
 *
 * @return 返回从内核地址读取到的32位无符号整数值。
 */
uint32_t kread32(uint64_t where);

/**
 * @brief 从内核内存中读取一个64位无符号整数值。
 *
 * @param where 指定要读取的内核地址。
 *
 * @return 返回从内核地址读取到的64位无符号整数值。
 */
uint64_t kread64(uint64_t where);

/**
 * @brief 向内核内存写入一个8位无符号整数值。
 *
 * 此函数用于向指定的内核地址写入一个8位无符号整数。通常用于修改内核数据以实现漏洞利用。
 *
 * @param where 指定要写入的内核地址。
 * @param what  要写入的8位无符号整数值。
 */
void kwrite8(uint64_t where, uint8_t what);

/**
 * @brief 向内核内存写入一个16位无符号整数值。
 *
 * @param where 指定要写入的内核地址。
 * @param what  要写入的16位无符号整数值。
 */
void kwrite16(uint64_t where, uint16_t what);

/**
 * @brief 向内核内存写入一个32位无符号整数值。
 *
 * @param where 指定要写入的内核地址。
 * @param what  要写入的32位无符号整数值。
 */
void kwrite32(uint64_t where, uint32_t what);

/**
 * @brief 向内核内存写入一个64位无符号整数值。
 *
 * @param where 指定要写入的内核地址。
 * @param what  要写入的64位无符号整数值。
 */
void kwrite64(uint64_t where, uint64_t what);

/**
 * @brief 从内核内存中读取一段连续的数据。
 *
 * 此函数用于从指定的内核地址开始，读取一段指定大小的数据，并将其存储到提供的缓冲区中。
 *
 * @param where 指定要读取的内核地址。
 * @param buf   用于存储读取数据的缓冲区。
 * @param size  要读取的数据大小（以字节为单位）。
 *
 * @return 成功时返回0，失败时返回负值错误码。
 */
int kreadbuf(uint64_t where, void *buf, size_t size);

/**
 * @brief 向内核内存写入一段连续的数据。
 *
 * @param where 指定要写入的内核地址。
 * @param buf   包含要写入数据的缓冲区。
 * @param size  要写入的数据大小（以字节为单位）。
 */
int kwritebuf(uint64_t where, const void *buf, size_t size);

#ifdef __cplusplus
}
#endif

