//
//  BBZView.h
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BBZView : UIViewController
@property (nonatomic, strong) UIView *backgroundView;
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag;
- (void)reloadMainButtonState;
@end

NS_ASSUME_NONNULL_END
