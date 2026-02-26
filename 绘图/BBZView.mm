//
//  BBZView.mm - 主菜单（三角洲风格）
//

#import <notify.h>
#import "HUDHelper.h"
#import "MainButton.h"
#import "MainApplication.h"
#import "HUDPresetPosition.h"
#import "BBZView.h"
#import "UIApplication+Private.h"
#import "DOJailbreaker.h"
#import "LFSenderIDViewController.h"
#import "pp.h"

#ifdef __cplusplus
extern "C" {
#endif
void KernelLoggerSetHandler(void (^handler)(NSString *line));
void KernelLogLine(const char *line);
#ifdef __cplusplus
}
#endif

// ========================================
// 颜色定义（三角洲风格）
// ========================================
#define 主题背景色 [UIColor colorWithRed:15.0f/255.0f green:15.0f/255.0f blue:20.0f/255.0f alpha:1.0f]
#define 卡片背景色 [UIColor colorWithRed:25.0f/255.0f green:25.0f/255.0f blue:32.0f/255.0f alpha:1.0f]
#define 粉色 [UIColor colorWithRed:236.0f/255.0f green:72.0f/255.0f blue:153.0f/255.0f alpha:1.0f]
#define 紫色 [UIColor colorWithRed:168.0f/255.0f green:85.0f/255.0f blue:247.0f/255.0f alpha:1.0f]
#define 主文字色 [UIColor whiteColor]
#define 副文字色 [UIColor colorWithWhite:0.5f alpha:1.0f]
#define 红色开关 [UIColor colorWithRed:239.0f/255.0f green:68.0f/255.0f blue:68.0f/255.0f alpha:1.0f]
#define 绿色开关 [UIColor colorWithRed:34.0f/255.0f green:197.0f/255.0f blue:94.0f/255.0f alpha:1.0f]

static BOOL _gShouldToggleHUDAfterLaunch = NO;
static __weak BBZView *gRootVC = nil;

// ========================================
// 圆形进度视图
// ========================================
@interface 圆形进度视图 : UIView
@property (nonatomic, strong) CAShapeLayer* 背景层;
@property (nonatomic, strong) CAShapeLayer* 进度层;
@property (nonatomic, strong) UILabel* 数值标签;
@property (nonatomic, strong) UILabel* 总数标签;
@property (nonatomic, strong) UILabel* 百分比标签;
@end

@implementation 圆形进度视图

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self 初始化];
    return self;
}

- (void)初始化 {
    CGFloat 半径 = 35.0f;
    CGPoint 中心 = CGPointMake(50, 50);
    UIBezierPath* 路径 = [UIBezierPath bezierPathWithArcCenter:中心 radius:半径 startAngle:-M_PI_2 endAngle:M_PI_2 * 3 clockwise:YES];
    
    self.背景层 = [CAShapeLayer layer];
    self.背景层.path = 路径.CGPath;
    self.背景层.fillColor = UIColor.clearColor.CGColor;
    self.背景层.strokeColor = [UIColor colorWithWhite:0.2f alpha:1.0f].CGColor;
    self.背景层.lineWidth = 6.0f;
    self.背景层.lineCap = kCALineCapRound;
    [self.layer addSublayer:self.背景层];
    
    self.进度层 = [CAShapeLayer layer];
    self.进度层.path = 路径.CGPath;
    self.进度层.fillColor = UIColor.clearColor.CGColor;
    self.进度层.strokeColor = 紫色.CGColor;
    self.进度层.lineWidth = 6.0f;
    self.进度层.lineCap = kCALineCapRound;
    self.进度层.strokeEnd = 0;
    [self.layer addSublayer:self.进度层];
    
    self.数值标签 = [[UILabel alloc] initWithFrame:CGRectMake(0, 28, 100, 30)];
    self.数值标签.font = [UIFont systemFontOfSize:24.0f weight:UIFontWeightBold];
    self.数值标签.textColor = 主文字色;
    self.数值标签.textAlignment = NSTextAlignmentCenter;
    self.数值标签.text = @"0";
    [self addSubview:self.数值标签];
    
    self.总数标签 = [[UILabel alloc] initWithFrame:CGRectMake(0, 52, 100, 20)];
    self.总数标签.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
    self.总数标签.textColor = 副文字色;
    self.总数标签.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.总数标签];
    
    self.百分比标签 = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 40, 20)];
    self.百分比标签.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightMedium];
    self.百分比标签.textColor = 紫色;
    self.百分比标签.textAlignment = NSTextAlignmentRight;
    self.百分比标签.text = @"0%";
    [self addSubview:self.百分比标签];
}

- (void)设置进度:(int)当前 总数:(int)总数 {
    CGFloat 进度 = 总数 > 0 ? (CGFloat)当前 / 总数 : 0;
    self.数值标签.text = [NSString stringWithFormat:@"%d", 当前];
    self.总数标签.text = [NSString stringWithFormat:@"/ %d", 总数];
    self.百分比标签.text = [NSString stringWithFormat:@"%.0f%%", 进度 * 100];
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.3f];
    self.进度层.strokeEnd = 进度;
    [CATransaction commit];
}
@end

// ========================================
// 主开关卡片
// ========================================
@interface 主开关卡片 : UIView
@property (nonatomic, strong) UIView* 开关容器;
@property (nonatomic, strong) UIImageView* 勾选图标;
@property (nonatomic, strong) UILabel* 状态标签;
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy) void (^切换回调)(BOOL);
@end

@implementation 主开关卡片

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self 初始化];
    return self;
}

