//
//  AimFloatRootViewController.h
//  可拖动自瞄快捷开关悬浮球（对标 qwer）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AimFloatRootViewController : UIViewController

/// 从当前自瞄状态 / 大小刷新按钮
- (void)refreshAimButtonAppearance;
/// 将悬浮层挂到指定 window（对齐特斯拉 overlay 挂窗）
- (void)attachOverlayToWindow:(UIWindow *)window;

@end

NS_ASSUME_NONNULL_END
