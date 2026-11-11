//
//  Step19EspHost.mm
//

#import "Step19EspHost.h"
#import "Step18ReadProbe.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import <vector>

#import "BBZGui.h"
#import "BBZGui_impl_metal.h"
#import "SDK.h"
#import "绘制类型.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

__attribute__((used)) static const char kStep17Keep[] = "STEP17-IMGUI";
__attribute__((used)) static const char kStep18Keep[] = "STEP18-READPROBE";
__attribute__((used)) static const char kStep19Marker[] = "STEP19-THINESP";

struct Step19Box {
  float x, y, w, h;
  float dist;
  bool ai;
};

static bool ReadBytes(uint64_t addr, void *out, size_t n) {
  return [Step18ReadProbe readGameAt:addr size:n into:out];
}

template <typename T>
static bool ReadVal(uint64_t addr, T *out) {
  return ReadBytes(addr, out, sizeof(T));
}

static uint64_t ReadPtr(uint64_t addr) {
  uint64_t v = 0;
  if (!ReadVal(addr, &v)) {
    return 0;
  }
  return UNSIGN_PTR(v);
}

static float Dot3(Vector3 lhs, Vector3 rhs) {
  return lhs.X * rhs.X + lhs.Y * rhs.Y + lhs.Z * rhs.Z;
}

static float Dist3(Vector3 a, Vector3 b) {
  Vector3 v = a - b;
  return sqrtf(v.X * v.X + v.Y * v.Y + v.Z * v.Z);
}

static FMatrix RotToMatrix(FRotator rotation) {
  float radPitch = rotation.Pitch * (float)(M_PI / 180.0);
  float radYaw = rotation.Yaw * (float)(M_PI / 180.0);
  float radRoll = rotation.Roll * (float)(M_PI / 180.0);
  float SP = sinf(radPitch), CP = cosf(radPitch);
  float SY = sinf(radYaw), CY = cosf(radYaw);
  float SR = sinf(radRoll), CR = cosf(radRoll);
  FMatrix matrix;
  matrix[0][0] = CP * CY;
  matrix[0][1] = CP * SY;
  matrix[0][2] = SP;
  matrix[0][3] = 0;
  matrix[1][0] = SR * SP * CY - CR * SY;
  matrix[1][1] = SR * SP * SY + CR * CY;
  matrix[1][2] = -SR * CP;
  matrix[1][3] = 0;
  matrix[2][0] = -(CR * SP * CY + SR * SY);
  matrix[2][1] = CY * SR - CR * SP * SY;
  matrix[2][2] = CR * CP;
  matrix[2][3] = 0;
  matrix[3][0] = 0;
  matrix[3][1] = 0;
  matrix[3][2] = 0;
  matrix[3][3] = 1;
  return matrix;
}

static Vector2 W2S(Vector3 worldLocation, CoViewInfo cam, int width, int height) {
  float fovRadian = cam.FOV * (float)(M_PI / 360.0);
  float tanFov = tanf(fovRadian);
  if (tanFov == 0) {
    tanFov = 0.001f;
  }
  float screenCenterX = width / 2.0f;
  float screenCenterY = height / 2.0f;
  FMatrix tempMatrix = RotToMatrix(cam.Rotation);
  Vector3 vAxisX(tempMatrix[0][0], tempMatrix[0][1], tempMatrix[0][2]);
  Vector3 vAxisY(tempMatrix[1][0], tempMatrix[1][1], tempMatrix[1][2]);
  Vector3 vAxisZ(tempMatrix[2][0], tempMatrix[2][1], tempMatrix[2][2]);
  Vector3 vDelta = worldLocation - cam.Location;
  float transformedX = Dot3(vDelta, vAxisY);
  float transformedY = Dot3(vDelta, vAxisZ);
  float transformedZ = Dot3(vDelta, vAxisX);
  if (transformedZ < 1.0f) {
    transformedZ = 1.0f;
  }
  return Vector2(screenCenterX + transformedX * (screenCenterX / tanFov) / transformedZ,
                 screenCenterY - transformedY * (screenCenterX / tanFov) / transformedZ);
}