- (void)初始化 {
    self.layer.cornerRadius = 16.0f;
    self.clipsToBounds = YES;
    
    CAGradientLayer* 渐变 = [CAGradientLayer layer];
    渐变.frame = CGRectMake(0, 0, 400, 80);
    渐变.colors = @[(id)粉色.CGColor, (id)紫色.CGColor];
    渐变.startPoint = CGPointMake(0, 0.5);
    渐变.endPoint = CGPointMake(1, 0.5);
    [self.layer addSublayer:渐变];
    
    UILabel* 图标 = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 30, 30)];
    图标.text = @"⏻";
    图标.font = [UIFont systemFontOfSize:18.0f weight:UIFontWeightBold];
    图标.textColor = [UIColor colorWithWhite:1.0f alpha:0.9f];
    [self addSubview:图标];
    
    UILabel* 标题 = [[UILabel alloc] initWithFrame:CGRectMake(40, 12, 100, 20)];
    标题.text = @"主开关";
    标题.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightMedium];
    标题.textColor = [UIColor colorWithWhite:1.0f alpha:0.8f];
    [self addSubview:标题];
    
    self.状态标签 = [[UILabel alloc] initWithFrame:CGRectMake(16, 38, 200, 30)];
    self.状态标签.text = @"HUD 已关闭";
    self.状态标签.font = [UIFont systemFontOfSize:22.0f weight:UIFontWeightBold];
    self.状态标签.textColor = 主文字色;
    [self addSubview:self.状态标签];
    
    self.开关容器 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    self.开关容器.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.25f];
    self.开关容器.layer.cornerRadius = 25.0f;
    [self addSubview:self.开关容器];
    
    self.勾选图标 = [[UIImageView alloc] initWithFrame:CGRectMake(13, 13, 24, 24)];
    if (@available(iOS 13.0, *)) {
        self.勾选图标.image = [[UIImage systemImageNamed:@"checkmark" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightBold]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    self.勾选图标.tintColor = 主文字色;
    self.勾选图标.alpha = 0;
    [self.开关容器 addSubview:self.勾选图标];
    
    UITapGestureRecognizer* 点击 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(切换)];
    [self addGestureRecognizer:点击];
    
    self.isOn = NO;
    [self 更新状态:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.开关容器.frame = CGRectMake(self.bounds.size.width - 66, 15, 50, 50);
    for (CALayer* layer in self.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) layer.frame = self.bounds;
    }
}

- (void)切换 {
    self.isOn = !self.isOn;
    [self 更新状态:YES];
    if (self.切换回调) self.切换回调(self.isOn);
}

- (void)更新状态:(BOOL)动画 {
    NSTimeInterval 时长 = 动画 ? 0.25f : 0;
    [UIView animateWithDuration:时长 animations:^{
        self.勾选图标.alpha = self.isOn ? 1.0f : 0;
        self.开关容器.backgroundColor = self.isOn ? [UIColor colorWithWhite:1.0f alpha:0.4f] : [UIColor colorWithWhite:1.0f alpha:0.25f];
    }];
    self.状态标签.text = self.isOn ? @"HUD 已启用" : @"HUD 已关闭";
}
@end

// ========================================
// 日志卡片
// ========================================
@interface 日志卡片 : UIView
@property (nonatomic, strong) UITextView* 日志视图;
@end

@implementation 日志卡片

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = 卡片背景色;
        self.layer.cornerRadius = 16.0f;
        
        UIView* 图标背景 = [[UIView alloc] init];
        图标背景.translatesAutoresizingMaskIntoConstraints = NO;
        图标背景.backgroundColor = [紫色 colorWithAlphaComponent:0.15f];
        图标背景.layer.cornerRadius = 8.0f;
        [self addSubview:图标背景];
        
        UIImageView* 图标 = [[UIImageView alloc] init];
        图标.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            图标.image = [[UIImage systemImageNamed:@"doc.text.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightMedium]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        图标.tintColor = 紫色;
        [图标背景 addSubview:图标];
        
        UILabel* 标题 = [[UILabel alloc] init];
        标题.translatesAutoresizingMaskIntoConstraints = NO;
        标题.text = @"运行日志";
        标题.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightBold];
        标题.textColor = 主文字色;
        [self addSubview:标题];
        
        self.日志视图 = [[UITextView alloc] init];
        self.日志视图.translatesAutoresizingMaskIntoConstraints = NO;
        self.日志视图.backgroundColor = [UIColor colorWithWhite:0.08f alpha:1.0f];
        self.日志视图.textColor = [UIColor colorWithRed:0.4f green:0.8f blue:0.4f alpha:1.0f];
        self.日志视图.font = [UIFont fontWithName:@"Menlo" size:11.0];
        self.日志视图.editable = NO;
        self.日志视图.layer.cornerRadius = 10.0f;
        self.日志视图.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
        self.日志视图.showsVerticalScrollIndicator = YES;
        self.日志视图.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        [self addSubview:self.日志视图];
        
        [NSLayoutConstraint activateConstraints:@[
            [图标背景.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            [图标背景.topAnchor constraintEqualToAnchor:self.topAnchor constant:16],
            [图标背景.widthAnchor constraintEqualToConstant:28],
            [图标背景.heightAnchor constraintEqualToConstant:28],
            [图标.centerXAnchor constraintEqualToAnchor:图标背景.centerXAnchor],
            [图标.centerYAnchor constraintEqualToAnchor:图标背景.centerYAnchor],
            [图标.widthAnchor constraintEqualToConstant:14],
            [图标.heightAnchor constraintEqualToConstant:14],
            [标题.leadingAnchor constraintEqualToAnchor:图标背景.trailingAnchor constant:10],
            [标题.centerYAnchor constraintEqualToAnchor:图标背景.centerYAnchor],
            [self.日志视图.topAnchor constraintEqualToAnchor:图标背景.bottomAnchor constant:12],
            [self.日志视图.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [self.日志视图.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [self.日志视图.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-12],
        ]];
    }
    return self;
}

- (void)追加日志:(NSString*)行 {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *old = self.日志视图.text ?: @"";
        NSString *nl = old.length ? @"\n" : @"";
        self.日志视图.text = [old stringByAppendingFormat:@"%@%@", nl, 行];
        [self.日志视图 scrollRangeToVisible:NSMakeRange(self.日志视图.text.length, 0)];
    });
}
@end

