#import <pthread.h>
#import <sys/utsname.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOKitKeys.h>

#import "HUD控制器.h"

#import "游戏/三角洲行动/国服/子线程.h"
#import "游戏/三角洲行动/国服/主线程.h"
#import "内核/kfd.h"
#import "网页雷达服务器.h"


@implementation HUD控制器 {
    FBSOrientationObserver* FBSOrientationObserver;
    BOOL 当前过直播状态;
    BOOL 网页雷达已启动;
};

- (void) viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    
    // 读取过直播开关状态
    NSDictionary *配置 = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.map.settings.plist"];
    当前过直播状态 = [[配置 objectForKey:@"过直播密钥"] boolValue];
    
    self.过直播窗口 = [[过直播窗口 alloc] initWithFrame:self.view.bounds];
    self.过直播窗口.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.MTKView = [[MTKView alloc] initWithFrame:self.view.bounds];
    self.MTKView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.MTKView.preferredFramesPerSecond = 120.0f;
    self.MTKView.device = MTLCreateSystemDefaultDevice();
    self.MTKView.opaque = NO;
    self.MTKView.backgroundColor = UIColor.clearColor;
    self.MTKView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.MTKView.delegate = self;
    
    // 根据过直播状态决定添加方式
    if (当前过直播状态) {
        self.MTKView.frame = self.过直播窗口.bounds;
        [self.过直播窗口 addSubview:self.MTKView];
        [self.view addSubview:self.过直播窗口];
    } else {
        [self.view addSubview:self.MTKView];
    };
    
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui::StyleColorsClassic();
    
    ImGuiIO& ImGuiIO = ImGui::GetIO();
    ImGuiIO.Fonts->Clear();
    ImFontConfig ImFontConfig;
    ImFontConfig.FontDataOwnedByAtlas = false;
    ImVector<ImWchar> ImVector;
    ImFontGlyphRangesBuilder ImFontGlyphRangesBuilder;
    ImFontGlyphRangesBuilder.AddRanges(ImGuiIO.Fonts->GetGlyphRangesDefault());
    ImFontGlyphRangesBuilder.AddRanges(ImGuiIO.Fonts->GetGlyphRangesGreek());
    ImFontGlyphRangesBuilder.AddRanges(ImGuiIO.Fonts->GetGlyphRangesKorean());
    ImFontGlyphRangesBuilder.AddRanges(ImGuiIO.Fonts->GetGlyphRangesJapanese());
    ImFontGlyphRangesBuilder.AddRanges(ImGuiIO.Fonts->GetGlyphRangesChineseFull());
    ImFontGlyphRangesBuilder.AddRanges(ImGuiIO.Fonts->GetGlyphRangesChineseSimplifiedCommon());
    ImFontGlyphRangesBuilder.AddRanges(ImGuiIO.Fonts->GetGlyphRangesCyrillic());
    ImFontGlyphRangesBuilder.AddRanges(ImGuiIO.Fonts->GetGlyphRangesThai());
    ImFontGlyphRangesBuilder.AddRanges(ImGuiIO.Fonts->GetGlyphRangesVietnamese());
    ImFontGlyphRangesBuilder.BuildRanges(&ImVector);
    
    ImGuiIO.Fonts->Clear();
    NSString* 字体路径 = [[NSBundle mainBundle] pathForResource:@"阿里巴巴惠普体" ofType:@"ttf"];
    ImGuiIO.Fonts->AddFontFromFileTTF([字体路径 UTF8String], 30.0f, &ImFontConfig, ImVector.Data);
    ImGuiIO.Fonts->Build();
    
    pthread_t 子线程ID;
    pthread_create(&子线程ID, nullptr, 子线程, nullptr);
    
    UIDevice *Device = [UIDevice currentDevice];
    struct utsname sname;
    uname(&sname);
    
    string systemVersion = [Device.systemVersion UTF8String];
    string machine = [[NSString stringWithCString:sname.machine encoding:NSUTF8StringEncoding] UTF8String];
    if (machine == "iPad14,1") {
        设备类型.设备信息.设备名 = "iPad mini (第六代) [ " + systemVersion + " ]";
    } else if (machine == "iPhone14,5") {
        设备类型.设备信息.设备名 = "iPhone13 [ " + systemVersion + " ]";
    } else {
        设备类型.设备信息.设备名 = machine + " [ " + systemVersion + " ]";
    };
    
    io_service_t IOPlatformExpertDevice = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    CFTypeRef SerialNumber = IORegistryEntryCreateCFProperty(IOPlatformExpertDevice, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0);
    IOObjectRelease(IOPlatformExpertDevice);
    设备类型.设备信息.序列号 = [(__bridge NSString *)SerialNumber UTF8String];
    CFRelease(SerialNumber);
    
    绘制类型.内核 = kfd.调用kfd();
    if (绘制类型.内核) {
        绘制类型.内核 = kfd.取目标进程ID(绘制类型.进程名.c_str());
        if (绘制类型.内核) {
            kfd.patch目标进程();
            绘制类型.模块地址 = kfd.取目标模块地址(绘制类型.模块名.c_str());
            绘制类型.内核 = 绘制类型.模块地址 == 0 ? false : true;
        };
    };
    
    // 启动网页雷达客户端
    NSDictionary *雷达配置 = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.map.settings.plist"];
    BOOL 网页雷达开关 = [[雷达配置 objectForKey:@"网页雷达密钥"] boolValue];
    网页雷达已启动 = NO;
    if (网页雷达开关) {
        g_网页雷达.设置服务器("http://ld.rivp.cn/api.php");
        if (g_网页雷达.启动()) {
            网页雷达已启动 = YES;
        }
    }
    
    ImGui_ImplMetal_Init(self.MTKView.device);
    self.MTLCommandQueue = [self.MTKView.device newCommandQueue];
};

