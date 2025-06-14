#import "Menu.hpp"
#import <UIKit/UIKit.h>

@interface GestureSwitch : UIView
@property(nonatomic, assign) BOOL isOn;                            // 开关状态
@property(nonatomic, strong) UIColor *trackOnColor;                // 开启时的轨道颜色
@property(nonatomic, strong) UIColor *trackOffColor;               // 关闭时的轨道颜色
@property(nonatomic, strong) UIColor *thumbColor;                  // 滑块颜色
@property(nonatomic, strong) UIColor *onColor;                     // 开启时的填充颜色
@property(nonatomic, strong) UIColor *offColor;                    // 关闭时的边框颜色
@property(nonatomic, copy) void (^valueChangedHandler)(BOOL isOn); // 值变化回调
@end

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

@implementation GestureSwitch {
  UIView *_boxView; // 方框视图
  CGFloat _boxSize; // 方框大小
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _boxSize = 24.0; // 方框大小
    _isOn = NO;
    _onColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0]; // 开启时的填充颜色
    _offColor = [UIColor colorWithWhite:0.8 alpha:1.0];                 // 关闭时的边框颜色
    
    // 方框视图
    _boxView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _boxSize, _boxSize)];
    _boxView.layer.borderWidth = 2.0;
    _boxView.layer.borderColor = _offColor.CGColor;
    _boxView.layer.cornerRadius = 4.0;               // 圆角
    _boxView.backgroundColor = [UIColor clearColor]; // 默认背景透明
    
    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tap];
    
    [self addSubview:_boxView];
    [self updateBoxAppearance];
  }
  return self;
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
  self.isOn = !self.isOn;
  [self updateBoxAppearance];
  if (self.valueChangedHandler) {
    self.valueChangedHandler(self.isOn);
  }
}

- (void)updateBoxAppearance {
  [UIView animateWithDuration:0.2
                   animations:^{
    if (self.isOn) {
      // 打开时填充颜色
      self->_boxView.backgroundColor = self.onColor;
      self->_boxView.layer.borderColor = self.onColor.CGColor;
    } else {
      // 关闭时清空颜色
      self->_boxView.backgroundColor = [UIColor clearColor];
      self->_boxView.layer.borderColor = self.offColor.CGColor;
    }
  }];
}

- (void)setIsOn:(BOOL)isOn {
  _isOn = isOn;
  [self updateBoxAppearance];
}

@end

@interface GestureSlider : UIView
@property(nonatomic) CGFloat value;    // 当前值
@property(nonatomic) CGFloat minValue; // 最小值
@property(nonatomic) CGFloat maxValue; // 最大值
@property(nonatomic, strong) UIColor *trackColor;
@property(nonatomic, strong) UIColor *thumbColor;
@property(nonatomic, copy) void (^valueChangedHandler)(CGFloat newValue);
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
    _trackColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    _thumbColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0]; // 默认颜色
    
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
    _thumbView.layer.shadowOpacity = 0.2;
    
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
  CGPoint location = [gesture locationInView:self];
  [self updateValueWithLocation:location];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
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
@end

@interface RootView : UIView
@property(weak, nonatomic) cd *menuController;
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

@implementation cd

CGRect screenBounds = [UIScreen mainScreen].bounds;
CGFloat kuan = screenBounds.size.width;
CGFloat gao = screenBounds.size.height;

// 私有方法封装样式设置
- (void)_setupMenuAppearance {
  CAGradientLayer *gradientLayer = [CAGradientLayer layer];
  gradientLayer.frame = self.menuView.bounds;
  gradientLayer.colors = @[ (id)[UIColor whiteColor].CGColor, (id)[UIColor whiteColor].CGColor ];
  [self.menuView.layer insertSublayer:gradientLayer atIndex:0];
  
  self.menuView.layer.cornerRadius = 12;
  self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
  self.menuView.layer.shadowOffset = CGSizeMake(0, 4);
  self.menuView.layer.shadowOpacity = 0.2;
  
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuPan:)];
  [self.menuView addGestureRecognizer:pan];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.switchStates = [NSMutableDictionary dictionary];
  
  // 替换根视图为自定义视图
  self.view = [[RootView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  ((RootView *)self.view).menuController = self;
  
  self.view.backgroundColor = [UIColor clearColor];
  self.view.userInteractionEnabled = YES;
  [self setupOrientationObserver];
  [self createFloatingBall];
  
  Startgame();
  
  //    [self createMenuView]; // 创建菜单视图
  
  UITapGestureRecognizer *globalTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(handleGlobalTap:)];
  globalTap.cancelsTouchesInView = NO; // 关键设置
  [self.view addGestureRecognizer:globalTap];
}

