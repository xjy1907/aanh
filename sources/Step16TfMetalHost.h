//
//  Step16TfMetalHost.h
//  验收⑯：对标 wasd ImGuiDraw（UITextField 宿主 + MTKView）；不链 ImGui/PhysX/DrawView.mm
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// wasd: ImGuiDraw : UITextField，再 [self addSubview:mtkView]
@interface Step16TfMetalHost : UITextField

- (void)startAnimating;
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
