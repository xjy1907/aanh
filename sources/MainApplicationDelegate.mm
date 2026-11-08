//
//  MainApplicationDelegate.mm
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import "MainApplicationDelegate.h"
#import "MainApplication.h"
#import "BBZView.h"

#import "HUDHelper.h"

@implementation MainApplicationDelegate {
    BBZView *_cdViewController;
}

- (instancetype)init {
    if (self = [super init]) {
        log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate init]");
    }
    return self;
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    if ([url.scheme isEqualToString:@"Books"]) {
        if ([url.host isEqualToString:@"toggle"]) {
            [self setupAndNotifyToggleHUDAfterLaunchWithAction:nil];
            return YES;
        } else if ([url.host isEqualToString:@"on"]) {
            [self setupAndNotifyToggleHUDAfterLaunchWithAction:kToggleHUDAfterLaunchNotificationActionToggleOn];
            return YES;
        } else if ([url.host isEqualToString:@"off"]) {
            [self setupAndNotifyToggleHUDAfterLaunchWithAction:kToggleHUDAfterLaunchNotificationActionToggleOff];
            return YES;
        }
    }
    return NO;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler
{
    if ([shortcutItem.type isEqualToString:@"com.nh.shortcut.toggle-hud"])
    {
        [self setupAndNotifyToggleHUDAfterLaunchWithAction:nil];
    }
}

- (void)setupAndNotifyToggleHUDAfterLaunchWithAction:(NSString *)action
{
    [BBZView setShouldToggleHUDAfterLaunch:YES];
    if (action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kToggleHUDAfterLaunchNotificationName object:nil userInfo:@{
            kToggleHUDAfterLaunchNotificationActionKey: action,
        }];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kToggleHUDAfterLaunchNotificationName object:nil];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions {
    log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions);

    // 对齐 Dopamine：先亮窗再挂主界面，避免冷启动同步拉起重依赖导致 iPadOS15 黑屏。
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *boot = [[UIViewController alloc] init];
    boot.view.backgroundColor = [UIColor colorWithRed:18.0f/255.0f green:10.0f/255.0f blue:28.0f/255.0f alpha:1.0f];
    UILabel *status = [[UILabel alloc] initWithFrame:CGRectZero];
    status.translatesAutoresizingMaskIntoConstraints = NO;
    status.text = @"正在初始化系统...";
    status.textColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
    status.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
    status.textAlignment = NSTextAlignmentCenter;
    [boot.view addSubview:status];
    [NSLayoutConstraint activateConstraints:@[
        [status.centerXAnchor constraintEqualToAnchor:boot.view.centerXAnchor],
        [status.centerYAnchor constraintEqualToAnchor:boot.view.centerYAnchor],
        [status.leadingAnchor constraintGreaterThanOrEqualToAnchor:boot.view.leadingAnchor constant:24],
        [status.trailingAnchor constraintLessThanOrEqualToAnchor:boot.view.trailingAnchor constant:-24],
    ]];
    [self.window setRootViewController:boot];
    [self.window makeKeyAndVisible];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf->_cdViewController = [[BBZView alloc] init];
        [strongSelf.window setRootViewController:strongSelf->_cdViewController];
    });

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    log_debug(OS_LOG_DEFAULT, "- [MainApplicationDelegate applicationDidBecomeActive:%{public}@]", application);

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf->_cdViewController reloadMainButtonState];
    });
}

@end
