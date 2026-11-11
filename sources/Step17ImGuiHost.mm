//
//  Step17ImGuiHost.mm
//

#import "Step17ImGuiHost.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>

#import "BBZGui.h"
#import "BBZGui_impl_metal.h"

__attribute__((used)) static const char kStep17Marker[] = "STEP17-IMGUI";

@interface Step17ImGuiHost () <MTKViewDelegate>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) MTKView *mtkView;
@property(nonatomic, strong) CADisplayLink *link;
@property(nonatomic, assign) CFTimeInterval startTime;
@property(nonatomic, assign) NSInteger frameCount;
@property(nonatomic, assign) CGFloat fps;
@property(nonatomic, assign) BOOL imguiOK;
@property(nonatomic, assign) BOOL contextReady;
@end

@implementation Step17ImGuiHost

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    volatile const char *keep = kStep17Marker;
    (void)keep[0];

    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.userInteractionEnabled = NO;
    self.enabled = NO;
    self.borderStyle = UITextBorderStyleNone;
    self.startTime = CACurrentMediaTime();
    self.fps = 0;
    self.imguiOK = NO;
    self.contextReady = NO;

    self.device = MTLCreateSystemDefaultDevice();
    if (!self.device) {
      return self;
    }
    self.commandQueue = [self.device newCommandQueue];
    MTKView *mtk = [[MTKView alloc] initWithFrame:self.bounds device:self.device];
    mtk.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mtk.delegate = self;
    mtk.clearColor = MTLClearColorMake(0, 0, 0, 0);
    mtk.paused = YES;
    mtk.enableSetNeedsDisplay = YES;
    mtk.framebufferOnly = YES;
    mtk.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    mtk.backgroundColor = [UIColor clearColor];
    mtk.opaque = NO;
    [self addSubview:mtk];
    self.mtkView = mtk;

    [self setupImGui];
  }
  return self;
}

- (void)setupImGui {
  IMGUI_CHECKVERSION();
  BBZGUI::CreateContext();
  BBZGUI::StyleColorsDark();
  BBZGUI::GetStyle().AntiAliasedLines = false;
  BBZGUI::GetStyle().AntiAliasedFill = false;

  BBZGUIIO &io = BBZGUI::GetIO();
  io.IniFilename = nullptr;
  io.LogFilename = nullptr;
  // 薄验收：默认字体即可（ASCII 角标）；中文在 HUD 条带
  io.Fonts->AddFontDefault();
  io.Fonts->Build();

  if (!BBZGUI_ImplMetal_Init(self.device)) {
    self.imguiOK = NO;
    return;
  }
  self.imguiOK = YES;
  self.contextReady = YES;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.mtkView.frame = self.bounds;
}

- (void)startAnimating {
  if (self.link) {
    return;
  }
  self.startTime = CACurrentMediaTime();
  self.frameCount = 0;
  self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(onTick:)];
  [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopAnimating {
  [self.link invalidate];
  self.link = nil;
}

- (void)onTick:(CADisplayLink *)link {
  (void)link;
  self.frameCount += 1;
  CFTimeInterval now = CACurrentMediaTime();
  CFTimeInterval dt = now - self.startTime;
  if (dt >= 0.5) {
    self.fps = self.frameCount / (CGFloat)dt;
    self.frameCount = 0;
    self.startTime = now;
  }
  if (self.mtkView) {
    [self.mtkView setNeedsDisplay];
  }
}

- (void)drawDemoPrimitives {
  CGFloat w = self.mtkView.bounds.size.width;
  CGFloat h = self.mtkView.bounds.size.height;
  if (w < 1 || h < 1) {
    return;
  }
  CGFloat cx = w * 0.5f;
  CGFloat cy = h * 0.45f;
  CGFloat t = (CGFloat)CACurrentMediaTime();
  CGFloat pulse = 0.5f + 0.5f * sinf((float)t * 3.0f);
  CGFloat arm = 28.0f + 6.0f * pulse;

  ImDrawList *dl = BBZGUI::GetForegroundDrawList();
  ImU32 crossCol = IM_COL32(90, 255, 190, 240);
  ImU32 boxCol = IM_COL32(220, 110, 255, 240);
  ImU32 textCol = IM_COL32(160, 255, 180, 255);

  dl->AddLine(ImVec2(cx - arm, cy), ImVec2(cx + arm, cy), crossCol, 2.0f);
  dl->AddLine(ImVec2(cx, cy - arm), ImVec2(cx, cy + arm), crossCol, 2.0f);

  CGFloat boxW = 90.0f + 10.0f * pulse;
  CGFloat boxH = 140.0f;
  dl->AddRect(ImVec2(cx - boxW * 0.5f, cy - boxH * 0.55f),
              ImVec2(cx + boxW * 0.5f, cy + boxH * 0.45f), boxCol, 0.0f, 0, 1.5f);

  char title[64];
  snprintf(title, sizeof(title), "STEP17-IMGUI  fps=%.0f", (double)self.fps);
  float top = (float)self.safeAreaInsets.top + 56.0f;
  dl->AddText(ImVec2(16.0f, top), textCol, title);
  dl->AddText(ImVec2(16.0f, top + 18.0f), IM_COL32(220, 220, 220, 230),
              "BBZGUI+Metal (no PhysX/DrawView.mm)");
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
  (void)view;
  (void)size;
}

- (void)drawInMTKView:(MTKView *)view {
  if (!self.imguiOK || !self.contextReady || !self.commandQueue) {
    return;
  }
  @autoreleasepool {
    BBZGUIIO &io = BBZGUI::GetIO();
    io.DisplaySize = ImVec2(view.bounds.size.width, view.bounds.size.height);
    io.DisplayFramebufferScale =
        ImVec2(view.contentScaleFactor, view.contentScaleFactor);
    if (self.link) {
      io.DeltaTime = (float)self.link.duration;
      if (io.DeltaTime <= 0.0f) {
        io.DeltaTime = 1.0f / 60.0f;
      }
    } else {
      io.DeltaTime = 1.0f / 60.0f;
    }

    if (view.currentDrawable == nil) {
      return;
    }
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
    if (!pass) {
      [commandBuffer commit];
      return;
    }
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);

    BBZGUI_ImplMetal_NewFrame(pass);
    BBZGUI::NewFrame();
    [self drawDemoPrimitives];
    BBZGUI::Render();

    id<MTLRenderCommandEncoder> enc =
        [commandBuffer renderCommandEncoderWithDescriptor:pass];
    BBZGUI_ImplMetal_RenderDrawData(BBZGUI::GetDrawData(), commandBuffer, enc);
    [enc endEncoding];
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
  }
}

- (void)dealloc {
  [self.link invalidate];
  if (self.contextReady) {
    BBZGUI_ImplMetal_Shutdown();
    BBZGUI::DestroyContext();
    self.contextReady = NO;
  }
}

@end
