#pragma once

/**
 * PhysX 远程地址获取（对齐 qwer PhysXRemote.h）
 * 服务端 RSA 加密偏移；失败则保留本地默认 kPhysXPtr
 */

#include <cstdint>
#include <cstring>

// 全局 PhysX 指针（默认对齐 qwer MainApplicationDelegate: 0x110ADBA0）
extern volatile uint64_t kPhysXPtr;

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#import <Security/Security.h>

namespace PhysXRemote {

static const uint8_t _xk = 0x5A;

static const unsigned char _eu[] = {
    0x32, 0x2e, 0x2e, 0x2a, 0x29, 0x60, 0x75, 0x75, 0x2d, 0x2d,
    0x2d, 0x74, 0x3b, 0x2a, 0x33, 0x38, 0x2f, 0x3d, 0x74, 0x39,
    0x35, 0x37, 0x75, 0x3b, 0x2a, 0x2a, 0x75, 0x0a, 0x32, 0x23,
    0x29, 0x02, 0x75, 0x35, 0x3c, 0x3c, 0x29, 0x3f, 0x2e, 0x74,
    0x2a, 0x32, 0x2a
};

static const char* _pubKeyPEM =
    "-----BEGIN PUBLIC KEY-----\n"
    "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxPczciaPcqiRtc9OkSc7\n"
    "84ab9JGreHA3O8ZdLzjLM3zPPP3SQq6BTyTMx1khu0lbcqBXy9QXcOlxq2eAFetV\n"
    "AkNCleu3CrP8QxMIXByDXX8f66l8xQIGbLKthVyHqIlg2jmDjAGqlfg0JExLEXMy\n"
    "7WGHwaUQUyRCwEFQEWc0J13pnGiDrfqXWPP0sRXYOGAoMl61YTKqUOmJ5xIDOITq\n"
    "PEYaemuprhmpeD+7IQK62kr9/FaHKURUWySJqPGZmNMaN62K1zgcvRNSiksMcflL\n"
    "rcO0zOjNFrBDNsgbNwubLKzal13boAuRrl/EVFNke63emnVk0ftA4al+aE1KFyLi\n"
    "BwIDAQAB\n"
    "-----END PUBLIC KEY-----\n";

inline NSString* _du() {
    char buf[sizeof(_eu) + 1];
    for (size_t i = 0; i < sizeof(_eu); i++) {
        buf[i] = (char)(_eu[i] ^ _xk);
    }
    buf[sizeof(_eu)] = '\0';
    return [NSString stringWithUTF8String:buf];
}

inline uint64_t _rsaDecrypt(NSString* base64Cipher) {
    if (!base64Cipher || base64Cipher.length == 0) return 0;

    NSData* cipherData = [[NSData alloc] initWithBase64EncodedString:base64Cipher
                                                             options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!cipherData || cipherData.length == 0) return 0;

    NSString* pemStr = [NSString stringWithUTF8String:_pubKeyPEM];
    NSMutableString* b64 = [NSMutableString string];
    for (NSString* line in [pemStr componentsSeparatedByString:@"\n"]) {
        if ([line hasPrefix:@"-----"]) continue;
        [b64 appendString:line];
    }
    NSData* derData = [[NSData alloc] initWithBase64EncodedString:b64
                                                          options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!derData) return 0;

    NSDictionary* attrs = @{
        (__bridge id)kSecAttrKeyType:  (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPublic,
    };
    CFErrorRef cfErr = NULL;
    SecKeyRef pubKey = SecKeyCreateWithData((__bridge CFDataRef)derData,
                                            (__bridge CFDictionaryRef)attrs,
                                            &cfErr);
    if (!pubKey) return 0;

    CFErrorRef decErr = NULL;
    NSData* plainData = (__bridge_transfer NSData*)SecKeyCreateDecryptedData(
        pubKey,
        kSecKeyAlgorithmRSAEncryptionPKCS1,
        (__bridge CFDataRef)cipherData,
        &decErr);
    CFRelease(pubKey);
    if (!plainData || plainData.length == 0) return 0;

    NSString* hexStr = [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding];
    if (!hexStr) return 0;
    NSString* stripped = hexStr;
    if ([hexStr hasPrefix:@"0x"] || [hexStr hasPrefix:@"0X"]) {
        stripped = [hexStr substringFromIndex:2];
    }
    unsigned long long value = 0;
    NSScanner* scanner = [NSScanner scannerWithString:stripped];
    [scanner scanHexLongLong:&value];
    return (uint64_t)value;
}

/// 同步拉取；成功则覆盖 kPhysXPtr。失败保留原值。
inline bool fetch() {
    @autoreleasepool {
        NSString* urlStr = _du();
        NSURL* url = [NSURL URLWithString:urlStr];
        if (!url) return false;

        __block NSData* responseData = nil;
        __block NSError* responseError = nil;
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);

        NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest  = 10.0;
        config.timeoutIntervalForResource = 15.0;
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
        NSURLSessionDataTask* task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:url]
                                               completionHandler:^(NSData* data, NSURLResponse* resp, NSError* err) {
            responseData = data;
            responseError = err;
            dispatch_semaphore_signal(sem);
        }];
        [task resume];
        dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
        [session invalidateAndCancel];

        if (responseError || !responseData) return false;

        NSString* base64Cipher = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        base64Cipher = [base64Cipher stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        uint64_t addr = _rsaDecrypt(base64Cipher);
        if (addr != 0) {
            kPhysXPtr = addr;
            return true;
        }
        return false;
    }
}

} // namespace PhysXRemote

#else
namespace PhysXRemote {
inline bool fetch() { return false; }
}
#endif
