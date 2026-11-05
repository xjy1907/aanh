#include "touchaa.h"
#include "UIKit/UIKit.h"
#include <sys/syscall.h>
#include "IOHIDEvent.h"
#include "IOHIDEventData.h"
#include "IOHIDEventTypes.h"
#include "IOHIDEventSystemClient.h"
#include "IOHIDEventSystem.h"
#include "IOHIDService.h"
#include "IOKitLib.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreHaptics/CoreHaptics.h>
#import <dlfcn.h>
#import <os/log.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <mach/mach_time.h>
#include <math.h>
#include <stdlib.h>
#import <notify.h>
#import "NHIdentity.h"

// ============================================================
// 字符串XOR加密
// ============================================================
static NSString* _x(const unsigned char *key, size_t len) {
    char *buf = (char *)malloc(len + 1);
    if (!buf) return @"";
    for (size_t i = 0; i < len; i++) buf[i] = key[i] ^ 0x5A;
    buf[len] = '\0';
    NSString *r = [NSString stringWithUTF8String:buf];
    free(buf);
    return r ? r : @"";
}

// 以下均为明文 ^ 0x5A（校验过，避免 qwer 旧密文 dlsym 失败）
static const unsigned char _kSvc[] = { // IOHIDService
    0x13,0x15,0x12,0x13,0x1e,0x09,0x3f,0x28,0x2c,0x33,0x39,0x3f
};
static const unsigned char _kUsage[] = { // PrimaryUsagePage
    0x0a,0x28,0x33,0x37,0x3b,0x28,0x23,0x0f,0x29,0x3b,0x3d,0x3f,0x0a,0x3b,0x3d,0x3f
};
static const unsigned char _kSID[] = { // SenderID
    0x09,0x3f,0x34,0x3e,0x3f,0x28,0x13,0x1e
};
static const unsigned char _kSys[] = { // IOHIDEventSystem
    0x13,0x15,0x12,0x13,0x1e,0x1f,0x2c,0x3f,0x34,0x2e,0x09,0x23,0x29,0x2e,0x3f,0x37
};
static const unsigned char _kShared[] = { // sharedInstance
    0x29,0x32,0x3b,0x28,0x3f,0x3e,0x13,0x34,0x29,0x2e,0x3b,0x34,0x39,0x3f
};
static const unsigned char _kM1[] = { // _dispatchEvent:
    0x05,0x3e,0x33,0x29,0x2a,0x3b,0x2e,0x39,0x32,0x1f,0x2c,0x3f,0x34,0x2e,0x60
};
static const unsigned char _kM2[] = { // _sendEvent:
    0x05,0x29,0x3f,0x34,0x3e,0x1f,0x2c,0x3f,0x34,0x2e,0x60
};
static const unsigned char _kM3[] = { // _handleEvent:
    0x05,0x32,0x3b,0x34,0x3e,0x36,0x3f,0x1f,0x2c,0x3f,0x34,0x2e,0x60
};
static const unsigned char _kRootTag[] = { 0x1b,0x0e,0x35,0x2a }; // ATop
static const unsigned char _kSidFile[] = { 0x29,0x33,0x3e,0x74,0x3e,0x3b,0x2e }; // sid.dat

static const unsigned char _kCreateFinger[] = { // IOHIDEventCreateDigitizerFingerEvent
    0x13,0x15,0x12,0x13,0x1e,0x1f,0x2c,0x3f,0x34,0x2e,0x19,0x28,0x3f,0x3b,0x2e,0x3f,
    0x1e,0x33,0x3d,0x33,0x2e,0x33,0x20,0x3f,0x28,0x1c,0x33,0x34,0x3d,0x3f,0x28,0x1f,
    0x2c,0x3f,0x34,0x2e
};
static const unsigned char _kClientCreate[] = { // IOHIDEventSystemClientCreate
    0x13,0x15,0x12,0x13,0x1e,0x1f,0x2c,0x3f,0x34,0x2e,0x09,0x23,0x29,0x2e,0x3f,0x37,
    0x19,0x36,0x33,0x3f,0x34,0x2e,0x19,0x28,0x3f,0x3b,0x2e,0x3f
};
static const unsigned char _kClientDispatch[] = { // IOHIDEventSystemClientDispatchEvent
    0x13,0x15,0x12,0x13,0x1e,0x1f,0x2c,0x3f,0x34,0x2e,0x09,0x23,0x29,0x2e,0x3f,0x37,
    0x19,0x36,0x33,0x3f,0x34,0x2e,0x1e,0x33,0x29,0x2a,0x3b,0x2e,0x39,0x32,0x1f,0x2c,
    0x3f,0x34,0x2e
};

