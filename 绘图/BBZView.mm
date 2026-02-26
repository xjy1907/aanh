//
//  RootViewController.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <notify.h>
#import "HUDHelper.h"
#import "MainButton.h"
#import "MainApplication.h"
#import "HUDPresetPosition.h"
#import "BBZView.h"
#import "UIApplication+Private.h"
#import "AdSupport/AdSupport.h"
#import "DOJailbreaker.h"
#import "LFSenderIDViewController.h"  // 内核选择页

// 数据线程仅在 HUD 进程中启动，这里只做初始化与拦截

// 声明日志回调注册接口（由 DOJailbreaker.m 内嵌提供）
#ifdef __cplusplus
extern "C" {
#endif
void KernelLoggerSetHandler(void (^handler)(NSString *line));
#ifdef __cplusplus
}
#endif


#define HUD_TRANSITION_DURATION 0.25

static bool bFindDNF = false, shouldKeepDeleting = NO;

static BOOL _gShouldToggleHUDAfterLaunch = NO;
static const CGFloat _gTopButtonConstraintsConstantCompact = 46.f;
static const CGFloat _gTopButtonConstraintsConstantRegular = 28.f;
static const CGFloat _gTopButtonConstraintsConstantRegularPad = 46.f;
static const CGFloat _gAuthorLabelBottomConstraintConstantCompact = -20.f;
static const CGFloat _gAuthorLabelBottomConstraintConstantRegular = -80.f;

// 内核日志全局弱引用（供 C 函数转发）
static __weak BBZView *gRootVC = nil;

// 对外提供的 C 接口：DOJailbreaker.m 可直接调用 KernelLogLine("...") 输出到日志框
#ifdef __cplusplus
extern "C" {
#endif
void KernelLogLine(const char *line);
#ifdef __cplusplus
}
#endif

@implementation BBZView {
    NSMutableDictionary *_userDefaults;
    MainButton *_mainButton;
    UIButton *_initKernelButton;
    UIActivityIndicatorView *_initActivity;
    BOOL _isInitializingKernel;
    UIButton *_settingsButton;
    UIButton *_topLeftButton;
    UIButton *_topRightButton;
    UIButton *_topCenterButton;
    UIButton *_topCenterMostButton;
    UILabel *_authorLabel;
    BOOL _supportsCenterMost;
    NSLayoutConstraint *_topLeftConstraint;
    NSLayoutConstraint *_topRightConstraint;
    NSLayoutConstraint *_topCenterConstraint;
    NSLayoutConstraint *_authorLabelBottomConstraint;
    BOOL _isRemoteHUDActive;
    //HUDRootViewController *_localHUDRootViewController;  // Only for debugging
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
    UITextView *_kernelLogView;
}

+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag
{
    _gShouldToggleHUDAfterLaunch = flag;
}

+ (BOOL)shouldToggleHUDAfterLaunch
{
    return _gShouldToggleHUDAfterLaunch;
}

- (BOOL)isHUDEnabled
{
#if !NO_TROLL
    return IsHUDEnabled();
#else
    return _localHUDRootViewController != nil;
#endif
}

- (void)setHUDEnabled:(BOOL)enabled
{
#if !NO_TROLL
    SetHUDEnabled(enabled);
#else
    if (enabled && _localHUDRootViewController == nil) {
        _localHUDRootViewController = [[HUDRootViewController alloc] init];
        [self presentViewController:_localHUDRootViewController animated:YES completion:nil];
    } else {
        [_localHUDRootViewController dismissViewControllerAnimated:YES completion:nil];
        _localHUDRootViewController = nil;
    }
#endif
}

- (void)registerNotifications
{
    int token;
    notify_register_dispatch(NOTIFY_RELOAD_APP, &token, dispatch_get_main_queue(), ^(int token) {
        [self loadUserDefaults:YES];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleHUDNotificationReceived:) name:kToggleHUDAfterLaunchNotificationName object:nil];
}

