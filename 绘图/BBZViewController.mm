//
//  BBZViewController.mm
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import <QuartzCore/CADisplayLink.h>
#import "BBZViewController.h"
#import "HonyWindow.h"
#import "SBSAccessibilityWindowHostingController.h"
#import "UIWindow+Private.h"
#import "DOJailbreaker.h"
#include "DrawView.hpp"
#import "过直播窗口.h"
//#include "ShowClient.h"

// 日志输出到主页日志框
#ifdef __cplusplus
extern "C" {
#endif
void KernelLogLine(const char *line);
#ifdef __cplusplus
}
#endif

CGFloat BBZWidth = 0; // 存储屏幕宽度
CGFloat BBZHeight = 0; // 存储屏幕高度

@implementation BBZViewController { // BBZViewController 类的实现
    SBSAccessibilityWindowHostingController *_BBZHostingController; // 无障碍窗口托管控制器
    MTKView *_MetalView; // Metal 渲染视图
    id<MTLCommandQueue> _mtlCommandQueue; // Metal 命令队列
    // CDController *_cdViewController; // 主菜单视图控制器
    SBSAccessibilityWindowHostingController *BBZMenuHostingController; // 另一个无障碍窗口托管控制器
    过直播窗口 *_过直播容器; // 对标 wasd CoverView+CoverView1
    BOOL _liveHiddenApplied; // 当前 secure 状态
    NSInteger _overlayPollTick;
}

