//
//  HUDApp.mm
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <mach-o/dyld.h>
#import <notify.h>
#import <objc/runtime.h>
#import <sys/utsname.h>

#if !NO_TROLL
#import "AXEventRepresentation.h"
#import "BackboardServices.h"
#import "HUDHelper.h"
#import "IOKit+SPI.h"
#import "TSEventFetcher.h"
#import "UIApplication+Private.h"

#import "DOEnvironmentManager.h"
#import <libjailbreak/info.h>
#import <libjailbreak/jbclient_xpc.h>
#import "LFVirtualDigitizer.h"
#define PID_PATH "/var/mobile/Library/Caches/com.nh.hud.pid"

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
        static UIWindow *keyWindow = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
          keyWindow = [[app windows] firstObject];
        });
        
        UIView *keyView = [keyWindow hitTest:[rep location] withEvent:nil];
        
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
        if (pointerId > 0)
          [TSEventFetcher receiveAXEventID:MIN(MAX(pointerId, 1), 98)
                        atGlobalCoordinate:[rep location]
                            withTouchPhase:phase
                                  inWindow:keyWindow
                                    onView:keyView];
      });
    }
  }
}
#endif

int main(int argc, char *argv[]) {
  @autoreleasepool {
    log_debug(OS_LOG_DEFAULT, "launched argc %{public}d, argv[1] %{public}s", argc, argc > 1 ? argv[1] : "NULL");
    
    /// jai
    {
      // If systemhook isn't loaded and we are already jailbroken, we need to do the checkin ourselves
      // This can happen when the jailbreak is hidden or when tweak injection into the Dopamine app is disabled via Choicy
      jbclient_process_checkin(NULL, NULL, NULL, NULL);
      
      if ([DOEnvironmentManager sharedManager].isJailbroken) {
        setenv("PATH", "/sbin:/bin:/usr/sbin:/usr/bin:/var/jb/sbin:/var/jb/bin:/var/jb/usr/sbin:/var/jb/usr/bin", 1);
        setenv("TERM", "xterm-256color", 1);
      }
    }
    
#if !NO_TROLL
    if (argc <= 1) {
      return UIApplicationMain(argc, argv, @"MainApplication", @"MainApplicationDelegate");
    }
    
    if (strcmp(argv[1], "-hud") == 0) {
        
        
      pid_t pid = getpid();
      pid_t pgid = getgid();
      (void)pgid;
      log_debug(OS_LOG_DEFAULT, "HUD pid %d, pgid %d", pid, pgid);
      
      NSString *pidString = [NSString stringWithFormat:@"%d", pid];
      [pidString writeToFile:ROOT_PATH_NS(PID_PATH) atomically:YES encoding:NSUTF8StringEncoding error:nil];
      
      [UIScreen initialize];
      CFRunLoopGetCurrent();
            
      GSInitialize();
      BKSDisplayServicesStart();
      UIApplicationInitialize();
      
      UIApplicationInstantiateSingleton(objc_getClass("HUDMainApplication"));
      static id<UIApplicationDelegate> appDelegate = [[objc_getClass("BBZViewController") alloc] init];
      [UIApplication.sharedApplication setDelegate:appDelegate];
      [UIApplication.sharedApplication _accessibilityInit];
      
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
    } else if (strcmp(argv[1], "-exit") == 0) {
      NSString *pidString = [NSString stringWithContentsOfFile:ROOT_PATH_NS(PID_PATH)
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];
      
      if (pidString) {
        pid_t pid = (pid_t)[pidString intValue];
        kill(pid, SIGKILL);
        unlink([ROOT_PATH_NS(PID_PATH) UTF8String]);
      }
      
      return EXIT_SUCCESS;
    } else if (strcmp(argv[1], "-check") == 0) {
      NSString *pidString = [NSString stringWithContentsOfFile:ROOT_PATH_NS(PID_PATH)
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];
      
      if (pidString) {
        pid_t pid = (pid_t)[pidString intValue];
        int killed = kill(pid, 0);
        return (killed == 0 ? EXIT_FAILURE : EXIT_SUCCESS);
      } else
        return EXIT_SUCCESS; // No PID file, so HUD is not running
    }
#else
    return UIApplicationMain(argc, argv, @"MainApplication", @"MainApplicationDelegate");
#endif
  }
}