- (void)loadView
{
    CGRect bounds = UIScreen.mainScreen.bounds;
    
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3]; // 更浅的半透明背景
    
    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // 清新风格的渐变背景
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = bounds;
    
    gradientLayer.colors = @[
        (id)[UIColor colorWithRed:0.95 green:0.97 blue:1.00 alpha:1.0].CGColor,   // 浅蓝色
        (id)[UIColor colorWithRed:0.88 green:0.93 blue:0.98 alpha:1.0].CGColor, // 淡蓝色
        (id)[UIColor colorWithRed:0.92 green:0.96 blue:0.95 alpha:1.0].CGColor  // 浅青绿色
    ];
    
    // 设置渐变方向（从上到下）
    gradientLayer.startPoint = CGPointMake(0.5, 0);
    gradientLayer.endPoint = CGPointMake(0.5, 1);
    
    // 添加渐变层
    [self.backgroundView.layer insertSublayer:gradientLayer atIndex:0];
    
    [self.view addSubview:self.backgroundView];
    
    [self reloadModeButtonState];
    
    UILayoutGuide *safeArea = self.backgroundView.safeAreaLayoutGuide;
    
    // 创建图标和文字的容器
    UIView *headerContainer = [[UIView alloc] init];
    headerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addSubview:headerContainer];
    
    // 图标 - 使用系统图标
    UIImageView *iconImageView = [[UIImageView alloc] init];
    if (@available(iOS 13.0, *)) {
        UIImage *iconImage = [UIImage systemImageNamed:@"gamecontroller" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:80 weight:UIImageSymbolWeightLight]];
        iconImageView.image = iconImage;
    } else {
        // iOS 13 以下的备用方案
        iconImageView.image = [UIImage imageNamed:@"gamecontroller"]; // 需要你有这个图片资源
    }
    iconImageView.tintColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0]; // 蓝色图标
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerContainer addSubview:iconImageView];
    
    // 标题 Label - 清新风格
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"和平精英";
    titleLabel.textColor = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1.0];
    titleLabel.font = [UIFont fontWithName:@"Menlo-Bold" size:36];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.layer.shadowColor = [UIColor colorWithRed:0.7 green:0.8 blue:1.0 alpha:0.5].CGColor;
    titleLabel.layer.shadowRadius = 6;
    titleLabel.layer.shadowOpacity = 0.6;
    titleLabel.layer.shadowOffset = CGSizeMake(0, 2);
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [headerContainer addSubview:titleLabel];
    
    // 布局约束
    [NSLayoutConstraint activateConstraints:@[
        // 容器约束
        [headerContainer.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [headerContainer.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:50],
        
        // 图标约束
        [iconImageView.topAnchor constraintEqualToAnchor:headerContainer.topAnchor],
        [iconImageView.centerXAnchor constraintEqualToAnchor:headerContainer.centerXAnchor],
        [iconImageView.widthAnchor constraintEqualToConstant:50],
        [iconImageView.heightAnchor constraintEqualToConstant:50],
        
        // 标题约束
        [titleLabel.topAnchor constraintEqualToAnchor:iconImageView.bottomAnchor constant:8],
        [titleLabel.leadingAnchor constraintEqualToAnchor:headerContainer.leadingAnchor],
        [titleLabel.trailingAnchor constraintEqualToAnchor:headerContainer.trailingAnchor],
        [titleLabel.bottomAnchor constraintEqualToAnchor:headerContainer.bottomAnchor]
    ]];
    
    
    [self.backgroundView addSubview:titleLabel];
    
    [titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [titleLabel.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:60],
    ]];
    
    // 副标题 Label
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"点击按钮开启绘制";
    subtitleLabel.textColor = [UIColor colorWithRed:0.4 green:0.5 blue:0.6 alpha:1.0]; // 灰蓝色
    subtitleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.backgroundView addSubview:subtitleLabel];
    
    [subtitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [subtitleLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
    ]];
    
    // 移除粒子效果，保持清新简洁
    
    // 主按钮 - 清新风格
    _mainButton = [MainButton buttonWithType:UIButtonTypeSystem];
    [_mainButton setTintColor:[UIColor whiteColor]];
    [_mainButton addTarget:self action:@selector(tapMainButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration filledButtonConfiguration];
        config.baseBackgroundColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0]; // 清新蓝色
        config.baseForegroundColor = [UIColor whiteColor];
        config.cornerStyle = UIButtonConfigurationCornerStyleLarge;
        
        [config setTitleTextAttributesTransformer:^NSDictionary <NSAttributedStringKey, id> * _Nonnull(NSDictionary <NSAttributedStringKey, id> * _Nonnull textAttributes) {
            NSMutableDictionary *newAttributes = [textAttributes mutableCopy];
            [newAttributes setObject:[UIFont boldSystemFontOfSize:20.0] forKey:NSFontAttributeName];
            return newAttributes;
        }];
        
        [_mainButton setConfiguration:config];
    }
    else
    {
        [_mainButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
        _mainButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0];
        _mainButton.layer.cornerRadius = 12;
    }
    [self.backgroundView addSubview:_mainButton];
    
    [_mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_mainButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_mainButton.topAnchor constraintEqualToAnchor:subtitleLabel.bottomAnchor constant:50],
        [_mainButton.widthAnchor constraintEqualToConstant:200],
        [_mainButton.heightAnchor constraintEqualToConstant:50]
    ]];
    
    // 初始化内核按钮 - 清新风格
    _initKernelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_initKernelButton setTitle:@"初始化内核" forState:UIControlStateNormal];
    
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *initCfg = [UIButtonConfiguration borderedButtonConfiguration];
        initCfg.title = @"初始化内核";
        initCfg.cornerStyle = UIButtonConfigurationCornerStyleMedium;
        initCfg.baseForegroundColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0]; // 蓝色文字
        initCfg.baseBackgroundColor = [UIColor clearColor];
        initCfg.background.strokeColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0]; // 蓝色边框
        initCfg.background.strokeWidth = 2;
        
        initCfg.titleTextAttributesTransformer = ^NSDictionary *(NSDictionary *textAttributes) {
            NSMutableDictionary *newAttributes = [textAttributes mutableCopy];
            newAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
            return newAttributes;
        };
        
        initCfg.contentInsets = NSDirectionalEdgeInsetsMake(10, 25, 10, 25);
        
        _initKernelButton.configuration = initCfg;
    } else {
        _initKernelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _initKernelButton.backgroundColor = [UIColor clearColor];
        _initKernelButton.layer.cornerRadius = 10;
        _initKernelButton.layer.borderWidth = 2;
        _initKernelButton.layer.borderColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0].CGColor;
        [_initKernelButton setTitleColor:[UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0] forState:UIControlStateNormal];
        _initKernelButton.contentEdgeInsets = UIEdgeInsetsMake(10, 25, 10, 25);
    }
    
    [_initKernelButton addTarget:self action:@selector(tapInitKernelButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.backgroundView addSubview:_initKernelButton];
    [_initKernelButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_initKernelButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [_initKernelButton.topAnchor constraintEqualToAnchor:_mainButton.bottomAnchor constant:20],
    ]];
    
    // 第二个按钮 - 读取自瞄（清新风格）
    UIButton *secondButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [secondButton setTitle:@"读取自瞄" forState:UIControlStateNormal];
    
    if (@available(iOS 15.0, *)) {
        UIButtonConfiguration *secondConfig = [UIButtonConfiguration filledButtonConfiguration];
        
        secondConfig.title = @"读取自瞄";
        secondConfig.image = [UIImage systemImageNamed:@"scope"];
        secondConfig.imagePadding = 8;
        secondConfig.imagePlacement = NSDirectionalRectEdgeLeading;
        secondConfig.cornerStyle = UIButtonConfigurationCornerStyleMedium;
        secondConfig.baseBackgroundColor = [UIColor colorWithRed:0.4 green:0.7 blue:0.4 alpha:1.0]; // 清新绿色
        secondConfig.baseForegroundColor = [UIColor whiteColor];
        
        secondConfig.titleTextAttributesTransformer = ^NSDictionary *(NSDictionary *textAttributes) {
            NSMutableDictionary *newAttributes = [textAttributes mutableCopy];
            newAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
            return newAttributes;
        };
        
        secondConfig.contentInsets = NSDirectionalEdgeInsetsMake(12, 20, 12, 20);
        
        secondButton.configuration = secondConfig;
        
    } else {
        secondButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        secondButton.backgroundColor = [UIColor colorWithRed:0.4 green:0.7 blue:0.4 alpha:1.0];
        secondButton.layer.cornerRadius = 10;
        [secondButton setImage:[UIImage systemImageNamed:@"scope"] forState:UIControlStateNormal];
        secondButton.imageEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
        secondButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
        secondButton.contentEdgeInsets = UIEdgeInsetsMake(12, 20, 12, 20);
    }
    
    [secondButton addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
    [self.backgroundView addSubview:secondButton];
    
    [secondButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [secondButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [secondButton.topAnchor constraintEqualToAnchor:_initKernelButton.bottomAnchor constant:20],
    ]];
    
    // 初始化内核加载指示器
    if (@available(iOS 13.0, *)) {
        _initActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _initActivity.color = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1.0];
    } else {
        _initActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    }
    _initActivity.hidesWhenStopped = YES;
    [self.backgroundView addSubview:_initActivity];
    [_initActivity setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [_initActivity.centerXAnchor constraintEqualToAnchor:_initKernelButton.centerXAnchor],
        [_initActivity.topAnchor constraintEqualToAnchor:_initKernelButton.bottomAnchor constant:8],
    ]];
    
    // 日志文本框 - 清新风格
    _kernelLogView = [[UITextView alloc] init];
    _kernelLogView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9]; // 白色半透明背景
    _kernelLogView.textColor = [UIColor colorWithRed:0.2 green:0.3 blue:0.4 alpha:1.0]; // 深蓝色文字
    _kernelLogView.font = [UIFont fontWithName:@"Menlo" size:12.0];
    _kernelLogView.editable = NO;
    _kernelLogView.layer.cornerRadius = 12.0;
    _kernelLogView.layer.borderWidth = 1.5;
    _kernelLogView.layer.borderColor = [UIColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:1.0].CGColor; // 浅蓝色边框
    _kernelLogView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
    
    // 添加阴影
    _kernelLogView.layer.shadowColor = [UIColor colorWithRed:0.7 green:0.8 blue:0.9 alpha:0.3].CGColor;
    _kernelLogView.layer.shadowOffset = CGSizeMake(0, 2);
    _kernelLogView.layer.shadowRadius = 8;
    _kernelLogView.layer.shadowOpacity = 0.5;
    
    [self.backgroundView addSubview:_kernelLogView];
    [_kernelLogView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // 优化布局 - 按钮在上方，日志在下方
    [NSLayoutConstraint activateConstraints:@[
        [_kernelLogView.topAnchor constraintEqualToAnchor:secondButton.bottomAnchor constant:30],
        [_kernelLogView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:20],
        [_kernelLogView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-20],
        [_kernelLogView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-20],
        [_kernelLogView.heightAnchor constraintEqualToConstant:150] // 合适的高度
    ]];
    
    [self verticalSizeClassUpdated];
    [self reloadMainButtonState];
}