// 系统实际签名：14个参数
typedef IOHIDEventRef (*CreateFingerFunc_t)(
    CFAllocatorRef allocator,
    uint64_t timeStamp,
    uint32_t index,
    uint32_t identity,
    uint32_t eventMask,
    IOHIDFloat x,
    IOHIDFloat y,
    IOHIDFloat z,
    IOHIDFloat tipPressure,
    IOHIDFloat barrelPressure,
    Boolean twist,
    Boolean range,
    Boolean touch,
    IOOptionBits quality
);

static CreateFingerFunc_t _createFingerFunc = NULL;

static CreateFingerFunc_t _getCreateFingerFunc(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // 仅 dlsym，避免 __stubs 残留 IOHIDEventCreateDigitizerFingerEvent 符号
        NSString *funcName = _x(_kCreateFinger, sizeof(_kCreateFinger));
        _createFingerFunc = (CreateFingerFunc_t)dlsym(RTLD_DEFAULT, [funcName UTF8String]);
    });
    return _createFingerFunc;
}

// ============================================================
// 常量
// ============================================================
#define TOUCH_UP 0
#define TOUCH_DOWN 1
#define TOUCH_MOVE 2

#define MAX_FINGER_INDEX 20
#define MAX_BACKUP_SID 8

#define NOT_VALID 0
#define VALID 1
#define VALID_AT_NEXT_APPEND 2

#define EVENT_VALID_INDEX 0
#define EVENT_TYPE_INDEX 1
#define EVENT_X_INDEX 2
#define EVENT_Y_INDEX 3

// ============================================================
// 全局状态
// ============================================================
static CGFloat _sw = 0;
static CGFloat _sh = 0;
static IOHIDEventSystemClientRef _sysClient = NULL;
static unsigned long long int _sid = 0x0;
static uint64_t _regID = 0;

static uint64_t _backupSIDs[MAX_BACKUP_SID] = {0};
static int _backupSIDCount = 0;
static int _currentSIDIndex = 0;

static const uint32_t kIdxBase = 9;
static inline uint32_t _mapIdx(int slot) {
    return kIdxBase + (uint32_t)slot;
}
static inline uint32_t _mapIdentity(int slot) {
    uint32_t base = (uint32_t)(_regID & 0xFFF);
    if (base < 0x100) base += 0x100;
    uint32_t id = base + (uint32_t)slot * 7;
    if (id > 0xFFF) id = (id & 0xFFF) + 0x100;
    return id;
}

// ============================================================
// 每个手指独立的物理属性
// ============================================================
typedef struct {
    float baseMajor;
    float baseMinor;
    float baseOrient;
    float baseQual;
    float stiffness;
    float damping;
} _FingerPhys;

static _FingerPhys _phys[MAX_FINGER_INDEX] = {0};
static bool _physInitDone[MAX_FINGER_INDEX] = {false};

static void _initPhys(int slot) {
    if (_physInitDone[slot]) return;
    _phys[slot].baseMajor = 0.035f + ((float)arc4random() / UINT32_MAX) * 0.02f;
    _phys[slot].baseMinor = 0.025f + ((float)arc4random() / UINT32_MAX) * 0.015f;
    _phys[slot].baseOrient = ((float)arc4random() / UINT32_MAX) * M_PI * 2;
    _phys[slot].baseQual = 0.85f + ((float)arc4random() / UINT32_MAX) * 0.15f;
    _phys[slot].stiffness = 0.7f + ((float)arc4random() / UINT32_MAX) * 0.6f;
    _phys[slot].damping = 0.5f + ((float)arc4random() / UINT32_MAX) * 1.0f;
    _physInitDone[slot] = true;
}

// ============================================================
// 随机化工具
// ============================================================
static inline float _jitter(float base, float amp) {
    float r1 = (float)arc4random() / UINT32_MAX;
    float r2 = (float)arc4random() / UINT32_MAX;
    return base + (r1 - r2) * amp;
}

