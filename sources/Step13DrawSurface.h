//
//  Step13DrawSurface.h
//  验收⑬：HUD 叠层内轻量绘制面（十字/框/FPS）；不链 DrawView.mm / PhysX
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Step13DrawSurface : UIView

- (void)startAnimating;
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