// ========================================
// Plist 配置路径
// ========================================
static NSString* 取配置文件路径() {
    return @"/var/mobile/Library/Preferences/com.map.settings.plist";
}

static void 设置开关状态(NSString* 密钥, BOOL 状态) {
    NSString *路径 = 取配置文件路径();
    NSMutableDictionary *配置 = [NSMutableDictionary dictionaryWithContentsOfFile:路径];
    if (!配置) 配置 = [NSMutableDictionary dictionary];
    [配置 setObject:@(状态) forKey:密钥];
    [配置 writeToFile:路径 atomically:YES];
}

static BOOL 取开关状态(NSString* 密钥) {
    NSDictionary *配置 = [NSDictionary dictionaryWithContentsOfFile:取配置文件路径()];
    if (!配置) return NO;
    return [[配置 objectForKey:密钥] boolValue];
}

// ========================================
// 开关行视图（三角洲风格）
// ========================================
@interface 开关行视图 : UIView
@property (nonatomic, strong) UILabel* 标题标签;
@property (nonatomic, strong) UILabel* 状态标签;
@property (nonatomic, strong) UIView* 开关轨道;
@property (nonatomic, strong) UIView* 开关滑块;
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy) NSString* 密钥;
@property (nonatomic, copy) void (^切换回调)(BOOL);
@end

@implementation 开关行视图

- (instancetype)initWithIcon:(NSString*)图标名 标题:(NSString*)标题 密钥:(NSString*)密钥 {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.密钥 = 密钥;
        self.backgroundColor = 卡片背景色;
        self.layer.cornerRadius = 12.0f;
        
        UIView* 图标背景 = [[UIView alloc] init];
        图标背景.translatesAutoresizingMaskIntoConstraints = NO;
        图标背景.backgroundColor = [紫色 colorWithAlphaComponent:0.15f];
        图标背景.layer.cornerRadius = 8.0f;
        [self addSubview:图标背景];
        
        UIImageView* 图标 = [[UIImageView alloc] init];
        图标.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            图标.image = [[UIImage systemImageNamed:图标名 withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightMedium]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        图标.tintColor = 紫色;
        图标.contentMode = UIViewContentModeScaleAspectFit;
        [图标背景 addSubview:图标];
        
        self.标题标签 = [[UILabel alloc] init];
        self.标题标签.translatesAutoresizingMaskIntoConstraints = NO;
        self.标题标签.text = 标题;
        self.标题标签.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightMedium];
        self.标题标签.textColor = 主文字色;
        [self addSubview:self.标题标签];
        
        self.状态标签 = [[UILabel alloc] init];
        self.状态标签.translatesAutoresizingMaskIntoConstraints = NO;
        self.状态标签.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightRegular];
        self.状态标签.textColor = 副文字色;
        [self addSubview:self.状态标签];
        
        self.开关轨道 = [[UIView alloc] init];
        self.开关轨道.translatesAutoresizingMaskIntoConstraints = NO;
        self.开关轨道.backgroundColor = [UIColor colorWithWhite:0.25f alpha:1.0f];
        self.开关轨道.layer.cornerRadius = 15.0f;
        [self addSubview:self.开关轨道];
        
        self.开关滑块 = [[UIView alloc] initWithFrame:CGRectMake(2, 2, 26, 26)];
        self.开关滑块.backgroundColor = 主文字色;
        self.开关滑块.layer.cornerRadius = 13.0f;
        [self.开关轨道 addSubview:self.开关滑块];
        
        [NSLayoutConstraint activateConstraints:@[
            [图标背景.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [图标背景.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [图标背景.widthAnchor constraintEqualToConstant:32],
            [图标背景.heightAnchor constraintEqualToConstant:32],
            [图标.centerXAnchor constraintEqualToAnchor:图标背景.centerXAnchor],
            [图标.centerYAnchor constraintEqualToAnchor:图标背景.centerYAnchor],
            [图标.widthAnchor constraintEqualToConstant:16],
            [图标.heightAnchor constraintEqualToConstant:16],
            [self.标题标签.leadingAnchor constraintEqualToAnchor:图标背景.trailingAnchor constant:10],
            [self.标题标签.topAnchor constraintEqualToAnchor:self.topAnchor constant:12],
            [self.状态标签.leadingAnchor constraintEqualToAnchor:self.标题标签.leadingAnchor],
            [self.状态标签.topAnchor constraintEqualToAnchor:self.标题标签.bottomAnchor constant:2],
            [self.开关轨道.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [self.开关轨道.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.开关轨道.widthAnchor constraintEqualToConstant:50],
            [self.开关轨道.heightAnchor constraintEqualToConstant:30],
            [self.heightAnchor constraintEqualToConstant:56],
        ]];
        
        UITapGestureRecognizer* 点击 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(切换)];
        [self addGestureRecognizer:点击];
        
        self.isOn = 取开关状态(密钥);
        [self 更新状态:NO];
    }
    return self;
}

- (void)切换 {
    self.isOn = !self.isOn;
    [self 更新状态:YES];
    if (self.切换回调) self.切换回调(self.isOn);
}

- (void)更新状态:(BOOL)动画 {
    CGFloat 滑块X = self.isOn ? 22 : 2;
    UIColor* 轨道色 = self.isOn ? 红色开关 : [UIColor colorWithWhite:0.25f alpha:1.0f];
    NSTimeInterval 时长 = 动画 ? 0.25f : 0;
    [UIView animateWithDuration:时长 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:0 animations:^{
        self.开关滑块.frame = CGRectMake(滑块X, 2, 26, 26);
        self.开关轨道.backgroundColor = 轨道色;
    } completion:nil];
    self.状态标签.text = self.isOn ? @"已启用" : @"已关闭";
    self.状态标签.textColor = self.isOn ? 红色开关 : 副文字色;
}
@end

