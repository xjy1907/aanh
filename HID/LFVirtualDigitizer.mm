
#import "LFVirtualDigitizer.h"
#import <CoreFoundation/CoreFoundation.h>
#import <os/log.h>

// 私有 HID 头
#include "IOHIDEvent.h"
#include "IOHIDEventTypes.h"
#include "IOHIDEventSystemClient.h"
#include "IOHIDService.h"
#import "IOHIDUserDevice.h"

NS_ASSUME_NONNULL_BEGIN

// 前置声明
static void EnsureUserDevice(void);

// file‑static 全局
static IOHIDUserDeviceRef g_device = NULL;
static NSTimer *g_timer = nil;
static BOOL g_isDown = NO;

#pragma mark - 发报告（单点）

static inline void sendTouch(IOHIDUserDeviceRef device, bool touching, int contactID, float x, float y) {
    if (!device) return;

    // clamp
    if (x < 0) x = 0; if (x > 1) x = 1;
    if (y < 0) y = 0; if (y > 1) y = 1;

    uint16_t xi = (uint16_t)lrintf(x * 32767.0f);
    uint16_t yi = (uint16_t)lrintf(y * 32767.0f);

    // 与描述符匹配：ReportID=1，总长7字节
    uint8_t report[7] = {0};
    report[0] = 0x01;                      // Report ID
    report[1] = touching ? 0x03 : 0x00;    // TipSwitch|InRange
    report[2] = (uint8_t)(contactID & 0x7F);
    report[3] = (uint8_t)(xi & 0xFF);
    report[4] = (uint8_t)((xi >> 8) & 0xFF);
    report[5] = (uint8_t)(yi & 0xFF);
    report[6] = (uint8_t)((yi >> 8) & 0xFF);

    IOReturn ret = IOHIDUserDeviceHandleReport(device, report, sizeof(report));
    if (ret != kIOReturnSuccess) {
        os_log_error(OS_LOG_DEFAULT, "IOHIDUserDevice handle report failed: 0x%08x", ret);
    } else {
        os_log(OS_LOG_DEFAULT, "IOHIDUserDevice report ok (touching=%d)", touching);
    }
}

static inline void touchDown(int slot, float x, float y) { sendTouch(g_device, true,  slot, x, y); }
static inline void touchMove(int slot, float x, float y) { sendTouch(g_device, true,  slot, x, y); }
static inline void touchUp  (int slot, float x, float y) { sendTouch(g_device, false, slot, x, y); }

#pragma mark - HID UserDevice 构建

