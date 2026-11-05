//
//  AimFloatRootViewController.mm
//  自瞄悬浮球：长按切换自瞄；拖动调整位置；大小由菜单滑条「悬浮球大小」控制
//

#import "AimFloatRootViewController.h"
#import "Aim/AimFloatBridge.h"
#import "NHIdentity.h"
#import <objc/runtime.h>
#import "FBSOrientationObserver.h"
#import "FBSOrientationUpdate.h"

static NSString * const kAimFloatSideKey = @"aanh.aimfloat.side"; // 1=左 2=右
static NSString * const kAimFloatRelYKey = @"aanh.aimfloat.relY";
static NSString * const kAimFloatSizeKey = @"悬浮球大小";

@interface AimPassThroughView : UIView
@end

@implementation AimPassThroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) {
        return nil;
    }
    return hit;
}
@end

@interface AimFloatRootViewController ()
@property (nonatomic, strong) AimPassThroughView *overlayView;
@property (nonatomic, strong) UIButton *aimButton;
@property (nonatomic, strong) NSTimer *syncTimer;
@property (nonatomic, assign) UIInterfaceOrientation currentOrientation;
@property (nonatomic, assign) CGRect originalFrame;
@property (nonatomic, assign) CGFloat buttonSize;
@property (nonatomic, strong) FBSOrientationObserver *orientationObserver;
@end

@implementation AimFloatRootViewController

- (void)loadView {
    AimPassThroughView *root = [[AimPassThroughView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    root.backgroundColor = [UIColor clearColor];
    root.userInteractionEnabled = NO;
    self.view = root;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.currentOrientation = UIInterfaceOrientationLandscapeRight;
    self.buttonSize = [self loadButtonSize];

    CGRect frame = [UIScreen mainScreen].bounds;
    self.originalFrame = frame;

    self.overlayView = [[AimPassThroughView alloc] initWithFrame:frame];
    self.overlayView.backgroundColor = [UIColor clearColor];
    self.overlayView.userInteractionEnabled = YES;

    [self setupAimButton];
    [self setupOrientationObserver];
    [self applyOrientation:self.currentOrientation duration:0];

    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:0.8
                                                      target:self
                                                    selector:@selector(onSyncTick)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self attachOverlayToWindow:self.view.window];
}

- (void)attachOverlayToWindow:(UIWindow *)window {
    if (!window || !self.overlayView) {
        return;
    }
    if (self.overlayView.superview != window) {
        [window addSubview:self.overlayView];
    }
    [window bringSubviewToFront:self.overlayView];
    [self applyOrientation:self.currentOrientation duration:0];
    [self onSyncTick];
}

- (void)dealloc {
    [self.syncTimer invalidate];
    [self.orientationObserver invalidate];
}

- (CGFloat)loadButtonSize {
    NSDictionary *settings = NHPrefsRead();
    CGFloat size = 48.0f;
    if (settings[kAimFloatSizeKey]) {
        size = [settings[kAimFloatSizeKey] floatValue];
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kAimFloatSizeKey]) {
        size = [[NSUserDefaults standardUserDefaults] floatForKey:kAimFloatSizeKey];
    }
    if (size < 28.0f) size = 28.0f;
    if (size > 96.0f) size = 96.0f;
    return size;
}

- (void)applyButtonSize:(CGFloat)size {
    if (!self.aimButton) return;
    if (size < 28.0f) size = 28.0f;
    if (size > 96.0f) size = 96.0f;
    if (fabs(size - self.buttonSize) < 0.5f &&
        fabs(self.aimButton.bounds.size.width - size) < 0.5f) {
        return;
    }
    self.buttonSize = size;
    CGPoint center = self.aimButton.center;
    self.aimButton.bounds = CGRectMake(0, 0, size, size);
    self.aimButton.layer.cornerRadius = size / 2.0;
    CGFloat fontSize = MAX(10.0, MIN(16.0, size * 0.28));
    self.aimButton.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    self.aimButton.center = center;
    [self restoreButtonPosition];
}

