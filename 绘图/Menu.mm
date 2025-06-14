#import "Menu.hpp"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

bool dk = false;

NSString *decode(NSString *string) {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:0];
  NSString *decodedStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  return decodedStr;
}

void Startgame(void) {
  if (!dk) {
    // 使用dispatch_after实现2秒延迟
    // dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    NSString *LSApplicationWorkspaceNAme = decode(@"TFNBcHBsaWNhdGlvbldvcmtzcGFjZQ==");
    const char *cLSApplicationWorkspaceNAme = [LSApplicationWorkspaceNAme UTF8String];
    Class LSApplicationWorkspace = objc_getClass(cLSApplicationWorkspaceNAme);
    NSObject *workspace = [LSApplicationWorkspace performSelector:@selector(defaultWorkspace)];
    NSArray *allApplications = [workspace performSelector:@selector(allApplications)];
    
    for (NSObject *appInfo in allApplications) {
      NSString *bundleID = [appInfo performSelector:@selector(bundleIdentifier)];
      NSString *bundleName = decode(@"Y29tLnRlbmNlbnQudG1ncC5kZm0=");
      if ([bundleID isEqualToString:bundleName]) {
        [workspace performSelector:@selector(openApplicationWithBundleID:) withObject:bundleID];
      }
    }
    dk = true;
    // });
  }
}

@interface GestureSwitch : UIView
@property(nonatomic, assign) BOOL isOn;                            // 开关状态
@property(nonatomic, strong) UIColor *trackOnColor;                // 开启时的轨道颜色
@property(nonatomic, strong) UIColor *trackOffColor;               // 关闭时的轨道颜色
@property(nonatomic, strong) UIColor *thumbColor;                  // 滑块颜色
@property(nonatomic, strong) UIColor *onColor;                     // 开启时的填充颜色
@property(nonatomic, strong) UIColor *offColor;                    // 关闭时的边框颜色
@property(nonatomic, copy) void (^valueChangedHandler)(BOOL isOn); // 值变化回调
@property(nonatomic, assign) BOOL enabled;                         // 是否启用
@end

@implementation GestureSwitch {
  UIView *_circleView; // 圆圈视图
  UIView *_checkmarkView; // 勾选标记视图 - 暂时注释
  CGFloat _circleSize; // 圆圈大小
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _circleSize = 20.0; // 圆圈大小调整为20
    _isOn = NO;
    _enabled = YES; // 默认启用
    _onColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0]; // 绿色主题色
    _offColor = [UIColor colorWithWhite:0.3 alpha:1.0];                 // 深灰色边框
    
    // 圆圈视图
    _circleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _circleSize, _circleSize)];
    _circleView.layer.borderWidth = 1.0;
    _circleView.layer.borderColor = _offColor.CGColor;
    _circleView.layer.cornerRadius = 4;           // 圆形
    _circleView.backgroundColor = [UIColor clearColor]; // 默认背景透明
    
    // 勾选标记视图 - 暂时注释
    _checkmarkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _circleSize, _circleSize)];
    _checkmarkView.backgroundColor = [UIColor clearColor];
    _checkmarkView.hidden = YES; // 初始隐藏
    
    // 创建勾选路径
    CAShapeLayer *checkmarkLayer = [CAShapeLayer layer];
    UIBezierPath *checkmarkPath = [UIBezierPath bezierPath];
    [checkmarkPath moveToPoint:CGPointMake(_circleSize * 0.25, _circleSize * 0.60)];
    [checkmarkPath addLineToPoint:CGPointMake(_circleSize * 0.4, _circleSize * 0.75)];
    [checkmarkPath addLineToPoint:CGPointMake(_circleSize * 0.75, _circleSize * 0.35)];
    
    checkmarkLayer.path = checkmarkPath.CGPath;
    checkmarkLayer.strokeColor = [UIColor whiteColor].CGColor;
    checkmarkLayer.fillColor = [UIColor clearColor].CGColor;
    checkmarkLayer.lineWidth = 2.0;
    checkmarkLayer.lineCap = kCALineCapRound;
    checkmarkLayer.lineJoin = kCALineJoinRound;
    
    [_checkmarkView.layer addSublayer:checkmarkLayer];
    
    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tap];
    
    [self addSubview:_circleView];
    [self addSubview:_checkmarkView]; // 暂时注释
    [self updateCircleAppearance];
  }
  return self;
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
  // 如果禁用状态，不响应点击
  if (!self.enabled) {
    return;
  }
  
  self.isOn = !self.isOn;
  [self updateCircleAppearance];
  if (self.valueChangedHandler) {
    self.valueChangedHandler(self.isOn);
  }
}

