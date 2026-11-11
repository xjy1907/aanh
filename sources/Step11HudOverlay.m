//
//  Step11HudOverlay.m
//  验收⑲：SBS 托管叠层 + 过直播 + 横屏旋转 + 保活重注册（对齐 753e2e1/BBZ）
//

#import "Step11HudOverlay.h"
#import "Step19EspHost.h"
#import "过直播窗口.h"

#import "FBSOrientationObserver.h"
#import "FBSOrientationUpdate.h"

#import <math.h>
#import <objc/message.h>
#import <objc/runtime.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif
#ifndef M_PI_2
#define M_PI_2 1.57079632679489661923
#endif

@interface UIWindow (Step11Private)
- (unsigned int)_contextId;
@end

__attribute__((used)) static const char kStep11HudMarker[] = "STEP11-HUDHOST";
__attribute__((used)) static const char kStep14LiveCoverMarker[] = "STEP14-LIVECOVER";
__attribute__((used)) static const char kStep15MetalMarker[] = "STEP15-METAL";
__attribute__((used)) static const char kStep16TfHostMarker[] = "STEP16-TFHOST";
__attribute__((used)) static const char kStep17ImGuiMarker[] = "STEP17-IMGUI";
__attribute__((used)) static const char kStep18ReadMarker[] = "STEP18-READPROBE";
__attribute__((used)) static const char kStep19EspMarker[] = "STEP19-THINESP";
__attribute__((used)) static const char kStep19SbsMarker[] = "STEP19-SBS-HUD";

@interface Step11HudOverlay ()
@property(nonatomic, strong) UIWindow *overlayWindow;
@property(nonatomic, strong) UILabel *bannerLabel;
@property(nonatomic, strong) UIView *bannerView;
@property(nonatomic, strong) 过直播窗口 *liveCover;
@property(nonatomic, strong) Step19EspHost *drawSurface;
@property(nonatomic, strong) id sbsHostingController;
@property(nonatomic, assign) BOOL sbsRegistered;
@property(nonatomic, assign, readwrite, getter=isVisible) BOOL visible;
@property(nonatomic, strong) FBSOrientationObserver *orientationObserver;
@property(nonatomic, assign) UIInterfaceOrientation currentOrientation;
@property(nonatomic, strong) NSTimer *keepAliveTimer;
@property(nonatomic, assign) NSInteger keepAliveTick;
@property(nonatomic, assign) CGFloat canvasW;
@property(nonatomic, assign) CGFloat canvasH;
@end

@implementation Step11HudOverlay

+ (instancetype)shared {
  static Step11HudOverlay *inst;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    inst = [[Step11HudOverlay alloc] init];
    volatile const char *keep11 = kStep11HudMarker;
    volatile const char *keep14 = kStep14LiveCoverMarker;
    volatile const char *keep15 = kStep15MetalMarker;
    volatile const char *keep16 = kStep16TfHostMarker;
    volatile const char *keep17 = kStep17ImGuiMarker;
    volatile const char *keep18 = kStep18ReadMarker;
    volatile const char *keep19 = kStep19EspMarker;
    volatile const char *keepSbs = kStep19SbsMarker;
    (void)keep11[0];
    (void)keep14[0];
    (void)keep15[0];
    (void)keep16[0];
    (void)keep17[0];
    (void)keep18[0];
    (void)keep19[0];
    (void)keepSbs[0];
  });
  return inst;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.currentOrientation = UIInterfaceOrientationUnknown;
    self.canvasW = 0;
    self.canvasH = 0;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(onAppBecameActive:)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(onAppBecameActive:)
               name:UIApplicationWillEnterForegroundNotification
             object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.keepAliveTimer invalidate];
  [self.orientationObserver invalidate];
}

- (void)onAppBecameActive:(NSNotification *)note {
  (void)note;
  if (!self.visible || !self.overlayWindow) {
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    self.overlayWindow.hidden = NO;
    self.sbsRegistered = NO;
    [self registerSbsIfNeeded];
    [self.drawSurface startAnimating];
    [self applyOrientationNow:self.currentOrientation duration:0];
  });
}

- (void)registerSbsIfNeeded {
  if (!self.overlayWindow) {
    return;
  }
  Class cls = objc_getClass("SBSAccessibilityWindowHostingController");
  if (!cls) {
    return;
  }
  if (!self.sbsHostingController) {
    self.sbsHostingController = [[cls alloc] init];
  }
  if (!self.sbsHostingController) {
    return;
  }
  unsigned int ctx = [self.overlayWindow _contextId];
  double level = [self.overlayWindow windowLevel];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  ((void (*)(id, SEL, unsigned int, double))objc_msgSend)(
      self.sbsHostingController, NSSelectorFromString(@"registerWindowWithContextID:atLevel:"), ctx, level);
#pragma clang diagnostic pop
  self.sbsRegistered = YES;
}

- (void)forceSbsReregister {
  self.sbsRegistered = NO;
  [self registerSbsIfNeeded];
}

