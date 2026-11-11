//
//  Step11HudOverlay.m
//  验收⑲：SBS 托管叠层 + 过直播 + 薄 ESP/W2S（对齐 753e2e1/BBZ 的系统窗托管，而非仅 App 内 UIWindow）
//

#import "Step11HudOverlay.h"
#import "Step19EspHost.h"
#import "过直播窗口.h"

#import <objc/message.h>
#import <objc/runtime.h>

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
@property(nonatomic, strong) 过直播窗口 *liveCover;
@property(nonatomic, strong) Step19EspHost *drawSurface;
@property(nonatomic, strong) id sbsHostingController;
@property(nonatomic, assign) BOOL sbsRegistered;
@property(nonatomic, assign, readwrite, getter=isVisible) BOOL visible;
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

- (void)registerSbsIfNeeded {
  if (self.sbsRegistered || !self.overlayWindow) {
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

- (void)ensureWindow {
  if (self.overlayWindow) {
    return;
  }

  CGRect bounds = [UIScreen mainScreen].bounds;
  UIWindow *win = [[UIWindow alloc] initWithFrame:bounds];
  // 对齐 BBZViewController / 753e2e1：状态栏附近层级 + SBS 托管，而不是 App 内 StatusBar+120 自嗨窗
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
  surface.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
      // 不抢 Books 主窗 key；靠 SBS 把绘制窗挂到系统层，切到游戏仍可见
      [self registerSbsIfNeeded];
    } else {
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
