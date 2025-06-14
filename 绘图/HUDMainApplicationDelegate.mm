//
//  HUDMainApplicationDelegate.mm
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "HUDMainApplicationDelegate.h"
#import "HUDMainWindow.h"
#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"
#include "ESP.hpp"

CGFloat kWidth = 0; // 存储屏幕宽度
CGFloat kHeight = 0; // 存储屏幕高度

@implementation HUDMainApplicationDelegate { // HUDMainApplicationDelegate 类的实现
  SBSAccessibilityWindowHostingController *_windowHostingController; // 无障碍窗口托管控制器
  MTKView *_mtkView; // Metal 渲染视图
  id<MTLCommandQueue> _mtlCommandQueue; // Metal 命令队列
  MenuFloatController *_rootViewController; // 主菜单视图控制器
  SBSAccessibilityWindowHostingController *MenuwindowHostingController; // 另一个无障碍窗口托管控制器
}

- (instancetype)init { // 构造函数
  if (self = [super init]) { // 调用父类初始化
    log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate init]"); // 记录日志
  }
  return self; // 返回实例
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions { // 应用启动回调
  log_debug(OS_LOG_DEFAULT, "- [HUDMainApplicationDelegate application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions); // 记录日志
  
  self.Startwindow = [[HUDMainWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; // 创建 HUDMainWindow，大小为屏幕大小
  //[[UIApplication sharedApplication].keyWindow addSubview:self.Startwindow];
  
  [self.Startwindow setWindowLevel:UIWindowLevelStatusBar + 1]; // 设置窗口层级，比状态栏高
  [self.Startwindow setHidden:NO]; // 使窗口可见
  [self.Startwindow makeKeyAndVisible]; // 使窗口成为主窗口并显示
  // [self.window setPreferredFrameRateRange:CAFrameRateRangeMake(120, 120, 120)];
  // _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:_mtlDevice];
  
  _mtkView = [[MTKView alloc] initWithFrame:self.Startwindow.bounds]; // 创建 MTKView，大小为窗口大小
  //_mtkView.contentScaleFactor = [UIScreen mainScreen].nativeScale; // 设置物理像素比例
  _mtkView.device = MTLCreateSystemDefaultDevice(); // 绑定默认 Metal 设备
  _mtkView.opaque = NO; // 设置透明
  _mtkView.preferredFramesPerSecond = 120;
  _mtkView.backgroundColor = UIColor.clearColor; // 设置背景色透明
  _mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0.0); // Metal 清屏颜色为透明
  _mtkView.delegate = self; // 设定自身为 MTKView 代理
  [self.Startwindow addSubview:_mtkView]; // 将 MTKView 添加到主窗口
  
  //    UITextField *HiddenView = [[UITextField alloc]initWithFrame:_mtkView.frame];
  //    HiddenView.backgroundColor = [UIColor clearColor];
  //    HiddenView.secureTextEntry = YES;
  //    HiddenView.userInteractionEnabled = YES;
  //    [HiddenView setUserInteractionEnabled:NO];
  //    [HiddenView.subviews.firstObject addSubview:_mtkView];
  //    [self.Startwindow addSubview:HiddenView];
  
  _rootViewController = [[MenuFloatController alloc] init]; // 创建菜单视图控制器
  self.StartMenuwindow = [[HUDMenuWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; // 创建 HUDMenuWindow
  [self.StartMenuwindow setRootViewController:_rootViewController]; // 设置菜单窗口的根视图控制器
  [self.StartMenuwindow setWindowLevel:UIWindowLevelStatusBar - 20]; // 设置菜单窗口层级，比状态栏低 20
  [self.StartMenuwindow setHidden:NO]; // 使菜单窗口可见
  
  IMGUI_CHECKVERSION(); // 检查 ImGui 版本
  ImGui::CreateContext(); // 创建 ImGui 上下文
  ImGui::StyleColorsDark(); // 设定 ImGui 主题为深色
  
  ImGuiIO& io = ImGui::GetIO(); (void)io; // 获取 ImGui 输入输出对象
  ImGui::StyleColorsClassic(); // 设定 ImGui 主题为经典样式
  io.Fonts->Clear(); // 清除字体
  ImFontConfig config; // 创建字体配置
  config.FontDataOwnedByAtlas = false; // 字体数据不归 Atlas 管理
  io.Fonts->AddFontFromMemoryTTF((void *)dfmbold_data, dfmbold_size, 38.0f, NULL,
                                 //io.Fonts->AddFontFromFileTTF("/System/Library/Fonts/LanguageSupport/PingFang.ttc", 45.f, &config,
                                 io.Fonts->GetGlyphRangesChineseFull());
  
  if (!ImGui_ImplMetal_Init(_mtkView.device)) { // 初始化 ImGui 的 Metal 绑定
    return YES; // 如果失败，返回 YES，结束启动
  }
  
  _mtlCommandQueue = [_mtkView.device newCommandQueue]; // 创建 Metal 命令队列
  if (!_mtlCommandQueue) { // 如果创建失败
    return YES; // 返回 YES，结束启动
  }
  
  _windowHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init]; // 初始化无障碍窗口托管控制器
  MenuwindowHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init]; // 初始化另一个无障碍窗口托管控制器
  
  unsigned int _contextId = [self.Startwindow _contextId]; // 获取主窗口的上下文 ID
  unsigned int _contextId1 = [self.StartMenuwindow _contextId]; // 获取菜单窗口的上下文 ID
  
  double windowLevel = [self.Startwindow windowLevel]; // 获取主窗口层级
  double windowLevel1 = [self.StartMenuwindow windowLevel]; // 获取菜单窗口层级
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  
  ((void (*)(id, SEL, unsigned int, double))objc_msgSend)(_windowHostingController,
                                                          NSSelectorFromString(@"registerWindowWithContextID:atLevel:"),
                                                          _contextId,
                                                          windowLevel); // 通过 objc_msgSend 方式调用注册窗口方法
  
  ((void (*)(id, SEL, unsigned int, double))objc_msgSend)(MenuwindowHostingController,
                                                          NSSelectorFromString(@"registerWindowWithContextID:atLevel:"),
                                                          _contextId1,
                                                          windowLevel1); // 注册菜单窗口
  
#pragma clang diagnostic pop
  
  
  
  [self setupOrientationObserver]; // 设置屏幕方向变化的监听器
  
  return YES; // 启动成功，返回 YES
}

- (void)setupOrientationObserver { // 设置屏幕方向监听
  self.orientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init]; // 创建 FBSOrientationObserver 观察者
  __weak typeof(self) weakSelf = self; // 采用弱引用，防止循环引用
  
  [self.orientationObserver setHandler:^(FBSOrientationUpdate *orientationUpdate) { // 设置方向变化的回调
    dispatch_async(dispatch_get_main_queue(), ^{ // 在主线程执行
      [weakSelf handleInterfaceOrientationChange:(UIInterfaceOrientation)orientationUpdate.orientation
                                        duration:orientationUpdate.duration]; // 处理屏幕方向变化
    });
  }];
}

- (void)handleInterfaceOrientationChange:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
  BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
  CGSize screenSize = [UIScreen mainScreen].bounds.size; // 直接使用点尺寸
  
  // 计算横竖屏下的逻辑尺寸（点单位）
  kWidth = isLandscape ? MAX(screenSize.width, screenSize.height) : MIN(screenSize.width, screenSize.height);
  kHeight = isLandscape ? MIN(screenSize.width, screenSize.height) : MAX(screenSize.width, screenSize.height);
  
  [UIView animateWithDuration:duration animations:^{
    switch (orientation) {
      case UIInterfaceOrientationLandscapeLeft:
        self->_mtkView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        self->_mtkView.bounds = CGRectMake(0, 0, kWidth, kHeight);
        break;
        
      case UIInterfaceOrientationLandscapeRight:
        self->_mtkView.transform = CGAffineTransformMakeRotation(M_PI_2);
        self->_mtkView.bounds = CGRectMake(0, 0, kWidth, kHeight);
        break;
        
      case UIInterfaceOrientationPortraitUpsideDown:
        self->_mtkView.transform = CGAffineTransformMakeRotation(M_PI);
        self->_mtkView.bounds = CGRectMake(0, 0, kWidth, kHeight);
        break;
        
      default: // Portrait
        self->_mtkView.transform = CGAffineTransformIdentity;
        self->_mtkView.bounds = CGRectMake(0, 0, kWidth, kHeight);
        break;
    }
    
    // 确保 Metal 视图更新尺寸
    [self->_mtkView setNeedsDisplay];
    [self->_mtkView draw];
  }];
}

