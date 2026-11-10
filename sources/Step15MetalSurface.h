//
//  Step15MetalSurface.h
//  验收⑮：过直播宿主内薄 Metal/MTKView 面；不链 DrawView.mm / PhysX / ImGui
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Step15MetalSurface : UIView

- (void)startAnimating;
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
