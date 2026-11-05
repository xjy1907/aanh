//
//  BBZViewController.h
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>
#import "BBZGui.h"
#import "BBZGui_impl_metal.h"
#import <MetalKit/MTKView.h>
#import <Metal/MTLDevice.h>
#import "FBSOrientationUpdate.h"
#import "FBSOrientationObserver.h"
//#import "BBZCD.hpp"
//#include "fontxx.h"

@class SimpleTouchPassthrough;

NS_ASSUME_NONNULL_BEGIN

extern CGFloat BBZWidth;
extern CGFloat BBZHeight;

@interface BBZViewController : UIResponder <UIApplicationDelegate, MTKViewDelegate>

@property (nonatomic, strong) UIWindow *BBZwindow;
@property (nonatomic, strong) UIWindow *BBZMenu;
@property (nonatomic, strong) UIWindow *aimFloatWindow;
@property (nonatomic, strong) FBSOrientationObserver *orientationObserver;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) double lastTime;

@end

NS_ASSUME_NONNULL_END