- (void)updateCircleAppearance {
  [UIView animateWithDuration:0.2 animations:^{
    if (!self.enabled) {
      // 禁用状态：显示为灰色
      self->_circleView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.3];
      self->_circleView.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.5].CGColor;
      self->_checkmarkView.alpha = 0.0;
      self->_checkmarkView.hidden = YES;
    } else if (self.isOn) {
      // 打开时填充颜色
      self->_circleView.backgroundColor = self.onColor;
      self->_circleView.layer.borderColor = self.onColor.CGColor;
      // 勾选逻辑暂时注释
      self->_checkmarkView.hidden = NO;
      self->_checkmarkView.alpha = 1.0;
    } else {
      // 关闭时清空颜色
      self->_circleView.backgroundColor = [UIColor clearColor];
      self->_circleView.layer.borderColor = self.offColor.CGColor;
      // 勾选逻辑暂时注释
      self->_checkmarkView.alpha = 0.0;
      self->_checkmarkView.hidden = YES;
    }
  }];
}

- (void)setIsOn:(BOOL)isOn {
  _isOn = isOn;
  [self updateCircleAppearance];
}

- (void)setEnabled:(BOOL)enabled {
  _enabled = enabled;
  [self updateCircleAppearance];
}

@end

@interface GestureSlider : UIView
@property(nonatomic) CGFloat value;    // 当前值
@property(nonatomic) CGFloat minValue; // 最小值
@property(nonatomic) CGFloat maxValue; // 最大值
@property(nonatomic, strong) UIColor *trackColor;
@property(nonatomic, strong) UIColor *thumbColor;
@property(nonatomic, copy) void (^valueChangedHandler)(CGFloat newValue);
@property(nonatomic, assign) BOOL enabled; // 是否启用
@end

@implementation GestureSlider {
  UIView *_trackView;
  UIView *_thumbView;
  CGFloat _thumbSize;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _thumbSize = 18.0;
    _minValue = 0.0f;
    _maxValue = 1.0f;
    _value = 0.5f;
    _enabled = YES; // 默认启用
    _trackColor = [UIColor colorWithWhite:0.2 alpha:1.0]; // 深灰色轨道
    _thumbColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0]; // 绿色主题色
    
    // 轨道
    _trackView = [[UIView alloc] initWithFrame:CGRectMake(0, (frame.size.height - 4) / 2, frame.size.width, 3)];
    _trackView.backgroundColor = _trackColor;
    _trackView.layer.cornerRadius = 1.5;
    
    // 滑块
    _thumbView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _thumbSize, _thumbSize)];
    _thumbView.backgroundColor = _thumbColor; // 设置滑块颜色
    _thumbView.layer.cornerRadius = _thumbSize / 2;
    _thumbView.layer.shadowColor = [UIColor blackColor].CGColor;
    _thumbView.layer.shadowOffset = CGSizeMake(0, 1.5);
    _thumbView.layer.shadowOpacity = 0.3;
    
    // 添加拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:pan];
    
    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tap];
    
    [self addSubview:_trackView];
    [self addSubview:_thumbView];
    [self updateThumbPosition];
  }
  return self;
}

- (void)setThumbColor:(UIColor *)thumbColor {
  _thumbColor = thumbColor;
  _thumbView.backgroundColor = thumbColor; // 更新滑块颜色
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
  // 如果禁用状态，不响应拖拽
  if (!self.enabled) {
    return;
  }
  
  CGPoint location = [gesture locationInView:self];
  [self updateValueWithLocation:location];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
  // 如果禁用状态，不响应点击
  if (!self.enabled) {
    return;
  }
  
  CGPoint location = [gesture locationInView:self];
  [self updateValueWithLocation:location];
}

- (void)updateValueWithLocation:(CGPoint)location {
  // 计算滑条的值（基于 minValue 和 maxValue）
  CGFloat newValue = (location.x - _thumbSize / 2) / (self.bounds.size.width - _thumbSize);
  newValue = fmax(0.0, fmin(1.0, newValue));                 // 限制在 0.0 ~ 1.0 之间
  newValue = _minValue + newValue * (_maxValue - _minValue); // 映射到 minValue ~ maxValue 范围
  
  if (newValue != _value) {
    _value = newValue;
    [self updateThumbPosition];
    if (_valueChangedHandler) {
      _valueChangedHandler(_value);
    }
  }
}

- (void)updateThumbPosition {
  // 根据当前值计算滑块的位置
  CGFloat normalizedValue = (_value - _minValue) / (_maxValue - _minValue); // 归一化到 0.0 ~ 1.0
  CGFloat x = (self.bounds.size.width - _thumbSize) * normalizedValue;
  _thumbView.center = CGPointMake(x + _thumbSize / 2, self.bounds.size.height / 2);
}

- (void)setValue:(CGFloat)value {
  _value = value;
  [self updateThumbPosition];
}

- (void)setEnabled:(BOOL)enabled {
  _enabled = enabled;
  [self updateAppearance];
}

- (void)updateAppearance {
  if (!self.enabled) {
    // 禁用状态：显示为灰色
    _trackView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.5];
    _thumbView.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.8];
    _thumbView.layer.shadowOpacity = 0.1;
  } else {
    // 启用状态：恢复正常颜色
    _trackView.backgroundColor = _trackColor;
    _thumbView.backgroundColor = _thumbColor;
    _thumbView.layer.shadowOpacity = 0.3;
  }
}

@end

@interface RootView : UIView
@property(weak, nonatomic) MenuFloatController *menuController;
@end

