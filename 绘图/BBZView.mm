//
//  BBZView.mm - AB 控制面板
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
#import "游戏/MaterialConfigViewController.h"
#import "游戏/DrawSettingsViewController.h"
//#import "pp.h"

#ifdef __cplusplus
extern "C" {
#endif
void KernelLoggerSetHandler(void (^handler)(NSString *line));
void KernelLogLine(const char *line);
void ResetKernelStatus();
void SetReadingEnabled(bool enabled);
bool IsReadingEnabled(void);
void kfd_log(const char *format, ...);
void NHDebugLogInvalidateCache(void);
#ifdef __cplusplus
}
#endif

// ========================================
// AB 配色方案 - 紫粉渐变风格
// ========================================
#define JVR_深色背景 [UIColor colorWithRed:18.0f/255.0f green:10.0f/255.0f blue:28.0f/255.0f alpha:1.0f]
#define JVR_卡片色 [UIColor colorWithRed:30.0f/255.0f green:18.0f/255.0f blue:45.0f/255.0f alpha:0.95f]
#define JVR_边框色 [UIColor colorWithRed:180.0f/255.0f green:100.0f/255.0f blue:255.0f/255.0f alpha:0.3f]
#define JVR_主色 [UIColor colorWithRed:200.0f/255.0f green:120.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
#define JVR_副色 [UIColor colorWithRed:255.0f/255.0f green:150.0f/255.0f blue:200.0f/255.0f alpha:1.0f]
#define JVR_警告色 [UIColor colorWithRed:255.0f/255.0f green:80.0f/255.0f blue:120.0f/255.0f alpha:1.0f]
#define JVR_文字色 [UIColor colorWithRed:240.0f/255.0f green:230.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
#define JVR_暗文字色 [UIColor colorWithRed:140.0f/255.0f green:110.0f/255.0f blue:170.0f/255.0f alpha:1.0f]
#define JVR_发光色 [UIColor colorWithRed:180.0f/255.0f green:100.0f/255.0f blue:255.0f/255.0f alpha:0.6f]

static BOOL _gShouldToggleHUDAfterLaunch = NO;
static __weak BBZView *gRootVC = nil;

// ========================================
// Plist 配置
// ========================================
static NSString* JVR_取配置路径() {
    return NHPrefsPath();
}

static NSMutableDictionary *JVR_开关缓存(void) {
    static NSMutableDictionary *cache = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cache = [NSMutableDictionary dictionary];
        // 默认落盘开；无有效 state 时 UI 显示为开
        cache[@"persist"] = @YES;
    });
    return cache;
}

static void JVR_保存开关(NSString* key, BOOL val) {
    NSMutableDictionary *cfg = [NSMutableDictionary dictionary];
    NSDictionary *cur = NHPrefsRead();
    if (cur) {
        [cfg addEntriesFromDictionary:cur];
    } else {
        [cfg addEntriesFromDictionary:JVR_开关缓存()];
    }
    cfg[key] = @(val);
    JVR_开关缓存()[key] = @(val);
    NHPrefsWrite(cfg);
}

static BOOL JVR_读取开关(NSString* key) {
    NSDictionary *cfg = NHPrefsRead();
    if (!cfg) {
        NSMutableDictionary *cached = JVR_开关缓存();
        if (cached.count > 0) {
            NHPrefsWrite(cached);
        }
        if ([key isEqualToString:@"persist"]) return YES; // 默认落盘
        return [[cached objectForKey:key] boolValue];
    }
    BOOL v;
    if ([key isEqualToString:@"persist"]) {
        v = cfg[@"persist"] != nil ? [cfg[@"persist"] boolValue] : YES;
    } else {
        v = [[cfg objectForKey:key] boolValue];
    }
    JVR_开关缓存()[key] = @(v);
    return v;
}

/// drawFps：0=跟屏刷，60/90/120（对标 wasd 选项卡存档方式）
static NSInteger JVR_规范化DrawFps(NSInteger fps) {
    if (fps == 60 || fps == 90 || fps == 120) return fps;
    return 0;
}

static void JVR_保存DrawFps(NSInteger fps) {
    fps = JVR_规范化DrawFps(fps);
    NSMutableDictionary *cfg = [NSMutableDictionary dictionary];
    NSDictionary *cur = NHPrefsRead();
    if (cur) [cfg addEntriesFromDictionary:cur];
    else [cfg addEntriesFromDictionary:JVR_开关缓存()];
    cfg[@"drawFps"] = @(fps);
    JVR_开关缓存()[@"drawFps"] = @(fps);
    NHPrefsWrite(cfg);
}

static NSInteger JVR_读取DrawFps(void) {
    id cached = JVR_开关缓存()[@"drawFps"];
    if (cached != nil) return JVR_规范化DrawFps([cached integerValue]);
    NSDictionary *cfg = NHPrefsRead();
    NSInteger fps = (cfg && cfg[@"drawFps"] != nil) ? [cfg[@"drawFps"] integerValue] : 0;
    fps = JVR_规范化DrawFps(fps);
    JVR_开关缓存()[@"drawFps"] = @(fps);
    return fps;
}

static NSInteger JVR_DrawFpsToSegmentIndex(NSInteger fps) {
    if (fps == 60) return 1;
    if (fps == 90) return 2;
    if (fps == 120) return 3;
    return 0; // 跟屏刷
}

static NSInteger JVR_SegmentIndexToDrawFps(NSInteger idx) {
    switch (idx) {
        case 1: return 60;
        case 2: return 90;
        case 3: return 120;
        default: return 0;
    }
}


// ========================================
// JVR 六边形装饰视图
// ========================================
@interface JVRHexagonView : UIView
@property (nonatomic, strong) CAShapeLayer *hexLayer;
@property (nonatomic, strong) CAShapeLayer *glowLayer;
@end

@implementation JVRHexagonView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupHexagon];
    }
    return self;
}

- (void)setupHexagon {
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat cx = w / 2.0f;
    CGFloat cy = h / 2.0f;
    CGFloat r = MIN(w, h) / 2.0f - 4.0f;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (int i = 0; i < 6; i++) {
        CGFloat angle = (M_PI / 3.0f) * i - M_PI / 2.0f;
        CGFloat x = cx + r * cos(angle);
        CGFloat y = cy + r * sin(angle);
        if (i == 0) [path moveToPoint:CGPointMake(x, y)];
        else [path addLineToPoint:CGPointMake(x, y)];
    }
    [path closePath];
    
    self.glowLayer = [CAShapeLayer layer];
    self.glowLayer.path = path.CGPath;
    self.glowLayer.fillColor = [UIColor clearColor].CGColor;
    self.glowLayer.strokeColor = JVR_发光色.CGColor;
    self.glowLayer.lineWidth = 3.0f;
    self.glowLayer.shadowColor = JVR_主色.CGColor;
    self.glowLayer.shadowOffset = CGSizeZero;
    self.glowLayer.shadowOpacity = 0.8f;
    self.glowLayer.shadowRadius = 8.0f;
    [self.layer addSublayer:self.glowLayer];
    
    self.hexLayer = [CAShapeLayer layer];
    self.hexLayer.path = path.CGPath;
    self.hexLayer.fillColor = JVR_卡片色.CGColor;
    self.hexLayer.strokeColor = JVR_边框色.CGColor;
    self.hexLayer.lineWidth = 1.5f;
    [self.layer addSublayer:self.hexLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.hexLayer removeFromSuperlayer];
    [self.glowLayer removeFromSuperlayer];
    [self setupHexagon];
}
@end