- (void)showSettings:(UIButton *)sender {
    LFSenderIDViewController *vc = [LFSenderIDViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
    
}


- (UIImage *)generateParticleImage {
    CGFloat size = 10.0;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.4 green:0.8 blue:1.0 alpha:1.0].CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, size, size));
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _supportsCenterMost = CGRectGetMinY(self.view.window.safeAreaLayoutGuide.layoutFrame) >= 51;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    
    [self registerNotifications];
    
    // 注册全局弱引用与日志处理回调
    gRootVC = self;
    KernelLoggerSetHandler(^(NSString *line) {
        if ([gRootVC respondsToSelector:@selector(appendKernelLog:)]) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [gRootVC performSelector:@selector(appendKernelLog:) withObject:line];
    #pragma clang diagnostic pop
        } else if (self->_kernelLogView) { // 显式引用 self
            NSString *old = self->_kernelLogView.text ?: @"";
            NSString *nl = old.length ? @"\n" : @"";
            self->_kernelLogView.text = [old stringByAppendingFormat:@"%@%@", nl, line];
            [self->_kernelLogView scrollRangeToVisible:NSMakeRange(self->_kernelLogView.text.length, 0)];
        }
    });
    
    // 验证链路：注册后输出一行测试日志
    KernelLogLine("UI 日志回调已注册");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self toggleHUDAfterLaunch];
    
    // 视图出现后查询一次内核状态并写入日志
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL ok = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
        KernelLogLine(ok ? "内核状态：已就绪" : "内核状态：未就绪");
    });
}

