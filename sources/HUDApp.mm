//
//  HUDApp.mm
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <mach-o/dyld.h>
#import <notify.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <sys/utsname.h>

#if !NO_TROLL
#import "AXEventRepresentation.h"
#import "BackboardServices.h"
#import "HUDHelper.h"
#import "IOKit+SPI.h"
#import "TSEventFetcher.h"
#import "UIApplication+Private.h"

#import "LFVirtualDigitizer.h"
#import "AimFloatWindow.h"
// PID 文件改为每机派生路径，见 NHIdentity.h → NHPidPath()

static __used NSString *mDeviceModel(void) {
  struct utsname systemInfo;
  uname(&systemInfo);
  return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

static __used void _HUDEventCallback(void *target, void *refcon, IOHIDServiceRef service, IOHIDEventRef event) {
  static UIApplication *app = [UIApplication sharedApplication];
  log_debug(OS_LOG_DEFAULT, "_HUDEventCallback => %{public}@", event);
  
  // iOS 15.1+ has a new API for handling HID events.
  if (@available(iOS 15.1, *)) {
  } else {
    [app _enqueueHIDEvent:event];
  }
  
  BOOL shouldUseAXEvent = YES; // Always use AX events now...
  
  BOOL isExactly15 = NO;
  static NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
  if (version.majorVersion == 15 && version.minorVersion == 0 && version.patchVersion == 0) {
    NSString *deviceModel = mDeviceModel();
    if (![deviceModel hasPrefix:@"iPhone13,"] && ![deviceModel hasPrefix:@"iPhone14,"]) { // iPhone 12 & 13 Series
      isExactly15 = YES;
    }
  }
  
  if (@available(iOS 15.0, *)) {
    shouldUseAXEvent = !isExactly15;
  } else {
    shouldUseAXEvent = NO;
  }
  
  if (shouldUseAXEvent) {
    static Class AXEventRepresentationCls = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework"] load];
      AXEventRepresentationCls = objc_getClass("AXEventRepresentation");
    });
    
    AXEventRepresentation *rep = [AXEventRepresentationCls representationWithHIDEvent:event
                                                                  hidStreamIdentifier:@"UIApplicationEvents"];
    log_debug(OS_LOG_DEFAULT, "_HUDEventCallback => %{public}@", rep.handInfo);
    
    /* I don't like this. It's too hacky, but it works. */
    {
      dispatch_async(dispatch_get_main_queue(), ^(void) {
        // 对标 qwer：优先投递到自瞄悬浮球交互窗，否则点不到
        UIWindow *hitWindow = [AimFloatWindow activeWindow];
        if (!hitWindow) {
          for (UIWindow *w in [app windows]) {
            if ([w respondsToSelector:@selector(_ignoresHitTest)] &&
                ((BOOL (*)(id, SEL))objc_msgSend)(w, @selector(_ignoresHitTest))) {
              continue;
            }
            hitWindow = w;
            break;
          }
        }
        if (!hitWindow) {
          hitWindow = [[app windows] firstObject];
        }
        if (!hitWindow) return;

        CGPoint loc = [rep location];
        UIView *keyView = [hitWindow hitTest:loc withEvent:nil];
        // 空白穿透：不合成触摸，避免抢走游戏操作
        if (!keyView) return;
        
        UITouchPhase phase = UITouchPhaseEnded;
        if ([rep isTouchDown])
          phase = UITouchPhaseBegan;
        else if ([rep isMove])
          phase = UITouchPhaseMoved;
        else if ([rep isCancel])
          phase = UITouchPhaseCancelled;
        else if ([rep isLift] || [rep isInRange] || [rep isInRangeLift])
          phase = UITouchPhaseEnded;
        
        NSInteger pointerId = [[[[rep handInfo] paths] firstObject] pathIdentity];
        if (pointerId <= 0) pointerId = 1;
        [TSEventFetcher receiveAXEventID:MIN(MAX(pointerId, 1), 98)
                      atGlobalCoordinate:loc
                          withTouchPhase:phase
                                inWindow:hitWindow
                                  onView:keyView];
      });
    }
  }
}
#endif

int main(int argc, char *argv[]) {
  @autoreleasepool {
    log_debug(OS_LOG_DEFAULT, "launched argc %{public}d, argv[1] %{public}s", argc, argc > 1 ? argv[1] : "NULL");

#if !NO_TROLL
    // 对齐 qwer/wasd：普通点击启动直接进 UI，不做 jbclient/DOEnvironmentManager
    // （那些会在启动瞬间拉起 libjailbreak→libchoma；choma 坏切片曾导致 iOS15 秒退）
    if (!NHIsOverlayRole()) {
      // 对齐 Dopamine：principalClass=nil，走系统 UIApplication
      return UIApplicationMain(argc, argv, nil, @"MainApplicationDelegate");
    }

    // 叠层角色由每机派生 env 标记（不再依赖 Helium 同源 -hud/-exit/-check argv）
    {
      pid_t pid = getpid();
      pid_t pgid = getgid();
      (void)pgid;
      log_debug(OS_LOG_DEFAULT, "overlay pid %d, pgid %d", pid, pgid);
      
      // 始终写入 notify 态；仅「配置落盘」开启时才写 pid 文件
      NHPublishPid(pid);
      if (NHPersistFilesEnabled()) {
        NSString *pidString = [NSString stringWithFormat:@"%d", pid];
        [pidString writeToFile:NHPidPath() atomically:YES encoding:NSUTF8StringEncoding error:nil];
      } else {
        unlink([NHPidPath() UTF8String]);
      }
      
      [UIScreen initialize];
      CFRunLoopGetCurrent();
            
      GSInitialize();
      BKSDisplayServicesStart();
      UIApplicationInitialize();
      
      UIApplicationInstantiateSingleton(objc_getClass("HUDMainApplication"));
      static id<UIApplicationDelegate> appDelegate = [[objc_getClass("BBZViewController") alloc] init];
      [UIApplication.sharedApplication setDelegate:appDelegate];
      [UIApplication.sharedApplication _accessibilityInit];

      // HUD 路径才初始化触摸池（Books 冷启动不再 +load）
      [TSEventFetcher setupIfNeeded];
      
      [NSRunLoop currentRunLoop];
      BKSHIDEventRegisterEventCallback(_HUDEventCallback);
      
      if (@available(iOS 15.0, *)) {
        GSEventInitialize(0);
        GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
      }
      
      [UIApplication.sharedApplication __completeAndRunAsPlugin];
      
      static int _springboardBootToken;
      notify_register_dispatch("SBSpringBoardDidLaunchNotification", &_springboardBootToken, dispatch_get_main_queue(), ^(int token) {
        notify_cancel(token);
        notify_post(NOTIFY_DISMISSAL_HUD);
        // Re-enable HUD after SpringBoard is launched.
        SetHUDEnabled(YES);
        // Exit the current instance of HUD.
        kill(pid, SIGKILL);
      });
      
      CFRunLoopRun();
      return EXIT_SUCCESS;
    }
#else
    return UIApplicationMain(argc, argv, nil, @"MainApplicationDelegate");
#endif
  }
}