@implementation RootView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  // 判断是否需要处理触摸
  BOOL shouldHandle = NO;
  if (self.menuController) {
    shouldHandle = CGRectContainsPoint(self.menuController.floatingBall.frame, point) ||
    CGRectContainsPoint(self.menuController.menuView.frame, point);
  }
  return shouldHandle ? [super hitTest:point withEvent:event] : nil;
}
@end

@implementation MenuFloatController

CGRect screenBounds = [UIScreen mainScreen].bounds;
CGFloat kuan = screenBounds.size.width;
CGFloat gao = screenBounds.size.height;

#pragma mark - Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.switchStates = [NSMutableDictionary dictionary];
  
  // 设置菜单初始状态为隐藏
  self.isMenuVisible = NO;
  
  // 替换根视图为自定义视图
  self.view = [[RootView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  ((RootView *)self.view).menuController = self;
  
  self.view.backgroundColor = [UIColor clearColor];
  self.view.userInteractionEnabled = YES;
  
  [self configOrientationObserver];
  [self configFloatingBall];
  
  Startgame();
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  if (!self.isMenuVisible) {
    _menuView = nil;
  }
}

- (void)dealloc {
  // 移除通知监听
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Lazy Views

- (UIView *)menuView {
  if (!_menuView) {
    _menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kuan/2, gao * 0.6)];
    _menuView.center = CGPointMake(kuan/2, gao/2);
    _menuView.alpha = 0;
    
    // ✅ 直接使用 UIVisualEffectView 作为背景，移除黑色背景视图
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = _menuView.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_menuView addSubview:blurView];
    
    // ✅ 添加深色叠加层
    UIView *darkOverlay = [[UIView alloc] initWithFrame:_menuView.bounds];
    darkOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    darkOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [blurView.contentView addSubview:darkOverlay];
    
    // ✅ 使 `menuView` 具有圆角
    _menuView.layer.cornerRadius = 12;
    _menuView.layer.masksToBounds = YES;
    
    // ✅ 添加阴影（提升 UI 质量）
    _menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    _menuView.layer.shadowOffset = CGSizeMake(0, 4);
    _menuView.layer.shadowOpacity = 0.2;
    _menuView.layer.shadowRadius = 5;
    _menuView.layer.shouldRasterize = YES;
    _menuView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    // ✅ 添加拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuPan:)];
    [_menuView addGestureRecognizer:pan];
    
    [self.view addSubview:_menuView];
    [self configSwitchSlider]; // 初始化控件
  }
  return _menuView;
}

#pragma mark - UIGesture Actions

- (void)handleTap:(UITapGestureRecognizer *)gesture {
  [self toggleMenu];
}

- (void)handleMenuPan:(UIPanGestureRecognizer *)gesture {
  static CGPoint initialCenter;
  
  switch (gesture.state) {
    case UIGestureRecognizerStateBegan: {
      initialCenter = self.menuView.center;
      
      // 生成菜单快照
      UIGraphicsBeginImageContextWithOptions(self.menuView.bounds.size, NO, 0);
      [self.menuView.layer renderInContext:UIGraphicsGetCurrentContext()];
      UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
      
      self.menuCacheView = [[UIImageView alloc] initWithImage:snapshot];
      self.menuCacheView.frame = self.menuView.frame;
      [self.view insertSubview:self.menuCacheView belowSubview:self.menuView];
      self.menuView.hidden = YES;
      
      break;
    }
      
    case UIGestureRecognizerStateChanged: {
      CGPoint translation = [gesture translationInView:self.view];
      CGPoint newCenter = CGPointMake(initialCenter.x + translation.x, initialCenter.y + translation.y);
      
      // 边界限制
      newCenter.x = MAX(self.menuView.frame.size.width/2, MIN(kuan - self.menuView.frame.size.width/2, newCenter.x));
      newCenter.y = MAX(self.menuView.frame.size.height/2, MIN(gao - self.menuView.frame.size.height/2, newCenter.y));
      
      self.menuCacheView.center = newCenter;
      break;
    }
      
    case UIGestureRecognizerStateEnded:
    case UIGestureRecognizerStateCancelled: {
      self.menuView.center = self.menuCacheView.center;
      self.menuView.hidden = NO;
      [self.menuCacheView removeFromSuperview];
      self.menuCacheView = nil;
      // 添加惯性滑动（可选）
      CGPoint velocity = [gesture velocityInView:self.view];
      CGFloat deceleration = 0.9; // 衰减系数
      CGRect finalFrame = self.menuView.frame;
      
      CGFloat targetX = finalFrame.origin.x + velocity.x * 0.1;
      targetX = MAX(0, MIN(kuan - finalFrame.size.width, targetX));
      
      CGFloat targetY = finalFrame.origin.y + velocity.y * 0.1;
      targetY = MAX(0, MIN(gao - finalFrame.size.height, targetY));
      
      break;
    }
      
    default:
      break;
  }
}

#pragma mark - Configs

- (void)configOrientationObserver {
  self.orientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];
  __weak typeof(self) weakSelf = self;
  
  [self.orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf handleInterfaceOrientationChange:(UIInterfaceOrientation)orientationUpdate.orientation duration:orientationUpdate.duration];
    });
  }];
}

