//
//  MainApplicationDelegate.m — SHELL5 纯 ObjC UI
//

#import "MainApplicationDelegate.h"
#import <stdio.h>
#import <unistd.h>

__attribute__((used)) static const char kDrawFpsSegMarker[] = "DRAWFPS_SEG_V1";
__attribute__((used)) static const char kShellMarker[] = "SHELL5-NOPCH";

static void Shell5Probe(const char *tag) {
  const char *paths[] = {
      "/var/mobile/Documents/SHELL5_PROBE.txt",
      "/tmp/SHELL5_PROBE.txt",
      NULL,
  };
  for (int i = 0; paths[i]; i++) {
    FILE *f = fopen(paths[i], "a");
    if (!f) continue;
    fprintf(f, "%s pid=%d\n", tag, (int)getpid());
    fclose(f);
  }
  NSArray *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  if (docs.count) {
    NSString *p = [docs[0] stringByAppendingPathComponent:@"SHELL5_PROBE.txt"];
    FILE *f = fopen(p.fileSystemRepresentation, "a");
    if (f) {
      fprintf(f, "%s pid=%d home\n", tag, (int)getpid());
      fclose(f);
    }
  }
}

@implementation MainApplicationDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
  (void)application;
  (void)launchOptions;
  volatile const char *keepFps = kDrawFpsSegMarker;
  volatile const char *keepShell = kShellMarker;
  (void)keepFps[0];
  (void)keepShell[0];
  Shell5Probe("didFinish-enter");

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  UIViewController *root = [[UIViewController alloc] init];
  // 纯蓝：区分 SHELL3 红 / SHELL4 绿
  root.view.backgroundColor = [UIColor colorWithRed:0.05f green:0.35f blue:0.95f alpha:1.0f];

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = @"SHELL5-NOPCH";
  title.textColor = [UIColor whiteColor];
  title.font = [UIFont systemFontOfSize:22.0f weight:UIFontWeightBold];
  title.textAlignment = NSTextAlignmentCenter;

  UILabel *hint = [[UILabel alloc] init];
  hint.translatesAutoresizingMaskIntoConstraints = NO;
  hint.text = @"蓝屏=活着\n无 pch / 纯 ObjC / 空 entitlements\n探针: Documents/SHELL5_PROBE.txt";
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
  Shell5Probe("didFinish-visible");
  return YES;
}

@end