// ========================================
// BBZView 主控制器
// ========================================
@implementation BBZView {
    NSMutableDictionary *_userDefaults;
    MainButton *_mainButton;
    BOOL _isRemoteHUDActive;
    UIImpactFeedbackGenerator *_impactFeedbackGenerator;
    日志卡片 *_logCard;
    BOOL _已进入菜单;
}

+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag { _gShouldToggleHUDAfterLaunch = flag; }
+ (BOOL)shouldToggleHUDAfterLaunch { return _gShouldToggleHUDAfterLaunch; }

- (BOOL)isHUDEnabled {
#if !NO_TROLL
    return IsHUDEnabled();
#else
    return NO;
#endif
}

- (void)setHUDEnabled:(BOOL)enabled {
#if !NO_TROLL
    SetHUDEnabled(enabled);
#endif
}

- (void)registerNotifications {
    int token;
    notify_register_dispatch(NOTIFY_RELOAD_APP, &token, dispatch_get_main_queue(), ^(int token) {
        [self loadUserDefaults:YES];
    });
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleHUDNotificationReceived:) name:kToggleHUDAfterLaunchNotificationName object:nil];
}

- (void)loadView {
    CGRect bounds = UIScreen.mainScreen.bounds;
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = 主题背景色;
    
    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = 主题背景色;
    [self.view addSubview:self.backgroundView];
    
    _已进入菜单 = NO;
    [self 显示加载页面];
}