- (void)configFloatingBall {
  // 悬浮球基础设置
  self.floatingBall = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
  self.floatingBall.backgroundColor = UIColor.redColor; // [UIColor colorWithWhite:0.0 alpha:0.01]; // 透明但可点击
  self.floatingBall.layer.cornerRadius = 20;
  self.floatingBall.userInteractionEnabled = YES;
  
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  [self.floatingBall addGestureRecognizer:tap];
  
  [self updateFloatingBallPosition];
  [self.view addSubview:self.floatingBall];
  [self.view bringSubviewToFront:self.floatingBall]; // 确保在最前
}

- (void)configSwitchSlider {
  // 清除现有子视图，但保留背景视图
  NSMutableArray *subviewsToRemove = [NSMutableArray array];
  for (UIView *subview in self.menuView.subviews) {
    // 保留UIVisualEffectView（模糊背景）和其内容视图
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      [subviewsToRemove addObject:subview];
    }
  }
  
  for (UIView *subview in subviewsToRemove) {
    [subview removeFromSuperview];
  }
  
  // 获取当前菜单尺寸
  CGFloat menuWidth = self.menuView.frame.size.width;
  CGFloat menuHeight = self.menuView.frame.size.height;
  
  // 添加大标题 "DZ"
  UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, menuWidth, 30)];
  titleLabel.text = @"DZ";
  titleLabel.font = [UIFont boldSystemFontOfSize:24];
  titleLabel.textColor = [UIColor whiteColor];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  titleLabel.backgroundColor = [UIColor clearColor];
  [self.menuView addSubview:titleLabel];
  
  [self createSwitchOpen:@"总开关" startY:12 container:self.menuView];
  
  // 设置三级视图布局
  CGFloat buttonWidth = 80;
  CGFloat buttonHeight = 40;
  CGFloat contentWidth = menuWidth - buttonWidth - 20;
  CGFloat currentY = 46;
  
  // 创建左侧按钮容器
  UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(10, currentY, buttonWidth, menuHeight - 24)];
  buttonContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15]; // 深色背景
  buttonContainer.layer.cornerRadius = 8;
  [self.menuView addSubview:buttonContainer];
  
  // 创建内容容器
  UIView *contentContainer = [[UIView alloc] initWithFrame:CGRectMake(buttonWidth + 15, currentY, contentWidth, menuHeight - 24)];
  contentContainer.backgroundColor = [UIColor clearColor];
  [self.menuView addSubview:contentContainer];
  
  // 创建三个级别按钮
  NSArray *levelTitles = @[@"基础功能", @"物资功能", @"高危功能"];
  
  for (int i = 0; i < 3; i++) {
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(5, 10 + i * (buttonHeight + 10), buttonWidth - 10, buttonHeight);
    label.text = levelTitles[i];
    label.textColor = UIColor.lightGrayColor;
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0]; // 深灰色背景
    label.layer.masksToBounds = YES;
    label.layer.cornerRadius = 6;
    label.tag = 1000 + i;
    [label setUserInteractionEnabled:YES];
    [label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(levellabelTapped:)]];
    [buttonContainer addSubview:label];
  }
  
  // 创建三个级别的内容视图
  [self createLevel1Content:contentContainer];
  [self createLevel2Content:contentContainer];
  [self createLevel3Content:contentContainer];
  
  // 默认显示第一级
  [self showLevel:0];
  
  // 根据总开关状态设置其他控件的启用状态
  [self updateControlsEnabledState];
}

#pragma mark - Create

// 创建第一级内容（基础功能）
- (void)createLevel1Content:(UIView *)container {
  UIView *level1View = [[UIView alloc] initWithFrame:container.bounds];
  level1View.tag = 2000;
  level1View.hidden = NO;
  [container addSubview:level1View];
  
  CGFloat currentY = 8;
  
  // 顶部警告
  UILabel *topWarning = [[UILabel alloc] initWithFrame:CGRectMake(10, currentY, container.frame.size.width - 20, 20)];
  topWarning.text = @"对局结束请关闭总开关";
  topWarning.font = [UIFont boldSystemFontOfSize:14];
  topWarning.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0]; // 绿色主题
  topWarning.textAlignment = NSTextAlignmentLeft;
  [level1View addSubview:topWarning];
  // 总开关
  currentY += 35;
  
  // 第一组开关
  NSArray *group1Names = @[@"射线", @"信息", @"骨骼", @"血量", @"雷达", @"BOOS绘制", @"过滤人机", @"阵营模式", @"技能预警"];
  currentY = [self createSwitchGroup:group1Names startY:currentY container:level1View];
  
  // 雷达滑条组
  NSArray *radarSliders = @[@"雷达大小", @"雷达 X", @"雷达 Y"];
  [self createSliderGroup:radarSliders startY:currentY + 5 container:level1View];
}