static void BoxFromLoc(Vector3 worldLocation, VectorRect *rect, CoViewInfo cam, Vector2 canvasSize) {
  Vector3 head = worldLocation;
  head.Z += 85.f;
  Vector3 foot = worldLocation;
  foot.Z -= 85.f;
  Vector2 h = W2S(head, cam, (int)canvasSize.X, (int)canvasSize.Y);
  Vector2 f = W2S(foot, cam, (int)canvasSize.X, (int)canvasSize.Y);
  rect->h = (int)(f.Y - h.Y);
  rect->w = (int)(rect->h / 2.0f);
  rect->x = (int)(h.X - rect->w / 2.0f);
  rect->y = (int)h.Y;
}

@interface Step19EspHost () <MTKViewDelegate>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) MTKView *mtkView;
@property(nonatomic, strong) CADisplayLink *link;
@property(nonatomic, assign) CFTimeInterval startTime;
@property(nonatomic, assign) NSInteger frameCount;
@property(nonatomic, assign) CGFloat fps;
@property(nonatomic, assign) BOOL imguiOK;
@property(nonatomic, assign) BOOL contextReady;
@property(nonatomic, assign) BOOL refreshBusy;
@property(nonatomic, strong) NSString *statusLine;
@property(nonatomic, assign) NSInteger boxCount;
@end

@implementation Step19EspHost {
  std::vector<Step19Box> _boxes;
  NSLock *_boxLock;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    volatile const char *k17 = kStep17Keep;
    volatile const char *k18 = kStep18Keep;
    volatile const char *k19 = kStep19Marker;
    (void)k17[0];
    (void)k18[0];
    (void)k19[0];

    _boxLock = [[NSLock alloc] init];
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.userInteractionEnabled = NO;
    self.enabled = NO;
    self.borderStyle = UITextBorderStyleNone;
    self.startTime = CACurrentMediaTime();
    self.fps = 0;
    self.imguiOK = NO;
    self.contextReady = NO;
    self.statusLine = @"STEP19 waiting";
    self.boxCount = 0;

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

- (void)applyBoxes:(std::vector<Step19Box>)boxes status:(NSString *)status {
  [_boxLock lock];
  _boxes.swap(boxes);
  self.boxCount = (NSInteger)_boxes.size();
  [_boxLock unlock];
  self.statusLine = status;
  self.refreshBusy = NO;
}

- (void)refreshEspAsync {
  if (self.refreshBusy) {
    return;
  }
  if (![Step18ReadProbe isReadingEnabled]) {
    [self applyBoxes:{} status:@"reading=0"];
    return;
  }
  uint64_t base = [Step18ReadProbe moduleBase];
  pid_t pid = [Step18ReadProbe gamePid];
  if (pid <= 1 || base == 0) {
    self.statusLine = [Step18ReadProbe statusSummary];
    return;
  }

  self.refreshBusy = YES;
  CGFloat sw = self.bounds.size.width;
  CGFloat sh = self.bounds.size.height;
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    std::vector<Step19Box> local;
    NSString *status = @"lobby?";
    do {
      uint64_t gWorld = ReadPtr(base + SDK::GWorld);
      if (!IsValidAddr(gWorld)) {
        status = [NSString stringWithFormat:@"pid=%d base=0x%llx GWorld=0", (int)pid,
                                            (unsigned long long)base];
        break;
      }
      uint64_t netDriver = ReadPtr(gWorld + SDK::NetDriver);
      if (!IsValidAddr(netDriver)) {
        status = @"GWorld ok lobby NetDriver=0";
        break;
      }
      uint64_t serverConn = ReadPtr(netDriver + SDK::ServerConnection);
      uint64_t pc = ReadPtr(serverConn + SDK::PlayerController);
      uint64_t pcm = ReadPtr(pc + SDK::PlayerCameraManager);
      uint64_t myChar = ReadPtr(pc + SDK::Character);
      int myTeam = 0;
      ReadVal(pc + SDK::MyTeamID, &myTeam);

      CoViewInfo pov{};
      if (!IsValidAddr(pcm) || !ReadVal(pcm + SDK::ViewTarget, &pov)) {
        status = @"PCM/POV read fail";
        break;
      }
      if (!(pov.FOV > 1.0f && pov.FOV <= 170.0f)) {
        pov.FOV = 90.0f;
      }

      uint64_t level = ReadPtr(gWorld + SDK::PersistentLevel);
      uint64_t actorArray = ReadPtr(level + SDK::ActorArray);
      int actorCount = 0;
      ReadVal(level + SDK::ActorCount, &actorCount);
      if (!IsValidAddr(actorArray) || actorCount <= 0 || actorCount >= 50000) {
        status = [NSString stringWithFormat:@"actors=%d", actorCount];
        break;
      }

      int scanned = 0;
      const int kMaxScan = (actorCount < 8000) ? actorCount : 8000;
      for (int i = 0; i < kMaxScan; ++i) {
        uint64_t actor = ReadPtr(actorArray + (uint64_t)i * 8ULL);
        if (!IsValidAddr(actor) || actor == myChar) {
          continue;
        }
        float speed = 0;
        if (!ReadVal(actor + SDK::DefaultSpeedValue, &speed) || speed != 479.5f) {
          continue;
        }
        scanned++;
        int team = 0;
        ReadVal(actor + SDK::TeamID, &team);
        if (team == myTeam || team == -1) {
          continue;
        }
        bool isAI = false;
        ReadVal(actor + SDK::bIsAI, &isAI);

        uint64_t root = ReadPtr(actor + SDK::RootComponent);
        Vector3 loc{};
        if (!IsValidAddr(root) || !ReadVal(root + SDK::RelativeLocation, &loc)) {
          continue;
        }

        VectorRect rect{};
        BoxFromLoc(loc, &rect, pov, Vector2((float)sw, (float)sh));
        if (rect.w < 2 || rect.h < 4) {
          continue;
        }
        float dist = Dist3(loc, pov.Location) / 100.0f;
        Step19Box b;
        b.x = (float)rect.x;
        b.y = (float)rect.y;
        b.w = (float)rect.w;
        b.h = (float)rect.h;
        b.dist = dist;
        b.ai = isAI;
        local.push_back(b);
        if (local.size() >= 48) {
          break;
        }
      }
      status = [NSString stringWithFormat:@"ESP boxes=%zu scanP=%d fov=%.0f", local.size(), scanned,
                                          pov.FOV];
    } while (0);

    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf applyBoxes:std::move(local) status:status];
    });
  });
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
  static CFTimeInterval lastEsp = 0;
  if (now - lastEsp >= 0.20) {
    lastEsp = now;
    [self refreshEspAsync];
  }
  if (self.mtkView) {
    [self.mtkView setNeedsDisplay];
  }
}

