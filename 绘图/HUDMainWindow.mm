//
//  HUDMainWindow.mm
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import "HUDMainWindow.h"

@implementation HUDMainWindow

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_isSecure { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }
- (BOOL)_ignoresHitTest { return YES; } //触摸


@end


@implementation HUDMenuWindow

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_isSecure { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }

//- (BOOL)_ignoresHitTest { return YES; } //触摸调试

@end