static inline uint64_t _timeJitter(uint64_t base, int maxUs) {
    static mach_timebase_info_data_t tb = {0};
    if (tb.denom == 0) mach_timebase_info(&tb);
    uint32_t r = 1 + arc4random_uniform(maxUs);
    return base + (uint64_t)r * 1000ULL * tb.denom / tb.numer;
}

// ============================================================
// 动态SenderID + 备选池
// ============================================================
static uint64_t _fetchLiveSID(void) {
    io_iterator_t iter = 0;
    NSString *svcName  = _x(_kSvc, sizeof(_kSvc));
    NSString *usageKey = _x(_kUsage, sizeof(_kUsage));
    NSString *senderKey = _x(_kSID, sizeof(_kSID));
    
    CFMutableDictionaryRef match = IOServiceMatching([svcName UTF8String]);
    if (!match) return 0;
    
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, match, &iter) != KERN_SUCCESS) return 0;
    
    uint64_t found = 0;
    _backupSIDCount = 0;
    io_service_t srv = 0;
    
    while ((srv = IOIteratorNext(iter)) != 0 && _backupSIDCount < MAX_BACKUP_SID) {
        CFTypeRef up = IORegistryEntryCreateCFProperty(srv, (__bridge CFStringRef)usageKey, kCFAllocatorDefault, 0);
        if (up) {
            int pg = 0;
            CFNumberGetValue((CFNumberRef)up, kCFNumberIntType, &pg);
            CFRelease(up);
            if (pg == 0x0D || pg == 0x01 || pg == 0x0C) {
                if (pg == 0x0D && _regID == 0) {
                    IORegistryEntryGetRegistryEntryID(srv, &_regID);
                }
                CFTypeRef sr = IORegistryEntryCreateCFProperty(srv, (__bridge CFStringRef)senderKey, kCFAllocatorDefault, 0);
                if (sr) {
                    uint64_t fid = 0;
                    CFNumberGetValue((CFNumberRef)sr, kCFNumberSInt64Type, &fid);
                    CFRelease(sr);
                    if (fid != 0) {
                        bool dup = false;
                        for (int i = 0; i < _backupSIDCount; i++) {
                            if (_backupSIDs[i] == fid) { dup = true; break; }
                        }
                        if (!dup) {
                            _backupSIDs[_backupSIDCount++] = fid;
                            if (found == 0) found = fid;
                        }
                    }
                }
            }
        }
        IOObjectRelease(srv);
    }
    IOObjectRelease(iter);
    return found;
}

static uint64_t _getCurrentSID(void) {
    static uint64_t lastSwitch = 0;
    uint64_t now = mach_absolute_time();
    if (_backupSIDCount > 1 && (now - lastSwitch) > (uint64_t)(300 + arc4random_uniform(600)) * 1000000000ULL) {
        _currentSIDIndex = (_currentSIDIndex + 1) % _backupSIDCount;
        lastSwitch = now;
    }
    if (_backupSIDCount > 0 && _currentSIDIndex < _backupSIDCount) {
        return _backupSIDs[_currentSIDIndex];
    }
    return _sid;
}

// ============================================================
// 触摸上下文
// ============================================================
typedef struct {
    uint32_t identity;
    uint8_t  index;
    float    majorRadius;
    float    minorRadius;
    float    orientation;
    float    lastForce;
    float    quality;
    uint64_t seqStart;
} _TouchCtx;

static _TouchCtx _ctx[MAX_FINGER_INDEX] = {0};
static bool _ctxInit[MAX_FINGER_INDEX] = {false};
static float _evBuf[MAX_FINGER_INDEX][4];

// ============================================================
// 触摸序列号
// ============================================================
static uint32_t _touchSeq = 0;
static inline uint32_t _nextSeq(void) {
    _touchSeq++;
    if (_touchSeq > 0xFFFF) _touchSeq = 1;
    return _touchSeq;
}

