//
//  MainApplicationDelegate.m — 验收④B：去掉 iOS15 禁用权限，保留 HUD/HID
//

#import "MainApplicationDelegate.h"
#import "Step2BusinessViewController.h"

__attribute__((used)) static const char kDrawFpsSegMarker[] = "DRAWFPS_SEG_V1";
__attribute__((used)) static const char kStep4bMarker[] = "STEP4B-SAFE-ENT";

@implementation MainApplicationDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
  (void)application;
  (void)launchOptions;
  volatile const char *keepFps = kDrawFpsSegMarker;
  volatile const char *keepStep = kStep4bMarker;
  (void)keepFps[0];
  (void)keepStep[0];

  // 先亮窗（对齐 SHELL5 / Dopamine），避免同步拉起重依赖
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
    // 验收④B：轻量面板 + 延后 dlopen；本步只用 iOS15 安全 entitlements
    strongSelf.window.rootViewController = [[Step2BusinessViewController alloc] init];
  });
  return YES;
}

@end
