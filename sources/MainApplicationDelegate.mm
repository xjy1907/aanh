//
//  MainApplicationDelegate.mm — SHELL4：极简 entitlements + 独立 Bundle ID
//

#import "MainApplicationDelegate.h"

__attribute__((used)) static const char kDrawFpsSegMarker[] = "DRAWFPS_SEG_V1";
__attribute__((used)) static const char kShellMarker[] = "SHELL4-MIN-ENT";

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
  // 纯绿：区分 SHELL3 红屏；能看见 = 冷启动已活
  root.view.backgroundColor = [UIColor colorWithRed:0.0f green:0.75f blue:0.2f alpha:1.0f];

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = @"SHELL4-MIN-ENT";
  title.textColor = [UIColor whiteColor];
  title.font = [UIFont systemFontOfSize:22.0f weight:UIFontWeightBold];
  title.textAlignment = NSTextAlignmentCenter;

  UILabel *hint = [[UILabel alloc] init];
  hint.translatesAutoresizingMaskIntoConstraints = NO;
  hint.text = @"绿屏=活着\nbundle=com.nh.shell4diag\nent=skip-libval only";
  hint.textColor = [UIColor colorWithWhite:1.0f alpha:0.92f];
  hint.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
  hint.textAlignment = NSTextAlignmentCenter;
  hint.numberOfLines = 0;

  [root.view addSubview:title];
  [root.view addSubview:hint];
  [NSLayoutConstraint activateConstraints:@[
    [title.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
    [title.centerYAnchor constraintEqualToAnchor:root.view.centerYAnchor constant:-28],
    [hint.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
    [hint.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:14],
    [hint.leadingAnchor constraintGreaterThanOrEqualToAnchor:root.view.leadingAnchor constant:24],
    [hint.trailingAnchor constraintLessThanOrEqualToAnchor:root.view.trailingAnchor constant:-24],
  ]];

  self.window.rootViewController = root;
  [self.window makeKeyAndVisible];
  return YES;
}

@end