// ============================================================
// 独立压力曲线
// ============================================================
static float _naturalForce(int slot, bool isDown, bool isMove) {
    _TouchCtx *c = &_ctx[slot];
    uint64_t now = mach_absolute_time();
    _initPhys(slot);
    
    if (isDown) {
        if (!_ctxInit[slot]) return 0.0f;
        uint64_t elapsed = now - c->seqStart;
        double tau = 0.2 / _phys[slot].stiffness;
        double t = (double)elapsed / (tau * 1000000000.0);
        if (t >= 1.0) t = 1.0;
        float peak = 0.15f + ((float)arc4random() / UINT32_MAX) * 0.35f;
        return peak * (1.0f - expf(-5.0f * _phys[slot].stiffness * t));
    } else if (isMove) {
        return fmaxf(0.0f, fminf(1.0f, c->lastForce + _jitter(0, 0.03f * _phys[slot].damping)));
    } else {
        return c->lastForce * 0.2f * _phys[slot].damping;
    }
}

// ============================================================
// 数据解析
// ============================================================
static int _getCnt(UInt8* d) { return (d[0] - '0'); }
static int _getType(UInt8* d, int idx) { return (d[1 + idx * TOUCH_DATA_LEN] - '0'); }
static int _getIdx(UInt8* d, int idx) {
    int r = 0;
    for (int i = 2; i <= 3; i++) r += (d[i + idx * TOUCH_DATA_LEN] - '0') * (int)pow(10, 3 - i);
    return r;
}
static float _getX(UInt8* d, int idx) {
    float x = 0;
    for (int i = 4; i <= 8; i++) {
        UInt8 c = d[i + idx * TOUCH_DATA_LEN];
        if (c < '0' || c > '9') continue;
        x += (c - '0') * powf(10, 8 - i);
    }
    return x / 10.0f;
}
static float _getY(UInt8* d, int idx) {
    float y = 0;
    for (int i = 9; i <= 13; i++) {
        UInt8 c = d[i + idx * TOUCH_DATA_LEN];
        if (c < '0' || c > '9') continue;
        y += (c - '0') * powf(10, 13 - i);
    }
    return y / 10.0f;
}

// ============================================================
// Range事件 (dlsym动态调用，14参数)
// ============================================================
static IOHIDEventRef _makeRange(int slot, float x, float y) {
    _TouchCtx *c = &_ctx[slot];
    _initPhys(slot);
    
    c->index    = (uint8_t)_mapIdx(slot);
    c->identity = _mapIdentity(slot);
    
    if (!_ctxInit[slot]) {
        c->majorRadius = _phys[slot].baseMajor;
        c->minorRadius = _phys[slot].baseMinor;
        c->orientation = _phys[slot].baseOrient;
        c->lastForce   = 0.0f;
        c->quality     = _phys[slot].baseQual;
        c->seqStart    = mach_absolute_time();
        _ctxInit[slot] = true;
    }
    
    uint64_t t = _timeJitter(mach_absolute_time(), 40);
    
    CreateFingerFunc_t create = _getCreateFingerFunc();
    if (!create) return NULL;
    IOHIDEventRef ev = create(
        kCFAllocatorDefault, t,
        c->index, c->identity,
        kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventRange,
        x, y, 0, 0, 0, 0, 0, 0, 0);
    
    IOHIDEventSetIntegerValue(ev, 0xb000c, 1);
    IOHIDEventSetFloatValue(ev, 0xb0013, 0.3f + ((float)arc4random() / UINT32_MAX) * 0.7f);
    IOHIDEventSetIntegerValue(ev, 0xb001a, _nextSeq());
    return ev;
}