- (instancetype)init { // 构造函数
    if (self = [super init]) { // 调用父类初始化
        //log_debug(OS_LOG_DEFAULT, "- [BBZViewController init]"); // 记录日志
    }
    return self; // 返回实例
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary <UIApplicationLaunchOptionsKey, id> *)launchOptions {
    // 应用启动回调
    //log_debug(OS_LOG_DEFAULT, "- [BBZViewController application:%{public}@ didFinishLaunchingWithOptions:%{public}@]", application, launchOptions); // 记录日志
    @autoreleasepool {
        // HUD 进程：在窗口创建前优先确保内核环境准备好（与原先未拆分时保持一致）
        KernelLogLine("HUD: 准备内核环境...");
        [DOJailbreaker.sharedInstance run];
        BOOL kernelReady = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
        KernelLogLine(kernelReady ? "HUD: 内核就绪" : "HUD: 内核初始化完成（可能未成功）");
        // 无论状态如何，启动数据线程（内部会自行重试）
        //StartDataThreads();
        NSLog(@"DH666 DOJailbreaker");
        self.BBZwindow = [[HonyWindow alloc] init];
        self.BBZwindow.frame = [[UIScreen mainScreen] bounds]; // 创建 HUDMainWindow，大小为屏幕大小
        //    sss();
        [self.BBZwindow setWindowLevel:2000000]; // 显著提高窗口层级，确保在 iPad Pro 上覆盖所有应用层
        
        self.BBZwindow.backgroundColor = [UIColor clearColor];
        self.BBZwindow.opaque = NO;
        
        [self.BBZwindow setHidden:NO]; // 使窗口可见
        //[self.BBZwindow makeKeyAndVisible]; // 使窗口成为主窗口并显示
        
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        rootVC.view.opaque = NO;
        self.BBZwindow.rootViewController = rootVC;
        
        _MetalView = [[MTKView alloc] initWithFrame:rootVC.view.bounds]; // 创建 MTKView，大小为窗口大小
        _MetalView.contentScaleFactor = [UIScreen mainScreen].nativeScale; // 设置物理像素比例，确保 iPad Pro 渲染清晰
        _MetalView.device = MTLCreateSystemDefaultDevice(); // 绑定默认 Metal 设备
        _MetalView.opaque = NO; // 设置透明
        // 对标 wasd：暂停自动刷新，由 CADisplayLink 手动触发，避免 120fps 空转
        _MetalView.enableSetNeedsDisplay = YES;
        _MetalView.paused = YES;
        _MetalView.backgroundColor = UIColor.clearColor; // 设置背景色透明
        _MetalView.clearColor = MTLClearColorMake(0, 0, 0, 0.0); // Metal 清屏颜色为透明
        _MetalView.delegate = self; // 设定自身为 MTKView 代理
        _MetalView.autoResizeDrawable = YES;
        _MetalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        _MetalView.depthStencilPixelFormat = MTLPixelFormatInvalid; // 不需要深度缓冲，减少GPU开销
        _MetalView.framebufferOnly = YES; // 提高 GPU 性能
        
        // —— 对标 wasd DrawRootViewController：始终双层 UITextField，再用 secureTextEntry 开关过直播 ——
        // wasd: CoverView / CoverView1 常驻；DrawView 挂在 CoverView1.subviews.firstObject；
        //       CoverView.secureTextEntry = CoverView1.secureTextEntry = live;
        rootVC.view.userInteractionEnabled = NO;
        _过直播容器 = [[过直播窗口 alloc] initWithFrame:rootVC.view.bounds];
        _过直播容器.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [rootVC.view addSubview:_过直播容器];
        [_过直播容器 attachDrawView:_MetalView];

        BOOL 过直播开关 = [self loadOverlayFlagFromDisk];
        _liveHiddenApplied = !过直播开关; // 强制第一次 apply
        [self applyLiveHide:过直播开关];
        KernelLogLine(过直播开关
                      ? "HUD: 过直播已启用 (wasd 双层 UITextField secure)"
                      : "HUD: 过直播关闭 (结构已就绪，开开关即生效)");

        // 对标 wasd：CADisplayLink 驱动绘制；限 60fps，ProMotion 机型也别空烧 CPU
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        if (@available(iOS 15.0, *)) {
            self.displayLink.preferredFrameRateRange = CAFrameRateRangeMake(30, 60, 60);
        } else {
            self.displayLink.preferredFramesPerSecond = 60;
        }
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

        // 调试用 UIKit 字条已关闭（按需求不再绘制 AB HUD ALIVE）
        // _hudAliveLabel = ...
        
        // 悬浮菜单 - 暂时注释掉
        // _cdViewController = [[CDController alloc] init];
        // _cdViewController.view.frame = rootVC.view.bounds;
        // _cdViewController.view.backgroundColor = [UIColor clearColor];
        // [rootVC.view addSubview:_cdViewController.view];
        
        self.BBZMenu = [[HonyMenu alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.BBZMenu.backgroundColor = [UIColor clearColor];
        self.BBZMenu.opaque = NO;
        [self.BBZMenu setWindowLevel:100000];
        [self.BBZMenu setHidden:NO];
        
        IMGUI_CHECKVERSION(); // 检查 BBZGUI 版本
        BBZGUI::CreateContext(); // 创建 BBZGUI 上下文
        BBZGUI::StyleColorsDark(); // 设定 BBZGUI 主题为深色
        
        BBZGUIIO& io = BBZGUI::GetIO(); (void)io; // 获取 BBZGUI 输入输出对象
        BBZGUI::StyleColorsClassic(); // 设定 BBZGUI 主题为经典样式
        // 对标 wasd：关线条抗锯齿，少算半个像素、少画顶点
        BBZGUI::GetStyle().AntiAliasedLines = false;
        BBZGUI::GetStyle().AntiAliasedFill = false;
        
        // 字体：只保留 Default + 简中常用，避免 ChineseFull/多语种 atlas 膨胀拖渲染
        ImFontConfig config;
        config.FontDataOwnedByAtlas = false;
        ImVector<ImWchar> ranges;
        ImFontGlyphRangesBuilder builder;
        builder.AddRanges(io.Fonts->GetGlyphRangesDefault());
        builder.AddRanges(io.Fonts->GetGlyphRangesChineseSimplifiedCommon());
        builder.BuildRanges(&ranges);
        
        io.Fonts->Clear();
        NSString* 字体路径 = [[NSBundle mainBundle] pathForResource:@"阿里巴巴惠普体" ofType:@"ttf"];
        if (字体路径.length == 0) {
            // 工程未带 ttf 时用系统苹方，否则中文全部空白
            字体路径 = @"/System/Library/Fonts/LanguageSupport/PingFang.ttc";
            if (![[NSFileManager defaultManager] fileExistsAtPath:字体路径]) {
                字体路径 = @"/System/Library/Fonts/Core/PingFang.ttc";
            }
            if (![[NSFileManager defaultManager] fileExistsAtPath:字体路径]) {
                字体路径 = @"/System/Library/Fonts/Cache/PingFang.ttc";
            }
        }
        if (字体路径.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:字体路径]) {
            char fontLog[320];
            snprintf(fontLog, sizeof(fontLog), "HUD: load font %s", 字体路径.UTF8String);
            KernelLogLine(fontLog);
            io.Fonts->AddFontFromFileTTF([字体路径 UTF8String], 30.0f, &config, ranges.Data);
        } else {
            KernelLogLine("HUD: ERROR no CJK font — ASCII only (AddFontDefault)");
            io.Fonts->AddFontDefault();
        }
        io.Fonts->Build();
        
        if (!BBZGUI_ImplMetal_Init(_MetalView.device)) { // 初始化 BBZGUI 的 Metal 绑定
            return YES; // 如果失败，返回 YES，结束启动
        }
        
        _mtlCommandQueue = [_MetalView.device newCommandQueue]; // 创建 Metal 命令队列
        if (!_mtlCommandQueue) { // 如果创建失败
            return YES; // 返回 YES，结束启动
        }
        
        _BBZHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init]; // 初始化无障碍窗口托管控制器
        BBZMenuHostingController = [[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init]; // 初始化另一个无障碍窗口托管控制器
        
        unsigned int _contextId = [self.BBZwindow _contextId]; // 获取主窗口的上下文 ID
        unsigned int _contextId1 = [self.BBZMenu _contextId]; // 获取菜单窗口的上下文 ID
        
        char logContext[128];
        snprintf(logContext, 128, "HUD: Window ContextID: %u, Menu ContextID: %u", _contextId, _contextId1);
        KernelLogLine(logContext);
        
        double windowLevel = [self.BBZwindow windowLevel]; // 获取主窗口层级
        double windowLevel1 = [self.BBZMenu windowLevel]; // 获取菜单窗口层级
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        
        ((void (*)(id, SEL, unsigned int, double))objc_msgSend)(_BBZHostingController,
                                                                NSSelectorFromString(@"registerWindowWithContextID:atLevel:"),
                                                                _contextId,
                                                                windowLevel); // 通过 objc_msgSend 方式调用注册窗口方法
        
        ((void (*)(id, SEL, unsigned int, double))objc_msgSend)(BBZMenuHostingController,
                                                                NSSelectorFromString(@"registerWindowWithContextID:atLevel:"),
                                                                _contextId1,
                                                                windowLevel1); // 注册菜单窗口
        
#pragma clang diagnostic pop
        
        // 设置屏幕方向变化的监听器
        [self setupOrientationObserver];
        
        // HUD 进程自检：如未就绪则在后台补跑一次内核初始化，避免跨进程能力缺失
       
        BOOL kernel = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
        NSLog(@"DH666 kernel %d",kernel);
        if (!kernel) {
            KernelLogLine("HUD: 检测到内核环境未就绪，开始在 HUD 进程补充初始化...");
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                [DOJailbreaker.sharedInstance run];
                NSLog(@"DH666 DOJailbreaker2");
                BOOL ok = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
                dispatch_async(dispatch_get_main_queue(), ^{
                    KernelLogLine(ok ? "HUD: 内核初始化成功" : "HUD: 内核初始化完成（可能未成功）");
                    //StartDataThreads();
                });
            });
        }
        
        
        
        return YES; // 启动成功，返回 YES
    }
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