// 创建第二级内容（物资功能）
- (void)createLevel2Content:(UIView *)container {
  UIView *level2View = [[UIView alloc] initWithFrame:container.bounds];
  level2View.tag = 2001;
  level2View.hidden = YES;
  [container addSubview:level2View];
  
  CGFloat currentY = 8;
  
  // 物资警告
  UILabel *itemWarning = [[UILabel alloc] initWithFrame:CGRectMake(10, currentY, container.frame.size.width - 20, 20)];
  itemWarning.text = @"物资绘制过多可能导致卡顿";
  itemWarning.font = [UIFont systemFontOfSize:14];
  itemWarning.textColor = [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0]; // 蓝色主题
  itemWarning.textAlignment = NSTextAlignmentLeft;
  [level2View addSubview:itemWarning];
  
  currentY += 35;
  
  // 物资开关组
  NSArray *itemSwitches = @[@"物资开关", @"红", @"金", @"紫", @"蓝", @"绿", @"盒子", @"盒子物资"];
  currentY = [self createSwitchGroup:itemSwitches startY:currentY container:level2View];
  
  // 物资距离滑条
  [self createSliderGroup:@[@"物资绘制距离"] startY:currentY + 5 container:level2View];
}

// 创建第三级内容（高危功能）
- (void)createLevel3Content:(UIView *)container {
  UIView *level3View = [[UIView alloc] initWithFrame:container.bounds];
  level3View.tag = 2002;
  level3View.hidden = YES;
  [container addSubview:level3View];
  
  CGFloat currentY = 8;
  
  // 高危警告
  UILabel *dangerWarning = [[UILabel alloc] initWithFrame:CGRectMake(10, currentY, container.frame.size.width - 20, 20)];
  dangerWarning.text = @"高危功能封号自理";
  dangerWarning.font = [UIFont boldSystemFontOfSize:14];
  dangerWarning.textColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0]; // 红色主题
  dangerWarning.textAlignment = NSTextAlignmentLeft;
  [level3View addSubview:dangerWarning];
  currentY += 35;
  
  // 高危功能开关组
  NSArray *dangerSwitches = @[@"无后", @"聚点", @"自瞄", @"倒地不瞄", @"微加速"];
  currentY = [self createSwitchGroup:dangerSwitches startY:currentY container:level3View];
  
  // 范围滑条
  [self createSliderGroup:@[@"自瞄距离"] startY:currentY + 5 container:level3View];
}

// 创建开关视图
- (void)createSwitchOpen:(NSString *)name startY:(CGFloat)startY container:(UIView *)container {
  CGFloat containerWidth = container.frame.size.width;
  // 开关
  GestureSwitch *switcher = [[GestureSwitch alloc] initWithFrame:CGRectMake(containerWidth - 48, startY, 20, 20)];
  
  // 根据开关组设置颜色
  switcher.onColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0]; // 绿色主题
  switcher.offColor = UIColor.whiteColor; // [UIColor colorWithWhite:0.3 alpha:1.0]; // 深灰色边框
  
  // 配置初始状态
  [self configureSwitchState:switcher forName:name];
  
  // 开关回调
  __weak typeof(self) weakSelf = self;
  switcher.valueChangedHandler = ^(BOOL isOn) {
    [weakSelf updateSwitchState:name isOn:isOn];
  };
  [container addSubview:switcher];
}

// 创建开关组
- (CGFloat)createSwitchGroup:(NSArray *)names startY:(CGFloat)startY container:(UIView *)container {
  CGFloat containerWidth = (container.frame.size.width - 30) / 2;
  CGFloat containerHeight = 30;
  CGFloat horizontalSpacing = 10;
  CGFloat verticalSpacing = 8;   // 减少垂直间距
  
  NSInteger columns = 2;
  NSInteger rowCount = ceil(names.count / (CGFloat)columns);
  
  for (int i = 0; i < names.count; i++) {
    NSInteger row = i / columns;
    NSInteger col = i % columns;
    
    UIView *switchContainer = [[UIView alloc] initWithFrame:CGRectMake(10 + col * (containerWidth + horizontalSpacing),
                                                                       startY + row * (containerHeight + verticalSpacing),
                                                                       containerWidth, containerHeight)];
    
    // 标签
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, containerWidth - 60, 20)];
    label.text = names[i];
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = [UIColor whiteColor]; // 白色文字
    label.adjustsFontSizeToFitWidth = YES;
    
    // 开关
    GestureSwitch *switcher = [[GestureSwitch alloc] initWithFrame:CGRectMake(containerWidth - 33, 3, 20, 20)];
    switcher.tag = 101 + i;
    
    // 根据开关组设置颜色
    if ([names[i] isEqualToString:@"射线"] ||
        [names[i] isEqualToString:@"信息"] || [names[i] isEqualToString:@"骨骼"] ||
        [names[i] isEqualToString:@"血量"] || [names[i] isEqualToString:@"BOOS绘制"] ||
        [names[i] isEqualToString:@"雷达"] || [names[i] isEqualToString:@"过滤人机"] ||
        [names[i] isEqualToString:@"阵营模式"]) {
      switcher.onColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0]; // 绿色主题
    } else if ([names[i] isEqualToString:@"物资开关"] || [names[i] isEqualToString:@"红"] ||
               [names[i] isEqualToString:@"金"] || [names[i] isEqualToString:@"紫"] ||
               [names[i] isEqualToString:@"蓝"] || [names[i] isEqualToString:@"绿"] ||
               [names[i] isEqualToString:@"盒子"] || [names[i] isEqualToString:@"盒子物资"]) {
      switcher.onColor = [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0]; // 蓝色主题
    } else {
      switcher.onColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0]; // 红色主题
    }
    
    switcher.offColor = [UIColor colorWithWhite:0.3 alpha:1.0]; // 深灰色边框
    
    // 配置初始状态
    [self configureSwitchState:switcher forName:names[i]];
    
    // 开关回调
    __weak typeof(self) weakSelf = self;
    switcher.valueChangedHandler = ^(BOOL isOn) {
      [weakSelf updateSwitchState:names[i] isOn:isOn];
    };
    
    switchContainer.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor; // 深灰色边框
    switchContainer.layer.borderWidth = 0.5;
    switchContainer.layer.cornerRadius = 6;
    
    [switchContainer addSubview:label];
    [switchContainer addSubview:switcher];
    [container addSubview:switchContainer];
  }
  
  return startY + rowCount * (containerHeight + verticalSpacing);
}