// ============================================================
// 子事件 TouchDown (14参数)
// ============================================================
static IOHIDEventRef generateChildEventTouchDown(int slot, float x, float y) {
    _TouchCtx *c = &_ctx[slot];
    uint64_t now = mach_absolute_time();
    _initPhys(slot);

    c->index    = (uint8_t)_mapIdx(slot);
    c->identity = _mapIdentity(slot);

    if (!_ctxInit[slot]) {
        c->majorRadius = _phys[slot].baseMajor;
        c->minorRadius = _phys[slot].baseMinor;
        c->orientation = _phys[slot].baseOrient;
        c->lastForce   = 0.0f;
        c->quality     = _phys[slot].baseQual;
        c->seqStart    = now;
        _ctxInit[slot] = true;
    }
    
    c->lastForce   = _naturalForce(slot, true, false);
    c->majorRadius = _jitter(c->majorRadius, 0.003f);
    c->minorRadius = _jitter(c->minorRadius, 0.002f);
    c->orientation = _jitter(c->orientation, 0.05f);
    c->quality     = fminf(1.0f, fmaxf(0.8f, _jitter(c->quality, 0.02f)));

    uint64_t t = _timeJitter(now, 50);

    CreateFingerFunc_t create = _getCreateFingerFunc();
    if (!create) return NULL;
    IOHIDEventRef ev = create(
        kCFAllocatorDefault, t,
        c->index, c->identity,
        kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventStart,
        x, y, 0, 0, 0, 0, 1, 1, 0);

    IOHIDEventSetFloatValue(ev, 0xb0014, c->majorRadius);
    IOHIDEventSetFloatValue(ev, 0xb0015, c->minorRadius);
    IOHIDEventSetFloatValue(ev, 0xb0016, c->lastForce);
    IOHIDEventSetFloatValue(ev, 0xb0017, c->orientation);
    IOHIDEventSetFloatValue(ev, 0xb0018, c->quality);
    IOHIDEventSetIntegerValue(ev, 0xb0010, 0);
    IOHIDEventSetIntegerValue(ev, 0xb001a, _nextSeq());
    
    return ev;
}

// ============================================================
// 子事件 TouchMove (14参数)
// ============================================================
static IOHIDEventRef generateChildEventTouchMove(int slot, float x, float y) {
    _TouchCtx *c = &_ctx[slot];
    uint64_t now = mach_absolute_time();
    _initPhys(slot);

    c->index    = (uint8_t)_mapIdx(slot);
    c->identity = _mapIdentity(slot);

    if (!_ctxInit[slot]) {
        c->majorRadius = _phys[slot].baseMajor;
        c->minorRadius = _phys[slot].baseMinor;
        c->orientation = _phys[slot].baseOrient;
        c->lastForce   = 0.2f;
        c->quality     = _phys[slot].baseQual;
        c->seqStart    = now;
        _ctxInit[slot] = true;
    }

    c->lastForce   = _naturalForce(slot, false, true);
    c->majorRadius = _jitter(c->majorRadius, 0.002f);
    c->minorRadius = _jitter(c->minorRadius, 0.001f);
    c->orientation = _jitter(c->orientation, 0.03f);
    c->quality     = fminf(1.0f, fmaxf(0.8f, _jitter(c->quality, 0.02f)));

    uint64_t t = _timeJitter(now, 30);

    CreateFingerFunc_t create = _getCreateFingerFunc();
    if (!create) return NULL;
    IOHIDEventRef ev = create(
        kCFAllocatorDefault, t,
        c->index, c->identity,
        kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventPosition,
        x, y, 0, 0, 0, 0, 1, 1, 0);

    IOHIDEventSetFloatValue(ev, 0xb0014, c->majorRadius);
    IOHIDEventSetFloatValue(ev, 0xb0015, c->minorRadius);
    IOHIDEventSetFloatValue(ev, 0xb0016, c->lastForce);
    IOHIDEventSetFloatValue(ev, 0xb0017, c->orientation);
    IOHIDEventSetFloatValue(ev, 0xb0018, c->quality);
    IOHIDEventSetIntegerValue(ev, 0xb0010, 0);
    IOHIDEventSetIntegerValue(ev, 0xb001a, _nextSeq());
    
    return ev;
}

