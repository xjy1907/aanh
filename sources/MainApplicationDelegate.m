//
//  MainApplicationDelegate.m — 验收⑲：薄 ESP / W2S
//

#import "MainApplicationDelegate.h"
#import "Step2BusinessViewController.h"

__attribute__((used)) static const char kDrawFpsSegMarker[] = "DRAWFPS_SEG_V1";
__attribute__((used)) static const char kStep13Marker[] = "STEP13-DRAWSURF";
__attribute__((used)) static const char kStep14Marker[] = "STEP14-LIVECOVER";
__attribute__((used)) static const char kStep15Marker[] = "STEP15-METAL";
__attribute__((used)) static const char kStep16Marker[] = "STEP16-TFHOST";
__attribute__((used)) static const char kStep17Marker[] = "STEP17-IMGUI";
__attribute__((used)) static const char kStep18Marker[] = "STEP18-READPROBE";
__attribute__((used)) static const char kStep19Marker[] = "STEP19-THINESP";

@implementation MainApplicationDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
  (void)application;
  (void)launchOptions;
  volatile const char *keepFps = kDrawFpsSegMarker;
  volatile const char *keepStep13 = kStep13Marker;
  volatile const char *keepStep14 = kStep14Marker;
  volatile const char *keepStep15 = kStep15Marker;
  volatile const char *keepStep16 = kStep16Marker;
  volatile const char *keepStep17 = kStep17Marker;
  volatile const char *keepStep18 = kStep18Marker;
  volatile const char *keepStep19 = kStep19Marker;
  (void)keepFps[0];
  (void)keepStep13[0];
  (void)keepStep14[0];
  (void)keepStep15[0];
  (void)keepStep16[0];
  (void)keepStep17[0];
  (void)keepStep18[0];
  (void)keepStep19[0];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  UIViewController *boot = [[UIViewController alloc] init];
  boot.view.backgroundColor = [UIColor colorWithRed:18.0f / 255.0f
                                               green:10.0f / 255.0f
                                                blue:28.0f / 255.0f
                                               alpha:1.0f];
  UILabel *status = [[UILabel alloc] init];
  status.translatesAutoresizingMaskIntoConstraints = NO;
  status.text = @"正在初始化系统...";
  status.textColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
  status.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
  status.textAlignment = NSTextAlignmentCenter;
  [boot.view addSubview:status];
  [NSLayoutConstraint activateConstraints:@[
    [status.centerXAnchor constraintEqualToAnchor:boot.view.centerXAnchor],
    [status.centerYAnchor constraintEqualToAnchor:boot.view.centerYAnchor],
  ]];
  self.window.rootViewController = boot;
  [self.window makeKeyAndVisible];

  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    strongSelf.window.rootViewController = [[Step2BusinessViewController alloc] init];
  });
  return YES;
}

@end