- (void)drawEspPrimitives {
  CGFloat w = self.mtkView.bounds.size.width;
  CGFloat h = self.mtkView.bounds.size.height;
  if (w < 1 || h < 1) {
    return;
  }
  ImDrawList *dl = BBZGUI::GetForegroundDrawList();
  ImU32 textCol = IM_COL32(160, 255, 180, 255);
  ImU32 crossCol = IM_COL32(90, 255, 190, 200);

  float cx = (float)(w * 0.5);
  float cy = (float)(h * 0.5);
  dl->AddLine(ImVec2(cx - 12, cy), ImVec2(cx + 12, cy), crossCol, 1.5f);
  dl->AddLine(ImVec2(cx, cy - 12), ImVec2(cx, cy + 12), crossCol, 1.5f);

  char title[128];
  snprintf(title, sizeof(title), "STEP19-THINESP  fps=%.0f  n=%ld", (double)self.fps,
           (long)self.boxCount);
  float top = (float)self.safeAreaInsets.top + 56.0f;
  dl->AddText(ImVec2(16.0f, top), textCol, title);
  NSString *st = self.statusLine ?: @"";
  dl->AddText(ImVec2(16.0f, top + 18.0f), IM_COL32(220, 220, 220, 230), st.UTF8String);

  [_boxLock lock];
  std::vector<Step19Box> snap = _boxes;
  [_boxLock unlock];
  for (const Step19Box &b : snap) {
    ImU32 col = b.ai ? IM_COL32(120, 200, 255, 230) : IM_COL32(255, 90, 90, 240);
    dl->AddRect(ImVec2(b.x, b.y), ImVec2(b.x + b.w, b.y + b.h), col, 0.0f, 0, 1.5f);
    char distBuf[32];
    snprintf(distBuf, sizeof(distBuf), "%.0fm", b.dist);
    dl->AddText(ImVec2(b.x, b.y - 14.0f), col, distBuf);
  }
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
    io.DisplayFramebufferScale = ImVec2(view.contentScaleFactor, view.contentScaleFactor);
    io.DeltaTime = self.link ? (float)self.link.duration : (1.0f / 60.0f);
    if (io.DeltaTime <= 0.0f) {
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
    [self drawEspPrimitives];
    BBZGUI::Render();

    id<MTLRenderCommandEncoder> enc = [commandBuffer renderCommandEncoderWithDescriptor:pass];
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
