//
//  AimFloatWindow.h
//  自瞄快捷开关：独立交互窗（绘制窗保持穿透）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AimFloatWindow : UIWindow

/// HUD HID 触摸投递用：当前交互窗
+ (nullable AimFloatWindow *)activeWindow;
+ (void)setActiveWindow:(nullable AimFloatWindow *)window;

@end

NS_ASSUME_NONNULL_END