// 创建滑条组
- (void)createSliderGroup:(NSArray *)names startY:(CGFloat)startY container:(UIView *)container {
  CGFloat sliderHeight = 35; // 减少滑条高度
  CGFloat containerWidth = container.frame.size.width;
  
  for (int i = 0; i < names.count; i++) {
    UIView *sliderContainer = [[UIView alloc] initWithFrame:CGRectMake(10, startY + i * (sliderHeight + 8), // 减少间距
                                                                       containerWidth - 20, sliderHeight)];
    
    // 标题标签
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 120, 20)];
    titleLabel.text = names[i];
    titleLabel.font = [UIFont systemFontOfSize:12];
    titleLabel.textColor = [UIColor whiteColor]; // 白色文字
    
    // 数值显示
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(sliderContainer.frame.size.width - 60, 5, 60, 20)];
    valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    valueLabel.textAlignment = NSTextAlignmentRight;
    valueLabel.textColor = [UIColor whiteColor]; // 白色文字
    valueLabel.tag = 2000 + i;
    
    // 滑条控件
    GestureSlider *slider = [[GestureSlider alloc] initWithFrame:CGRectMake(5, 22, sliderContainer.frame.size.width - 10, 24)];
    slider.tag = 3000 + i;
    slider.trackColor = [UIColor colorWithWhite:0.2 alpha:1.0]; // 深灰色轨道
    
    // 根据滑动条组设置颜色
    if ([names[i] isEqualToString:@"雷达大小"] || [names[i] isEqualToString:@"雷达 X"] ||
        [names[i] isEqualToString:@"雷达 Y"]) {
      slider.thumbColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0]; // 绿色主题
    } else if ([names[i] isEqualToString:@"自瞄距离"]) {
      slider.thumbColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0]; // 红色主题
    } else {
      slider.thumbColor = [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0]; // 蓝色主题
    }
    
    // 配置滑条参数
    [self configureSliderParameters:slider forName:names[i]];
    
    // 滑条回调
    __weak typeof(self) weakSelf = self;
    slider.valueChangedHandler = ^(CGFloat value) {
      valueLabel.text = [NSString stringWithFormat:@"%d", (int)round(value)];
      [weakSelf updateSliderValue:names[i] value:value];
    };
    
    // 初始化显示
    valueLabel.text = [NSString stringWithFormat:@"%d", (int)round(slider.value)];
    
    [sliderContainer addSubview:titleLabel];
    [sliderContainer addSubview:slider];
    [sliderContainer addSubview:valueLabel];
    [container addSubview:sliderContainer];
  }
}

// 级别按钮点击事件
- (void)levellabelTapped:(UITapGestureRecognizer *)tap {
  NSInteger level = tap.view.tag - 1000;
  NSLog(@"按钮被点击: level=%ld", (long)level);
  [self showLevel:level];
}

// 显示指定级别
- (void)showLevel:(NSInteger)level {
  NSLog(@"显示级别: %ld", (long)level);
  
  // 更新按钮状态
  for (int i = 0; i < 3; i++) {
    UILabel *label = [self.menuView viewWithTag:1000 + i];
    if (label) {
      if (i == level) {
        label.textColor = UIColor.whiteColor;
        label.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0]; // 绿色主题
        NSLog(@"按钮 %d 设置为选中状态", i);
      } else {
        label.textColor = UIColor.lightGrayColor;
        label.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0]; // 深灰色背景
        NSLog(@"按钮 %d 设置为未选中状态", i);
      }
    } else {
      NSLog(@"未找到按钮 %d (tag: %ld)", i, (long)(1000 + i));
    }
  }
  
  // 直接遍历menuView的所有子视图，查找级别视图
  BOOL foundAnyLevelView = NO;
  for (UIView *subview in self.menuView.subviews) {
    for (UIView *contentView in subview.subviews) {
      if (contentView.tag >= 2000 && contentView.tag <= 2002) {
        NSInteger viewLevel = contentView.tag - 2000;
        contentView.hidden = (viewLevel != level);
        foundAnyLevelView = YES;
        NSLog(@"找到级别视图 %ld (tag: %ld): %@", (long)viewLevel, (long)contentView.tag, contentView.hidden ? @"隐藏" : @"显示");
      }
    }
  }
  
  if (!foundAnyLevelView) {
    NSLog(@"警告：未找到任何级别视图");
  }
  
  // 根据总开关状态更新控件启用状态
  [self updateControlsEnabledState];
}