- (void)handleGlobalTap:(UITapGestureRecognizer *)gesture {
  CGPoint location = [gesture locationInView:self.view];
  
  // 判断点击区域是否在悬浮球或菜单
  BOOL inFloatingBall = CGRectContainsPoint(self.floatingBall.frame, location);
  BOOL inMenu = CGRectContainsPoint(self.menuView.frame, location);
  
  self.shouldHandleTouch = (inFloatingBall || inMenu);
}

- (void)createFloatingBall {
  // 悬浮球基础设置
  self.floatingBall = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
  self.floatingBall.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.01]; // 透明但可点击
  self.floatingBall.layer.cornerRadius = 20;
  self.floatingBall.userInteractionEnabled = YES;
  
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  [self.floatingBall addGestureRecognizer:tap];
  
  [self updateFloatingBallPosition];
  [self.view addSubview:self.floatingBall];
  [self.view bringSubviewToFront:self.floatingBall]; // 确保在最前
}

- (void)updateFloatingBallPosition {
  self.floatingBall.center = CGPointMake(kuan / 2, 20);
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
  // 点击事件处理（示例：改变文字颜色）
  //    UILabel *menuLabel = (UILabel *)self.floatingBall.subviews.firstObject;
  //    if ([menuLabel isKindOfClass:[UILabel class]]) {
  //        [UIView animateWithDuration:0.2 animations:^{
  //            menuLabel.textColor = [UIColor colorWithRed:1.0 green:0.4 blue:0.2 alpha:1.0]; // 点击时文字变为橙色
  //        } completion:^(BOOL finished) {
  //            [UIView animateWithDuration:0.2 animations:^{
  //                menuLabel.textColor = [UIColor whiteColor]; // 恢复文字颜色
  //            }];
  //        }];
  //    }
  
  // 切换菜单
  [self toggleMenu];
}

- (void)StartMenuView {
  self.menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 500)];
  self.menuView.center = CGPointMake(kuan / 2, gao / 2);
  [self.view addSubview:self.menuView]; // 确保父视图是 self.view
  
  // 添加拖动手势
  UIPanGestureRecognizer *menuPan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(handleMenuPan:)];
  [self.menuView addGestureRecognizer:menuPan];
  
  CAGradientLayer *gradientLayer = [CAGradientLayer layer];
  gradientLayer.frame = self.menuView.bounds;
  
  // 设置颜色为白色
  gradientLayer.colors = @[
    (id)[UIColor whiteColor].CGColor, // 白色
    (id)[UIColor whiteColor].CGColor  // 白色
  ];
  
  gradientLayer.startPoint = CGPointMake(0.0, 0.0);
  gradientLayer.endPoint = CGPointMake(1.0, 1.0);
  
  [self.menuView.layer insertSublayer:gradientLayer atIndex:0];
  self.menuView.layer.cornerRadius = 12;
  self.menuView.layer.masksToBounds = YES; // 确保子图层（如渐变色图层）也应用圆角
  
  self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
  self.menuView.layer.shadowOffset = CGSizeMake(0, 4);
  self.menuView.layer.shadowOpacity = 0.2;
  self.menuView.userInteractionEnabled = YES;
  
  // 创建开关和滑条
  [self StartSwitchesAndSliders];
}

- (UIView *)menuView {
  if (!_menuView) {
    _menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kuan / 2, gao * 0.65)];
    _menuView.center = CGPointMake(kuan / 2, gao / 2);
    _menuView.alpha = 1; // 确保可见
    
    // ✅ 直接使用 UIVisualEffectView 作为背景，移除黑色背景视图
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]; // 浅色模糊
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = _menuView.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_menuView addSubview:blurView];
    
    // ✅ 让模糊背景看起来更白一些
    UIView *whiteOverlay = [[UIView alloc] initWithFrame:_menuView.bounds];
    whiteOverlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3]; // 轻微的白色半透明叠加
    whiteOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [blurView.contentView addSubview:whiteOverlay];
    
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
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleMenuPan:)];
    [_menuView addGestureRecognizer:pan];
    
    [self.view addSubview:_menuView];
    [self StartSwitchesAndSliders]; // 初始化控件
  }
  return _menuView;
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
      newCenter.x =
      MAX(self.menuView.frame.size.width / 2, MIN(kuan - self.menuView.frame.size.width / 2, newCenter.x));
      newCenter.y =
      MAX(self.menuView.frame.size.height / 2, MIN(gao - self.menuView.frame.size.height / 2, newCenter.y));
      
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