- (void) drawInMTKView:(nonnull MTKView *)view {
    // 检测过直播开关变化
    NSDictionary *配置 = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.map.settings.plist"];
    BOOL 过直播开关 = [[配置 objectForKey:@"过直播密钥"] boolValue];
    
    if (过直播开关 != 当前过直播状态) {
        当前过直播状态 = 过直播开关;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.MTKView removeFromSuperview];
            [self.过直播窗口 removeFromSuperview];
            
            if (过直播开关) {
                self.MTKView.frame = self.过直播窗口.bounds;
                [self.过直播窗口 addSubview:self.MTKView];
                [self.view addSubview:self.过直播窗口];
            } else {
                self.MTKView.frame = self.view.bounds;
                [self.view addSubview:self.MTKView];
            };
        });
    };
    
    // 检查设备和命令队列是否有效
    if (!self.MTKView.device || !self.MTLCommandQueue) {
        return;
    };
    
    ImGuiIO& ImGuiIO = ImGui::GetIO();
    设备类型.设备信息.宽度 = view.bounds.size.width * UIScreen.mainScreen.scale;
    设备类型.设备信息.高度 = view.bounds.size.height * UIScreen.mainScreen.scale;
    
    // 检查屏幕尺寸是否有效
    if (设备类型.设备信息.宽度 <= 0 || 设备类型.设备信息.高度 <= 0) {
        return;
    };
    
    ImGuiIO.DisplaySize = ImVec2(设备类型.设备信息.宽度, 设备类型.设备信息.高度);
    ImGuiIO.DisplayFramebufferScale = ImVec2(1.0f, 1.0f);
    
    id<MTLCommandBuffer> MTLCommandBuffer = [self.MTLCommandQueue commandBuffer];
    if (!MTLCommandBuffer) {
        return;
    };
    
    MTLRenderPassDescriptor* MTLRenderPassDescriptor = view.currentRenderPassDescriptor;
    if (MTLRenderPassDescriptor == nil) {
        [MTLCommandBuffer commit];
        return;
    };
    
    // 检查drawable是否有效
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!drawable) {
        [MTLCommandBuffer commit];
        return;
    };
    
    ImGui_ImplMetal_NewFrame(MTLRenderPassDescriptor);
    ImGui::NewFrame();
    
    ImDrawList* ImDrawList = ImGui::GetForegroundDrawList();
    int 玩家数量 = 0, 人机数量 = 0, 盒子数量 = 0;
    
    // 只有内核初始化成功才进行绘制
    if (绘制类型.内核) {
        主线程(ImDrawList, 玩家数量, 人机数量, 盒子数量);
    };
    
    绘制矩形(ImDrawList, ImVec4(设备类型.设备信息.宽度 * 0.5f - 110.0f, 70.0f, 220.0f, 60.0f), IM_COL32(0, 0, 0, 128), 30.0f);
    绘制文字(ImDrawList, "P: " + to_string(玩家数量), 30.0f, ImVec2(设备类型.设备信息.宽度 * 0.5f - 65.0f, 100.0f), IM_COL32(255, 102, 102, 255), 0, true);
    绘制文字(ImDrawList, "A: " + to_string(人机数量), 30.0f, ImVec2(设备类型.设备信息.宽度 * 0.5f, 100.0f), IM_COL32(102, 255, 102, 255), 0, true);
    绘制文字(ImDrawList, "B: " + to_string(盒子数量), 30.0f, ImVec2(设备类型.设备信息.宽度 * 0.5f + 65.0f, 100.0f), IM_COL32(255, 255, 102, 255), 0, true);
    
    绘制文字(ImDrawList, "设备名: " + 设备类型.设备信息.设备名  + "    序列号: " + 设备类型.设备信息.序列号 + "    内核: " + string(绘制类型.内核 ? "成功" : "失败"), 30.0f, ImVec2(150.0f, 设备类型.设备信息.高度 - 20.0f), 绘制类型.内核 ? IM_COL32(102, 255, 102, 255) : IM_COL32(255, 102, 102, 255), 1, true);
    
    // 显示网页雷达状态
    if (网页雷达已启动 && g_网页雷达.是否运行中()) {
        string 雷达信息 = g_网页雷达.获取访问信息();
        绘制文字(ImDrawList, "网页雷达: " + 雷达信息, 25.0f, ImVec2(设备类型.设备信息.宽度 - 450.0f, 设备类型.设备信息.高度 - 20.0f), IM_COL32(102, 255, 255, 255), 1, true);
    }
    
    ImGui::Render();
    id<MTLRenderCommandEncoder> MTLRenderCommandEncoder = [MTLCommandBuffer renderCommandEncoderWithDescriptor:MTLRenderPassDescriptor];
    if (!MTLRenderCommandEncoder) {
        [MTLCommandBuffer commit];
        return;
    };
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), MTLCommandBuffer, MTLRenderCommandEncoder);
    [MTLRenderCommandEncoder endEncoding];
    [MTLCommandBuffer presentDrawable:drawable];
    [MTLCommandBuffer commit];
};

