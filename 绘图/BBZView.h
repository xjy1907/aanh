//
//  RootViewController.h
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>
#import "Books-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface BBZView : UIViewController <TSSettingsControllerDelegate>
@property (nonatomic, strong) UIView *backgroundView;
+ (void)setShouldToggleHUDAfterLaunch:(BOOL)flag;
@property (nonatomic, strong) UISwitch *cleanEnvironmentSwitch;
- (void)reloadMainButtonState;

// 新增的IDFV相关属性
@property (nonatomic, strong) UILabel *idfvLabel;
@property (nonatomic, strong) UILabel *idfvStatusLabel;
@property (nonatomic, strong) UIButton *fetchIdfvButton;
@property (nonatomic, strong) UIButton *resetIdfvButton;


@end

NS_ASSUME_NONNULL_END