- (void)StartSwitchesAndSliders {
  CGFloat currentY = 12;          // 当前Y坐标
  CGFloat horizontalSpacing = 10; // 水平间距
  CGFloat verticalSpacing = 12;   // 垂直间距
  NSInteger columns = 5;          // 每行列数（保持原有排列方式）
  
  // 根据设备类型调整控件大小
  CGFloat containerWidth, containerHeight;
  
  // 手机设备
  containerWidth = (self.menuView.frame.size.width - (columns + 1) * horizontalSpacing) / columns - 3;
  containerHeight = 30; // 固定高度
  
  // ================= 顶部警告 =================
  UILabel *topWarning =
  [[UILabel alloc] initWithFrame:CGRectMake(20, currentY, self.menuView.frame.size.width - 40, 20)];
  topWarning.text = @"对局结束请关闭总开关";
  topWarning.font = [UIFont boldSystemFontOfSize:14];
  topWarning.textColor = [UIColor greenColor];
  topWarning.textAlignment = NSTextAlignmentCenter;
  [self.menuView addSubview:topWarning];
  currentY += 30; // 高度+间距
  
  // ================= 第一组开关 =================
  NSArray *group1Names =
  @[ @"总开关", @"射线", @"信息", @"骨骼", @"血量", @"雷达", @"BOOS绘制", @"过滤人机", @"阵营模式", @"技能预警" ];
  currentY = [self StartSwitchGroupWithNames:group1Names
                                      startY:currentY
                                     columns:columns
                              containerWidth:containerWidth
                             containerHeight:containerHeight];
  
  // ================= 雷达滑条组 =================
  NSArray *radarSliders = @[ @"雷达大小", @"雷达 X", @"雷达 Y" ];
  currentY = [self StartSliderGroupWithNames:radarSliders startY:currentY - 10];
  
  // ================= 物资警告 =================
  UILabel *itemWarning =
  [[UILabel alloc] initWithFrame:CGRectMake(20, currentY, self.menuView.frame.size.width - 40, 20)];
  itemWarning.text = @"物资绘制过多可能导致卡顿";
  itemWarning.font = [UIFont systemFontOfSize:14];
  itemWarning.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
  itemWarning.textAlignment = NSTextAlignmentCenter;
  [self.menuView addSubview:itemWarning];
  currentY += 30;
  
  // ================= 物资开关组 ==============jin===
  NSArray *itemSwitches = @[ @"物资开关", @"红", @"金", @"紫", @"蓝", @"绿", @"盒子", @"盒子物资" ];
  currentY = [self StartSwitchGroupWithNames:itemSwitches
                                      startY:currentY
                                     columns:columns
                              containerWidth:containerWidth
                             containerHeight:containerHeight];
  
  // ================= 物资距离滑条 =================
  currentY = [self StartSliderGroupWithNames:@[ @"物资绘制距离" ] startY:currentY - 10];
  
  // ================= 高危警告 =================
  UILabel *dangerWarning =
  [[UILabel alloc] initWithFrame:CGRectMake(20, currentY, self.menuView.frame.size.width - 40, 20)];
  dangerWarning.text = @"高危功能封号自理";
  dangerWarning.font = [UIFont boldSystemFontOfSize:14];
  dangerWarning.textColor = [UIColor redColor];
  dangerWarning.textAlignment = NSTextAlignmentCenter;
  [self.menuView addSubview:dangerWarning];
  currentY += 30;
  
  // ================= 高危功能开关组 =================
  NSArray *dangerSwitches = @[ @"无后", @"聚点", @"自瞄", @"倒地不瞄", @"微加速" ];
  currentY = [self StartSwitchGroupWithNames:dangerSwitches
                                      startY:currentY
                                     columns:5
                              containerWidth:containerWidth
                             containerHeight:containerHeight];
  
  // ================= 范围滑条 =================
  [self StartSliderGroupWithNames:@[ @"自瞄距离" ] startY:currentY - 10];
}