- (void)toggleHUDNotificationReceived:(NSNotification *)notification {
    NSString *toggleAction = notification.userInfo[kToggleHUDAfterLaunchNotificationActionKey];
    if (!toggleAction) {
        [self toggleHUDAfterLaunch];
    } else if ([toggleAction isEqualToString:kToggleHUDAfterLaunchNotificationActionToggleOn]) {
        [self toggleOnHUDAfterLaunch];
    } else if ([toggleAction isEqualToString:kToggleHUDAfterLaunchNotificationActionToggleOff]) {
        [self toggleOffHUDAfterLaunch];
    }
}

- (void)toggleHUDAfterLaunch {
    if ([BBZView shouldToggleHUDAfterLaunch]) {
        [BBZView setShouldToggleHUDAfterLaunch:NO];
        [self tapMainButton:_mainButton];
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOnHUDAfterLaunch {
    if ([BBZView shouldToggleHUDAfterLaunch]) {
        [BBZView setShouldToggleHUDAfterLaunch:NO];
        if (!_isRemoteHUDActive) {
            [self tapMainButton:_mainButton];
        }
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOffHUDAfterLaunch {
    if ([BBZView shouldToggleHUDAfterLaunch]) {
        [BBZView setShouldToggleHUDAfterLaunch:NO];
        if (_isRemoteHUDActive) {
            [self tapMainButton:_mainButton];
        }
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Developer Area", nil) message:NSLocalizedString(@"Choose an action below.", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Reset Settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self resetUserDefaults];
        }]];
#if DEBUG && !NO_TROLL
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Memory Pressure", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            SimulateMemoryPressure();
        }]];