- (void)startKeepAlive {
  if (self.keepAliveTimer) {
    return;
  }
  self.keepAliveTick = 0;
  __weak typeof(self) weakSelf = self;
  self.keepAliveTimer = [NSTimer timerWithTimeInterval:1.5
                                               repeats:YES
                                                 block:^(NSTimer *timer) {
                                                   (void)timer;
                                                   __strong typeof(weakSelf) self = weakSelf;
                                                   if (!self || !self.visible || !self.overlayWindow) {
                                                     return;
                                                   }
                                                   self.keepAliveTick += 1;
                                                   self.overlayWindow.hidden = NO;
                                                   [self.drawSurface startAnimating];
                                                   // 对齐正式 HUD：SBS 托管偶发掉线，周期性重挂
                                                   if ((self.keepAliveTick % 2) == 0) {
                                                     [self forceSbsReregister];
                                                   }
                                                 }];
  [[NSRunLoop mainRunLoop] addTimer:self.keepAliveTimer forMode:NSRunLoopCommonModes];
}

- (void)stopKeepAlive {
  [self.keepAliveTimer invalidate];
  self.keepAliveTimer = nil;
  self.keepAliveTick = 0;
}

- (void)setupOrientationObserver {
  if (self.orientationObserver) {
    return;
  }
  Class cls = objc_getClass("FBSOrientationObserver");
  if (!cls) {
    return;
  }
  self.orientationObserver = [[cls alloc] init];
  __weak typeof(self) weakSelf = self;
  [self.orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf applyOrientationNow:(UIInterfaceOrientation)orientationUpdate.orientation
                           duration:orientationUpdate.duration];
    });
  }];
}

- (void)applyOrientationNow:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
  if (!self.overlayWindow || !self.drawSurface) {
    return;
  }
  if (orientation == UIInterfaceOrientationUnknown) {
    orientation = UIInterfaceOrientationLandscapeRight;
  }
  self.currentOrientation = orientation;

  BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGFloat longSide = MAX(screenSize.width, screenSize.height);
  CGFloat shortSide = MIN(screenSize.width, screenSize.height);
  self.canvasW = isLandscape ? longSide : shortSide;
  self.canvasH = isLandscape ? shortSide : longSide;

  UIView *rootView = self.overlayWindow.rootViewController.view;
  CGRect screenBounds = rootView.bounds;
  if (screenBounds.size.width < 1 || screenBounds.size.height < 1) {
    screenBounds = [UIScreen mainScreen].bounds;
  }

  void (^apply)(void) = ^{
    if (self.liveCover) {
      self.liveCover.frame = screenBounds;
      self.liveCover.coverView.transform = CGAffineTransformIdentity;
      self.liveCover.coverView1.transform = CGAffineTransformIdentity;
      self.liveCover.coverView.frame = self.liveCover.bounds;
      self.liveCover.coverView1.frame = self.liveCover.coverView.bounds;
    }

    // Cover 不转；只转绘制面（对齐 BBZ MetalView）
    switch (orientation) {
      case UIInterfaceOrientationLandscapeLeft:
        self.drawSurface.transform = CGAffineTransformMakeRotation((CGFloat)-M_PI_2);
        self.drawSurface.bounds = CGRectMake(0, 0, self.canvasW, self.canvasH);
        break;
      case UIInterfaceOrientationLandscapeRight:
        self.drawSurface.transform = CGAffineTransformMakeRotation((CGFloat)M_PI_2);
        self.drawSurface.bounds = CGRectMake(0, 0, self.canvasW, self.canvasH);
        break;
      case UIInterfaceOrientationPortraitUpsideDown:
        self.drawSurface.transform = CGAffineTransformMakeRotation((CGFloat)M_PI);
        self.drawSurface.bounds = CGRectMake(0, 0, self.canvasW, self.canvasH);
        break;
      default:
        self.drawSurface.transform = CGAffineTransformIdentity;
        self.drawSurface.bounds = CGRectMake(0, 0, self.canvasW, self.canvasH);
        break;
    }
    self.drawSurface.center = CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds));
    [self.drawSurface applyCanvasWidth:self.canvasW height:self.canvasH];
    [self.drawSurface setNeedsLayout];
    [self.drawSurface layoutIfNeeded];

    if (self.bannerView) {
      self.bannerView.transform = CGAffineTransformIdentity;
    }
  };

  if (duration > 0.01) {
    [UIView animateWithDuration:duration animations:apply];
  } else {
    apply();
  }
}