#pragma mark - 创建开关组
- (CGFloat)StartSwitchGroupWithNames:(NSArray *)names
                              startY:(CGFloat)startY
                             columns:(NSInteger)columns
                      containerWidth:(CGFloat)containerWidth
                     containerHeight:(CGFloat)containerHeight {
  CGFloat horizontalSpacing = 10; // 水平间距
  CGFloat verticalSpacing = 12;   // 垂直间距
  CGFloat sidePadding = 20;       // 统一左右边距
  
  NSInteger rowCount = ceil(names.count / (CGFloat)columns);
  
  for (int i = 0; i < names.count; i++) {
    NSInteger row = i / columns;
    NSInteger col = i % columns;
    
    UIView *switchContainer =
    [[UIView alloc] initWithFrame:CGRectMake(sidePadding + col * (containerWidth + horizontalSpacing),
                                             startY + row * (containerHeight + verticalSpacing), containerWidth,
                                             containerHeight)];
    
    // 标签
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, containerWidth - 50, 20)];
    label.text = names[i];
    label.font = [UIFont systemFontOfSize:10];
    label.adjustsFontSizeToFitWidth = YES;
    
    // 开关
    GestureSwitch *switcher = [[GestureSwitch alloc] initWithFrame:CGRectMake(containerWidth - 33, 3, 24, 24)];
    switcher.tag = 100 + i;
    
    // 根据开关组设置颜色
    if ([names[i] isEqualToString:@"总开关"] || [names[i] isEqualToString:@"射线"] ||
        [names[i] isEqualToString:@"信息"] || [names[i] isEqualToString:@"骨骼"] ||
        [names[i] isEqualToString:@"血量"] || [names[i] isEqualToString:@"BOOS绘制"] ||
        [names[i] isEqualToString:@"雷达"] || [names[i] isEqualToString:@"过滤人机"] ||
        [names[i] isEqualToString:@"阵营模式"]) {
      // 第一组开关：绿色
      switcher.onColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0]; // 绿色
    } else if ([names[i] isEqualToString:@"物资开关"] || [names[i] isEqualToString:@"红"] ||
               [names[i] isEqualToString:@"金"] || [names[i] isEqualToString:@"紫"] ||
               [names[i] isEqualToString:@"蓝"] || [names[i] isEqualToString:@"绿"] ||
               [names[i] isEqualToString:@"盒子"] || [names[i] isEqualToString:@"盒子物资"]) {
      // 物资开关组：蓝色
      switcher.onColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0]; // 蓝色
    } else {
      // 默认颜色
      switcher.onColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0]; // 红色
    }
    
    switcher.offColor = [UIColor colorWithWhite:0.85 alpha:1.0]; // 关闭时的边框颜色
    
    // 配置初始状态
    if ([names[i] isEqualToString:@"总开关"]) {
      switcher.isOn = 总开关;
    } else if ([names[i] isEqualToString:@"射线"]) {
      switcher.isOn = is射线;
    } else if ([names[i] isEqualToString:@"信息"]) {
      switcher.isOn = is信息;
    } else if ([names[i] isEqualToString:@"骨骼"]) {
      switcher.isOn = is骨骼;
    } else if ([names[i] isEqualToString:@"血量"]) {
      switcher.isOn = is血量;
    } else if ([names[i] isEqualToString:@"BOOS绘制"]) {
      switcher.isOn = is手持;
    } else if ([names[i] isEqualToString:@"雷达"]) {
      switcher.isOn = is雷达;
    } else if ([names[i] isEqualToString:@"过滤人机"]) {
      switcher.isOn = is人机;
    } else if ([names[i] isEqualToString:@"阵营模式"]) {
      switcher.isOn = is阵营;
    } else if ([names[i] isEqualToString:@"技能预警"]) {
      switcher.isOn = 资源名;
    } else if ([names[i] isEqualToString:@"物资开关"]) {
      switcher.isOn = is物资;
    } else if ([names[i] isEqualToString:@"红"]) {
      switcher.isOn = is红;
    } else if ([names[i] isEqualToString:@"金"]) {
      switcher.isOn = is金;
    } else if ([names[i] isEqualToString:@"紫"]) {
      switcher.isOn = is紫;
    } else if ([names[i] isEqualToString:@"蓝"]) {
      switcher.isOn = is蓝;
    } else if ([names[i] isEqualToString:@"绿"]) {
      switcher.isOn = is绿;
    } else if ([names[i] isEqualToString:@"盒子"]) {
      switcher.isOn = is盒子;
    } else if ([names[i] isEqualToString:@"盒子物资"]) {
      switcher.isOn = is盒子物资;
    } else if ([names[i] isEqualToString:@"无后"]) {
      switcher.isOn = is无后;
    } else if ([names[i] isEqualToString:@"聚点"]) {
      switcher.isOn = is聚点;
    } else if ([names[i] isEqualToString:@"自瞄"]) {
      switcher.isOn = is躯体;
    } else if ([names[i] isEqualToString:@"倒地不瞄"]) {
      switcher.isOn = is手臂;
    } else if ([names[i] isEqualToString:@"微加速"]) {
      switcher.isOn = is加速;
    }
    
    // 开关回调
    __weak typeof(self) weakSelf = self;
    switcher.valueChangedHandler = ^(BOOL isOn) {
      if ([names[i] isEqualToString:@"总开关"]) {
        总开关 = isOn;
      } else if ([names[i] isEqualToString:@"射线"]) {
        is射线 = isOn;
      } else if ([names[i] isEqualToString:@"信息"]) {
        is信息 = isOn;
      } else if ([names[i] isEqualToString:@"骨骼"]) {
        is骨骼 = isOn;
      } else if ([names[i] isEqualToString:@"血量"]) {
        is血量 = isOn;
      } else if ([names[i] isEqualToString:@"BOOS绘制"]) {
        is手持 = isOn;
      } else if ([names[i] isEqualToString:@"雷达"]) {
        is雷达 = isOn;
      } else if ([names[i] isEqualToString:@"过滤人机"]) {
        is人机 = isOn;
      } else if ([names[i] isEqualToString:@"阵营阵营"]) {
        is阵营 = isOn;
      } else if ([names[i] isEqualToString:@"技能预警"]) {
        资源名 = isOn;
      } else if ([names[i] isEqualToString:@"物资开关"]) {
        is物资 = isOn;
      } else if ([names[i] isEqualToString:@"红"]) {
        is红 = isOn;
      } else if ([names[i] isEqualToString:@"金"]) {
        is金 = isOn;
      } else if ([names[i] isEqualToString:@"紫"]) {
        is紫 = isOn;
      } else if ([names[i] isEqualToString:@"蓝"]) {
        is蓝 = isOn;
      } else if ([names[i] isEqualToString:@"绿"]) {
        is绿 = isOn;
      } else if ([names[i] isEqualToString:@"盒子"]) {
        is盒子 = isOn;
      } else if ([names[i] isEqualToString:@"盒子物资"]) {
        is盒子物资 = isOn;
      } else if ([names[i] isEqualToString:@"无后"]) {
        is无后 = isOn;
      } else if ([names[i] isEqualToString:@"聚点"]) {
        is聚点 = isOn;
      } else if ([names[i] isEqualToString:@"自瞄"]) {
        is躯体 = isOn;
      } else if ([names[i] isEqualToString:@"倒地不瞄"]) {
        is手臂 = isOn;
      } else if ([names[i] isEqualToString:@"微加速"]) {
        is加速 = isOn;
      }
      // ...其他开关状态更新...
      //                    [weakSelf updateSwitchStates];
    };
    
    switchContainer.layer.borderColor = [UIColor lightGrayColor].CGColor;
    switchContainer.layer.borderWidth = 0.5;
    switchContainer.layer.cornerRadius = 6;
    
    [switchContainer addSubview:label];
    [switchContainer addSubview:switcher];
    [self.menuView addSubview:switchContainer];
  }
  
  return startY + rowCount * (containerHeight + verticalSpacing);
}