- (NSString *)prefsCfgPath {
    static NSString *path;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        path = @"/var/mobile/Library/Preferences/com.nh.cfg.plist";
        NSString *legacy = @"/var/mobile/Library/Preferences/com.map.settings.plist";
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:path] && [fm fileExistsAtPath:legacy]) {
            [fm moveItemAtPath:legacy toPath:path error:nil];
        }
    });
    return path;
}

- (BOOL)loadOverlayFlagFromDisk {
    NSDictionary *cfg = [NSDictionary dictionaryWithContentsOfFile:[self prefsCfgPath]];
    return [[cfg objectForKey:@"overlay"] boolValue];
}

/// 对标 wasd：CoverView + CoverView1 两层 secureTextEntry 同步
- (void)applyLiveHide:(BOOL)on {
    if (!_过直播容器 || !_MetalView) return;
    if (_liveHiddenApplied == on) {
        [_过直播容器 attachDrawView:_MetalView];
        return;
    }
    _liveHiddenApplied = on;
    [_过直播容器 setLiveHidden:on];
    KernelLogLine(on ? "HUD: secureTextEntry=YES (过直播/wasd双层+DrawHost)" : "HUD: secureTextEntry=NO");
}

- (void)handleInterfaceOrientationChange:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    // 恢复 abnh 原逻辑：只转 MetalView；过直播容器跟屏幕 bounds，不套 wasd 的 Cover 旋转
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    CGSize screenSize = [UIScreen mainScreen].bounds.size;

    BBZWidth = isLandscape ? MAX(screenSize.width, screenSize.height) : MIN(screenSize.width, screenSize.height);
    BBZHeight = isLandscape ? MIN(screenSize.width, screenSize.height) : MAX(screenSize.width, screenSize.height);

    UIView *rootView = self.BBZwindow.rootViewController.view;
    CGRect screenBounds = rootView.bounds;

    [UIView animateWithDuration:duration animations:^{
        // Cover 层保持与窗口一致、不旋转（避免绘制坐标系变成竖屏）
        if (self->_过直播容器) {
            self->_过直播容器.frame = screenBounds;
            self->_过直播容器.coverView.transform = CGAffineTransformIdentity;
            self->_过直播容器.coverView1.transform = CGAffineTransformIdentity;
            self->_过直播容器.coverView.frame = self->_过直播容器.bounds;
            self->_过直播容器.coverView1.frame = self->_过直播容器.coverView.bounds;
        }

        switch (orientation) {
            case UIInterfaceOrientationLandscapeLeft:
                self->_MetalView.transform = CGAffineTransformMakeRotation(-M_PI_2);
                self->_MetalView.bounds = CGRectMake(0, 0, BBZWidth, BBZHeight);
                break;
            case UIInterfaceOrientationLandscapeRight:
                self->_MetalView.transform = CGAffineTransformMakeRotation(M_PI_2);
                self->_MetalView.bounds = CGRectMake(0, 0, BBZWidth, BBZHeight);
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                self->_MetalView.transform = CGAffineTransformMakeRotation(M_PI);
                self->_MetalView.bounds = CGRectMake(0, 0, BBZWidth, BBZHeight);
                break;
            default:
                self->_MetalView.transform = CGAffineTransformIdentity;
                self->_MetalView.bounds = CGRectMake(0, 0, BBZWidth, BBZHeight);
                break;
        }

        [self->_MetalView setNeedsDisplay];
        [self->_MetalView draw];
    }];
}