static void EnsureUserDevice(void) {
    if (g_device) return;

    // 与 sendTouch 匹配的简化 Digitizer 报告
    const uint8_t descriptor[] = {
        0x05,0x0D,                    // Usage Page (Digitizers)
        0x09,0x04,                    // Usage (Touch Screen)
        0xA1,0x01,                    // Collection (Application)
        0x85,0x01,                    //   Report ID (1)
        0x09,0x22,                    //   Usage (Finger)
        0xA1,0x00,                    //   Collection (Physical)
          0x09,0x42,                  //     Tip Switch
          0x09,0x32,                  //     In Range
          0x15,0x00, 0x25,0x01,
          0x75,0x01, 0x95,0x02, 0x81,0x02,
          0x75,0x06, 0x95,0x01, 0x81,0x03,
          0x09,0x51,                  //     Contact Identifier (0..127)
          0x25,0x7F, 0x75,0x08, 0x95,0x01, 0x81,0x02,
          0x05,0x01,                  //     Generic Desktop
          0x09,0x30, 0x09,0x31,       //     X, Y
          0x16,0x00,0x00, 0x26,0xFF,0x7F, // logical 0..32767
          0x75,0x10, 0x95,0x02, 0x81,0x02,
        0xC0,
        0xC0
    };

    CFDataRef desc = CFDataCreate(kCFAllocatorDefault, descriptor, sizeof(descriptor));

    int32_t usagePage = 0x0D, usage = 0x04;      // Digitizer / Touch Screen
    int32_t vendorID  = 1452, productID = 34305; // 示例：Apple/示例PID，可自定义
    int32_t transducerType = 3;                  // Finger
    int32_t eventMask = 0x2F;                    // 常见 Digitizer 事件
    int32_t idleTimeoutMs = 0;                   // 永不超时
    int32_t maxInput = 7;                        // 与报告长度一致
    int32_t maxOutput = 0, maxFeature = 1;

    CFNumberRef nUsagePage = CFNumberCreate(NULL, kCFNumberSInt32Type, &usagePage);
    CFNumberRef nUsage     = CFNumberCreate(NULL, kCFNumberSInt32Type, &usage);
    CFNumberRef nVendor    = CFNumberCreate(NULL, kCFNumberSInt32Type, &vendorID);
    CFNumberRef nProduct   = CFNumberCreate(NULL, kCFNumberSInt32Type, &productID);
    CFNumberRef nTrans     = CFNumberCreate(NULL, kCFNumberSInt32Type, &transducerType);
    CFNumberRef nEventMask = CFNumberCreate(NULL, kCFNumberSInt32Type, &eventMask);
    CFNumberRef nIdle      = CFNumberCreate(NULL, kCFNumberSInt32Type, &idleTimeoutMs);
    CFNumberRef nMaxIn     = CFNumberCreate(NULL, kCFNumberSInt32Type, &maxInput);
    CFNumberRef nMaxOut    = CFNumberCreate(NULL, kCFNumberSInt32Type, &maxOutput);
    CFNumberRef nMaxFeat   = CFNumberCreate(NULL, kCFNumberSInt32Type, &maxFeature);

    const void *keys[] = {
        CFSTR("ReportDescriptor"),
        CFSTR("PrimaryUsagePage"),
        CFSTR("PrimaryUsage"),
        CFSTR("VendorID"),
        CFSTR("ProductID"),
        CFSTR("Built-In"),
        CFSTR("DisplayIntegrated"),
        CFSTR("DigitizerTransducerType"),
        CFSTR("EventMask"),
        CFSTR("IdleTimeout"),
        CFSTR("MaxInputReportSize"),
        CFSTR("MaxOutputReportSize"),
        CFSTR("MaxFeatureReportSize"),
        CFSTR("Product"),
        CFSTR("Manufacturer"),
        CFSTR("Transport"),
    };
    const void *vals[] = {
        desc,
        nUsagePage, nUsage,
        nVendor, nProduct,
        kCFBooleanFalse,               // 建议非内建，减少冲突
        kCFBooleanTrue,
        nTrans,
        nEventMask,
        nIdle,
        nMaxIn, nMaxOut, nMaxFeat,
        CFSTR("LF Virtual Touch"),
        CFSTR("LF"),
        CFSTR("Virtual"),
    };

    CFDictionaryRef props = CFDictionaryCreate(NULL, keys, vals,
        (CFIndex)(sizeof(keys)/sizeof(keys[0])),
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);

    g_device = IOHIDUserDeviceCreate(kCFAllocatorDefault, props);

    CFRelease(props); CFRelease(desc);
    CFRelease(nUsagePage); CFRelease(nUsage);
    CFRelease(nVendor);    CFRelease(nProduct);
    CFRelease(nTrans);     CFRelease(nEventMask);
    CFRelease(nIdle);      CFRelease(nMaxIn);
    CFRelease(nMaxOut);    CFRelease(nMaxFeat);

    if (g_device) {
        os_log(OS_LOG_DEFAULT, "IOHIDUserDevice created: %p", g_device);
    } else {
        os_log_error(OS_LOG_DEFAULT, "IOHIDUserDevice create failed");
    }
}

#pragma mark - 接口实现

@implementation LFVirtualDigitizer

+ (instancetype)shared {
    static LFVirtualDigitizer *inst;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ inst = [[self alloc] init]; });
    return inst;
}

- (instancetype)init {
    if ((self = [super init])) {
        EnsureUserDevice();
    }
    return self;
}

- (void)jiazai {
    if (g_timer) return;         // 已经在跑
    EnsureUserDevice();
    if (!g_device) return;

    // 立即来一发：按下→1s后抬起
    touchDown(7, 0.5f, 0.5f);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        touchUp(7, 0.5f, 0.5f);
    });

    // 每 2 秒循环：按下→1 秒后抬起
    g_timer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                              repeats:YES
                                                block:^(NSTimer * _Nonnull t) {
        if (g_isDown) return;
        g_isDown = YES;
        touchDown(7, 0.5f, 0.5f);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            touchUp(7, 0.5f, 0.5f);
            g_isDown = NO;
        });
    }];

    // 避免滚动时暂停
    [[NSRunLoop mainRunLoop] addTimer:g_timer forMode:NSRunLoopCommonModes];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
       
        g_isDown = NO;
        [self stop];
    });
    
}

- (void)stop {
    if (g_timer) {
        [g_timer invalidate];
        g_timer = nil;
    }
}

- (void)pressAtX:(float)x y:(float)y duration:(NSTimeInterval)duration {
    EnsureUserDevice();
    if (!g_device) return;

    touchDown(7, x, y);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        touchUp(7, x, y);
    });
}

- (void)dealloc {
    [self stop];
    if (g_device) { CFRelease(g_device); g_device = NULL; }
}

@end

NS_ASSUME_NONNULL_END
