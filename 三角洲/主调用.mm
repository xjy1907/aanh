
#import <MacTypes.h>
#import <CoreFoundation/CFBase.h>
#import <Foundation/NSPathUtilities.h>

typedef struct __IOHIDEvent* IOHIDEvent;
typedef struct __IOHIDNotification* IOHIDNotification;
typedef struct __IOHIDService* IOHIDService;
typedef struct __GSEvent* GSEvent;

extern "C" {
    void GSInitialize();
    void UIApplicationInitialize();
    void BKSDisplayServicesStart();
    void GSEventPushRunLoopMode(CFStringRef mode);
    void GSEventInitialize(Boolean registerPurple);
    void UIApplicationInstantiateSingleton(id aclass);
    void *BKSHIDEventRegisterEventCallback(void (*)(void *, void *, IOHIDService, IOHIDEvent));
};

@interface UIApplication (Private)

- (void)_accessibilityInit;
- (void)__completeAndRunAsPlugin;
- (void)_enqueueHIDEvent:(IOHIDEvent)IOHIDEvent;

@end

static __used void 挂载应用(void*, void*, IOHIDService IOHIDService, IOHIDEvent IOHIDEvent) {
    static UIApplication* 应用 = [UIApplication sharedApplication];
    [应用 _enqueueHIDEvent:IOHIDEvent];
};

NSString* 存储进程名() {
    static dispatch_once_t onceToken;
    static NSString* 进程名 = nil;
    dispatch_once(&onceToken, ^{
        static NSString* 路径 = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        进程名 = [路径 stringByAppendingPathComponent:@"进程名"];
    });
    return 进程名;
};

int main(int argc, char* argv[]) {
    @autoreleasepool {
        if (argc <= 1) {
            return UIApplicationMain(argc, argv, @"应用", @"应用挂载方法");
        };
        if (strcmp(argv[1], "开启HUD") == 0) {
            NSString* 进程ID = [NSString stringWithFormat:@"%d", getpid()];
            [进程ID writeToFile:存储进程名() atomically:YES encoding:NSUTF8StringEncoding error:nil];
            [UIScreen initialize];
            CFRunLoopGetCurrent();
            GSInitialize();
            BKSDisplayServicesStart();
            UIApplicationInitialize();
            UIApplicationInstantiateSingleton(objc_getClass("HUD"));
            static id<UIApplicationDelegate> HUD挂载方法 = [[objc_getClass("HUD挂载方法") alloc] init];
            [UIApplication.sharedApplication setDelegate:HUD挂载方法];
            
            [UIApplication.sharedApplication _accessibilityInit];
            [UIApplication.sharedApplication __completeAndRunAsPlugin];
            
            
            [NSRunLoop currentRunLoop];
            BKSHIDEventRegisterEventCallback(挂载应用);
            
            GSEventInitialize(0);
            GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
            
            CFRunLoopRun();
        } else {
            NSString* 进程名 = [NSString stringWithContentsOfFile:存储进程名() encoding:NSUTF8StringEncoding error:nil];
            if (进程名) {
                pid_t 进程ID = (pid_t)[进程名 intValue];
                if (strcmp(argv[1], "关闭HUD") == 0) {
                    kill(进程ID, SIGKILL);
                    unlink(存储进程名().UTF8String);
                };
            };
        };
        return EXIT_SUCCESS;
    };
};