// ========================================
// 加载页面（缓冲页）
// ========================================
- (void)显示加载页面 {
    // 清空背景视图
    for (UIView *sub in self.backgroundView.subviews) [sub removeFromSuperview];
    
    UIView* bg = self.backgroundView;
    
    // Logo 容器（带阴影）
    UIView* logoContainer = [[UIView alloc] init];
    logoContainer.translatesAutoresizingMaskIntoConstraints = NO;
    logoContainer.layer.shadowColor = 紫色.CGColor;
    logoContainer.layer.shadowOffset = CGSizeZero;
    logoContainer.layer.shadowOpacity = 0.6f;
    logoContainer.layer.shadowRadius = 25.0f;
    [bg addSubview:logoContainer];
    
    // Logo 图标（紫色圆角方块 + 字母）
    UIView* logoView = [[UIView alloc] init];
    logoView.translatesAutoresizingMaskIntoConstraints = NO;
    logoView.backgroundColor = 紫色;
    logoView.layer.cornerRadius = 30.0f;
    logoView.clipsToBounds = YES;
    [logoContainer addSubview:logoView];
    
    UILabel* logoText = [[UILabel alloc] init];
    logoText.translatesAutoresizingMaskIntoConstraints = NO;
    logoText.text = @"S";
    logoText.font = [UIFont systemFontOfSize:48.0f weight:UIFontWeightBold];
    logoText.textColor = 主文字色;
    logoText.textAlignment = NSTextAlignmentCenter;
    [logoView addSubview:logoText];
    
    // 标题
    UILabel* 标题 = [[UILabel alloc] init];
    标题.translatesAutoresizingMaskIntoConstraints = NO;
    标题.text = @"和平精英";
    标题.font = [UIFont systemFontOfSize:28.0f weight:UIFontWeightBold];
    标题.textColor = 主文字色;
    [bg addSubview:标题];
    
    // 加载进度条容器
    UIView* 加载容器 = [[UIView alloc] init];
    加载容器.translatesAutoresizingMaskIntoConstraints = NO;
    加载容器.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
    加载容器.layer.cornerRadius = 4.0f;
    加载容器.clipsToBounds = YES;
    [bg addSubview:加载容器];
    
    // 进度渐变条
    CAGradientLayer* 进度渐变 = [CAGradientLayer layer];
    进度渐变.frame = CGRectMake(0, 0, 0, 8);
    进度渐变.cornerRadius = 4.0f;
    进度渐变.colors = @[(id)粉色.CGColor, (id)紫色.CGColor];
    进度渐变.startPoint = CGPointMake(0, 0.5);
    进度渐变.endPoint = CGPointMake(1, 0.5);
    [加载容器.layer addSublayer:进度渐变];
    
    // 状态标签
    UILabel* 状态标签 = [[UILabel alloc] init];
    状态标签.translatesAutoresizingMaskIntoConstraints = NO;
    状态标签.text = @"正在初始化...";
    状态标签.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
    状态标签.textColor = 副文字色;
    状态标签.tag = 100;
    [bg addSubview:状态标签];
    
    // 进入按钮
    UIButton* 进入按钮 = [UIButton buttonWithType:UIButtonTypeCustom];
    进入按钮.translatesAutoresizingMaskIntoConstraints = NO;
    [进入按钮 setTitle:@"进入菜单" forState:UIControlStateNormal];
    [进入按钮 setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    进入按钮.titleLabel.font = [UIFont systemFontOfSize:17.0f weight:UIFontWeightSemibold];
    进入按钮.layer.cornerRadius = 14.0f;
    进入按钮.clipsToBounds = YES;
    进入按钮.alpha = 0;
    进入按钮.transform = CGAffineTransformMakeTranslation(0, 20);
    [进入按钮 addTarget:self action:@selector(点击进入菜单) forControlEvents:UIControlEventTouchUpInside];
    进入按钮.tag = 101;
    [bg addSubview:进入按钮];
    
    // 按钮渐变背景
    CAGradientLayer* 按钮渐变 = [CAGradientLayer layer];
    按钮渐变.frame = CGRectMake(0, 0, 220, 56);
    按钮渐变.cornerRadius = 14.0f;
    按钮渐变.colors = @[(id)粉色.CGColor, (id)紫色.CGColor];
    按钮渐变.startPoint = CGPointMake(0, 0.5);
    按钮渐变.endPoint = CGPointMake(1, 0.5);
    [进入按钮.layer insertSublayer:按钮渐变 atIndex:0];
    
    [NSLayoutConstraint activateConstraints:@[
        [logoContainer.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [logoContainer.centerYAnchor constraintEqualToAnchor:bg.centerYAnchor constant:-100],
        [logoContainer.widthAnchor constraintEqualToConstant:100],
        [logoContainer.heightAnchor constraintEqualToConstant:100],
        [logoView.topAnchor constraintEqualToAnchor:logoContainer.topAnchor],
        [logoView.leadingAnchor constraintEqualToAnchor:logoContainer.leadingAnchor],
        [logoView.trailingAnchor constraintEqualToAnchor:logoContainer.trailingAnchor],
        [logoView.bottomAnchor constraintEqualToAnchor:logoContainer.bottomAnchor],
        [logoText.centerXAnchor constraintEqualToAnchor:logoView.centerXAnchor],
        [logoText.centerYAnchor constraintEqualToAnchor:logoView.centerYAnchor],
        [标题.topAnchor constraintEqualToAnchor:logoContainer.bottomAnchor constant:20],
        [标题.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [加载容器.topAnchor constraintEqualToAnchor:标题.bottomAnchor constant:40],
        [加载容器.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [加载容器.widthAnchor constraintEqualToConstant:220],
        [加载容器.heightAnchor constraintEqualToConstant:8],
        [状态标签.topAnchor constraintEqualToAnchor:加载容器.bottomAnchor constant:16],
        [状态标签.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [进入按钮.topAnchor constraintEqualToAnchor:状态标签.bottomAnchor constant:30],
        [进入按钮.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [进入按钮.widthAnchor constraintEqualToConstant:220],
        [进入按钮.heightAnchor constraintEqualToConstant:56],
    ]];
    
    // 加载动画
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.5f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            进度渐变.frame = CGRectMake(0, 0, 220, 8);
        } completion:^(BOOL finished) {
            状态标签.text = @"准备就绪";
            [UIView animateWithDuration:0.5f delay:0.2f usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:0 animations:^{
                进入按钮.alpha = 1;
                进入按钮.transform = CGAffineTransformIdentity;
            } completion:nil];
        }];
    });
}

- (void)点击进入菜单 {
    if (!sub_m889283YhOXNKlS0tZExbRameuKLu09M0FzgpOosYk3HJw0c1b0dpt) return;
    UIButton* btn = (UIButton*)[self.backgroundView viewWithTag:101];
    [UIView animateWithDuration:0.1f animations:^{
        btn.transform = CGAffineTransformMakeScale(0.95f, 0.95f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1f animations:^{
            btn.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [UIView transitionWithView:self.backgroundView duration:0.35f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [self 构建菜单页面];
            } completion:nil];
        }];
    }];
}

// ========================================
// 菜单页面
// ========================================
- (void)构建菜单页面 {
    _已进入菜单 = YES;
    // 清空背景视图
    for (UIView *sub in self.backgroundView.subviews) [sub removeFromSuperview];
    
    UIView* bg = self.backgroundView;
    UILayoutGuide *safeArea = bg.safeAreaLayoutGuide;
    
    UIScrollView* 滚动视图 = [[UIScrollView alloc] init];
    滚动视图.translatesAutoresizingMaskIntoConstraints = NO;
    滚动视图.showsVerticalScrollIndicator = NO;
    滚动视图.alwaysBounceVertical = YES;
    [bg addSubview:滚动视图];
    
    [NSLayoutConstraint activateConstraints:@[
        [滚动视图.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [滚动视图.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
        [滚动视图.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [滚动视图.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
    ]];
    
    UIView* 内容 = [[UIView alloc] init];
    内容.translatesAutoresizingMaskIntoConstraints = NO;
    [滚动视图 addSubview:内容];
    
    [NSLayoutConstraint activateConstraints:@[
        [内容.topAnchor constraintEqualToAnchor:滚动视图.contentLayoutGuide.topAnchor],
        [内容.bottomAnchor constraintEqualToAnchor:滚动视图.contentLayoutGuide.bottomAnchor],
        [内容.leadingAnchor constraintEqualToAnchor:滚动视图.contentLayoutGuide.leadingAnchor],
        [内容.trailingAnchor constraintEqualToAnchor:滚动视图.contentLayoutGuide.trailingAnchor],
        [内容.widthAnchor constraintEqualToAnchor:滚动视图.frameLayoutGuide.widthAnchor],
    ]];
    
    // ---- 头部 ----
    UIView* 头部 = [self 创建头部];
    头部.translatesAutoresizingMaskIntoConstraints = NO;
    [内容 addSubview:头部];
    
    // ---- 主开关 ----
    主开关卡片* 主开关 = [[主开关卡片 alloc] init];
    主开关.translatesAutoresizingMaskIntoConstraints = NO;
    _isRemoteHUDActive = [self isHUDEnabled];
    主开关.isOn = _isRemoteHUDActive;
    [主开关 更新状态:NO];
    [内容 addSubview:主开关];
    
    // ---- 初始化内核按钮 ----
    UIButton* 内核按钮 = [UIButton buttonWithType:UIButtonTypeCustom];
    内核按钮.translatesAutoresizingMaskIntoConstraints = NO;
    [内核按钮 setTitle:@"初始化内核" forState:UIControlStateNormal];
    [内核按钮 setTitleColor:紫色 forState:UIControlStateNormal];
    内核按钮.titleLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightSemibold];
    内核按钮.backgroundColor = [紫色 colorWithAlphaComponent:0.15f];
    内核按钮.layer.cornerRadius = 12.0f;
    [内核按钮 addTarget:self action:@selector(tapInitKernelButton:) forControlEvents:UIControlEventTouchUpInside];
    [内容 addSubview:内核按钮];
    
    // ---- 日志卡片（紧跟内核按钮下方）----
    _logCard = [[日志卡片 alloc] init];
    _logCard.translatesAutoresizingMaskIntoConstraints = NO;
    [内容 addSubview:_logCard];
    
    // ---- 功能列表标题 ----
    UIView* 功能标题 = [self 创建功能列表标题];
    功能标题.translatesAutoresizingMaskIntoConstraints = NO;
    [内容 addSubview:功能标题];
    
    // ---- 开关列表 ----
    UIStackView* 开关列表 = [self 创建开关列表];
    开关列表.translatesAutoresizingMaskIntoConstraints = NO;
    [内容 addSubview:开关列表];
    
    // ---- 布局：日志卡片在内核按钮下方，功能列表在日志下方 ----
    [NSLayoutConstraint activateConstraints:@[
        [头部.topAnchor constraintEqualToAnchor:内容.topAnchor constant:16],
        [头部.leadingAnchor constraintEqualToAnchor:内容.leadingAnchor constant:16],
        [头部.trailingAnchor constraintEqualToAnchor:内容.trailingAnchor constant:-16],
        
        [主开关.topAnchor constraintEqualToAnchor:头部.bottomAnchor constant:20],
        [主开关.leadingAnchor constraintEqualToAnchor:内容.leadingAnchor constant:16],
        [主开关.trailingAnchor constraintEqualToAnchor:内容.trailingAnchor constant:-16],
        [主开关.heightAnchor constraintEqualToConstant:80],
        
        [内核按钮.topAnchor constraintEqualToAnchor:主开关.bottomAnchor constant:16],
        [内核按钮.leadingAnchor constraintEqualToAnchor:内容.leadingAnchor constant:16],
        [内核按钮.trailingAnchor constraintEqualToAnchor:内容.trailingAnchor constant:-16],
        [内核按钮.heightAnchor constraintEqualToConstant:48],
        
        [_logCard.topAnchor constraintEqualToAnchor:内核按钮.bottomAnchor constant:16],
        [_logCard.leadingAnchor constraintEqualToAnchor:内容.leadingAnchor constant:16],
        [_logCard.trailingAnchor constraintEqualToAnchor:内容.trailingAnchor constant:-16],
        [_logCard.heightAnchor constraintEqualToConstant:180],
        
        [功能标题.topAnchor constraintEqualToAnchor:_logCard.bottomAnchor constant:20],
        [功能标题.leadingAnchor constraintEqualToAnchor:内容.leadingAnchor constant:16],
        [功能标题.trailingAnchor constraintEqualToAnchor:内容.trailingAnchor constant:-16],
        
        [开关列表.topAnchor constraintEqualToAnchor:功能标题.bottomAnchor constant:12],
        [开关列表.leadingAnchor constraintEqualToAnchor:内容.leadingAnchor constant:16],
        [开关列表.trailingAnchor constraintEqualToAnchor:内容.trailingAnchor constant:-16],
        [开关列表.bottomAnchor constraintEqualToAnchor:内容.bottomAnchor constant:-30],
    ]];
    
    // ---- 主开关回调 ----
    __weak typeof(self) weakSelf = self;
    主开关.切换回调 = ^(BOOL 状态) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (!sub_m889283YhOXNKlS0tZExbRameuKLu09M0FzgpOosYk3HJw0c1b0dpt) return;
        strongSelf->_isRemoteHUDActive = 状态;
        [strongSelf setHUDEnabled:状态];
        if (状态) {
            [strongSelf->_logCard 追加日志:@"HUD 已启用"];
        } else {
            [strongSelf->_logCard 追加日志:@"HUD 已关闭"];
        }
    };
    
    [self reloadMainButtonState];
    
    // 进入菜单后立即显示内核状态
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL ok = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
        [self->_logCard 追加日志:ok ? @"内核状态：已就绪" : @"内核状态：未就绪"];
    });
}

- (UIView*)创建头部 {
    UIView* 容器 = [[UIView alloc] init];
    
    UIView* 头像容器 = [[UIView alloc] init];
    头像容器.translatesAutoresizingMaskIntoConstraints = NO;
    头像容器.backgroundColor = 紫色;
    头像容器.layer.cornerRadius = 22.0f;
    [容器 addSubview:头像容器];
    
    UILabel* 头像文字 = [[UILabel alloc] init];
    头像文字.translatesAutoresizingMaskIntoConstraints = NO;
    头像文字.text = @"S";
    头像文字.font = [UIFont systemFontOfSize:20.0f weight:UIFontWeightBold];
    头像文字.textColor = 主文字色;
    [头像容器 addSubview:头像文字];
    
    UILabel* 标题 = [[UILabel alloc] init];
    标题.translatesAutoresizingMaskIntoConstraints = NO;
    标题.text = @"和平精英";
    标题.font = [UIFont systemFontOfSize:18.0f weight:UIFontWeightBold];
    标题.textColor = 主文字色;
    [容器 addSubview:标题];
    
    UILabel* 副标题 = [[UILabel alloc] init];
    副标题.translatesAutoresizingMaskIntoConstraints = NO;
    副标题.text = @"控制中心";
    副标题.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
    副标题.textColor = 副文字色;
    [容器 addSubview:副标题];
    
    [NSLayoutConstraint activateConstraints:@[
        [头像容器.leadingAnchor constraintEqualToAnchor:容器.leadingAnchor],
        [头像容器.topAnchor constraintEqualToAnchor:容器.topAnchor],
        [头像容器.widthAnchor constraintEqualToConstant:44],
        [头像容器.heightAnchor constraintEqualToConstant:44],
        [头像文字.centerXAnchor constraintEqualToAnchor:头像容器.centerXAnchor],
        [头像文字.centerYAnchor constraintEqualToAnchor:头像容器.centerYAnchor],
        [标题.leadingAnchor constraintEqualToAnchor:头像容器.trailingAnchor constant:12],
        [标题.topAnchor constraintEqualToAnchor:容器.topAnchor constant:4],
        [副标题.leadingAnchor constraintEqualToAnchor:标题.leadingAnchor],
        [副标题.topAnchor constraintEqualToAnchor:标题.bottomAnchor constant:2],
        [容器.heightAnchor constraintEqualToConstant:50],
    ]];
    
    return 容器;
}

- (UIView*)创建功能列表标题 {
    UIView* 容器 = [[UIView alloc] init];
    
    UIView* 线 = [[UIView alloc] init];
    线.translatesAutoresizingMaskIntoConstraints = NO;
    线.backgroundColor = 粉色;
    线.layer.cornerRadius = 2.0f;
    [容器 addSubview:线];
    
    UILabel* 标题 = [[UILabel alloc] init];
    标题.translatesAutoresizingMaskIntoConstraints = NO;
    标题.text = @"功能列表";
    标题.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightBold];
    标题.textColor = 主文字色;
    [容器 addSubview:标题];
    
    UILabel* 副标题 = [[UILabel alloc] init];
    副标题.translatesAutoresizingMaskIntoConstraints = NO;
    副标题.text = @"一键开关与状态";
    副标题.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightRegular];
    副标题.textColor = 副文字色;
    [容器 addSubview:副标题];
    
    [NSLayoutConstraint activateConstraints:@[
        [线.leadingAnchor constraintEqualToAnchor:容器.leadingAnchor],
        [线.topAnchor constraintEqualToAnchor:容器.topAnchor],
        [线.widthAnchor constraintEqualToConstant:4],
        [线.heightAnchor constraintEqualToConstant:36],
        [标题.leadingAnchor constraintEqualToAnchor:线.trailingAnchor constant:10],
        [标题.topAnchor constraintEqualToAnchor:容器.topAnchor],
        [副标题.leadingAnchor constraintEqualToAnchor:标题.leadingAnchor],
        [副标题.topAnchor constraintEqualToAnchor:标题.bottomAnchor constant:2],
        [容器.heightAnchor constraintEqualToConstant:50],
    ]];
    return 容器;
}