// ========================================
// JVR 霓虹开关
// ========================================
@interface JVRNeonSwitch : UIView
@property (nonatomic, assign) BOOL isOn;
@property (nonatomic, copy) NSString *switchKey;
@property (nonatomic, strong) UIView *track;
@property (nonatomic, strong) UIView *thumb;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, copy) void (^onToggle)(BOOL);
@end

// ========================================
// 绘制帧率选项卡（对标 wasd 血量样式：UISegmentedControl）
// 跟屏刷 / 60 / 90 / 120
// ========================================
@interface JVRFpsSegmentRow : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UISegmentedControl *segment;
@property (nonatomic, copy) void (^onChange)(NSInteger fps);
@end

@implementation JVRFpsSegmentRow

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [JVR_卡片色 colorWithAlphaComponent:0.6f];
        self.layer.cornerRadius = 8.0f;
        self.layer.borderWidth = 1.0f;
        self.layer.borderColor = JVR_边框色.CGColor;
        self.accessibilityIdentifier = @"DRAWFPS_SEG_V1";
        kfd_log("DRAWFPS_SEG_V1 init\n"); // ASCII 标记，供 CI strings 校验 IPA

        UIView *accent = [[UIView alloc] init];
        accent.translatesAutoresizingMaskIntoConstraints = NO;
        accent.backgroundColor = JVR_主色;
        accent.layer.cornerRadius = 1.5f;
        [self addSubview:accent];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.text = @"绘制帧率";
        self.titleLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
        self.titleLabel.textColor = JVR_文字色;
        [self addSubview:self.titleLabel];

        // 对标 wasd options 分段；默认跟屏刷=0（与 wasd CADisplayLink 不限帧一致）
        self.segment = [[UISegmentedControl alloc] initWithItems:@[ @"跟屏刷", @"60", @"90", @"120" ]];
        self.segment.translatesAutoresizingMaskIntoConstraints = NO;
        self.segment.selectedSegmentIndex = JVR_DrawFpsToSegmentIndex(JVR_读取DrawFps());
        if (@available(iOS 13.0, *)) {
            self.segment.selectedSegmentTintColor = [JVR_主色 colorWithAlphaComponent:0.55f];
            [self.segment setTitleTextAttributes:@{ NSForegroundColorAttributeName: JVR_文字色 } forState:UIControlStateNormal];
            [self.segment setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateSelected];
        }
        [self.segment addTarget:self action:@selector(onSegment:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.segment];

        [NSLayoutConstraint activateConstraints:@[
            [accent.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
            [accent.topAnchor constraintEqualToAnchor:self.topAnchor constant:12],
            [accent.widthAnchor constraintEqualToConstant:3],
            [accent.heightAnchor constraintEqualToConstant:18],
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:accent.trailingAnchor constant:10],
            [self.titleLabel.centerYAnchor constraintEqualToAnchor:accent.centerYAnchor],
            [self.segment.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [self.segment.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [self.segment.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:10],
            [self.segment.heightAnchor constraintEqualToConstant:30],
            [self.heightAnchor constraintEqualToConstant:72],
        ]];
    }
    return self;
}

- (void)onSegment:(UISegmentedControl *)sender {
    NSInteger fps = JVR_SegmentIndexToDrawFps(sender.selectedSegmentIndex);
    if (self.onChange) self.onChange(fps);
}

@end

// 手持样式：文字 / 图片
@interface JVRWeaponStyleRow : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UISegmentedControl *segment;
@property (nonatomic, copy) void (^onChange)(NSInteger style); // 0文字 1图片
@end

@implementation JVRWeaponStyleRow
- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [JVR_卡片色 colorWithAlphaComponent:0.6f];
        self.layer.cornerRadius = 8.0f;
        self.layer.borderWidth = 1.0f;
        self.layer.borderColor = JVR_边框色.CGColor;

        UIView *accent = [[UIView alloc] init];
        accent.translatesAutoresizingMaskIntoConstraints = NO;
        accent.backgroundColor = JVR_副色;
        accent.layer.cornerRadius = 1.5f;
        [self addSubview:accent];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.text = @"手持样式";
        self.titleLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
        self.titleLabel.textColor = JVR_文字色;
        [self addSubview:self.titleLabel];

        self.segment = [[UISegmentedControl alloc] initWithItems:@[ @"文字", @"图片" ]];
        self.segment.translatesAutoresizingMaskIntoConstraints = NO;
        NSInteger cur = 0;
        NSDictionary *cfg = NHPrefsRead();
        if (cfg[@"weaponStyle"]) cur = [cfg[@"weaponStyle"] integerValue];
        if (cur < 0) cur = 0;
        if (cur > 1) cur = 1;
        self.segment.selectedSegmentIndex = cur;
        if (@available(iOS 13.0, *)) {
            self.segment.selectedSegmentTintColor = [JVR_副色 colorWithAlphaComponent:0.55f];
            [self.segment setTitleTextAttributes:@{ NSForegroundColorAttributeName: JVR_文字色 } forState:UIControlStateNormal];
            [self.segment setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateSelected];
        }
        [self.segment addTarget:self action:@selector(onSegment:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.segment];

        [NSLayoutConstraint activateConstraints:@[
            [accent.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
            [accent.topAnchor constraintEqualToAnchor:self.topAnchor constant:12],
            [accent.widthAnchor constraintEqualToConstant:3],
            [accent.heightAnchor constraintEqualToConstant:18],
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:accent.trailingAnchor constant:10],
            [self.titleLabel.centerYAnchor constraintEqualToAnchor:accent.centerYAnchor],
            [self.segment.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [self.segment.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [self.segment.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:10],
            [self.segment.heightAnchor constraintEqualToConstant:30],
            [self.heightAnchor constraintEqualToConstant:72],
        ]];
    }
    return self;
}
- (void)onSegment:(UISegmentedControl *)sender {
    if (self.onChange) self.onChange(sender.selectedSegmentIndex);
}
@end

@implementation JVRNeonSwitch

- (instancetype)initWithTitle:(NSString *)title key:(NSString *)key {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.switchKey = key;
        self.backgroundColor = [JVR_卡片色 colorWithAlphaComponent:0.6f];
        self.layer.cornerRadius = 8.0f;
        self.layer.borderWidth = 1.0f;
        self.layer.borderColor = JVR_边框色.CGColor;
        
        // 左侧竖线装饰
        UIView *accent = [[UIView alloc] init];
        accent.translatesAutoresizingMaskIntoConstraints = NO;
        accent.backgroundColor = JVR_主色;
        accent.layer.cornerRadius = 1.5f;
        [self addSubview:accent];
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.text = title;
        self.titleLabel.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
        self.titleLabel.textColor = JVR_文字色;
        [self addSubview:self.titleLabel];
        
        self.statusLabel = [[UILabel alloc] init];
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.statusLabel.font = [UIFont fontWithName:@"Menlo" size:10.0f];
        self.statusLabel.textColor = JVR_暗文字色;
        [self addSubview:self.statusLabel];
        
        // 轨道
        self.track = [[UIView alloc] init];
        self.track.translatesAutoresizingMaskIntoConstraints = NO;
        self.track.backgroundColor = [UIColor colorWithWhite:0.15f alpha:1.0f];
        self.track.layer.cornerRadius = 12.0f;
        self.track.layer.borderWidth = 1.0f;
        self.track.layer.borderColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
        [self addSubview:self.track];
        
        // 滑块
        self.thumb = [[UIView alloc] initWithFrame:CGRectMake(2, 2, 20, 20)];
        self.thumb.backgroundColor = JVR_文字色;
        self.thumb.layer.cornerRadius = 10.0f;
        [self.track addSubview:self.thumb];
        
        [NSLayoutConstraint activateConstraints:@[
            [accent.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
            [accent.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [accent.widthAnchor constraintEqualToConstant:3],
            [accent.heightAnchor constraintEqualToConstant:24],
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:accent.trailingAnchor constant:10],
            [self.titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
            [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
            [self.statusLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:2],
            [self.track.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10],
            [self.track.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [self.track.widthAnchor constraintEqualToConstant:44],
            [self.track.heightAnchor constraintEqualToConstant:24],
            [self.heightAnchor constraintEqualToConstant:50],
        ]];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggle)];
        [self addGestureRecognizer:tap];
        
        self.isOn = JVR_读取开关(key);
        [self updateUI:NO];
    }
    return self;
}

- (void)toggle {
    self.isOn = !self.isOn;
    [self updateUI:YES];
    if (self.onToggle) self.onToggle(self.isOn);
}

- (void)updateUI:(BOOL)animated {
    CGFloat thumbX = self.isOn ? 22 : 2;
    UIColor *trackColor = self.isOn ? JVR_主色 : [UIColor colorWithWhite:0.15f alpha:1.0f];
    UIColor *borderColor = self.isOn ? JVR_主色 : [UIColor colorWithWhite:0.3f alpha:1.0f];
    
    NSTimeInterval dur = animated ? 0.2f : 0;
    [UIView animateWithDuration:dur delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:0 animations:^{
        self.thumb.frame = CGRectMake(thumbX, 2, 20, 20);
        self.track.backgroundColor = trackColor;
        self.track.layer.borderColor = borderColor.CGColor;
        if (self.isOn) {
            self.track.layer.shadowColor = JVR_主色.CGColor;
            self.track.layer.shadowOpacity = 0.6f;
            self.track.layer.shadowRadius = 6.0f;
            self.track.layer.shadowOffset = CGSizeZero;
        } else {
            self.track.layer.shadowOpacity = 0;
        }
    } completion:nil];
    
    self.statusLabel.text = self.isOn ? @"已启用" : @"已关闭";
    self.statusLabel.textColor = self.isOn ? JVR_副色 : JVR_暗文字色;
}
@end


// ========================================
// JVR 主控制卡片
// ========================================
@interface JVRMainCard : UIView
@property (nonatomic, strong) UIView *indicator;
@property (nonatomic, strong) UILabel *statusText;
@property (nonatomic, strong) UIView *pulseRing;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, copy) void (^onTap)(BOOL);
@end

@implementation JVRMainCard

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = JVR_卡片色;
    self.layer.cornerRadius = 12.0f;
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = JVR_边框色.CGColor;
    
    // 顶部装饰线
    UIView *topLine = [[UIView alloc] init];
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.colors = @[(id)JVR_主色.CGColor, (id)[UIColor clearColor].CGColor];
    grad.startPoint = CGPointMake(0, 0.5);
    grad.endPoint = CGPointMake(1, 0.5);
    [topLine.layer addSublayer:grad];
    [self addSubview:topLine];
    
    // 状态指示器
    self.pulseRing = [[UIView alloc] init];
    self.pulseRing.translatesAutoresizingMaskIntoConstraints = NO;
    self.pulseRing.backgroundColor = [UIColor clearColor];
    self.pulseRing.layer.borderWidth = 2.0f;
    self.pulseRing.layer.borderColor = JVR_主色.CGColor;
    self.pulseRing.layer.cornerRadius = 25.0f;
    [self addSubview:self.pulseRing];
    
    self.indicator = [[UIView alloc] init];
    self.indicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.indicator.backgroundColor = JVR_暗文字色;
    self.indicator.layer.cornerRadius = 20.0f;
    [self addSubview:self.indicator];
    
    // 标签
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"系统";
    label.font = [UIFont systemFontOfSize:10.0f weight:UIFontWeightBold];
    label.textColor = JVR_暗文字色;
    [self addSubview:label];
    
    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"主开关";
    title.font = [UIFont systemFontOfSize:18.0f weight:UIFontWeightBold];
    title.textColor = JVR_文字色;
    [self addSubview:title];
    
    self.statusText = [[UILabel alloc] init];
    self.statusText.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusText.font = [UIFont fontWithName:@"Menlo" size:12.0f];
    self.statusText.textColor = JVR_暗文字色;
    [self addSubview:self.statusText];
    
    // 右侧箭头
    UILabel *arrow = [[UILabel alloc] init];
    arrow.translatesAutoresizingMaskIntoConstraints = NO;
    arrow.text = @"▶";
    arrow.font = [UIFont systemFontOfSize:14.0f];
    arrow.textColor = JVR_主色;
    [self addSubview:arrow];
    
    [NSLayoutConstraint activateConstraints:@[
        [topLine.topAnchor constraintEqualToAnchor:self.topAnchor],
        [topLine.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [topLine.widthAnchor constraintEqualToConstant:120],
        [topLine.heightAnchor constraintEqualToConstant:3],
        [self.pulseRing.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
        [self.pulseRing.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.pulseRing.widthAnchor constraintEqualToConstant:50],
        [self.pulseRing.heightAnchor constraintEqualToConstant:50],
        [self.indicator.centerXAnchor constraintEqualToAnchor:self.pulseRing.centerXAnchor],
        [self.indicator.centerYAnchor constraintEqualToAnchor:self.pulseRing.centerYAnchor],
        [self.indicator.widthAnchor constraintEqualToConstant:40],
        [self.indicator.heightAnchor constraintEqualToConstant:40],
        [label.leadingAnchor constraintEqualToAnchor:self.pulseRing.trailingAnchor constant:14],
        [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:16],
        [title.leadingAnchor constraintEqualToAnchor:label.leadingAnchor],
        [title.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:2],
        [self.statusText.leadingAnchor constraintEqualToAnchor:label.leadingAnchor],
        [self.statusText.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
        [arrow.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
        [arrow.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.heightAnchor constraintEqualToConstant:80],
    ]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    [self addGestureRecognizer:tap];
    
    self.isActive = NO;
    [self updateState:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (CALayer *sub in self.subviews.firstObject.layer.sublayers) {
        if ([sub isKindOfClass:[CAGradientLayer class]]) {
            sub.frame = CGRectMake(0, 0, 120, 3);
        }
    }
}

- (void)tapped {
    self.isActive = !self.isActive;
    [self updateState:YES];
    if (self.onTap) self.onTap(self.isActive);
}

- (void)updateState:(BOOL)animated {
    UIColor *indicatorColor = self.isActive ? JVR_副色 : JVR_暗文字色;
    UIColor *ringColor = self.isActive ? JVR_副色 : JVR_主色;
    
    NSTimeInterval dur = animated ? 0.25f : 0;
    [UIView animateWithDuration:dur animations:^{
        self.indicator.backgroundColor = indicatorColor;
        self.pulseRing.layer.borderColor = ringColor.CGColor;
        if (self.isActive) {
            self.indicator.layer.shadowColor = JVR_副色.CGColor;
            self.indicator.layer.shadowOpacity = 0.8f;
            self.indicator.layer.shadowRadius = 10.0f;
            self.indicator.layer.shadowOffset = CGSizeZero;
        } else {
            self.indicator.layer.shadowOpacity = 0;
        }
    }];
    
    self.statusText.text = self.isActive ? @"状态: 运行中" : @"状态: 已关闭";
    self.statusText.textColor = self.isActive ? JVR_副色 : JVR_暗文字色;
    
    if (self.isActive) {
        [self startPulse];
    } else {
        [self.pulseRing.layer removeAllAnimations];
        self.pulseRing.alpha = 1.0f;
    }
}

- (void)startPulse {
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @1.0f;
    pulse.toValue = @1.2f;
    pulse.duration = 1.0f;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.pulseRing.layer addAnimation:pulse forKey:@"pulse"];
}
@end


// ========================================
// JVR 终端日志视图
// ========================================
@interface JVRTerminal : UIView
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UIView *scanLine;
@end

@implementation JVRTerminal

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor colorWithRed:5.0f/255.0f green:10.0f/255.0f blue:18.0f/255.0f alpha:1.0f];
    self.layer.cornerRadius = 10.0f;
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = JVR_边框色.CGColor;
    self.clipsToBounds = YES;
    
    // 顶部栏
    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.backgroundColor = [UIColor colorWithWhite:0.1f alpha:1.0f];
    [self addSubview:header];
    
    // 三个小圆点
    UIView *dot1 = [[UIView alloc] init];
    dot1.translatesAutoresizingMaskIntoConstraints = NO;
    dot1.backgroundColor = JVR_警告色;
    dot1.layer.cornerRadius = 4.0f;
    [header addSubview:dot1];
    
    UIView *dot2 = [[UIView alloc] init];
    dot2.translatesAutoresizingMaskIntoConstraints = NO;
    dot2.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:204.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
    dot2.layer.cornerRadius = 4.0f;
    [header addSubview:dot2];
    
    UIView *dot3 = [[UIView alloc] init];
    dot3.translatesAutoresizingMaskIntoConstraints = NO;
    dot3.backgroundColor = JVR_副色;
    dot3.layer.cornerRadius = 4.0f;
    [header addSubview:dot3];
    
    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"运行日志";
    title.font = [UIFont systemFontOfSize:10.0f weight:UIFontWeightBold];
    title.textColor = JVR_暗文字色;
    [header addSubview:title];
    
    self.logView = [[UITextView alloc] init];
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logView.backgroundColor = [UIColor clearColor];
    self.logView.textColor = JVR_主色;
    self.logView.font = [UIFont fontWithName:@"Menlo" size:10.0f];
    self.logView.editable = NO;
    self.logView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.logView.showsVerticalScrollIndicator = YES;
    self.logView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [self addSubview:self.logView];
    
    // 扫描线效果
    self.scanLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 2)];
    self.scanLine.backgroundColor = [JVR_主色 colorWithAlphaComponent:0.3f];
    [self addSubview:self.scanLine];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:self.topAnchor],
        [header.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [header.heightAnchor constraintEqualToConstant:28],
        [dot1.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:10],
        [dot1.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [dot1.widthAnchor constraintEqualToConstant:8],
        [dot1.heightAnchor constraintEqualToConstant:8],
        [dot2.leadingAnchor constraintEqualToAnchor:dot1.trailingAnchor constant:6],
        [dot2.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [dot2.widthAnchor constraintEqualToConstant:8],
        [dot2.heightAnchor constraintEqualToConstant:8],
        [dot3.leadingAnchor constraintEqualToAnchor:dot2.trailingAnchor constant:6],
        [dot3.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [dot3.widthAnchor constraintEqualToConstant:8],
        [dot3.heightAnchor constraintEqualToConstant:8],
        [title.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
        [title.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [self.logView.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [self.logView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.logView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.logView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
    
    [self startScanAnimation];
}

- (void)startScanAnimation {
    [UIView animateWithDuration:3.0f delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear animations:^{
        self.scanLine.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, 2);
    } completion:nil];
}

- (void)appendLog:(NSString *)line {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *timestamp = [self timestamp];
        NSString *old = self.logView.text ?: @"";
        NSString *nl = old.length ? @"\n" : @"";
        self.logView.text = [old stringByAppendingFormat:@"%@[%@] > %@", nl, timestamp, line];
        [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length, 0)];
    });
}

- (NSString *)timestamp {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"HH:mm:ss";
    return [fmt stringFromDate:[NSDate date]];
}
@end


// ========================================
// JVR 内核按钮
// ========================================
@interface JVRKernelButton : UIView
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) CAGradientLayer *borderGrad;
@property (nonatomic, copy) void (^onTap)(void);
@end

@implementation JVRKernelButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 10.0f;
    self.clipsToBounds = YES;
    
    // 渐变边框
    UIView *borderView = [[UIView alloc] init];
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.layer.cornerRadius = 10.0f;
    borderView.clipsToBounds = YES;
    [self addSubview:borderView];
    
    self.borderGrad = [CAGradientLayer layer];
    self.borderGrad.colors = @[(id)JVR_主色.CGColor, (id)JVR_副色.CGColor];
    self.borderGrad.startPoint = CGPointMake(0, 0);
    self.borderGrad.endPoint = CGPointMake(1, 1);
    [borderView.layer addSublayer:self.borderGrad];
    
    // 内部填充
    UIView *inner = [[UIView alloc] init];
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    inner.backgroundColor = JVR_深色背景;
    inner.layer.cornerRadius = 8.0f;
    [self addSubview:inner];
    
    // 图标
    UILabel *icon = [[UILabel alloc] init];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.text = @"⚡";
    icon.font = [UIFont systemFontOfSize:16.0f];
    [self addSubview:icon];
    
    self.label = [[UILabel alloc] init];
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.label.text = @"初始化内核";
    self.label.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightBold];
    self.label.textColor = JVR_主色;
    [self addSubview:self.label];
    
    [NSLayoutConstraint activateConstraints:@[
        [borderView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [borderView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [borderView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [borderView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [inner.topAnchor constraintEqualToAnchor:self.topAnchor constant:2],
        [inner.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:2],
        [inner.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-2],
        [inner.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-2],
        [icon.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
        [icon.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.label.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.heightAnchor constraintEqualToConstant:44],
    ]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    [self addGestureRecognizer:tap];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.borderGrad.frame = self.bounds;
}

- (void)tapped {
    [UIView animateWithDuration:0.1f animations:^{
        self.transform = CGAffineTransformMakeScale(0.96f, 0.96f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1f animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];
    if (self.onTap) self.onTap();
}
@end

// ========================================
// JVR 分区标题
// ========================================
@interface JVRSectionHeader : UIView
@end

@implementation JVRSectionHeader

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        UIView *line = [[UIView alloc] init];
        line.translatesAutoresizingMaskIntoConstraints = NO;
        line.backgroundColor = JVR_主色;
        line.layer.cornerRadius = 1.0f;
        line.layer.shadowColor = JVR_主色.CGColor;
        line.layer.shadowOpacity = 0.8f;
        line.layer.shadowRadius = 4.0f;
        line.layer.shadowOffset = CGSizeZero;
        [self addSubview:line];
        
        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.text = title;
        label.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightBold];
        label.textColor = JVR_主色;
        [self addSubview:label];
        
        UIView *dash = [[UIView alloc] init];
        dash.translatesAutoresizingMaskIntoConstraints = NO;
        dash.backgroundColor = [JVR_边框色 colorWithAlphaComponent:0.5f];
        [self addSubview:dash];
        
        [NSLayoutConstraint activateConstraints:@[
            [line.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [line.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [line.widthAnchor constraintEqualToConstant:3],
            [line.heightAnchor constraintEqualToConstant:16],
            [label.leadingAnchor constraintEqualToAnchor:line.trailingAnchor constant:10],
            [label.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [dash.leadingAnchor constraintEqualToAnchor:label.trailingAnchor constant:10],
            [dash.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [dash.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [dash.heightAnchor constraintEqualToConstant:1],
            [self.heightAnchor constraintEqualToConstant:30],
        ]];
    }
    return self;
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
    JVRTerminal *_terminal;
    BOOL _hasEnteredMenu;
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
    self.view.backgroundColor = JVR_深色背景;
    
    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = JVR_深色背景;
    [self.view addSubview:self.backgroundView];
    
    _hasEnteredMenu = NO;
    [self showBootScreen];
}

// ========================================
// JVR 启动界面
// ========================================
- (void)showBootScreen {
    for (UIView *sub in self.backgroundView.subviews) [sub removeFromSuperview];
    
    UIView *bg = self.backgroundView;
    
    // 网格背景
    [self addGridBackground:bg];
    
    // Logo 容器
    UIView *logoBox = [[UIView alloc] init];
    logoBox.translatesAutoresizingMaskIntoConstraints = NO;
    logoBox.backgroundColor = JVR_卡片色;
    logoBox.layer.cornerRadius = 20.0f;
    logoBox.layer.borderWidth = 2.0f;
    logoBox.layer.borderColor = JVR_边框色.CGColor;
    logoBox.layer.shadowColor = JVR_主色.CGColor;
    logoBox.layer.shadowOpacity = 0.5f;
    logoBox.layer.shadowRadius = 20.0f;
    logoBox.layer.shadowOffset = CGSizeZero;
    [bg addSubview:logoBox];
    
    UILabel *logoText = [[UILabel alloc] init];
    logoText.translatesAutoresizingMaskIntoConstraints = NO;
    logoText.text = @"AB";
    logoText.font = [UIFont systemFontOfSize:42.0f weight:UIFontWeightBlack];
    logoText.textColor = JVR_主色;
    [logoBox addSubview:logoText];
    
    // 版本号
    UILabel *version = [[UILabel alloc] init];
    version.translatesAutoresizingMaskIntoConstraints = NO;
    version.text = @"v1.0.0";
    version.font = [UIFont fontWithName:@"Menlo" size:10.0f];
    version.textColor = JVR_暗文字色;
    [bg addSubview:version];
    
    // 加载条容器
    UIView *loadBar = [[UIView alloc] init];
    loadBar.translatesAutoresizingMaskIntoConstraints = NO;
    loadBar.backgroundColor = [UIColor colorWithWhite:0.15f alpha:1.0f];
    loadBar.layer.cornerRadius = 3.0f;
    loadBar.clipsToBounds = YES;
    [bg addSubview:loadBar];
    
    // 进度条
    UIView *progress = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 6)];
    progress.backgroundColor = JVR_主色;
    progress.layer.cornerRadius = 3.0f;
    progress.layer.shadowColor = JVR_主色.CGColor;
    progress.layer.shadowOpacity = 0.8f;
    progress.layer.shadowRadius = 6.0f;
    progress.layer.shadowOffset = CGSizeZero;
    [loadBar addSubview:progress];
    
    // 状态文字
    UILabel *status = [[UILabel alloc] init];
    status.translatesAutoresizingMaskIntoConstraints = NO;
    status.text = @"正在初始化系统...";
    status.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightMedium];
    status.textColor = JVR_暗文字色;
    status.tag = 100;
    [bg addSubview:status];
    
    // 进入按钮
    UIButton *enterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    enterBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [enterBtn setTitle:@"进入系统" forState:UIControlStateNormal];
    [enterBtn setTitleColor:JVR_主色 forState:UIControlStateNormal];
    enterBtn.titleLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightBold];
    enterBtn.backgroundColor = [JVR_卡片色 colorWithAlphaComponent:0.8f];
    enterBtn.layer.cornerRadius = 10.0f;
    enterBtn.layer.borderWidth = 1.0f;
    enterBtn.layer.borderColor = JVR_主色.CGColor;
    enterBtn.alpha = 0;
    enterBtn.transform = CGAffineTransformMakeTranslation(0, 20);
    [enterBtn addTarget:self action:@selector(enterMainMenu) forControlEvents:UIControlEventTouchUpInside];
    enterBtn.tag = 101;
    [bg addSubview:enterBtn];
    
    [NSLayoutConstraint activateConstraints:@[
        [logoBox.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [logoBox.centerYAnchor constraintEqualToAnchor:bg.centerYAnchor constant:-80],
        [logoBox.widthAnchor constraintEqualToConstant:140],
        [logoBox.heightAnchor constraintEqualToConstant:100],
        [logoText.centerXAnchor constraintEqualToAnchor:logoBox.centerXAnchor],
        [logoText.centerYAnchor constraintEqualToAnchor:logoBox.centerYAnchor],
        [version.topAnchor constraintEqualToAnchor:logoBox.bottomAnchor constant:8],
        [version.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [loadBar.topAnchor constraintEqualToAnchor:version.bottomAnchor constant:30],
        [loadBar.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [loadBar.widthAnchor constraintEqualToConstant:200],
        [loadBar.heightAnchor constraintEqualToConstant:6],
        [status.topAnchor constraintEqualToAnchor:loadBar.bottomAnchor constant:12],
        [status.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [enterBtn.topAnchor constraintEqualToAnchor:status.bottomAnchor constant:30],
        [enterBtn.centerXAnchor constraintEqualToAnchor:bg.centerXAnchor],
        [enterBtn.widthAnchor constraintEqualToConstant:200],
        [enterBtn.heightAnchor constraintEqualToConstant:48],
    ]];
    
    // 加载动画
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.5f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            progress.frame = CGRectMake(0, 0, 200, 6);
        } completion:^(BOOL finished) {
            status.text = @"系统就绪";
            status.textColor = JVR_副色;
            [UIView animateWithDuration:0.4f delay:0.2f usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:0 animations:^{
                enterBtn.alpha = 1;
                enterBtn.transform = CGAffineTransformIdentity;
            } completion:nil];
        }];
    });
}

- (void)addGridBackground:(UIView *)container {
    CAShapeLayer *grid = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat spacing = 40.0f;
    CGFloat w = UIScreen.mainScreen.bounds.size.width;
    CGFloat h = UIScreen.mainScreen.bounds.size.height;
    
    for (CGFloat x = 0; x <= w; x += spacing) {
        [path moveToPoint:CGPointMake(x, 0)];
        [path addLineToPoint:CGPointMake(x, h)];
    }
    for (CGFloat y = 0; y <= h; y += spacing) {
        [path moveToPoint:CGPointMake(0, y)];
        [path addLineToPoint:CGPointMake(w, y)];
    }
    
    grid.path = path.CGPath;
    grid.strokeColor = [UIColor colorWithWhite:1.0f alpha:0.03f].CGColor;
    grid.lineWidth = 0.5f;
    [container.layer addSublayer:grid];
}

- (void)enterMainMenu {
    UIButton *btn = (UIButton *)[self.backgroundView viewWithTag:101];
    [UIView animateWithDuration:0.1f animations:^{
        btn.transform = CGAffineTransformMakeScale(0.95f, 0.95f);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1f animations:^{
            btn.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [UIView transitionWithView:self.backgroundView duration:0.35f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [self buildMainMenu];
            } completion:nil];
        }];
    }];
}


// ========================================
// JVR 主菜单
// ========================================
- (void)buildMainMenu {
    _hasEnteredMenu = YES;
    for (UIView *sub in self.backgroundView.subviews) [sub removeFromSuperview];
    
    UIView *bg = self.backgroundView;
    UILayoutGuide *safeArea = bg.safeAreaLayoutGuide;
    
    // 网格背景
    [self addGridBackground:bg];
    
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    scroll.alwaysBounceVertical = YES;
    [bg addSubview:scroll];
    
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
    ]];
    
    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];
    
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor],
    ]];
    
    // ---- 头部 ----
    UIView *header = [self createHeader];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:header];
    
    // ---- 主控制卡片 ----
    JVRMainCard *mainCard = [[JVRMainCard alloc] init];
    mainCard.translatesAutoresizingMaskIntoConstraints = NO;
    _isRemoteHUDActive = [self isHUDEnabled];
    mainCard.isActive = _isRemoteHUDActive;
    [mainCard updateState:NO];
    [content addSubview:mainCard];
    
    // ---- 内核按钮 ----
    JVRKernelButton *kernelBtn = [[JVRKernelButton alloc] init];
    kernelBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:kernelBtn];
    
    // ---- 重置内核按钮 ----
    JVRKernelButton *resetBtn = [[JVRKernelButton alloc] init];
    resetBtn.translatesAutoresizingMaskIntoConstraints = NO;
    resetBtn.label.text = @"重置内核状态";
    resetBtn.label.textColor = JVR_警告色;
    resetBtn.borderGrad.colors = @[(id)JVR_警告色.CGColor, (id)JVR_主色.CGColor];
    [content addSubview:resetBtn];

    // ---- 开始读取按钮 ----
    JVRKernelButton *readBtn = [[JVRKernelButton alloc] init];
    readBtn.translatesAutoresizingMaskIntoConstraints = NO;
    readBtn.label.text = @"开始读取";
    readBtn.label.textColor = JVR_副色;
    readBtn.borderGrad.colors = @[(id)JVR_副色.CGColor, (id)JVR_主色.CGColor];
    [content addSubview:readBtn];

    // ---- 关闭 HUD 按钮 ----
    JVRKernelButton *closeHudBtn = [[JVRKernelButton alloc] init];
    closeHudBtn.translatesAutoresizingMaskIntoConstraints = NO;
    closeHudBtn.label.text = @"关闭HUD";
    closeHudBtn.label.textColor = JVR_警告色;
    closeHudBtn.borderGrad.colors = @[(id)JVR_警告色.CGColor, (id)[UIColor colorWithRed:0.8f green:0.2f blue:0.2f alpha:1.0f].CGColor];
    [content addSubview:closeHudBtn];
    
    // ---- 终端 ----
    _terminal = [[JVRTerminal alloc] init];
    _terminal.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:_terminal];
    
    // ---- 功能区标题 ----
    JVRSectionHeader *sectionHeader = [[JVRSectionHeader alloc] initWithTitle:@"功能模块"];
    sectionHeader.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:sectionHeader];
    
    // ---- 开关列表 ----
    UIStackView *switchList = [self createSwitchList];
    switchList.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:switchList];
    
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:content.topAnchor constant:16],
        [header.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
        [header.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
        
        [mainCard.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:20],
        [mainCard.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
        [mainCard.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
        
        [kernelBtn.topAnchor constraintEqualToAnchor:mainCard.bottomAnchor constant:12],
        [kernelBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
        [kernelBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
        
        [resetBtn.topAnchor constraintEqualToAnchor:kernelBtn.bottomAnchor constant:8],
        [resetBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
        [resetBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],

        [readBtn.topAnchor constraintEqualToAnchor:resetBtn.bottomAnchor constant:8],
        [readBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
        [readBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],

        [closeHudBtn.topAnchor constraintEqualToAnchor:readBtn.bottomAnchor constant:8],
        [closeHudBtn.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
        [closeHudBtn.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
        
        [_terminal.topAnchor constraintEqualToAnchor:closeHudBtn.bottomAnchor constant:12],
        [_terminal.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
        [_terminal.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
        [_terminal.heightAnchor constraintEqualToConstant:150],
        
        [sectionHeader.topAnchor constraintEqualToAnchor:_terminal.bottomAnchor constant:20],
        [sectionHeader.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
        [sectionHeader.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
        
        [switchList.topAnchor constraintEqualToAnchor:sectionHeader.bottomAnchor constant:12],
        [switchList.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
        [switchList.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
        [switchList.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-30],
    ]];
    
    // ---- 回调 ----
    __weak typeof(self) weakSelf = self;
    mainCard.onTap = ^(BOOL active) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf->_isRemoteHUDActive = active;
        [strongSelf setHUDEnabled:active];
        if (!active) {
            // 主开关关掉时一并停读取，避免 HUD 关了 reading 还在跑
            SetReadingEnabled(false);
            readBtn.label.text = @"开始读取";
        }
        [strongSelf->_terminal appendLog:active ? @"HUD 已启用" : @"HUD 已关闭（读取已停）"];
        kfd_log("[UI] HUD %s\n", active ? "enabled" : "disabled");
    };
    
    kernelBtn.onTap = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        BOOL alreadyOk = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
        if (alreadyOk) {
            [strongSelf->_terminal appendLog:@"内核已就绪，无需重复初始化"];
            kfd_log("[UI] 初始化内核：已就绪，跳过\n");
            return;
        }
        
        [strongSelf->_terminal appendLog:@"正在初始化内核..."];
        kfd_log("[UI] 初始化内核：开始 DOJailbreaker.run\n");
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            [DOJailbreaker.sharedInstance run];
            BOOL ok = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
            kfd_log("[UI] 初始化内核：结果 isSuccess=%d\n", (int)ok);
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf->_terminal appendLog:ok ? @"内核初始化成功（krkw就绪）" : @"内核初始化失败"];
            });
        });
    };
    
    resetBtn.onTap = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        [strongSelf->_terminal appendLog:@"正在重置内核状态..."];
        kfd_log("[UI] 重置内核状态：开始\n");
        ResetKernelStatus();
        readBtn.label.text = @"开始读取";
        kfd_log("[UI] 重置内核状态：完成，读取已停止\n");
        [strongSelf->_terminal appendLog:@"内核状态已重置，读取已停止"];
    };

    readBtn.onTap = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        BOOL krkwOk = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
        if (!krkwOk) {
            [strongSelf->_terminal appendLog:@"请先点「初始化内核」获得 krkw"];
            kfd_log("[UI] 开始读取：拒绝，krkw 未就绪\n");
            return;
        }

        if (IsReadingEnabled()) {
            SetReadingEnabled(false);
            readBtn.label.text = @"开始读取";
            [strongSelf->_terminal appendLog:@"已停止读取"];
            kfd_log("[UI] 开始读取：切换为停止\n");
            return;
        }

        // 关键：没有 HUD 进程就没有任何像素——自动拉起 HUD（对标 wasd 悬浮窗）
        if (![strongSelf isHUDEnabled]) {
            [strongSelf setHUDEnabled:YES];
            strongSelf->_isRemoteHUDActive = YES;
            mainCard.isActive = YES;
            [mainCard updateState:YES];
            [strongSelf->_terminal appendLog:@"已自动开启 HUD（之前未开，所以屏幕上什么都看不到）"];
            kfd_log("[UI] auto SetHUDEnabled(YES)\n");
        }
        [strongSelf->_terminal appendLog:NHPersistFilesEnabled() ? @"开始读取 reading=1（已落盘）" : @"开始读取 reading=1（仅 notify，无文件）"];
        kfd_log("[UI] 开始读取：reading=1 persist=%d\n", (int)NHPersistFilesEnabled());
        SetReadingEnabled(true);
        readBtn.label.text = @"停止读取";
        BOOL countOn = JVR_读取开关(@"count");
        BOOL lineOn = JVR_读取开关(@"line");
        if (!countOn) {
            JVR_保存开关(@"count", YES);
            countOn = YES;
            [strongSelf->_terminal appendLog:@"已自动打开「显示人数」便于验证"];
        }
        [strongSelf->_terminal appendLog:countOn ? @"显示人数=开" : @"显示人数=关"];
        [strongSelf->_terminal appendLog:lineOn ? @"射线显示=开" : @"射线显示=关"];
        [strongSelf->_terminal appendLog:@"判据：新日志必须出现 HUD: / [绘制]；仅有[7s]说明还在主进程"];
        kfd_log("[UI] 开关 count=%d line=%d reading=1 hudOn=1\n", (int)countOn, (int)lineOn);
    };

    closeHudBtn.onTap = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        // 停读取 + 关 HUD 进程，同步主开关卡片
        SetReadingEnabled(false);
        readBtn.label.text = @"开始读取";
        strongSelf->_isRemoteHUDActive = NO;
        [strongSelf setHUDEnabled:NO];
        mainCard.isActive = NO;
        [mainCard updateState:YES];
        [strongSelf->_terminal appendLog:@"HUD 已关闭（读取已停）"];
        kfd_log("[UI] 关闭HUD：reading=0 SetHUDEnabled(NO)\n");
    };
    
    [self reloadMainButtonState];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL ok = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
        [self->_terminal appendLog:ok ? @"内核状态: 已就绪" : @"内核状态: 未就绪"];
    });
}

- (UIView *)createHeader {
    UIView *container = [[UIView alloc] init];
    
    // Logo
    UIView *logoBox = [[UIView alloc] init];
    logoBox.translatesAutoresizingMaskIntoConstraints = NO;
    logoBox.backgroundColor = JVR_卡片色;
    logoBox.layer.cornerRadius = 10.0f;
    logoBox.layer.borderWidth = 1.0f;
    logoBox.layer.borderColor = JVR_边框色.CGColor;
    [container addSubview:logoBox];
    
    UILabel *logoText = [[UILabel alloc] init];
    logoText.translatesAutoresizingMaskIntoConstraints = NO;
    logoText.text = @"AB";
    logoText.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightBlack];
    logoText.textColor = JVR_主色;
    [logoBox addSubview:logoText];
    
    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"设置";
    title.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightBold];
    title.textColor = JVR_文字色;
    [container addSubview:title];
    
    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.text = @"系统界面";
    subtitle.font = [UIFont systemFontOfSize:11.0f weight:UIFontWeightMedium];
    subtitle.textColor = JVR_暗文字色;
    [container addSubview:subtitle];
    
    [NSLayoutConstraint activateConstraints:@[
        [logoBox.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [logoBox.topAnchor constraintEqualToAnchor:container.topAnchor],
        [logoBox.widthAnchor constraintEqualToConstant:50],
        [logoBox.heightAnchor constraintEqualToConstant:40],
        [logoText.centerXAnchor constraintEqualToAnchor:logoBox.centerXAnchor],
        [logoText.centerYAnchor constraintEqualToAnchor:logoBox.centerYAnchor],
        [title.leadingAnchor constraintEqualToAnchor:logoBox.trailingAnchor constant:12],
        [title.topAnchor constraintEqualToAnchor:container.topAnchor constant:2],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2],
        [container.heightAnchor constraintEqualToConstant:44],
    ]];
    
    return container;
}