- (void)setupAimButton {
    CGFloat size = self.buttonSize > 0 ? self.buttonSize : 48.0;
    self.aimButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.aimButton.frame = CGRectMake(20, 100, size, size);
    self.aimButton.layer.cornerRadius = size / 2.0;
    self.aimButton.clipsToBounds = YES;
    self.aimButton.titleLabel.font = [UIFont boldSystemFontOfSize:MAX(10.0, MIN(16.0, size * 0.28))];
    self.aimButton.titleLabel.numberOfLines = 2;
    self.aimButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.aimButton.alpha = 0.88;
    self.aimButton.userInteractionEnabled = YES;
    self.aimButton.exclusiveTouch = YES;

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.cancelsTouchesInView = NO;
    [self.aimButton addGestureRecognizer:pan];

    // 长按切换自瞄（单击不可靠；长按已验证能进回调）
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressToggleAim:)];
    longPress.minimumPressDuration = 0.1;
    longPress.allowableMovement = 12.0;
    [self.aimButton addGestureRecognizer:longPress];

    NSInteger side = [[NSUserDefaults standardUserDefaults] integerForKey:kAimFloatSideKey];
    self.aimButton.tag = (side == 2) ? 2 : 1;

    CGFloat savedRelY = [[NSUserDefaults standardUserDefaults] floatForKey:kAimFloatRelYKey];
    if (savedRelY > 0.01f && savedRelY < 0.99f) {
        self.aimButton.layer.anchorPointZ = savedRelY;
    } else {
        self.aimButton.layer.anchorPointZ = 0.28f;
    }

    [self.overlayView addSubview:self.aimButton];
    [self refreshAimButtonAppearance];
}

- (void)setupOrientationObserver {
    Class cls = objc_getClass("FBSOrientationObserver");
    if (!cls) {
        return;
    }
    self.orientationObserver = [[cls alloc] init];
    __weak AimFloatRootViewController *weakSelf = self;
    [self.orientationObserver setHandler:^(FBSOrientationUpdate *update) {
        UIInterfaceOrientation ori = (UIInterfaceOrientation)update.orientation;
        if (UIInterfaceOrientationIsPortrait(ori)) {
            ori = UIInterfaceOrientationLandscapeRight;
        }
        NSTimeInterval duration = update.duration;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf applyOrientation:ori duration:duration];
        });
    }];
}

- (CGRect)effectiveBoundsForOrientation:(UIInterfaceOrientation)orientation {
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    CGSize screen = [UIScreen mainScreen].bounds.size;
    CGFloat w = isLandscape ? MAX(screen.width, screen.height) : MIN(screen.width, screen.height);
    CGFloat h = isLandscape ? MIN(screen.width, screen.height) : MAX(screen.width, screen.height);
    return CGRectMake(0, 0, w, h);
}

