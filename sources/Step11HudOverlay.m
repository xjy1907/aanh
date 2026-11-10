//
//  Step11HudOverlay.m
//  验收⑬：叠层宿主 + 轻量绘制面
//

#import "Step11HudOverlay.h"
#import "Step13DrawSurface.h"

__attribute__((used)) static const char kStep11HudMarker[] = "STEP11-HUDHOST";

@interface Step11HudOverlay ()
@property(nonatomic, strong) UIWindow *overlayWindow;
@property(nonatomic, strong) UILabel *bannerLabel;
@property(nonatomic, strong) Step13DrawSurface *drawSurface;
@property(nonatomic, assign, readwrite, getter=isVisible) BOOL visible;
@end

@implementation Step11HudOverlay

+ (instancetype)shared {
  static Step11HudOverlay *inst;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    inst = [[Step11HudOverlay alloc] init];
    volatile const char *keep = kStep11HudMarker;
    (void)keep[0];
  });
  return inst;
}

- (void)ensureWindow {
  if (self.overlayWindow) {
    return;
  }

  CGRect bounds = [UIScreen mainScreen].bounds;
  UIWindow *win = [[UIWindow alloc] initWithFrame:bounds];
  win.windowLevel = UIWindowLevelStatusBar + 120.0;
  win.backgroundColor = [UIColor clearColor];
  win.userInteractionEnabled = NO;
  win.hidden = YES;

  UIViewController *root = [[UIViewController alloc] init];
  root.view.backgroundColor = [UIColor clearColor];

  Step13DrawSurface *surface = [[Step13DrawSurface alloc] initWithFrame:bounds];
  surface.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [root.view addSubview:surface];
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
  label.text = @"STEP13-DRAWSURF";
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
          [NSString stringWithFormat:@"STEP13-DRAWSURF\n%@", detail];
    } else {
      self.bannerLabel.text = @"STEP13-DRAWSURF\n轻量绘制面（无 DrawView.mm/PhysX）";
    }
    self.visible = visible;
    self.overlayWindow.hidden = !visible;
    if (visible) {
      [self.drawSurface startAnimating];
      [self.overlayWindow makeKeyAndVisible];
      UIWindow *appKey = UIApplication.sharedApplication.windows.firstObject;
      for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w != self.overlayWindow && !w.hidden) {
          appKey = w;
          break;
        }
      }
      [appKey makeKeyWindow];
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
        [NSString stringWithFormat:@"STEP13-DRAWSURF\n%@", detail ?: @""];
  };
  if ([NSThread isMainThread]) {
    work();
  } else {
    dispatch_async(dispatch_get_main_queue(), work);
  }
}

@end
