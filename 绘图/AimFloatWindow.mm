//
//  AimFloatWindow.mm
//  对齐特斯拉 / qwer：参与 hitTest，不忽略触摸
//

#import "AimFloatWindow.h"

static AimFloatWindow *sActiveAimFloatWindow = nil;

@implementation AimFloatWindow

+ (AimFloatWindow *)activeWindow {
    return sActiveAimFloatWindow;
}

+ (void)setActiveWindow:(AimFloatWindow *)window {
    sActiveAimFloatWindow = window;
}

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_isSecure { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }
- (BOOL)_ignoresHitTest { return NO; }

@end