- (void)ensureWindow {
  if (self.overlayWindow) {
    return;
  }

  CGRect bounds = [UIScreen mainScreen].bounds;
  UIWindow *win = [[UIWindow alloc] initWithFrame:bounds];
  // 对齐 753e2e1/BBZ：StatusBar-1 + SBS 托管
  win.windowLevel = UIWindowLevelStatusBar - 1;
  win.backgroundColor = [UIColor clearColor];
  win.opaque = NO;
  win.userInteractionEnabled = NO;
  win.hidden = YES;

  UIViewController *root = [[UIViewController alloc] init];
  root.view.backgroundColor = [UIColor clearColor];
  root.view.opaque = NO;
  root.view.userInteractionEnabled = NO;

  过直播窗口 *cover = [[过直播窗口 alloc] initWithFrame:bounds];
  cover.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [root.view addSubview:cover];
  self.liveCover = cover;

  Step19EspHost *surface = [[Step19EspHost alloc] initWithFrame:bounds];
  surface.autoresizingMask = UIViewAutoresizingNone;
  [cover attachDrawView:surface];
  [cover setLiveHidden:YES];
  self.drawSurface = surface;

  UIView *banner = [[UIView alloc] init];
  banner.translatesAutoresizingMaskIntoConstraints = NO;
  banner.backgroundColor = [[UIColor colorWithRed:18.0f / 255.0f
                                            green:10.0f / 255.0f
                                             blue:28.0f / 255.0f
                                            alpha:1.0f] colorWithAlphaComponent:0.82f];
  banner.layer.cornerRadius = 10.0;
  banner.layer.borderWidth = 1.0;
  banner.layer.borderColor =
      [UIColor colorWithRed:100.0f / 255.0f green:220.0f / 255.0f blue:180.0f / 255.0f alpha:0.7f].CGColor;
  self.bannerView = banner;

  UILabel *label = [[UILabel alloc] init];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.textColor = [UIColor colorWithRed:160.0f / 255.0f
                                    green:255.0f / 255.0f
                                     blue:180.0f / 255.0f
                                    alpha:1.0f];
  label.font = [UIFont monospacedSystemFontOfSize:12.0f weight:UIFontWeightSemibold];
  label.numberOfLines = 2;
  label.textAlignment = NSTextAlignmentCenter;
  label.text = @"STEP19-THINESP";
  self.bannerLabel = label;

  [banner addSubview:label];
  [root.view addSubview:banner];
  [NSLayoutConstraint activateConstraints:@[
    [banner.centerXAnchor constraintEqualToAnchor:root.view.centerXAnchor],
    [banner.topAnchor constraintEqualToAnchor:root.view.safeAreaLayoutGuide.topAnchor constant:10],
    [banner.leadingAnchor constraintGreaterThanOrEqualToAnchor:root.view.leadingAnchor constant:24],
    [banner.trailingAnchor constraintLessThanOrEqualToAnchor:root.view.trailingAnchor constant:-24],
    [banner.heightAnchor constraintGreaterThanOrEqualToConstant:44],
    [label.leadingAnchor constraintEqualToAnchor:banner.leadingAnchor constant:14],
    [label.trailingAnchor constraintEqualToAnchor:banner.trailingAnchor constant:-14],
    [label.topAnchor constraintEqualToAnchor:banner.topAnchor constant:8],
    [label.bottomAnchor constraintEqualToAnchor:banner.bottomAnchor constant:-8],
  ]];

  win.rootViewController = root;
  self.overlayWindow = win;
  [self setupOrientationObserver];
}

- (UIInterfaceOrientation)probeActiveOrientation {
  if (self.orientationObserver &&
      [self.orientationObserver respondsToSelector:@selector(activeInterfaceOrientation)]) {
    long long o = [self.orientationObserver activeInterfaceOrientation];
    if (o > 0) {
      return (UIInterfaceOrientation)o;
    }
  }
  UIInterfaceOrientation fromApp = UIInterfaceOrientationUnknown;
  if (@available(iOS 13.0, *)) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
      if (![scene isKindOfClass:[UIWindowScene class]]) {
        continue;
      }
      fromApp = ((UIWindowScene *)scene).interfaceOrientation;
      if (fromApp != UIInterfaceOrientationUnknown) {
        break;
      }
    }
  }
  if (fromApp != UIInterfaceOrientationUnknown) {
    return fromApp;
  }
  // iPad 游戏默认横屏右
  return UIInterfaceOrientationLandscapeRight;
}

- (void)setVisible:(BOOL)visible detail:(NSString *)detail {
  dispatch_block_t work = ^{
    [self ensureWindow];
    if (detail.length > 0) {
      self.bannerLabel.text =
          [NSString stringWithFormat:@"STEP19-THINESP\n%@", detail];
    } else {
      self.bannerLabel.text = @"STEP19-THINESP\nSBS 托管叠层（对齐正式 HUD）";
    }
    self.visible = visible;
    self.overlayWindow.hidden = !visible;
    if (visible) {
      [self.liveCover setLiveHidden:YES];
      [self.drawSurface startAnimating];
      [self.overlayWindow setHidden:NO];
      UIInterfaceOrientation o = [self probeActiveOrientation];
      [self applyOrientationNow:o duration:0];
      [self forceSbsReregister];
      [self startKeepAlive];
    } else {
      [self stopKeepAlive];
      [self.drawSurface stopAnimating];
    }
  };
  if ([NSThread isMainThread]) {
    work();
  } else {
    dispatch_async(dispatch_get_main_queue(), work);
  }
}

- (void)updateDetail:(NSString *)detail {
  dispatch_block_t work = ^{
    if (!self.overlayWindow) {
      return;
    }
    self.bannerLabel.text =
        [NSString stringWithFormat:@"STEP19-THINESP\n%@", detail ?: @""];
  };
  if ([NSThread isMainThread]) {
    work();
  } else {
    dispatch_async(dispatch_get_main_queue(), work);
  }
}

@end
