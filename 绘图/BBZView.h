//
//  BBZView.h
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 对齐 wasd：不依赖 Books-Swift.h / TSSettingsControllerDelegate，避免链入
// SwiftUI、swiftCompatibility56 等在 iOS 15 上导致启动闪退的依赖。
@interface BBZView : UIViewController
@property (nonatomic, strong) UIView *backgroundView;
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag;
- (void)reloadMainButtonState;
@end

NS_ASSUME_NONNULL_END
