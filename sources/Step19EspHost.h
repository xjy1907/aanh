//
//  Step19EspHost.h
//  验收⑲：薄 ESP / W2S（对齐 753e2e1 DrawView 功能面；不链 PhysX / DrawView.mm）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Step19EspHost : UITextField

- (void)startAnimating;
- (void)stopAnimating;

/// 对齐 BBZ：横屏时 Metal 面 bounds = 逻辑宽高，W2S 用同一套尺寸
- (void)applyCanvasWidth:(CGFloat)width height:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END
