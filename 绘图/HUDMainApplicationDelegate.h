//
//  HUDMainApplicationDelegate.h
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <UIKit/UIKit.h>
#import "imgui.h"
#import "imgui_impl_metal.h"
#import <MetalKit/MTKView.h>
#import <Metal/MTLDevice.h>
#import "FBSOrientationUpdate.h"
#import "FBSOrientationObserver.h"
#import "Menu.hpp"
#include "dfmbold.h"

NS_ASSUME_NONNULL_BEGIN

extern CGFloat kWidth;
extern CGFloat kHeight;

@interface HUDMainApplicationDelegate : UIResponder <UIApplicationDelegate, MTKViewDelegate>

@property (nonatomic, strong) UIWindow *Startwindow;
@property (nonatomic, strong) UIWindow *StartMenuwindow;
@property (nonatomic, strong) FBSOrientationObserver *orientationObserver;

@property (nonatomic, assign) double lastTime;

@end

NS_ASSUME_NONNULL_END