#endif
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)resetUserDefaults
{
#if !NO_TROLL
    // Reset user defaults
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleIdentifier) {
        [GetStandardUserDefaults() removePersistentDomainForName:bundleIdentifier];
        [GetStandardUserDefaults() synchronize];
    }
#endif
    
    // Reset custom user defaults
    BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH)) error:nil];
    if (removed)
    {
        // Terminate HUD
        [self setHUDEnabled:NO];
        
        // Terminate App
        [[UIApplication sharedApplication] terminateWithSuccess];
    }
}

- (void)loadUserDefaults:(BOOL)forceReload
{
    if (forceReload || !_userDefaults) {
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH))] mutableCopy] ?: [NSMutableDictionary dictionary];
    }
}

- (void)saveUserDefaults
{
    [_userDefaults writeToFile:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH)) atomically:YES];
    notify_post(NOTIFY_RELOAD_HUD);
}

- (BOOL)isLandscapeOrientation
{
    UIInterfaceOrientation orientation;
    orientation = self.view.window.windowScene.interfaceOrientation;
    BOOL isLandscape;
    if (orientation == UIInterfaceOrientationUnknown) {
        isLandscape = CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds);
    } else {
        isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    }
    return isLandscape;
}

- (HUDUserDefaultsKey)selectedModeKeyForCurrentOrientation
{
    return [self isLandscapeOrientation] ? HUDUserDefaultsKeySelectedModeLandscape : HUDUserDefaultsKeySelectedMode;
}

- (HUDPresetPosition)selectedModeForCurrentOrientation
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:[self selectedModeKeyForCurrentOrientation]];
    return mode != nil ? (HUDPresetPosition)[mode integerValue] : HUDPresetPositionTopCenter;
}

- (void)setSelectedModeForCurrentOrientation:(HUDPresetPosition)selectedMode
{
    [self loadUserDefaults:NO];
    // Remove some keys that are not persistent
    if ([self isLandscapeOrientation]) {
        [_userDefaults removeObjectForKey:HUDUserDefaultsKeyCurrentLandscapePositionY];
    } else {
        [_userDefaults removeObjectForKey:HUDUserDefaultsKeyCurrentPositionY];
    }
    [_userDefaults setObject:@(selectedMode) forKey:[self selectedModeKeyForCurrentOrientation]];
    [self saveUserDefaults];
}

- (BOOL)passthroughMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyPassthroughMode];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setPassthroughMode:(BOOL)passthroughMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(passthroughMode) forKey:HUDUserDefaultsKeyPassthroughMode];
    [self saveUserDefaults];
}

- (BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeySingleLineMode];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setSingleLineMode:(BOOL)singleLineMode
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(singleLineMode) forKey:HUDUserDefaultsKeySingleLineMode];
    [self saveUserDefaults];
}