// ============================================================
// 子事件 TouchUp (14参数)
// ============================================================
static IOHIDEventRef generateChildEventTouchUp(int slot, float x, float y) {
    _TouchCtx *c = &_ctx[slot];
    uint64_t now = mach_absolute_time();
    _initPhys(slot);

    c->index    = (uint8_t)_mapIdx(slot);
    c->identity = _mapIdentity(slot);

    if (!_ctxInit[slot]) {
        c->majorRadius = _phys[slot].baseMajor;
        c->minorRadius = _phys[slot].baseMinor;
        c->orientation = _phys[slot].baseOrient;
        c->lastForce   = 0.1f;
        c->quality     = _phys[slot].baseQual;
        _ctxInit[slot] = true;
    }

    c->lastForce   = _naturalForce(slot, false, false);
    c->quality     *= 0.7f;
    c->majorRadius = _jitter(c->majorRadius * 0.95f, 0.001f);
    c->minorRadius = _jitter(c->minorRadius * 0.95f, 0.001f);
    c->orientation = _jitter(c->orientation, 0.03f);

    uint64_t t = _timeJitter(now, 50);

    CreateFingerFunc_t create = _getCreateFingerFunc();
    if (!create) return NULL;
    IOHIDEventRef ev = create(
        kCFAllocatorDefault, t,
        c->index, c->identity,
        kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventStop,
        x, y, 0, 0, 0, 0, 0, 0, 0);

    IOHIDEventSetFloatValue(ev, 0xb0014, c->majorRadius);
    IOHIDEventSetFloatValue(ev, 0xb0015, c->minorRadius);
    IOHIDEventSetFloatValue(ev, 0xb0016, 0.0f);
    IOHIDEventSetFloatValue(ev, 0xb0017, c->orientation);
    IOHIDEventSetFloatValue(ev, 0xb0018, fmaxf(0.0f, c->quality));
    IOHIDEventSetIntegerValue(ev, 0xb0010, 0);
    IOHIDEventSetIntegerValue(ev, 0xb001a, _nextSeq());

    _ctxInit[slot] = false;
    return ev;
}

// ============================================================
// 组装
// ============================================================
static void _appendChild(IOHIDEventRef parent, int type, int idx, float x, float y) {
    IOHIDEventRef child = NULL;
    switch (type) {
        case TOUCH_MOVE:
            child = generateChildEventTouchMove(idx, x, y);
            break;
        case TOUCH_DOWN:
            child = generateChildEventTouchDown(idx, x, y);
            break;
        case TOUCH_UP:
            child = generateChildEventTouchUp(idx, x, y);
            break;
    }
    if (child) {
        IOHIDEventAppendEvent(parent, child);
        CFRelease(child);
    }
}

// ============================================================
// 【过检测1】消除 _dispatchEvent: 符号特征
// ============================================================
static int (*_dispatchFunc)(id, SEL, IOHIDEventRef) = NULL;
static id _sysInst = nil;
static SEL _activeSel = NULL;

static void _initDispatch(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *clsName = _x(_kSys, sizeof(_kSys));
        NSString *selName = _x(_kShared, sizeof(_kShared));
        
        Class cls = NSClassFromString(clsName);
        if (cls && [cls respondsToSelector:NSSelectorFromString(selName)]) {
            _sysInst = [cls performSelector:NSSelectorFromString(selName)];
        }
        
        NSArray *candidates = @[
            _x(_kM1, sizeof(_kM1)),
            _x(_kM2, sizeof(_kM2)),
            _x(_kM3, sizeof(_kM3))
        ];
        
        for (NSString *name in candidates) {
            SEL sel = NSSelectorFromString(name);
            if ([_sysInst respondsToSelector:sel]) {
                _activeSel = sel;
                _dispatchFunc = (int (*)(id, SEL, IOHIDEventRef))dlsym(RTLD_DEFAULT, "objc_msgSend");
                break;
            }
        }
        
        if (!_dispatchFunc) {
            _dispatchFunc = (int (*)(id, SEL, IOHIDEventRef))objc_msgSend;
        }
    });
}

// ============================================================
// 发送事件
// ============================================================
static void postIOHIDEvent(IOHIDEventRef event) {
    static uint64_t cachedSID = 0;
    static uint64_t lastUpdate = 0;
    static IOHIDEventSystemClientRef (*_clientCreate)(CFAllocatorRef) = NULL;
    static void (*_clientDispatch)(IOHIDEventSystemClientRef, IOHIDEventRef) = NULL;
    static dispatch_once_t clientOnce;
    uint64_t now = mach_absolute_time();

    if (cachedSID == 0 || (now - lastUpdate) > 30000000000ULL) {
        uint64_t live = _fetchLiveSID();
        if (live != 0) {
            cachedSID = live;
            lastUpdate = now;
        }
    }

    uint64_t useSID = _getCurrentSID();
    if (useSID == 0) useSID = (cachedSID != 0) ? cachedSID : _sid;
    IOHIDEventSetSenderID(event, useSID);

    _initDispatch();

    if (_sysInst && _activeSel && _dispatchFunc) {
        _dispatchFunc(_sysInst, _activeSel, event);
        return;
    }

    dispatch_once(&clientOnce, ^{
        _clientCreate = (IOHIDEventSystemClientRef (*)(CFAllocatorRef))dlsym(
            RTLD_DEFAULT, [_x(_kClientCreate, sizeof(_kClientCreate)) UTF8String]);
        _clientDispatch = (void (*)(IOHIDEventSystemClientRef, IOHIDEventRef))dlsym(
            RTLD_DEFAULT, [_x(_kClientDispatch, sizeof(_kClientDispatch)) UTF8String]);
    });
    if (!_clientCreate || !_clientDispatch) return;
    if (!_sysClient) {
        _sysClient = _clientCreate(kCFAllocatorDefault);
    }
    if (_sysClient) {
        _clientDispatch(_sysClient, event);
    }
}