- (UIStackView*)创建开关列表 {
    UIStackView* 列表 = [[UIStackView alloc] init];
    列表.axis = UILayoutConstraintAxisVertical;
    列表.spacing = 10.0f;
    
    NSArray* 配置 = @[
        @{@"图标": @"heart.fill", @"标题": @"显示血量", @"密钥": @"血条密钥"},
        @{@"图标": @"info.circle.fill", @"标题": @"显示信息", @"密钥": @"信息密钥"},
        @{@"图标": @"shield.fill", @"标题": @"显示头甲", @"密钥": @"头甲密钥"},
        @{@"图标": @"bag.fill", @"标题": @"显示装备", @"密钥": @"装备密钥"},
        @{@"图标": @"ruler.fill", @"标题": @"显示距离", @"密钥": @"距离密钥"},
        @{@"图标": @"cube.fill", @"标题": @"显示物资", @"密钥": @"物资密钥"},
        @{@"图标": @"shippingbox.fill", @"标题": @"显示盒子", @"密钥": @"盒子密钥"},
        @{@"图标": @"person.fill.questionmark", @"标题": @"人机显示", @"密钥": @"人机密钥"},
        @{@"图标": @"figure.stand", @"标题": @"骨骼显示", @"密钥": @"骨骼密钥"},
    ];
    
    for (NSDictionary* 项 in 配置) {
        开关行视图* 行 = [[开关行视图 alloc] initWithIcon:项[@"图标"] 标题:项[@"标题"] 密钥:项[@"密钥"]];
        行.translatesAutoresizingMaskIntoConstraints = NO;
        行.切换回调 = ^(BOOL 状态) {
            if (!sub_m889283YhOXNKlS0tZExbRameuKLu09M0FzgpOosYk3HJw0c1b0dpt) return;
            设置开关状态(项[@"密钥"], 状态);
        };
        [列表 addArrangedSubview:行];
    }
    return 列表;
}