- (void) mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
};

- (instancetype) init {
    self = [super init];
    if (self) {
        FBSOrientationObserver = [[objc_getClass("FBSOrientationObserver") alloc] init];
        __weak HUD控制器* weakSelf = self;
        [FBSOrientationObserver setHandler:^(FBSOrientationUpdate* FBSOrientationUpdate) {
            HUD控制器* strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf updateOrientation:(UIInterfaceOrientation)FBSOrientationUpdate.orientation animateWithDuration:FBSOrientationUpdate.duration];
            });
        }];
    };
    return self;
};

- (void) dealloc {
    [FBSOrientationObserver invalidate];
};

static inline CGFloat orientationAngle(UIInterfaceOrientation orientation) {
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;
        case UIInterfaceOrientationLandscapeLeft:
            return -M_PI_2;
        case UIInterfaceOrientationLandscapeRight:
            return M_PI_2;
        default:
            return 0;
    };
};

static inline CGRect orientationBounds(UIInterfaceOrientation orientation, CGRect bounds) {
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return CGRectMake(0, 0, bounds.size.height, bounds.size.width);
        default:
            return bounds;
    };
};

- (void) updateOrientation:(UIInterfaceOrientation)orientation animateWithDuration:(NSTimeInterval)duration {
    CGRect Rect = orientationBounds(orientation, UIScreen.mainScreen.bounds);
    [self.view setNeedsUpdateConstraints];
    [self.view setBounds:Rect];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration animations:^{
        [weakSelf.view setTransform:CGAffineTransformMakeRotation(orientationAngle(orientation))];
    } completion:^(BOOL finished) {
        // 更新 MTKView 和过直播窗口的 frame
        weakSelf.过直播窗口.frame = weakSelf.view.bounds;
        if (当前过直播状态) {
            weakSelf.MTKView.frame = weakSelf.过直播窗口.bounds;
        } else {
            weakSelf.MTKView.frame = weakSelf.view.bounds;
        };
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
};

@end