- (BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesBitrate];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesBitrate:(BOOL)usesBitrate
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesBitrate) forKey:HUDUserDefaultsKeyUsesBitrate];
    [self saveUserDefaults];
}

- (BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesArrowPrefixes];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesArrowPrefixes:(BOOL)usesArrowPrefixes
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesArrowPrefixes) forKey:HUDUserDefaultsKeyUsesArrowPrefixes];
    [self saveUserDefaults];
}

- (BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesLargeFont];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesLargeFont:(BOOL)usesLargeFont
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesLargeFont) forKey:HUDUserDefaultsKeyUsesLargeFont];
    [self saveUserDefaults];
}

- (BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesRotation];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesRotation:(BOOL)usesRotation
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesRotation) forKey:HUDUserDefaultsKeyUsesRotation];
    [self saveUserDefaults];
}

- (BOOL)usesInvertedColor
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesInvertedColor];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setUsesInvertedColor:(BOOL)usesInvertedColor
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(usesInvertedColor) forKey:HUDUserDefaultsKeyUsesInvertedColor];
    [self saveUserDefaults];
}

- (BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyKeepInPlace];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setKeepInPlace:(BOOL)keepInPlace
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(keepInPlace) forKey:HUDUserDefaultsKeyKeepInPlace];
    [self saveUserDefaults];
}

- (BOOL)hideAtSnapshot
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:HUDUserDefaultsKeyHideAtSnapshot];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)setHideAtSnapshot:(BOOL)hideAtSnapshot
{
    [self loadUserDefaults:NO];
    [_userDefaults setObject:@(hideAtSnapshot) forKey:HUDUserDefaultsKeyHideAtSnapshot];
    [self saveUserDefaults];
}

- (void)reloadMainButtonState
{
    _isRemoteHUDActive = [self isHUDEnabled];
    
    static NSAttributedString *hintAttributedString = nil;
    static NSAttributedString *creditsAttributedString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *defaultAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
        };
        
        NSMutableParagraphStyle *creditsParaStyle = [[NSMutableParagraphStyle alloc] init];
        creditsParaStyle.lineHeightMultiple = 1.2;
        creditsParaStyle.alignment = NSTextAlignmentCenter;
        
        NSDictionary *creditsAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSParagraphStyleAttributeName: creditsParaStyle,
        };
        
        NSString *hintText = NSLocalizedString(@"You can quit this app now.\nThe HUD will persist on your screen.", nil);
        hintAttributedString = [[NSAttributedString alloc] initWithString:hintText attributes:defaultAttributes];
        
        NSTextAttachment *githubIcon = [NSTextAttachment textAttachmentWithImage:[UIImage imageNamed:@"github-mark-white"]];
        [githubIcon setBounds:CGRectMake(0, 0, 14, 14)];
        
        NSTextAttachment *i18nIcon = [NSTextAttachment textAttachmentWithImage:[UIImage systemImageNamed:@"character.bubble.fill"]];
        [i18nIcon setBounds:CGRectMake(0, 0, 14, 14)];
        
        NSAttributedString *githubIconText = [NSAttributedString attributedStringWithAttachment:githubIcon];
        NSMutableAttributedString *githubIconTextFull = [[NSMutableAttributedString alloc] initWithAttributedString:githubIconText];
        [githubIconTextFull appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:creditsAttributes]];
        
        NSAttributedString *i18nIconText = [NSAttributedString attributedStringWithAttachment:i18nIcon];
        NSMutableAttributedString *i18nIconTextFull = [[NSMutableAttributedString alloc] initWithAttributedString:i18nIconText];
        [i18nIconTextFull appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:creditsAttributes]];
        
        NSString *creditsText = NSLocalizedString(@"Made with ♥ by @GITHUB@Lessica and @GITHUB@jmpews\nTranslation @TRANSLATION@", nil);
        NSMutableAttributedString *creditsAttributedText = [[NSMutableAttributedString alloc] initWithString:creditsText attributes:creditsAttributes];
        
        // replace all "@GITHUB@" with github icon
        NSRange atRange;
        
        atRange = [creditsAttributedText.string rangeOfString:@"@GITHUB@"];
        while (atRange.location != NSNotFound) {
            [creditsAttributedText replaceCharactersInRange:atRange withAttributedString:githubIconTextFull];
            atRange = [creditsAttributedText.string rangeOfString:@"@GITHUB@"];
        }
        
        // replace all "@TRANSLATION@" with character bubble
        atRange = [creditsAttributedText.string rangeOfString:@"@TRANSLATION@"];
        while (atRange.location != NSNotFound) {
            [creditsAttributedText replaceCharactersInRange:atRange withAttributedString:i18nIconTextFull];
            atRange = [creditsAttributedText.string rangeOfString:@"@TRANSLATION@"];
        }
        
        creditsAttributedString = creditsAttributedText;
    });
    
    __weak typeof(self) weakSelf = self;
    [UIView transitionWithView:self.backgroundView duration:HUD_TRANSITION_DURATION options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf->_mainButton setTitle:(strongSelf->_isRemoteHUDActive ? NSLocalizedString(@"Exit HUD", nil) : NSLocalizedString(@"Open HUD", nil)) forState:UIControlStateNormal];
        [strongSelf->_authorLabel setAttributedText:(strongSelf->_isRemoteHUDActive ? hintAttributedString : creditsAttributedString)];
    } completion:nil];
}