- (void)tapInitKernelButton:(UIButton*)sender {
    if (!sub_m889283YhOXNKlS0tZExbRameuKLu09M0FzgpOosYk3HJw0c1b0dpt) return;
    // 已经初始化过就不要再初始化，防止闪退
    BOOL alreadyOk = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
    if (alreadyOk) {
        [_logCard 追加日志:@"内核已就绪，无需重复初始化"];
        return;
    }
    
    sender.enabled = NO;
    [_logCard 追加日志:@"正在初始化内核..."];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [DOJailbreaker.sharedInstance run];
        BOOL ok = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_logCard 追加日志:ok ? @"内核初始化成功" : @"内核初始化失败"];
            sender.enabled = YES;
        });
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [self registerNotifications];
    gRootVC = self;
    
    // 早期注册日志回调（logCard 创建前的日志会缓存）
    __weak typeof(self) weakSelf = self;
    KernelLoggerSetHandler(^(NSString *line) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && strongSelf->_logCard) {
            [strongSelf->_logCard 追加日志:line];
        }
    });
    KernelLogLine("UI 日志回调已注册");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self toggleHUDAfterLaunch];
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
        _isRemoteHUDActive = ![self isHUDEnabled];
        [self setHUDEnabled:_isRemoteHUDActive];
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOnHUDAfterLaunch {
    if ([BBZView shouldToggleHUDAfterLaunch]) {
        [BBZView setShouldToggleHUDAfterLaunch:NO];
        if (!_isRemoteHUDActive) {
            _isRemoteHUDActive = YES;
            [self setHUDEnabled:YES];
        }
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)toggleOffHUDAfterLaunch {
    if ([BBZView shouldToggleHUDAfterLaunch]) {
        [BBZView setShouldToggleHUDAfterLaunch:NO];
        if (_isRemoteHUDActive) {
            _isRemoteHUDActive = NO;
            [self setHUDEnabled:NO];
        }
        [[UIApplication sharedApplication] suspend];
    }
}

- (void)reloadMainButtonState {
    _isRemoteHUDActive = [self isHUDEnabled];
}

- (void)loadUserDefaults:(BOOL)forceReload {
    if (forceReload || !_userDefaults) {
        _userDefaults = [[NSDictionary dictionaryWithContentsOfFile:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH))] mutableCopy] ?: [NSMutableDictionary dictionary];
    }
}