// 配置开关状态
- (void)configureSwitchState:(GestureSwitch *)switcher forName:(NSString *)name {
  if ([name isEqualToString:@"总开关"]) {
    switcher.isOn = 总开关;
    // 当总开关状态改变时，更新所有其他控件的启用状态
    [self updateControlsEnabledState];
  } else if ([name isEqualToString:@"射线"]) {
    switcher.isOn = is射线;
  } else if ([name isEqualToString:@"信息"]) {
    switcher.isOn = is信息;
  } else if ([name isEqualToString:@"骨骼"]) {
    switcher.isOn = is骨骼;
  } else if ([name isEqualToString:@"血量"]) {
    switcher.isOn = is血量;
  } else if ([name isEqualToString:@"BOOS绘制"]) {
    switcher.isOn = is手持;
  } else if ([name isEqualToString:@"雷达"]) {
    switcher.isOn = is雷达;
  } else if ([name isEqualToString:@"过滤人机"]) {
    switcher.isOn = is人机;
  } else if ([name isEqualToString:@"阵营模式"]) {
    switcher.isOn = is阵营;
  } else if ([name isEqualToString:@"技能预警"]) {
    switcher.isOn = 资源名;
  } else if ([name isEqualToString:@"物资开关"]) {
    switcher.isOn = is物资;
  } else if ([name isEqualToString:@"红"]) {
    switcher.isOn = is红;
  } else if ([name isEqualToString:@"金"]) {
    switcher.isOn = is金;
  } else if ([name isEqualToString:@"紫"]) {
    switcher.isOn = is紫;
  } else if ([name isEqualToString:@"蓝"]) {
    switcher.isOn = is蓝;
  } else if ([name isEqualToString:@"绿"]) {
    switcher.isOn = is绿;
  } else if ([name isEqualToString:@"盒子"]) {
    switcher.isOn = is盒子;
  } else if ([name isEqualToString:@"盒子物资"]) {
    switcher.isOn = is盒子物资;
  } else if ([name isEqualToString:@"无后"]) {
    switcher.isOn = is无后;
  } else if ([name isEqualToString:@"聚点"]) {
    switcher.isOn = is聚点;
  } else if ([name isEqualToString:@"自瞄"]) {
    switcher.isOn = is躯体;
  } else if ([name isEqualToString:@"倒地不瞄"]) {
    switcher.isOn = is手臂;
  } else if ([name isEqualToString:@"微加速"]) {
    switcher.isOn = is加速;
  }
}

// 更新开关状态
- (void)updateSwitchState:(NSString *)name isOn:(BOOL)isOn {
  if ([name isEqualToString:@"总开关"]) {
    总开关 = isOn;
    // 当总开关状态改变时，更新所有其他控件的启用状态
    [self updateControlsEnabledState];
  } else if ([name isEqualToString:@"射线"]) {
    is射线 = isOn;
  } else if ([name isEqualToString:@"信息"]) {
    is信息 = isOn;
  } else if ([name isEqualToString:@"骨骼"]) {
    is骨骼 = isOn;
  } else if ([name isEqualToString:@"血量"]) {
    is血量 = isOn;
  } else if ([name isEqualToString:@"BOOS绘制"]) {
    is手持 = isOn;
  } else if ([name isEqualToString:@"雷达"]) {
    is雷达 = isOn;
  } else if ([name isEqualToString:@"过滤人机"]) {
    is人机 = isOn;
  } else if ([name isEqualToString:@"阵营模式"]) {
    is阵营 = isOn;
  } else if ([name isEqualToString:@"技能预警"]) {
    资源名 = isOn;
  } else if ([name isEqualToString:@"物资开关"]) {
    is物资 = isOn;
  } else if ([name isEqualToString:@"红"]) {
    is红 = isOn;
  } else if ([name isEqualToString:@"金"]) {
    is金 = isOn;
  } else if ([name isEqualToString:@"紫"]) {
    is紫 = isOn;
  } else if ([name isEqualToString:@"蓝"]) {
    is蓝 = isOn;
  } else if ([name isEqualToString:@"绿"]) {
    is绿 = isOn;
  } else if ([name isEqualToString:@"盒子"]) {
    is盒子 = isOn;
  } else if ([name isEqualToString:@"盒子物资"]) {
    is盒子物资 = isOn;
  } else if ([name isEqualToString:@"无后"]) {
    is无后 = isOn;
  } else if ([name isEqualToString:@"聚点"]) {
    is聚点 = isOn;
  } else if ([name isEqualToString:@"自瞄"]) {
    is躯体 = isOn;
  } else if ([name isEqualToString:@"倒地不瞄"]) {
    is手臂 = isOn;
  } else if ([name isEqualToString:@"微加速"]) {
    is加速 = isOn;
  }
}

