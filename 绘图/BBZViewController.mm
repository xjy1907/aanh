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
#import "NHIdentity.h"
#import "游戏/WeaponTextures.h"
//#include "ShowClient.h"

// 日志输出到主页日志框
#ifdef __cplusplus
extern "C" {
#endif
void KernelLogLine(const char *line);
bool IsReadingEnabled(void);
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
    NSInteger _appliedDrawFps; // 已应用到 DisplayLink 的 drawFps（0=跟屏刷）
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
        // 先建窗口再 exploit：避免二次 kopen 卡死时连 Window ContextID 都没有（无任何水印）
        KernelLogLine("HUD: 准备叠层窗口...");
        DOJailbreaker *jbEarly = (DOJailbreaker *)DOJailbreaker.sharedInstance;
        if (jbEarly.isSuccess && ![jbEarly hasLivePrimitives]) {
            jbEarly.isSuccess = NO;
            KernelLogLine("HUD: 忽略无原语的假就绪标记");
        }
        self.BBZwindow = [[HonyWindow alloc] init];
        self.BBZwindow.frame = [[UIScreen mainScreen] bounds]; // 创建 HUDMainWindow，大小为屏幕大小
        //    sss();
        // 对齐 AB：用状态栏附近层级，避免 2000000 这类异常 Accessibility 托管特征；SBS 注册后仍可盖住游戏绘制射线/骨骼
        [self.BBZwindow setWindowLevel:UIWindowLevelStatusBar - 1];
        
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

        // CADisplayLink + MTKView 手动刷；帧率由 prefs drawFps 控制（默认 60，降 CPU）
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        _appliedDrawFps = -1;
        [self applyDrawFpsFromPrefs:YES];
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
        // 菜单略高于绘制窗（StatusBar-1），避免 100000 异常 level；功能仍靠 SBSAccessibility 托管置顶
        [self.BBZMenu setWindowLevel:UIWindowLevelStatusBar + 1];
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

        // 手持图片纹理（对标 wasd initImageTexture）
        InitWeaponTextures(_MetalView.device);
        
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
        
        // 窗口与 ContextID 已就绪后再异步 exploit：
        // 二次拉起若 kopen 卡住，至少叠层在，且不会堵死 didFinishLaunching。
        DOJailbreaker *jb = (DOJailbreaker *)DOJailbreaker.sharedInstance;
        if ([jb hasLivePrimitives]) {
            jb.isSuccess = YES;
            KernelLogLine("HUD: 内核就绪（本进程原语已可用）");
        } else {
            jb.isSuccess = NO;
            KernelLogLine("HUD: 窗口已就绪，后台初始化本进程内核...");
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                [DOJailbreaker.sharedInstance run];
                BOOL ok = ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess;
                BOOL live = [((DOJailbreaker *)DOJailbreaker.sharedInstance) hasLivePrimitives];
                if (ok && !live) {
                    ((DOJailbreaker *)DOJailbreaker.sharedInstance).isSuccess = NO;
                    ok = NO;
                }
                KernelLogLine(ok ? "HUD: 内核就绪" : "HUD: 内核初始化完成（可能未成功）");
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
    return NHPrefsPath();
}

- (BOOL)loadOverlayFlagFromDisk {
    // 热路径：优先 notify state，避免每次读盘
    NSDictionary *st = NHPrefsDictFromState();
    if (st) return [[st objectForKey:@"overlay"] boolValue];
    NSDictionary *cfg = NHPrefsRead();
    return [[cfg objectForKey:@"overlay"] boolValue];
}

- (NSInteger)loadDrawFpsFromPrefs {
    // 默认 60（对齐历史 perf 提交）；0=跟屏刷仅在用户显式选择时
    static NSInteger sCachedFps = 60;
    static CFAbsoluteTime sLastExtras = 0;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (sLastExtras > 0 && (now - sLastExtras) < 2.0) {
        return sCachedFps;
    }
    sLastExtras = now;

    NSInteger fps = 60;
    NSDictionary *ex = NHDrawExtrasRead();
    if (ex[@"drawFps"] != nil) {
        fps = [ex[@"drawFps"] integerValue];
    } else {
        NSDictionary *st = NHPrefsDictFromState();
        if (st[@"drawFps"] != nil) {
            NSInteger modeFps = [st[@"drawFps"] integerValue];
            // state 仅编码 60/90/120；为 0 时保持默认 60（未写入 extras）
            if (modeFps == 60 || modeFps == 90 || modeFps == 120) fps = modeFps;
        }
    }
    if (fps != 0 && fps != 30 && fps != 60 && fps != 90 && fps != 120) fps = 60;
    sCachedFps = fps;
    return fps;
}

/// fps<=0：跟屏刷；1=空闲保活；否则 30/60/90/120（非法值回落 60）
- (void)applyDrawFpsToDisplayLink:(NSInteger)fps {
    if (!self.displayLink) return;
    if (fps != 0 && fps != 1 && fps != 30 && fps != 60 && fps != 90 && fps != 120) fps = 60;
    if (fps == _appliedDrawFps) return;
    _appliedDrawFps = fps;
    if (fps <= 0) {
        if (@available(iOS 15.0, *)) {
            self.displayLink.preferredFrameRateRange = CAFrameRateRangeDefault;
        }
        self.displayLink.preferredFramesPerSecond = 0;
        KernelLogLine("HUD: drawFps=follow-display");
    } else {
        if (@available(iOS 15.0, *)) {
            float f = (float)fps;
            self.displayLink.preferredFrameRateRange = CAFrameRateRangeMake(MAX(1.f, f * 0.5f), f, f);
        }
        self.displayLink.preferredFramesPerSecond = (NSInteger)fps;
        char buf[64];
        snprintf(buf, sizeof(buf), "HUD: drawFps=%ld", (long)fps);
        KernelLogLine(buf);
    }
}

- (void)applyDrawFpsFromPrefs:(BOOL)force {
    NSInteger fps = [self loadDrawFpsFromPrefs];
    if (force) _appliedDrawFps = -1;
    [self applyDrawFpsToDisplayLink:fps];
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
    // overlay / drawFps 热更新：2s 一次，且优先走 notify（不对每次读盘）
    _overlayPollTick++;
    static CFAbsoluteTime sLastPrefPoll = 0;
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (sLastPrefPoll <= 0 || (now - sLastPrefPoll) >= 2.0) {
        sLastPrefPoll = now;
        BOOL on = [self loadOverlayFlagFromDisk];
        if (on != _liveHiddenApplied) {
            [self applyLiveHide:on];
        }
        // 未开启读取：1fps 保活轮询；开启后恢复 prefs 帧率
        if (!IsReadingEnabled()) {
            [self applyDrawFpsToDisplayLink:1];
        } else {
            [self applyDrawFpsFromPrefs:NO];
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