- (void)saveUserDefaults {
    [_userDefaults writeToFile:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH)) atomically:YES];
    notify_post(NOTIFY_RELOAD_HUD);
}

- (void)reloadModeButtonState { }
- (void)verticalSizeClassUpdated { }

- (void)showSettings:(UIButton *)sender {
    LFSenderIDViewController *vc = [LFSenderIDViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Developer Area", nil) message:NSLocalizedString(@"Choose an action below.", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Reset Settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self resetUserDefaults];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)resetUserDefaults {
#if !NO_TROLL
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleIdentifier) {
        [GetStandardUserDefaults() removePersistentDomainForName:bundleIdentifier];
        [GetStandardUserDefaults() synchronize];
    }
#endif
    BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:(ROOT_PATH_NS_VAR(USER_DEFAULTS_PATH)) error:nil];
    if (removed) {
        [self setHUDEnabled:NO];
        [[UIApplication sharedApplication] terminateWithSuccess];
    }
}

- (BOOL)isLandscapeOrientation { return CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds); }
- (HUDUserDefaultsKey)selectedModeKeyForCurrentOrientation { return [self isLandscapeOrientation] ? HUDUserDefaultsKeySelectedModeLandscape : HUDUserDefaultsKeySelectedMode; }
- (HUDPresetPosition)selectedModeForCurrentOrientation {
    [self loadUserDefaults:NO];
    NSNumber *mode = [_userDefaults objectForKey:[self selectedModeKeyForCurrentOrientation]];
    return mode != nil ? (HUDPresetPosition)[mode integerValue] : HUDPresetPositionTopCenter;
}
- (void)setSelectedModeForCurrentOrientation:(HUDPresetPosition)selectedMode {
    [self loadUserDefaults:NO];
    if ([self isLandscapeOrientation]) [_userDefaults removeObjectForKey:HUDUserDefaultsKeyCurrentLandscapePositionY];
    else [_userDefaults removeObjectForKey:HUDUserDefaultsKeyCurrentPositionY];
    [_userDefaults setObject:@(selectedMode) forKey:[self selectedModeKeyForCurrentOrientation]];
    [self saveUserDefaults];
}
- (BOOL)passthroughMode { [self loadUserDefaults:NO]; NSNumber *m = [_userDefaults objectForKey:HUDUserDefaultsKeyPassthroughMode]; return m ? [m boolValue] : NO; }
- (void)setPassthroughMode:(BOOL)v { [self loadUserDefaults:NO]; [_userDefaults setObject:@(v) forKey:HUDUserDefaultsKeyPassthroughMode]; [self saveUserDefaults]; }
- (BOOL)singleLineMode { [self loadUserDefaults:NO]; NSNumber *m = [_userDefaults objectForKey:HUDUserDefaultsKeySingleLineMode]; return m ? [m boolValue] : NO; }
- (void)setSingleLineMode:(BOOL)v { [self loadUserDefaults:NO]; [_userDefaults setObject:@(v) forKey:HUDUserDefaultsKeySingleLineMode]; [self saveUserDefaults]; }
- (BOOL)usesBitrate { [self loadUserDefaults:NO]; NSNumber *m = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesBitrate]; return m ? [m boolValue] : NO; }
- (void)setUsesBitrate:(BOOL)v { [self loadUserDefaults:NO]; [_userDefaults setObject:@(v) forKey:HUDUserDefaultsKeyUsesBitrate]; [self saveUserDefaults]; }
- (BOOL)usesArrowPrefixes { [self loadUserDefaults:NO]; NSNumber *m = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesArrowPrefixes]; return m ? [m boolValue] : NO; }
- (void)setUsesArrowPrefixes:(BOOL)v { [self loadUserDefaults:NO]; [_userDefaults setObject:@(v) forKey:HUDUserDefaultsKeyUsesArrowPrefixes]; [self saveUserDefaults]; }
- (BOOL)usesLargeFont { [self loadUserDefaults:NO]; NSNumber *m = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesLargeFont]; return m ? [m boolValue] : NO; }
- (void)setUsesLargeFont:(BOOL)v { [self loadUserDefaults:NO]; [_userDefaults setObject:@(v) forKey:HUDUserDefaultsKeyUsesLargeFont]; [self saveUserDefaults]; }
- (BOOL)usesRotation { [self loadUserDefaults:NO]; NSNumber *m = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesRotation]; return m ? [m boolValue] : NO; }
- (void)setUsesRotation:(BOOL)v { [self loadUserDefaults:NO]; [_userDefaults setObject:@(v) forKey:HUDUserDefaultsKeyUsesRotation]; [self saveUserDefaults]; }
- (BOOL)usesInvertedColor { [self loadUserDefaults:NO]; NSNumber *m = [_userDefaults objectForKey:HUDUserDefaultsKeyUsesInvertedColor]; return m ? [m boolValue] : NO; }
- (void)setUsesInvertedColor:(BOOL)v { [self loadUserDefaults:NO]; [_userDefaults setObject:@(v) forKey:HUDUserDefaultsKeyUsesInvertedColor]; [self saveUserDefaults]; }
- (BOOL)keepInPlace { [self loadUserDefaults:NO]; NSNumber *m = [_userDefaults objectForKey:HUDUserDefaultsKeyKeepInPlace]; return m ? [m boolValue] : NO; }
- (void)setKeepInPlace:(BOOL)v { [self loadUserDefaults:NO]; [_userDefaults setObject:@(v) forKey:HUDUserDefaultsKeyKeepInPlace]; [self saveUserDefaults]; }
- (BOOL)hideAtSnapshot { [self loadUserDefaults:NO]; NSNumber *m = [_userDefaults objectForKey:HUDUserDefaultsKeyHideAtSnapshot]; return m ? [m boolValue] : NO; }
- (void)setHideAtSnapshot:(BOOL)v { [self loadUserDefaults:NO]; [_userDefaults setObject:@(v) forKey:HUDUserDefaultsKeyHideAtSnapshot]; [self saveUserDefaults]; }

@end