// 配置滑条参数
- (void)configureSliderParameters:(GestureSlider *)slider forName:(NSString *)name {
  // 获取当前屏幕尺寸
  CGRect screenBounds = [UIScreen mainScreen].bounds;
  CGFloat screenWidth = screenBounds.size.width;
  CGFloat screenHeight = screenBounds.size.height;
  
  if ([name isEqualToString:@"雷达大小"]) {
    slider.minValue = 0;
    slider.maxValue = 500;
    slider.value = 雷达大小;
  } else if ([name isEqualToString:@"雷达 X"]) {
    slider.minValue = 0;
    slider.maxValue = kuan*2;
    slider.value = 雷达x;
  } else if ([name isEqualToString:@"雷达 Y"]) {
    slider.minValue = 0;
    slider.maxValue = gao*2;
    slider.value = 雷达y;
  } else if ([name isEqualToString:@"物资绘制距离"]) {
    slider.minValue = 0;
    slider.maxValue = 100.0f;
    slider.value = 物资距离;
  } else if ([name isEqualToString:@"自瞄距离"]) {
    slider.minValue = 0;
    slider.maxValue = 200.0f;
    slider.value = 范围大小;
  }
}

// 更新滑条值
- (void)updateSliderValue:(NSString *)name value:(CGFloat)value {
  if ([name isEqualToString:@"雷达大小"]) {
    雷达大小 = value;
  } else if ([name isEqualToString:@"雷达 X"]) {
    雷达x = value;
  } else if ([name isEqualToString:@"雷达 Y"]) {
    雷达y = value;
  } else if ([name isEqualToString:@"物资绘制距离"]) {
    物资距离 = value;
  } else if ([name isEqualToString:@"自瞄距离"]) {
    范围大小 = value;
  }
}

- (void)updateFloatingBallPosition {
  self.floatingBall.center = CGPointMake(kuan / 2, 20);
}

- (void)toggleMenu {
  self.isMenuVisible = !self.isMenuVisible;
  
  if (self.isMenuVisible) {
    // 触发懒加载
    UIView *menu = self.menuView;
    
    menu.center = CGPointMake(kuan/2, gao/2);
    menu.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    [UIView animateWithDuration:0.25
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
      menu.alpha = 1;
      menu.transform = CGAffineTransformIdentity;
      menu.center = CGPointMake(kuan/2, gao/2);
    } completion:nil];
  } else {
    [UIView animateWithDuration:0.2 animations:^{
      self.menuView.alpha = 0;
      self.menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
      self.menuView.center = CGPointMake(kuan/2, gao/2);
    }];
  }
}

#pragma mark - Interface

- (void)handleInterfaceOrientationChange:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
  BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
  CGRect screenBounds = [UIScreen mainScreen].bounds;
  
  kuan = isLandscape ? MAX(screenBounds.size.width, screenBounds.size.height) : MIN(screenBounds.size.width, screenBounds.size.height);
  gao  = isLandscape ? MIN(screenBounds.size.width, screenBounds.size.height) : MAX(screenBounds.size.width, screenBounds.size.height);
  
  [UIView animateWithDuration:duration animations:^{
    switch (orientation) {
      case UIInterfaceOrientationLandscapeLeft:
        self.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self.view.bounds = CGRectMake(0, 0, kuan, gao);
        break;
      case UIInterfaceOrientationLandscapeRight:
        self.view.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.view.bounds = CGRectMake(0, 0, kuan, gao);
        break;
      case UIInterfaceOrientationPortraitUpsideDown:
        self.view.transform = CGAffineTransformMakeRotation(M_PI);
        self.view.bounds = screenBounds;
        break;
      default:
        self.view.transform = CGAffineTransformIdentity;
        self.view.bounds = screenBounds;
        break;
    }
    [self updateFloatingBallPosition];
    if (self.isMenuVisible) {
      self.menuView.center = CGPointMake(kuan/2, gao/2); // 使用全局变量
    }
    [self.view setNeedsDisplay];
  }];
}

#pragma mark - TogOn

// 更新所有控件的启用状态
- (void)updateControlsEnabledState {
  BOOL masterSwitchOn = 总开关;
  
  // 遍历所有级别视图
  for (UIView *subview in self.menuView.subviews) {
    for (UIView *contentView in subview.subviews) {
      if (contentView.tag >= 2000 && contentView.tag <= 2002) {
        // 遍历级别视图中的所有控件
        [self updateControlsInView:contentView enabled:masterSwitchOn];
      }
    }
  }
}

// 递归更新视图中的控件状态
- (void)updateControlsInView:(UIView *)view enabled:(BOOL)enabled {
  for (UIView *subview in view.subviews) {
    // 检查是否是开关控件
    if ([subview isKindOfClass:[GestureSwitch class]]) {
      GestureSwitch *switcher = (GestureSwitch *)subview;
      switcher.enabled = enabled;
    }
    // 检查是否是滑条控件
    else if ([subview isKindOfClass:[GestureSlider class]]) {
      GestureSlider *slider = (GestureSlider *)subview;
      slider.enabled = enabled;
    }
    // 递归检查子视图
    [self updateControlsInView:subview enabled:enabled];
  }
}

@end
