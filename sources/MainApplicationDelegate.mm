//
//  MainApplicationDelegate.mm — shell-only 冷启动诊断
//

#import "MainApplicationDelegate.h"

// CI Pack IPA 校验用：壳包暂无真实 FPS 面板，强制保留字符串避免被优化掉
__attribute__((used)) static const char kDrawFpsSegMarker[] = "DRAWFPS_SEG_V1";


@implementation MainApplicationDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
  (void)application;
  (void)launchOptions;
  // touch the marker so linker cannot dead-strip it
  volatile const char *keep = kDrawFpsSegMarker;
  (void)keep[0];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  UIViewController *root = [[UIViewController alloc] init];
  // 深紫，便于和 SpringBoard 模糊区分：能看到这屏 = 冷启动已活
  root.view.backgroundColor = [UIColor colorWithRed:18.0f / 255.0f
                                               green:10.0f / 255.0f
                                                blue:28.0f / 255.0f
                                               alpha:1.0f];

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = @"正在初始化系统...";
  title.textColor = [UIColor colorWithRed:200.0f / 255.0f
                                    green:120.0f / 255.0f
                                     blue:255.0f / 255.0f
                                    alpha:1.0f];
  title.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightSemibold];
  title.textAlignment = NSTextAlignmentCenter;

  UILabel *hint = [[UILabel alloc] init];
  hint.translatesAutoresizingMaskIntoConstraints = NO;
  hint.text = @"SHELL-ONLY / iOS15 诊断壳";
  hint.textColor = [UIColor colorWithWhite:0.65f alpha:1.0f];
  hint.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
  hint.textAlignment = NSTextAlignmentCenter;

  [root.view addSubview:title];
  [root.view addSubview:hint];
  [NSLayoutConstraint activateConstraints:@[
    [title.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
    [title.centerYAnchor constraintEqualToAnchor:root.view.centerYAnchor constant:-12],
    [hint.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
    [hint.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
  ]];

  self.window.rootViewController = root;
  [self.window makeKeyAndVisible];
  return YES;
}

@end