#pragma mark - 创建滑条组
- (CGFloat)StartSliderGroupWithNames:(NSArray *)names startY:(CGFloat)startY {
  CGFloat sliderHeight = 40;
  
  for (int i = 0; i < names.count; i++) {
    UIView *sliderContainer =
    [[UIView alloc] initWithFrame:CGRectMake(20, startY + i * (sliderHeight + 10),
                                             self.menuView.frame.size.width - 40, sliderHeight)];
    
    // 标题标签
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 120, 20)];
    titleLabel.text = names[i];
    titleLabel.font = [UIFont systemFontOfSize:12];
    
    // 数值显示
    UILabel *valueLabel =
    [[UILabel alloc] initWithFrame:CGRectMake(sliderContainer.frame.size.width - 60, 5, 60, 20)];
    valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    valueLabel.textAlignment = NSTextAlignmentRight;
    valueLabel.tag = 2000 + i;
    
    // 滑条控件
    GestureSlider *slider =
    [[GestureSlider alloc] initWithFrame:CGRectMake(5, 25, sliderContainer.frame.size.width, 24)];
    slider.tag = 3000 + i;
    slider.trackColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    
    // 根据滑动条组设置颜色
    if ([names[i] isEqualToString:@"雷达大小"] || [names[i] isEqualToString:@"雷达 X"] ||
        [names[i] isEqualToString:@"雷达 Y"]) {
      // 第一组滑动条：绿色
      slider.thumbColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0]; // 绿色
    } else if ([names[i] isEqualToString:@"自瞄距离"]) {
      // 高危功能滑动条：红色
      slider.thumbColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0]; // 红色
    } else {
      // 默认颜色
      slider.thumbColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0]; // 蓝色
    }
    
    // 配置滑条参数
    if ([names[i] isEqualToString:@"雷达大小"]) {
      slider.minValue = 0;
      slider.maxValue = 500;
      slider.value = 雷达大小;
    } else if ([names[i] isEqualToString:@"雷达 X"]) {
      slider.minValue = 0;
      slider.maxValue = kuan * 2;
      slider.value = 雷达x;
    } else if ([names[i] isEqualToString:@"雷达 Y"]) {
      slider.minValue = 0;
      slider.maxValue = gao * 2;
      slider.value = 雷达y;
    } else if ([names[i] isEqualToString:@"物资绘制距离"]) {
      slider.minValue = 0;
      slider.maxValue = 100.0f;
      slider.value = 物资距离;
    } else if ([names[i] isEqualToString:@"自瞄距离"]) {
      slider.minValue = 0;
      slider.maxValue = 200.0f;
      slider.value = 范围大小;
    }
    
    // 滑条回调
    __weak typeof(self) weakSelf = self;
    slider.valueChangedHandler = ^(CGFloat value) {
      valueLabel.text = [NSString stringWithFormat:@"%d", (int)round(value)];
      
      if ([names[i] isEqualToString:@"雷达大小"]) {
        雷达大小 = value;
      } else if ([names[i] isEqualToString:@"雷达 X"]) {
        雷达x = value;
      } else if ([names[i] isEqualToString:@"雷达 Y"]) {
        雷达y = value;
      } else if ([names[i] isEqualToString:@"物资绘制距离"]) {
        物资距离 = value;
      } else if ([names[i] isEqualToString:@"自瞄距离"]) {
        范围大小 = value;
      }
    };
    
    // 初始化显示
    valueLabel.text = [NSString stringWithFormat:@"%d", (int)round(slider.value)];
    
    [sliderContainer addSubview:titleLabel];
    [sliderContainer addSubview:slider];
    [sliderContainer addSubview:valueLabel];
    [self.menuView addSubview:sliderContainer];
  }
  
  return startY + names.count * (sliderHeight + 10);
}