- (void)presentTopCenterMostHints
{
    if (!_isRemoteHUDActive) {
        return;
    }
    [_authorLabel setText:NSLocalizedString(@"Tap that button on the center again,\nto toggle ON/OFF “Dynamic Island” mode.", nil)];
}

- (BOOL)settingHighlightedWithKey:(NSString * _Nonnull)key
{
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:key];
    return mode != nil ? [mode boolValue] : NO;
}

- (void)settingDidSelectWithKey:(NSString * _Nonnull)key
{
    BOOL highlighted = [self settingHighlightedWithKey:key];
    [_userDefaults setObject:@(!highlighted) forKey:key];
    [self saveUserDefaults];
}

- (void)reloadModeButtonState
{
    HUDPresetPosition selectedMode = [self selectedModeForCurrentOrientation];
    BOOL isCentered = (selectedMode == HUDPresetPositionTopCenter || selectedMode == HUDPresetPositionTopCenterMost);
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    [_topLeftButton setSelected:(selectedMode == HUDPresetPositionTopLeft)];
    [_topCenterButton setSelected:isCentered];
    [_topRightButton setSelected:(selectedMode == HUDPresetPositionTopRight)];
    UIImage *topCenterImage = (isCenteredMost ? [UIImage systemImageNamed:@"arrow.up.to.line"] : [UIImage systemImageNamed:@"arrow.up"]);
    [_topCenterButton setImage:topCenterImage forState:UIControlStateNormal];
}

- (void)tapAuthorLabel:(UITapGestureRecognizer *)sender
{
    if (_isRemoteHUDActive) {
        return;
    }
    NSString *repoURLString = @"https://trollspeed.app";
    NSURL *repoURL = [NSURL URLWithString:repoURLString];
    [[UIApplication sharedApplication] openURL:repoURL options:@{} completionHandler:nil];
}

- (void)tapTopLeftButton:(UIButton *)sender
{
    //log_debug(OS_LOG_DEFAULT, "- [BBZView tapTopLeftButton:%{public}@]", sender);
    [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopLeft];
    [self reloadModeButtonState];
}

- (void)tapTopRightButton:(UIButton *)sender
{
    //log_debug(OS_LOG_DEFAULT, "- [BBZView tapTopRightButton:%{public}@]", sender);
    [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopRight];
    [self reloadModeButtonState];
}

- (void)tapTopCenterButton:(UIButton *)sender
{
    //log_debug(OS_LOG_DEFAULT, "- [BBZView tapTopCenterButton:%{public}@]", sender);
    HUDPresetPosition selectedMode = [self selectedModeForCurrentOrientation];
    BOOL isCenteredMost = (selectedMode == HUDPresetPositionTopCenterMost);
    if (!sender.isSelected || !_supportsCenterMost) {
        [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopCenter];
        if (_supportsCenterMost) {
            [self presentTopCenterMostHints];
        }
    } else {
        if (isCenteredMost) {
            [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopCenter];
        } else {
            [self setSelectedModeForCurrentOrientation:HUDPresetPositionTopCenterMost];
        }
    }
    [self reloadModeButtonState];
}