// ============================================================
// 主执行函数
// ============================================================
void performTouchFromRawData(NSMutableArray* touchList) {
    IOHIDEventRef parent =
        IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, mach_absolute_time(),
                                       3, 99, 1, 0, 0,
                                       0.f, 0.f, 0.f, 0.f, 0.f, 0, 0, 0);

    IOHIDEventSetIntegerValue(parent, 0xb0019, 1);
    IOHIDEventSetIntegerValue(parent, 0x4,      1);

    for (int i = 0; i < touchList.count; i++) {
        NSDictionary* dic = [touchList objectAtIndex:i];
        int ttype = [[dic objectForKey:@"touchType"] intValue];
        if (ttype == TOUCH_DOWN) {
            int idx = [[dic objectForKey:@"index"] intValue];
            float x = [[dic objectForKey:@"x"] floatValue];
            float y = [[dic objectForKey:@"y"] floatValue];
            IOHIDEventRef rev = _makeRange(idx, x, y);
            if (rev) {
                IOHIDEventAppendEvent(parent, rev);
                CFRelease(rev);
            }
        }
    }

    for (int i = 0; i < touchList.count; i++)
    {
        NSDictionary* dic = [touchList objectAtIndex:i];
        int ttype = [[dic objectForKey:@"touchType"] intValue];
        float x = [[dic objectForKey:@"x"] floatValue];
        float y = [[dic objectForKey:@"y"] floatValue];
        int idx = [[dic objectForKey:@"index"] intValue];

        _appendChild(parent, ttype, idx, x, y);

        switch (ttype) {
            case TOUCH_MOVE:
                _evBuf[idx][EVENT_VALID_INDEX] = VALID_AT_NEXT_APPEND;
                _evBuf[idx][EVENT_TYPE_INDEX]  = TOUCH_MOVE;
                _evBuf[idx][EVENT_X_INDEX]     = x;
                _evBuf[idx][EVENT_Y_INDEX]     = y;
                break;
            case TOUCH_DOWN:
                _evBuf[idx][EVENT_VALID_INDEX] = VALID_AT_NEXT_APPEND;
                _evBuf[idx][EVENT_TYPE_INDEX]  = TOUCH_DOWN;
                _evBuf[idx][EVENT_X_INDEX]     = x;
                _evBuf[idx][EVENT_Y_INDEX]     = y;
                break;
            case TOUCH_UP:
                _evBuf[idx][EVENT_VALID_INDEX] = NOT_VALID;
                break;
        }
    }

    for (int i = 0; i < MAX_FINGER_INDEX; i++) {
        if (_evBuf[i][EVENT_VALID_INDEX] == VALID) {
            _appendChild(parent,
                         (int)_evBuf[i][EVENT_TYPE_INDEX],
                         i,
                         _evBuf[i][EVENT_X_INDEX],
                         _evBuf[i][EVENT_Y_INDEX]);
        } else if (_evBuf[i][EVENT_VALID_INDEX] == VALID_AT_NEXT_APPEND) {
            _evBuf[i][EVENT_VALID_INDEX] = VALID;
        }
    }

    IOHIDEventSetIntegerValue(parent, 0xb0007, 0x23);
    IOHIDEventSetIntegerValue(parent, 0xb0008, 0x1);
    IOHIDEventSetIntegerValue(parent, 0xb0009, 0x1);

    postIOHIDEvent(parent);
    CFRelease(parent);
}