//- (void)calculateFPS {
//    static int frameCount = 0;
//    static CFTimeInterval lastTime = 0;
//
//    frameCount++;
//    CFTimeInterval currentTime = CACurrentMediaTime();
//    CFTimeInterval deltaTime = currentTime - lastTime;
//
//    if (deltaTime >= 1.0) {
//        NSLog(@"当前 FPS: %d", frameCount);
//        frameCount = 0;
//        lastTime = currentTime;
//    }
//}

- (void)drawInMTKView:(MTKView *)view {
  ImGuiIO& io = ImGui::GetIO();
  
  view.preferredFramesPerSecond = 120;
  
  //[self calculateFPS];
  
  // 将逻辑点转换为物理像素
  io.DisplaySize = ImVec2(view.drawableSize.width, view.drawableSize.height);
  
  struct timespec current_timespec;
  clock_gettime(CLOCK_MONOTONIC, &current_timespec);
  double current_time = (double)(current_timespec.tv_sec) + (current_timespec.tv_nsec / 1000000000.0);
  io.DeltaTime = _lastTime > 0.0 ? (float)(current_time - _lastTime) : (float)(1.0f / 120.0f);
  _lastTime = current_time;
  
  id<MTLCommandBuffer> commandBuffer = [_mtlCommandQueue commandBuffer];
  
  MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
  if (renderPassDescriptor == nil) {
    [commandBuffer commit];
    return;
  }
  ImGui_ImplMetal_NewFrame(renderPassDescriptor);
  ImGui::NewFrame();
  
  Draw::Startdfm(); // 调用自定义绘制函数
  
  ImGui::Render();
  id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
  ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderCommandEncoder);
  [renderCommandEncoder endEncoding];
  [commandBuffer presentDrawable:view.currentDrawable];
  [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size { // 视图尺寸变化时回调
}

@end
