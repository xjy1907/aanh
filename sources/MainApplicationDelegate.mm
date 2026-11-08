//
//  MainApplicationDelegate.mm — shell-only 冷启动诊断（无嵌入 dylib）
//

#import "MainApplicationDelegate.h"

// CI Pack IPA 校验用：壳包暂无真实 FPS 面板，强制保留字符串避免被优化掉
__attribute__((used)) static const char kDrawFpsSegMarker[] = "DRAWFPS_SEG_V1";
__attribute__((used)) static const char kShellMarker[] = "SHELL3-NO-DYLIB";

@implementation MainApplicationDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
  (void)application;
  (void)launchOptions;
  volatile const char *keepFps = kDrawFpsSegMarker;
  volatile const char *keepShell = kShellMarker;
  (void)keepFps[0];
  (void)keepShell[0];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  UIViewController *root = [[UIViewController alloc] init];
  // 纯红：一眼可辨；若仍秒退回桌面，说明崩在 makeKeyAndVisible 之前
  root.view.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f];

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = @"SHELL3-NO-DYLIB";
  title.textColor = [UIColor whiteColor];
  title.font = [UIFont systemFontOfSize:22.0f weight:UIFontWeightBold];
  title.textAlignment = NSTextAlignmentCenter;

  UILabel *hint = [[UILabel alloc] init];
  hint.translatesAutoresizingMaskIntoConstraints = NO;
  hint.text = @"能看见红屏 = 冷启动已活\n包内已剔除 libNH*/越狱 dylib";
  hint.textColor = [UIColor colorWithWhite:1.0f alpha:0.9f];
  hint.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
  hint.textAlignment = NSTextAlignmentCenter;
  hint.numberOfLines = 0;

  [root.view addSubview:title];
  [root.view addSubview:hint];
  [NSLayoutConstraint activateConstraints:@[
    [title.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
    [title.centerYAnchor constraintEqualToAnchor:root.view.centerYAnchor constant:-24],
    [hint.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
    [hint.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:16],
    [hint.leadingAnchor constraintGreaterThanOrEqualToAnchor:root.view.leadingAnchor constant:24],
    [hint.trailingAnchor constraintLessThanOrEqualToAnchor:root.view.trailingAnchor constant:-24],
  ]];

  self.window.rootViewController = root;
  [self.window makeKeyAndVisible];
  return YES;
}

@end