- (void)tapMainButton:(UIButton *)sender
{
    //log_debug(OS_LOG_DEFAULT, "- [BBZView tapMainButton:%{public}@]", sender);
    // 未初始化则禁止开启绘制
    BOOL kernelOK = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
    if (!kernelOK) {
        KernelLogLine("内核未就绪，请先点击“初始化内核”");
        //        return;
    }
    
    BOOL isNowEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isNowEnabled];
    isNowEnabled = !isNowEnabled;
    
    if (isNowEnabled)
    {
        KernelLogLine("正在启动绘制...");
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [_impactFeedbackGenerator prepare];
        int anyToken;
        __weak typeof(self) weakSelf = self;
        notify_register_dispatch(NOTIFY_LAUNCHED_HUD, &anyToken, dispatch_get_main_queue(), ^(int token) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            notify_cancel(token);
            [strongSelf->_impactFeedbackGenerator impactOccurred];
            dispatch_semaphore_signal(semaphore);
        });
        
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            intptr_t timedOut = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (timedOut) {
                    log_error(OS_LOG_DEFAULT, "Timed out waiting for HUD to launch");
                    KernelLogLine("启动绘制超时（不影响内核状态）");
                } else {
                    KernelLogLine("绘制已启动");
                }
                
                BOOL ok = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
                KernelLogLine(ok ? "内核状态：已就绪" : "内核状态：未就绪");
                [self reloadMainButtonState];
                [self.backgroundView setUserInteractionEnabled:YES];
            });
        });
    }
    else
    {
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
            [self.backgroundView setUserInteractionEnabled:YES];
        });
    }
}

- (void)tapInitKernelButton:(UIButton *)sender
{
    if (![_mainButton isEnabled]) return;
    if (_isInitializingKernel) return;
    _isInitializingKernel = YES;
    _initKernelButton.enabled = NO;
    [_initActivity startAnimating];
    KernelLogLine("开始内核初始化...");
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [DOJailbreaker.sharedInstance run];
        BOOL ok = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
        dispatch_async(dispatch_get_main_queue(), ^{
            KernelLogLine(ok ? "内核初始化成功" : "内核初始化完成（可能未成功）");
            [self->_initActivity stopAnimating];
            self->_initKernelButton.enabled = YES;
            self->_isInitializingKernel = NO;
            [self reloadMainButtonState];
        });
    });
}

- (void)tapSettingsButton:(UIButton *)sender
{
    if (![_mainButton isEnabled]) return;
    //log_debug(OS_LOG_DEFAULT, "- [BBZView tapSettingsButton:%{public}@]", sender);
    
    TSSettingsController *settingsViewController = [[TSSettingsController alloc] init];
    settingsViewController.delegate = self;
    settingsViewController.alreadyLaunched = _isRemoteHUDActive;
    
    SPLarkTransitioningDelegate *transitioningDelegate = [[SPLarkTransitioningDelegate alloc] init];
    settingsViewController.transitioningDelegate = transitioningDelegate;
    settingsViewController.modalPresentationStyle = UIModalPresentationCustom;
    settingsViewController.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:settingsViewController animated:YES completion:nil];
}

- (void)verticalSizeClassUpdated
{
    UIUserInterfaceSizeClass verticalClass = self.traitCollection.verticalSizeClass;
    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    if (verticalClass == UIUserInterfaceSizeClassCompact) {
        CGFloat topConstant = _gTopButtonConstraintsConstantCompact;
        [_settingsButton setHidden:YES];
        [_authorLabelBottomConstraint setConstant:_gAuthorLabelBottomConstraintConstantCompact];
        [_topLeftConstraint setConstant:topConstant];
        [_topRightConstraint setConstant:topConstant];
        [_topCenterConstraint setConstant:topConstant];
    } else {
        CGFloat topConstant = isPad ? _gTopButtonConstraintsConstantRegularPad : _gTopButtonConstraintsConstantRegular;
        [_settingsButton setHidden:NO];
        [_authorLabelBottomConstraint setConstant:_gAuthorLabelBottomConstraintConstantRegular];
        [_topLeftConstraint setConstant:topConstant];
        [_topRightConstraint setConstant:topConstant];
        [_topCenterConstraint setConstant:topConstant];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [self verticalSizeClassUpdated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self reloadModeButtonState];
    } completion:nil];
}

@end