- (void)applyOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    self.currentOrientation = orientation;

    CGSize screen = [UIScreen mainScreen].bounds.size;
    CGRect bounds = [self effectiveBoundsForOrientation:orientation];
    self.originalFrame = bounds;

    void (^apply)(void) = ^{
        switch (orientation) {
            case UIInterfaceOrientationLandscapeLeft:
                self.overlayView.transform = CGAffineTransformMakeRotation(-M_PI_2);
                break;
            case UIInterfaceOrientationLandscapeRight:
                self.overlayView.transform = CGAffineTransformMakeRotation(M_PI_2);
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                self.overlayView.transform = CGAffineTransformMakeRotation(M_PI);
                break;
            default:
                self.overlayView.transform = CGAffineTransformIdentity;
                break;
        }
        self.overlayView.bounds = bounds;
        self.overlayView.center = CGPointMake(screen.width / 2.0, screen.height / 2.0);
        [self restoreButtonPosition];
    };

    if (duration > 0) {
        [UIView animateWithDuration:duration animations:apply];
    } else {
        apply();
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *button = gesture.view;
    CGPoint translation = [gesture translationInView:button.superview];
    CGRect bounds = [self effectiveBoundsForOrientation:self.currentOrientation];
    CGFloat halfW = button.bounds.size.width / 2.0;
    CGFloat halfH = button.bounds.size.height / 2.0;

    CGPoint center = CGPointMake(button.center.x + translation.x, button.center.y + translation.y);
    center.x = MAX(halfW, MIN(bounds.size.width - halfW, center.x));
    center.y = MAX(halfH + 44, MIN(bounds.size.height - halfH - 34, center.y));
    button.center = center;
    [gesture setTranslation:CGPointZero inView:button.superview];

    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        BOOL toLeft = center.x < bounds.size.width / 2.0;
        center.x = toLeft ? (halfW + 10) : (bounds.size.width - halfW - 10);
        button.tag = toLeft ? 1 : 2;
        [UIView animateWithDuration:0.2 animations:^{
            button.center = center;
        } completion:^(__unused BOOL finished) {
            [self saveButtonPosition];
        }];
    }
}

- (void)handleLongPressToggleAim:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }

    [UIView animateWithDuration:0.1 animations:^{
        self.aimButton.transform = CGAffineTransformMakeScale(0.88, 0.88);
    } completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.aimButton.transform = CGAffineTransformIdentity;
        }];
    }];

    BOOL on = [AimFloatBridge toggleAimEnabled];
    [self applyAppearanceForEnabled:on];
}

- (void)onSyncTick {
    [self applyButtonSize:[self loadButtonSize]];
    [self refreshAimButtonAppearance];
}

- (void)saveButtonPosition {
    CGRect bounds = [self effectiveBoundsForOrientation:self.currentOrientation];
    if (bounds.size.height < 1) {
        return;
    }
    CGFloat relY = self.aimButton.center.y / bounds.size.height;
    self.aimButton.layer.anchorPointZ = relY;
    [[NSUserDefaults standardUserDefaults] setInteger:self.aimButton.tag forKey:kAimFloatSideKey];
    [[NSUserDefaults standardUserDefaults] setFloat:relY forKey:kAimFloatRelYKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)restoreButtonPosition {
    if (!self.aimButton) {
        return;
    }
    CGRect bounds = [self effectiveBoundsForOrientation:self.currentOrientation];
    CGFloat halfW = self.aimButton.bounds.size.width / 2.0;
    CGFloat halfH = self.aimButton.bounds.size.height / 2.0;

    CGPoint center;
    center.x = (self.aimButton.tag == 2) ? (bounds.size.width - halfW - 10) : (halfW + 10);

    CGFloat relY = self.aimButton.layer.anchorPointZ;
    if (relY <= 0.01f || relY >= 0.99f) {
        relY = [[NSUserDefaults standardUserDefaults] floatForKey:kAimFloatRelYKey];
        if (relY <= 0.01f || relY >= 0.99f) {
            relY = 0.28f;
        }
    }
    center.y = MAX(halfH + 44, MIN(bounds.size.height - halfH - 34, relY * bounds.size.height));
    self.aimButton.center = center;
}

- (void)refreshAimButtonAppearance {
    [self applyAppearanceForEnabled:[AimFloatBridge isAimEnabled]];
}

- (void)applyAppearanceForEnabled:(BOOL)enabled {
    if (!self.aimButton) {
        return;
    }
    UIColor *bg = enabled
        ? [UIColor colorWithRed:0.12 green:0.72 blue:0.38 alpha:0.92]
        : [UIColor colorWithRed:0.22 green:0.22 blue:0.24 alpha:0.88];
    self.aimButton.backgroundColor = bg;

    [self.aimButton setTitle:(enabled ? @"自瞄\n开" : @"自瞄\n关") forState:UIControlStateNormal];
    [self.aimButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.aimButton.layer.borderWidth = 1.0;
    self.aimButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.35].CGColor;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