- (UIStackView *)createSwitchList {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8.0f;
    stack.alignment = UIStackViewAlignmentFill;

    // 对标 wasd「血量样式」分段选项：跟屏刷 / 60 / 90 / 120
    JVRFpsSegmentRow *fpsRow = [[JVRFpsSegmentRow alloc] init];
    fpsRow.translatesAutoresizingMaskIntoConstraints = NO;
    fpsRow.onChange = ^(NSInteger fps) {
        JVR_保存DrawFps(fps);
        NSString *title = (fps <= 0) ? @"跟屏刷" : [NSString stringWithFormat:@"%ld", (long)fps];
        KernelLogLine([[NSString stringWithFormat:@"绘制帧率 = %@", title] UTF8String]);
        kfd_log("[UI] drawFps=%ld DRAWFPS_SEG_V1\n", (long)fps);
    };
    [stack addArrangedSubview:fpsRow];

    JVRWeaponStyleRow *weaponStyleRow = [[JVRWeaponStyleRow alloc] init];
    weaponStyleRow.translatesAutoresizingMaskIntoConstraints = NO;
    weaponStyleRow.onChange = ^(NSInteger style) {
        NSMutableDictionary *cfg = [NSMutableDictionary dictionary];
        NSDictionary *cur = NHPrefsRead();
        if (cur) [cfg addEntriesFromDictionary:cur];
        cfg[@"weaponStyle"] = @(style);
        NHPrefsWrite(cfg);
        KernelLogLine(style == 1 ? "手持样式 = 图片" : "手持样式 = 文字");
        kfd_log("[UI] weaponStyle=%ld\n", (long)style);
    };
    [stack addArrangedSubview:weaponStyleRow];
    
    NSArray *configs = @[
        @{@"title": @"显示人数", @"key": @"count"},
        @{@"title": @"射线显示", @"key": @"line"},
        @{@"title": @"方框显示", @"key": @"box"},
        @{@"title": @"血量显示", @"key": @"health"},
        @{@"title": @"玩家信息", @"key": @"info"},   // 名字 + 队伍
        @{@"title": @"显示距离", @"key": @"dist"},
        @{@"title": @"显示手持", @"key": @"weapon"},
        @{@"title": @"显示背敌", @"key": @"behind"},
        @{@"title": @"显示物资", @"key": @"loot"},   // 含手雷倒计时
        @{@"title": @"骨骼显示", @"key": @"bone"},
        @{@"title": @"过直播模式", @"key": @"overlay"},
        @{@"title": @"调试日志", @"key": @"dbglog"}, // 默认关；开才写 kfd_debug / 终端诊断
        @{@"title": @"配置落盘", @"key": @"persist"}, // 默认开；关则不生成 cfg/pid 文件，仅 notify 同步
    ];
    
    for (NSDictionary *cfg in configs) {
        JVRNeonSwitch *sw = [[JVRNeonSwitch alloc] initWithTitle:cfg[@"title"] key:cfg[@"key"]];
        sw.translatesAutoresizingMaskIntoConstraints = NO;
        sw.onToggle = ^(BOOL on) {
            JVR_保存开关(cfg[@"key"], on);
            if ([cfg[@"key"] isEqualToString:@"dbglog"]) {
                NHDebugLogInvalidateCache();
            }
            if ([cfg[@"key"] isEqualToString:@"persist"]) {
                KernelLogLine(on ? "配置落盘=开（写 Downloads cfg）" : "配置落盘=关（无文件，notify 同步；已有 cfg/pid 已删）");
            }
            kfd_log("[UI] 开关 %s = %d\n", [cfg[@"key"] UTF8String], (int)on);
            KernelLogLine([[NSString stringWithFormat:@"开关 %@ = %@", cfg[@"key"], on ? @"开" : @"关"] UTF8String]);
        };
        [stack addArrangedSubview:sw];
    }

    __weak typeof(self) weakSelf = self;

    // 绘制设置（在物资功能上方，对标 wasd 绘制设置）
    JVRKernelButton *drawSetBtn = [[JVRKernelButton alloc] init];
    drawSetBtn.translatesAutoresizingMaskIntoConstraints = NO;
    drawSetBtn.label.text = @"绘制设置";
    drawSetBtn.label.textColor = JVR_主色;
    drawSetBtn.borderGrad.colors = @[(id)JVR_主色.CGColor, (id)JVR_副色.CGColor];
    drawSetBtn.onTap = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        DrawSettingsViewController *vc = [[DrawSettingsViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        nav.navigationBar.barStyle = UIBarStyleBlack;
        nav.navigationBar.tintColor = JVR_主色;
        nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: JVR_文字色};
        [strongSelf presentViewController:nav animated:YES completion:nil];
        KernelLogLine("打开绘制设置界面");
    };
    [drawSetBtn.heightAnchor constraintEqualToConstant:44].active = YES;
    [stack addArrangedSubview:drawSetBtn];

    // 物资选项卡入口（对标 wasd 物资功能分类）
    JVRKernelButton *lootBtn = [[JVRKernelButton alloc] init];
    lootBtn.translatesAutoresizingMaskIntoConstraints = NO;
    lootBtn.label.text = @"物资功能";
    lootBtn.label.textColor = JVR_副色;
    lootBtn.borderGrad.colors = @[(id)JVR_副色.CGColor, (id)JVR_主色.CGColor];
    lootBtn.onTap = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        MaterialConfigViewController *vc = [[MaterialConfigViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        nav.navigationBar.barStyle = UIBarStyleBlack;
        nav.navigationBar.tintColor = JVR_主色;
        nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: JVR_文字色};
        [strongSelf presentViewController:nav animated:YES completion:nil];
        KernelLogLine("打开物资功能界面");
    };
    [lootBtn.heightAnchor constraintEqualToConstant:44].active = YES;
    [stack addArrangedSubview:lootBtn];
    
    return stack;
}


// ========================================
// 生命周期与其他方法
// ========================================
- (void)viewDidLoad {
    [super viewDidLoad];
    _impactFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [self registerNotifications];
    gRootVC = self;
    
    __weak typeof(self) weakSelf = self;
    KernelLoggerSetHandler(^(NSString *line) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && strongSelf->_terminal) {
            [strongSelf->_terminal appendLog:line];
        }
    });
    KernelLogLine("JVR 系统已初始化");
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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Developer Area" message:@"Choose an action below." preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Reset Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
