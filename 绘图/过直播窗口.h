//
//  过直播窗口.h — 完全参照 wasd DrawRootViewController + ImGuiDraw
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// wasd 结构：
/// CoverView(UITextField) → CoverView1(UITextField) → canvas → DrawHost(UITextField, 对标 ImGuiDraw) → MTKView
@interface 过直播窗口 : UIView

@property (nonatomic, strong, readonly) UITextField *coverView;
@property (nonatomic, strong, readonly) UITextField *coverView1;
@property (nonatomic, strong, readonly) UITextField *drawHost; // 对标 wasd ImGuiDraw : UITextField

- (void)attachDrawView:(UIView *)drawView;
- (void)setLiveHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
