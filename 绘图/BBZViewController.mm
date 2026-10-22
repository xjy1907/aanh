//
//  BBZViewController.mm
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <objc/runtime.h>
#import <objc/message.h>
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
    过直播窗口 *_过直播容器; // 过直播容器视图
    UILabel *_hudAliveLabel; // UIKit 兜底字：即使 ImGui/Metal 坏了也能看见
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
        _MetalView.enableSetNeedsDisplay = NO;
        _MetalView.paused = NO;
        _MetalView.preferredFramesPerSecond = 120;
        _MetalView.backgroundColor = UIColor.clearColor; // 设置背景色透明
        _MetalView.clearColor = MTLClearColorMake(0, 0, 0, 0.0); // Metal 清屏颜色为透明
        _MetalView.delegate = self; // 设定自身为 MTKView 代理
        _MetalView.autoResizeDrawable = YES;
        _MetalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        _MetalView.depthStencilPixelFormat = MTLPixelFormatInvalid; // 不需要深度缓冲，减少GPU开销
        _MetalView.framebufferOnly = YES; // 提高 GPU 性能
        
        //_MetalView.delegate = self;
        //[self.BBZwindow addSubview:_MetalView]; // 将 MTKView 添加到主窗口
        
        // 过直播功能：读取配置决定是否启用
        NSDictionary *配置 = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.map.settings.plist"];
        BOOL 过直播开关 = [[配置 objectForKey:@"过直播密钥"] boolValue];
        
        if (过直播开关) {
            // 启用过直播：将 MetalView 放入过直播容器
            KernelLogLine("HUD: 过直播模式已启用 (UITextField Secure Mode)");
            _过直播容器 = [[过直播窗口 alloc] initWithFrame:rootVC.view.bounds];
            _过直播容器.backgroundColor = [UIColor clearColor];
            _过直播容器.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [rootVC.view addSubview:_过直播容器];
            [_过直播容器 addSubview:_MetalView];
            KernelLogLine("HUD: 过直播模式已启用");
        } else {
            // 不启用过直播：直接添加 MetalView
            [rootVC.view addSubview:_MetalView];
        }

        // UIKit 兜底条：不依赖 ImGui，用来确认 HUD 窗口真的盖在游戏上
        _hudAliveLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 48, rootVC.view.bounds.size.width - 16, 28)];
        _hudAliveLabel.text = @"AB HUD ALIVE (UIKit)";
        _hudAliveLabel.textColor = [UIColor greenColor];
        _hudAliveLabel.font = [UIFont boldSystemFontOfSize:16];
        _hudAliveLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
        _hudAliveLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _hudAliveLabel.userInteractionEnabled = NO;
        [rootVC.view addSubview:_hudAliveLabel];
        KernelLogLine("HUD: UIKit overlay label added");
        
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
        
        // 三角洲字体加载方式
        ImFontConfig config;
        config.FontDataOwnedByAtlas = false;
        ImVector<ImWchar> ranges;
        ImFontGlyphRangesBuilder builder;
        builder.AddRanges(io.Fonts->GetGlyphRangesDefault());
        builder.AddRanges(io.Fonts->GetGlyphRangesGreek());
        builder.AddRanges(io.Fonts->GetGlyphRangesKorean());
        builder.AddRanges(io.Fonts->GetGlyphRangesJapanese());
        builder.AddRanges(io.Fonts->GetGlyphRangesChineseFull());
        builder.AddRanges(io.Fonts->GetGlyphRangesChineseSimplifiedCommon());
        builder.AddRanges(io.Fonts->GetGlyphRangesCyrillic());
        builder.AddRanges(io.Fonts->GetGlyphRangesThai());
        builder.AddRanges(io.Fonts->GetGlyphRangesVietnamese());
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

- (void)handleInterfaceOrientationChange:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(orientation);
    CGSize screenSize = [UIScreen mainScreen].bounds.size; // 直接使用点尺寸
    
    // 计算横竖屏下的逻辑尺寸（点单位）
    BBZWidth = isLandscape ? MAX(screenSize.width, screenSize.height) : MIN(screenSize.width, screenSize.height);
    BBZHeight = isLandscape ? MIN(screenSize.width, screenSize.height) : MAX(screenSize.width, screenSize.height);
    
    [UIView animateWithDuration:duration animations:^{
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
                
            default: // Portrait
                self->_MetalView.transform = CGAffineTransformIdentity;
                self->_MetalView.bounds = CGRectMake(0, 0, BBZWidth, BBZHeight);
                break;
        }
        
        // 确保 Metal 视图更新尺寸
        [self->_MetalView setNeedsDisplay];
        [self->_MetalView draw];
    }];
}

// 全局静态变量，减少系统调用次数
static double g_Time = 0.0;
static struct timespec current_timespec;

inline void UpdateImGuiIO(MTKView *view, BBZGUIIO &io) {
    clock_gettime(CLOCK_MONOTONIC, &current_timespec);
    double current_time = (double)(current_timespec.tv_sec) + (current_timespec.tv_nsec / 1e9);
    io.DeltaTime = g_Time > 0.0 ? (float)(current_time - g_Time) : (1.0f / view.preferredFramesPerSecond);
    g_Time = current_time;

    // iPad Pro 12.9 适配：优先使用 drawableSize，并确保不为 0
    float w = view.drawableSize.width;
    float h = view.drawableSize.height;
    if (w <= 0 || h <= 0) {
        CGSize sz = [UIScreen mainScreen].nativeBounds.size;
        w = sz.width;
        h = sz.height;
    }
    io.DisplaySize = ImVec2(w, h);
}

- (void)drawInMTKView:(MTKView *)view {
    static int callCount = 0;
    callCount++;
    // 每 ~1s 打一次，证明 HUD Metal 帧在跑（之前 600 帧太稀，日志里几乎看不到）
    if (callCount % 60 == 1) {
        char buf[128];
        snprintf(buf, sizeof(buf), "HUD: drawInMTKView #%d drawable=%p size=%.0fx%.0f",
                 callCount, view.currentDrawable,
                 view.drawableSize.width, view.drawableSize.height);
        KernelLogLine(buf);
        if (_hudAliveLabel) {
            _hudAliveLabel.text = [NSString stringWithFormat:@"AB HUD ALIVE Metal#%d", callCount];
        }
    }
    @autoreleasepool {
        BBZGUIIO& io = BBZGUI::GetIO();

        UpdateImGuiIO(view, io);

        if (view.currentDrawable == nil) {
            if (callCount % 60 == 1) KernelLogLine("HUD: currentDrawable=nil — Metal 无法出图");
            return;
        }

        id<MTLCommandBuffer> commandBuffer = [_mtlCommandQueue commandBuffer];
        MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

        if (!renderPassDescriptor) {
            if (callCount % 60 == 1) KernelLogLine("HUD: renderPassDescriptor=nil");
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