- (void)toggleMenu {
  self.isMenuVisible = !self.isMenuVisible;
  
  if (self.isMenuVisible) {
    // 触发懒加载
    UIView *menu = self.menuView;
    menu.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    [UIView animateWithDuration:0.4
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
      menu.alpha = 1;
      menu.transform = CGAffineTransformIdentity;
      menu.center = CGPointMake(kuan / 2, gao / 2);
    }
                     completion:nil];
  } else {
    [UIView animateWithDuration:0.2
                     animations:^{
      self.menuView.alpha = 0;
      self.menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    }
                     completion:^(BOOL finished) {
      self.menuView.center = CGPointMake(kuan / 2, gao / 2);
    }];
  }
}

- (void)setupOrientationObserver {
  self.orientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];
  __weak typeof(self) weakSelf = self;
  
  [self.orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf handleInterfaceOrientationChange:(UIInterfaceOrientation)orientationUpdate.orientation
                                        duration:orientationUpdate.duration];
    });
  }];
}

- (void)handleInterfaceOrientationChange:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
  BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
  CGRect screenBounds = [UIScreen mainScreen].bounds;
  
  kuan = isLandscape ? MAX(screenBounds.size.width, screenBounds.size.height)
  : MIN(screenBounds.size.width, screenBounds.size.height);
  gao = isLandscape ? MIN(screenBounds.size.width, screenBounds.size.height)
  : MAX(screenBounds.size.width, screenBounds.size.height);
  
  [UIView animateWithDuration:duration
                   animations:^{
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
      self.menuView.center = CGPointMake(kuan / 2, gao / 2); // 使用全局变量
    }
    
    [self.view setNeedsDisplay];
  }];
}
// 内存优化
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  if (!self.isMenuVisible) {
    _menuView = nil;
  }
}

@end