// ============================================================
// 【过检测2】路径混淆
// ============================================================
NSString* getDocumentRoot() {
    static NSString *dynamicPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *base = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        if (!base) base = NSTemporaryDirectory();

        pid_t pid = getpid();
        uint32_t r1 = arc4random();
        uint32_t r2 = arc4random();
        NSString *tag = _x(_kRootTag, sizeof(_kRootTag));
        NSString *subdir = [NSString stringWithFormat:@"%@_%d_%08x_%08x", tag, pid, r1, r2];
        dynamicPath = [base stringByAppendingPathComponent:subdir];

        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:dynamicPath]) {
            [fm createDirectoryAtPath:dynamicPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    });
    return dynamicPath;
}

// ============================================================
// SID 加载：硬件 live → prefs/iCloud → 动态路径旁路文件
// ============================================================
static inline uint64_t _loadSIDFromPrefs(void) {
    NSDictionary *cfg = NHPrefsRead();
    id v = cfg[@"TouchSenderID"];
    if ([v respondsToSelector:@selector(unsignedLongLongValue)]) {
        uint64_t sid = [v unsignedLongLongValue];
        if (sid != 0) return sid;
    }
    NSUbiquitousKeyValueStore *store = NSUbiquitousKeyValueStore.defaultStore;
    long long icloud = [store longLongForKey:@"TouchSenderID"];
    if (icloud != 0) return (uint64_t)icloud;

    NSString *sp = [getDocumentRoot() stringByAppendingPathComponent:_x(_kSidFile, sizeof(_kSidFile))];
    NSDictionary *s = [NSDictionary dictionaryWithContentsOfFile:sp];
    if (s && s[@"TouchSenderID"]) {
        return (uint64_t)[s[@"TouchSenderID"] unsignedLongLongValue];
    }
    return 0;
}

static void _ensureBackupHas(uint64_t sid) {
    if (sid == 0) return;
    for (int i = 0; i < _backupSIDCount; i++) {
        if (_backupSIDs[i] == sid) return;
    }
    if (_backupSIDCount < MAX_BACKUP_SID) {
        _backupSIDs[_backupSIDCount++] = sid;
    }
}

void initSenderId(void) {
    _sid = _fetchLiveSID();
    if (_sid == 0) _sid = _loadSIDFromPrefs();
    if (_sid != 0) _ensureBackupHas(_sid);
    if (_backupSIDCount == 0 && _sid != 0) {
        _backupSIDs[0] = _sid;
        _backupSIDCount = 1;
    }
}

void initTouchGetScreenSize(float width, float height) {
    _sw = width;
    _sh = height;
}

void huoqu(uint64_t aaa) {
    if (aaa == 0) return;
    _sid = aaa;
    _ensureBackupHas(aaa);
}

// ============================================================
// 对外接口
// ============================================================
void touchBegin(int index, float x, float y) {
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSNumber numberWithInt:TOUCH_DOWN] forKey:@"touchType"];
    [d setObject:[NSNumber numberWithFloat:x] forKey:@"x"];
    [d setObject:[NSNumber numberWithFloat:y] forKey:@"y"];
    [d setObject:[NSNumber numberWithInt:index] forKey:@"index"];
    [arr addObject:d];
    performTouchFromRawData(arr);
}

void touchMove(int index, float x, float y) {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSNumber numberWithInt:TOUCH_MOVE] forKey:@"touchType"];
    [d setObject:[NSNumber numberWithFloat:x] forKey:@"x"];
    [d setObject:[NSNumber numberWithFloat:y] forKey:@"y"];
    [d setObject:[NSNumber numberWithInt:index] forKey:@"index"];
    [arr addObject:d];
    performTouchFromRawData(arr);
}

void touchEnd(int index, float x, float y) {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSNumber numberWithInt:TOUCH_UP] forKey:@"touchType"];
    [d setObject:[NSNumber numberWithFloat:x] forKey:@"x"];
    [d setObject:[NSNumber numberWithFloat:y] forKey:@"y"];
    [d setObject:[NSNumber numberWithInt:index] forKey:@"index"];
    [arr addObject:d];
    performTouchFromRawData(arr);
}

NSArray *getGlobalTouchList(void) { return nil; }
NSArray *getSenderIDs(void) { return @[@(_sid)]; }
static void setSenderIdCallback(void* t, void* r, IOHIDServiceRef s, IOHIDEventRef e) {}
