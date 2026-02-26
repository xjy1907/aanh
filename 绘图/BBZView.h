//
//  BBZView.h
//

#import <UIKit/UIKit.h>
#import "Books-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface BBZView : UIViewController <TSSettingsControllerDelegate>
@property (nonatomic, strong) UIView *backgroundView;
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag;
- (void)reloadMainButtonState;
@end

NS_ASSUME_NONNULL_END