- (void)displayLinkCallback:(CADisplayLink *)displayLink {
    BBZGUI::GetIO().DeltaTime = (float)displayLink.duration;
    // 主界面改 overlay 后 HUD 热更新（约 1s）
    if ((++_overlayPollTick % 60) == 0) {
        BOOL on = [self loadOverlayFlagFromDisk];
        if (on != _liveHiddenApplied) {
            [self applyLiveHide:on];
        }
    }
    [_MetalView draw];
}

- (void)dealloc {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

inline void UpdateImGuiIO(MTKView *view, BBZGUIIO &io) {
    // DeltaTime 已由 displayLinkCallback 写入；此处只补 DisplaySize
    CGSize bounds = view.bounds.size;
    float w = (float)bounds.width;
    float h = (float)bounds.height;
    if (w <= 0 || h <= 0) {
        CGSize sz = [UIScreen mainScreen].bounds.size;
        w = (float)sz.width;
        h = (float)sz.height;
    }
    io.DisplaySize = ImVec2(w, h);
    float scale = (float)view.contentScaleFactor;
    if (scale <= 0.0f) scale = (float)[UIScreen mainScreen].scale;
    io.DisplayFramebufferScale = ImVec2(scale, scale);
}

- (void)drawInMTKView:(MTKView *)view {
    @autoreleasepool {
        BBZGUIIO& io = BBZGUI::GetIO();
        UpdateImGuiIO(view, io);

        if (view.currentDrawable == nil) return;

        id<MTLCommandBuffer> commandBuffer = [_mtlCommandQueue commandBuffer];
        MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
        if (!renderPassDescriptor) {
            [commandBuffer commit];
            return;
        }

        BBZGUI_ImplMetal_NewFrame(renderPassDescriptor);
        BBZGUI::NewFrame();

        Draw::StartBooks();

        BBZGUI::Render();

        id<MTLRenderCommandEncoder> renderCommandEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        BBZGUI_ImplMetal_RenderDrawData(BBZGUI::GetDrawData(), commandBuffer, renderCommandEncoder);
        [renderCommandEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size { }

@end
