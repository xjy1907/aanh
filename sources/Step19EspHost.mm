//
//  Step19EspHost.mm
//  薄 ESP：方框/射线/血量/信息/距离/手持/骨骼/背敌/人数（对齐 753e2e1 DrawView，无 PhysX）
//

#import "Step19EspHost.h"
#import "Step18ReadProbe.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import <string.h>
#import <string>
#import <vector>

#import "BBZGui.h"
#import "BBZGui_impl_metal.h"
#import "NHIdentity.h"
#import "SDK.h"
#import "绘制类型.h"
#import "武器名称.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

__attribute__((used)) static const char kStep17Keep[] = "STEP17-IMGUI";
__attribute__((used)) static const char kStep18Keep[] = "STEP18-READPROBE";
__attribute__((used)) static const char kStep19Marker[] = "STEP19-THINESP";

#pragma mark - Math / read helpers

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

static void WorldToCameraSpace(Vector3 worldLocation, CoViewInfo cam, float *outRight, float *outUp,
                               float *outForward) {
  FMatrix tempMatrix = RotToMatrix(cam.Rotation);
  Vector3 vAxisX(tempMatrix[0][0], tempMatrix[0][1], tempMatrix[0][2]);
  Vector3 vAxisY(tempMatrix[1][0], tempMatrix[1][1], tempMatrix[1][2]);
  Vector3 vAxisZ(tempMatrix[2][0], tempMatrix[2][1], tempMatrix[2][2]);
  Vector3 vDelta = worldLocation - cam.Location;
  if (outRight)
    *outRight = Dot3(vDelta, vAxisY);
  if (outUp)
    *outUp = Dot3(vDelta, vAxisZ);
  if (outForward)
    *outForward = Dot3(vDelta, vAxisX);
}

static float BehindAimAngle(Vector3 worldLocation, CoViewInfo cam) {
  float tx = 0.f, ty = 0.f, tz = 0.f;
  WorldToCameraSpace(worldLocation, cam, &tx, &ty, &tz);
  float dx = tx;
  float dy = -ty;
  if (dx * dx + dy * dy < 1e-8f) {
    return (tz < 0.f) ? ((float)M_PI * 0.5f) : 0.f;
  }
  return atan2f(dy, dx);
}

static Vector2 W2S(Vector3 worldLocation, CoViewInfo cam, int width, int height) {
  float fovRadian = cam.FOV * (float)(M_PI / 360.0);
  float tanFov = tanf(fovRadian);
  if (tanFov == 0) {
    tanFov = 0.001f;
  }
  float screenCenterX = width / 2.0f;
  float screenCenterY = height / 2.0f;
  float transformedX = 0.f, transformedY = 0.f, transformedZ = 0.f;
  WorldToCameraSpace(worldLocation, cam, &transformedX, &transformedY, &transformedZ);
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

static D3DXMATRIX ToMatrixWithScale(Vector4 rotation, Vector3 translation, Vector3 scale3D) {
  D3DXMATRIX ret{};
  ret._41 = translation.X;
  ret._42 = translation.Y;
  ret._43 = translation.Z;
  float x2 = rotation.x * 2, y2 = rotation.y * 2, z2 = rotation.z * 2;
  float xx2 = rotation.x * x2, yy2 = rotation.y * y2, zz2 = rotation.z * z2;
  ret._11 = (1 - (yy2 + zz2)) * scale3D.X;
  ret._22 = (1 - (xx2 + zz2)) * scale3D.Y;
  ret._33 = (1 - (xx2 + yy2)) * scale3D.Z;
  float yz2 = rotation.y * z2, wx2 = rotation.w * x2;
  ret._32 = (yz2 - wx2) * scale3D.Z;
  ret._23 = (yz2 + wx2) * scale3D.Y;
  float xy2 = rotation.x * y2, wz2 = rotation.w * z2;
  ret._21 = (xy2 - wz2) * scale3D.Y;
  ret._12 = (xy2 + wz2) * scale3D.X;
  float xz2 = rotation.x * z2, wy2 = rotation.w * y2;
  ret._31 = (xz2 + wy2) * scale3D.Z;
  ret._13 = (xz2 - wy2) * scale3D.X;
  ret._44 = 1.f;
  return ret;
}

static D3DXMATRIX MatrixMultiplication(D3DXMATRIX M1, D3DXMATRIX M2) {
  D3DXMATRIX ret;
  ret._11 = M1._11 * M2._11 + M1._12 * M2._21 + M1._13 * M2._31 + M1._14 * M2._41;
  ret._12 = M1._11 * M2._12 + M1._12 * M2._22 + M1._13 * M2._32 + M1._14 * M2._42;
  ret._13 = M1._11 * M2._13 + M1._12 * M2._23 + M1._13 * M2._33 + M1._14 * M2._43;
  ret._14 = M1._11 * M2._14 + M1._12 * M2._24 + M1._13 * M2._34 + M1._14 * M2._44;
  ret._21 = M1._21 * M2._11 + M1._22 * M2._21 + M1._23 * M2._31 + M1._24 * M2._41;
  ret._22 = M1._21 * M2._12 + M1._22 * M2._22 + M1._23 * M2._32 + M1._24 * M2._42;
  ret._23 = M1._21 * M2._13 + M1._22 * M2._23 + M1._23 * M2._33 + M1._24 * M2._43;
  ret._24 = M1._21 * M2._14 + M1._22 * M2._24 + M1._23 * M2._34 + M1._24 * M2._44;
  ret._31 = M1._31 * M2._11 + M1._32 * M2._21 + M1._33 * M2._31 + M1._34 * M2._41;
  ret._32 = M1._31 * M2._12 + M1._32 * M2._22 + M1._33 * M2._32 + M1._34 * M2._42;
  ret._33 = M1._31 * M2._13 + M1._32 * M2._23 + M1._33 * M2._33 + M1._34 * M2._43;
  ret._34 = M1._31 * M2._14 + M1._32 * M2._24 + M1._33 * M2._34 + M1._34 * M2._44;
  ret._41 = M1._41 * M2._11 + M1._42 * M2._21 + M1._43 * M2._31 + M1._44 * M2._41;
  ret._42 = M1._41 * M2._12 + M1._42 * M2._22 + M1._43 * M2._32 + M1._44 * M2._42;
  ret._43 = M1._41 * M2._13 + M1._42 * M2._23 + M1._43 * M2._33 + M1._44 * M2._43;
  ret._44 = M1._41 * M2._14 + M1._42 * M2._24 + M1._43 * M2._34 + M1._44 * M2._44;
  return ret;
}

static Vector3 GetBoneWithRotation(uint64_t staticMesh, int boneId, FTransform componentToWorld) {
  FTransform bone{};
  if (!ReadVal(staticMesh + (uint64_t)boneId * (uint64_t)SDK::BoneTransformSize, &bone)) {
    return Vector3();
  }
  D3DXMATRIX local = ToMatrixWithScale(bone.Rotation, bone.Translation, bone.Scale3D);
  D3DXMATRIX world =
      ToMatrixWithScale(componentToWorld.Rotation, componentToWorld.Translation, componentToWorld.Scale3D);
  D3DXMATRIX out = MatrixMultiplication(local, world);
  return Vector3(out._41, out._42, out._43);
}

static const int SkeletonList_Default[14][2] = {{6, 5},   {5, 1},   {5, 12},  {12, 13}, {13, 14},
                                               {5, 34},  {34, 35}, {35, 36}, {1, 56},  {56, 57},
                                               {57, 58}, {1, 60},  {60, 61}, {61, 62}};
static const int SkeletonList_61[14][2] = {{6, 5},   {5, 1},  {5, 8},  {8, 9},  {9, 10}, {5, 29},
                                          {29, 30}, {30, 31}, {1, 49}, {49, 50}, {50, 51}, {1, 53},
                                          {53, 54}, {54, 55}};
static const int SkeletonList_65[14][2] = {{6, 5},   {5, 1},  {5, 12}, {12, 13}, {13, 14}, {5, 33},
                                          {33, 34}, {34, 35}, {1, 53}, {53, 54}, {54, 55}, {1, 57},
                                          {57, 58}, {58, 59}};
static const int SkeletonList_70[14][2] = {{28, 5},  {5, 1},  {28, 7}, {7, 8},  {8, 9},  {28, 35},
                                          {35, 36}, {36, 37}, {1, 56}, {56, 57}, {57, 58}, {1, 60},
                                          {60, 61}, {61, 62}};

static inline const int (*GetSkeletonList(int boneCount))[2] {
  switch (boneCount) {
    case 61:
      return SkeletonList_61;
    case 65:
    case 66:
      return SkeletonList_65;
    case 70:
    case 71:
      return SkeletonList_70;
    default:
      return SkeletonList_Default;
  }
}

static std::string ReadPlayerName(uint64_t player) {
  uint64_t data = ReadPtr(player + SDK::PlayerName);
  if (!IsValidAddr(data)) {
    return "";
  }
  int32_t nameLen = 0;
  if (!ReadVal(player + SDK::PlayerName + 0x8, &nameLen) || nameLen <= 0 || nameLen > 32) {
    nameLen = 16;
  }
  uint16_t buf[33] = {0};
  if (!ReadBytes(data, buf, (size_t)nameLen * sizeof(uint16_t))) {
    return "";
  }
  NSString *ns = [[NSString alloc] initWithBytes:buf
                                          length:(NSUInteger)nameLen * sizeof(uint16_t)
                                        encoding:NSUTF16LittleEndianStringEncoding];
  if (ns.length == 0) {
    return "";
  }
  return std::string(ns.UTF8String ?: "");
}

#pragma mark - Entity

struct Step19BoneSeg {
  float x0, y0, x1, y1;
};

struct Step19Entity {
  float boxX, boxY, boxW, boxH;
  float headX, headY;
  float health;
  float dist;
  int team;
  bool ai;
  bool onScreen;
  bool behind;
  float behindAngle;
  char name[48];
  char weapon[40];
  Step19BoneSeg bones[14];
  int boneSegCount;
};

struct Step19EspFlags {
  bool count = true;
  bool line = true;
  bool box = true;
  bool health = true;
  bool info = true;
  bool bone = true;
  bool weapon = true;
  bool dist = true;
  bool behind = true;
  bool hideAi = false;
  float drawDist = 400.f;
  float behindDist = 252.f;
  float boneDist = 120.f;
};

static Step19EspFlags LoadEspFlags(void) {
  Step19EspFlags f;
  NSDictionary *cfg = NHPrefsRead();
  if (!cfg) {
    // 验收默认全开（对齐 753e2e1 功能面）
    return f;
  }
  // prefs 有键则跟用户；无键保持默认 true
  if (cfg[@"count"] != nil)
    f.count = [cfg[@"count"] boolValue];
  if (cfg[@"line"] != nil)
    f.line = [cfg[@"line"] boolValue];
  if (cfg[@"box"] != nil)
    f.box = [cfg[@"box"] boolValue];
  if (cfg[@"health"] != nil)
    f.health = [cfg[@"health"] boolValue];
  if (cfg[@"info"] != nil)
    f.info = [cfg[@"info"] boolValue];
  if (cfg[@"bone"] != nil)
    f.bone = [cfg[@"bone"] boolValue];
  if (cfg[@"weapon"] != nil)
    f.weapon = [cfg[@"weapon"] boolValue];
  if (cfg[@"dist"] != nil)
    f.dist = [cfg[@"dist"] boolValue];
  if (cfg[@"behind"] != nil)
    f.behind = [cfg[@"behind"] boolValue];
  if (cfg[@"hideAi"] != nil)
    f.hideAi = [cfg[@"hideAi"] boolValue];
  if (cfg[@"drawDist"] != nil)
    f.drawDist = [cfg[@"drawDist"] floatValue];
  if (cfg[@"behindDist"] != nil)
    f.behindDist = [cfg[@"behindDist"] floatValue];
  if (cfg[@"boneDist"] != nil)
    f.boneDist = [cfg[@"boneDist"] floatValue];
  if (f.drawDist < 50.f)
    f.drawDist = 400.f;
  return f;
}

#pragma mark - Host

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
@property(nonatomic, assign) NSInteger entityCount;
@property(nonatomic, assign) NSInteger playerCount;
@property(nonatomic, assign) NSInteger aiCount;
@property(nonatomic, assign) CGFloat canvasW;
@property(nonatomic, assign) CGFloat canvasH;
@end

@implementation Step19EspHost {
  std::vector<Step19Entity> _ents;
  NSLock *_entLock;
  Step19EspFlags _flags;
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

    _entLock = [[NSLock alloc] init];
    _flags = LoadEspFlags();
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
    self.entityCount = 0;
    self.playerCount = 0;
    self.aiCount = 0;
    self.canvasW = frame.size.width;
    self.canvasH = frame.size.height;

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

- (void)applyCanvasWidth:(CGFloat)width height:(CGFloat)height {
  if (width < 1 || height < 1) {
    return;
  }
  self.canvasW = width;
  self.canvasH = height;
  self.mtkView.frame = CGRectMake(0, 0, width, height);
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
  if (self.canvasW > 1 && self.canvasH > 1) {
    self.mtkView.frame = CGRectMake(0, 0, self.canvasW, self.canvasH);
  } else {
    self.mtkView.frame = self.bounds;
  }
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

- (void)applyEntities:(std::vector<Step19Entity>)ents
               status:(NSString *)status
            playerCnt:(NSInteger)pc
               aiCnt:(NSInteger)ac {
  [_entLock lock];
  _ents.swap(ents);
  self.entityCount = (NSInteger)_ents.size();
  [_entLock unlock];
  self.playerCount = pc;
  self.aiCount = ac;
  self.statusLine = status;
  self.refreshBusy = NO;
}

- (void)refreshEspAsync {
  if (self.refreshBusy) {
    return;
  }
  if (![Step18ReadProbe isReadingEnabled]) {
    [self applyEntities:{} status:@"reading=0" playerCnt:0 aiCnt:0];
    return;
  }
  uint64_t base = [Step18ReadProbe moduleBase];
  pid_t pid = [Step18ReadProbe gamePid];
  if (pid <= 1 || base == 0) {
    self.statusLine = [Step18ReadProbe statusSummary];
    return;
  }

  self.refreshBusy = YES;
  _flags = LoadEspFlags();
  Step19EspFlags flags = _flags;
  CGFloat sw = self.canvasW > 1 ? self.canvasW : self.bounds.size.width;
  CGFloat sh = self.canvasH > 1 ? self.canvasH : self.bounds.size.height;
  if (sw < 1)
    sw = 1;
  if (sh < 1)
    sh = 1;
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    std::vector<Step19Entity> local;
    NSString *status = @"lobby?";
    NSInteger playerCnt = 0;
    NSInteger aiCnt = 0;
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
      Vector2 canvas((float)sw, (float)sh);

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
        if (flags.hideAi && isAI) {
          continue;
        }

        float hp = 0, hpMax = 0;
        ReadVal(actor + SDK::Health, &hp);
        ReadVal(actor + SDK::HealthMax, &hpMax);
        float health = (hpMax > 0.f) ? (hp / hpMax * 100.f) : 0.f;
        if (health > 100.f) {
          continue;
        }

        uint64_t root = ReadPtr(actor + SDK::RootComponent);
        Vector3 loc{};
        if (!IsValidAddr(root) || !ReadVal(root + SDK::RelativeLocation, &loc)) {
          continue;
        }

        float dist = Dist3(loc, pov.Location) / 100.0f;
        bool needBehind = flags.behind && !isAI && dist <= flags.behindDist;
        if (dist > flags.drawDist && !needBehind) {
          continue;
        }

        Vector3 headWorld = loc;
        headWorld.Z += 85.f;
        Vector2 headScreen = W2S(headWorld, pov, (int)sw, (int)sh);
        bool onScreen = headScreen.X > -80 && headScreen.X < sw + 80 && headScreen.Y > -80 &&
                        headScreen.Y < sh + 80;

        if (isAI) {
          aiCnt++;
        } else {
          playerCnt++;
        }

        Step19Entity e{};
        e.health = health;
        e.dist = dist;
        e.team = team;
        e.ai = isAI;
        e.onScreen = onScreen;
        e.headX = headScreen.X;
        e.headY = headScreen.Y;
        e.boneSegCount = 0;
        e.name[0] = 0;
        e.weapon[0] = 0;

        VectorRect rect{};
        BoxFromLoc(loc, &rect, pov, canvas);
        e.boxX = (float)rect.x;
        e.boxY = (float)rect.y;
        e.boxW = (float)rect.w;
        e.boxH = (float)rect.h;

        if (needBehind) {
          e.behind = true;
          e.behindAngle = BehindAimAngle(loc, pov);
        }

        if (onScreen && dist <= flags.drawDist) {
          if (flags.info) {
            if (!isAI) {
              std::string nm = ReadPlayerName(actor);
              if (!nm.empty()) {
                snprintf(e.name, sizeof(e.name), "%s", nm.c_str());
              }
            } else {
              snprintf(e.name, sizeof(e.name), "人机");
            }
          }
          if (flags.weapon) {
            uint64_t weaponPtr = ReadPtr(actor + SDK::CurrentUsingWeaponSafety);
            int weaponId = 0;
            if (IsValidAddr(weaponPtr)) {
              ReadVal(weaponPtr + SDK::RepWeaponID, &weaponId);
            }
            if (weaponId > 0) {
              std::string wn = GetWeaponDisplayName(weaponId);
              if (!wn.empty()) {
                snprintf(e.weapon, sizeof(e.weapon), "%s", wn.c_str());
              } else {
                snprintf(e.weapon, sizeof(e.weapon), "W%d", weaponId);
              }
            }
          }
          if (flags.bone && dist <= flags.boneDist) {
            uint64_t mesh = ReadPtr(actor + SDK::Mesh);
            if (IsValidAddr(mesh)) {
              uint64_t staticMesh = ReadPtr(mesh + SDK::StaticMesh);
              FTransform ctw{};
              if (IsValidAddr(staticMesh) && ReadVal(mesh + SDK::ComponentToWorld, &ctw)) {
                int boneCount = 0;
                ReadVal(mesh + SDK::StaticMesh + 0x8, &boneCount);
                const int(*skel)[2] = GetSkeletonList(boneCount);
                Vector2 boneScreen[128];
                bool boneOk[128];
                memset(boneOk, 0, sizeof(boneOk));
                for (int bi = 0; bi < 14; bi++) {
                  for (int j = 0; j < 2; j++) {
                    int idx = skel[bi][j];
                    if (idx < 0 || idx >= 128 || boneOk[idx])
                      continue;
                    Vector3 wp = GetBoneWithRotation(staticMesh, idx, ctw);
                    boneScreen[idx] = W2S(wp, pov, (int)sw, (int)sh);
                    boneOk[idx] = true;
                  }
                  int a = skel[bi][0], b = skel[bi][1];
                  if (a < 0 || a >= 128 || b < 0 || b >= 128 || !boneOk[a] || !boneOk[b])
                    continue;
                  if (e.boneSegCount >= 14)
                    break;
                  Step19BoneSeg &seg = e.bones[e.boneSegCount++];
                  seg.x0 = boneScreen[a].X;
                  seg.y0 = boneScreen[a].Y;
                  seg.x1 = boneScreen[b].X;
                  seg.y1 = boneScreen[b].Y;
                }
              }
            }
          }
        }

        local.push_back(e);
        if (local.size() >= 64) {
          break;
        }
      }
      status = [NSString stringWithFormat:@"ESP n=%zu P=%ld AI=%ld scan=%d fov=%.0f %.0fx%.0f",
                                          local.size(), (long)playerCnt, (long)aiCnt, scanned, pov.FOV, sw,
                                          sh];
    } while (0);

    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf applyEntities:std::move(local) status:status playerCnt:playerCnt aiCnt:aiCnt];
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
  if (now - lastEsp >= 0.15) {
    lastEsp = now;
    [self refreshEspAsync];
  }
  if (self.mtkView) {
    [self.mtkView setNeedsDisplay];
  }
}

- (void)drawBehindArrow:(ImDrawList *)dl angle:(float)angle dist:(float)dist sw:(float)sw sh:(float)sh {
  float cx = sw * 0.5f;
  float cy = sh * 0.5f;
  float radius = fminf(sw, sh) * 0.38f;
  float tipX = cx + cosf(angle) * radius;
  float tipY = cy + sinf(angle) * radius;
  float size = 14.f;
  ImVec2 pts[4];
  float ang = angle;
  float ox[4] = {size, -size * 0.55f, -size * 0.25f, -size * 0.55f};
  float oy[4] = {0, size * 0.7f, 0, -size * 0.7f};
  for (int i = 0; i < 4; i++) {
    float x = ox[i], y = oy[i];
    pts[i].x = tipX + x * cosf(ang) - y * sinf(ang);
    pts[i].y = tipY + x * sinf(ang) + y * cosf(ang);
  }
  ImU32 col = IM_COL32(255, 80, 80, 230);
  dl->AddConvexPolyFilled(pts, 4, col);
  dl->AddPolyline(pts, 4, IM_COL32(0, 0, 0, 220), ImDrawFlags_Closed, 1.2f);
  char db[16];
  snprintf(db, sizeof(db), "%d", (int)dist);
  dl->AddText(ImVec2(tipX - 10.f, tipY + 12.f), IM_COL32(255, 220, 220, 255), db);
}

- (void)drawEspPrimitives {
  CGFloat w = self.canvasW > 1 ? self.canvasW : self.mtkView.bounds.size.width;
  CGFloat h = self.canvasH > 1 ? self.canvasH : self.mtkView.bounds.size.height;
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

  char title[160];
  snprintf(title, sizeof(title), "STEP19-ESP  fps=%.0f  n=%ld  P=%ld AI=%ld", (double)self.fps,
           (long)self.entityCount, (long)self.playerCount, (long)self.aiCount);
  float top = 8.0f;
  if (_flags.count) {
    dl->AddText(ImVec2(16.0f, top), textCol, title);
    NSString *st = self.statusLine ?: @"";
    dl->AddText(ImVec2(16.0f, top + 18.0f), IM_COL32(220, 220, 220, 230), st.UTF8String);
  }

  [_entLock lock];
  std::vector<Step19Entity> snap = _ents;
  [_entLock unlock];

  for (const Step19Entity &e : snap) {
    ImU32 col = e.ai ? IM_COL32(120, 200, 255, 230) : IM_COL32(255, 90, 90, 240);
    ImU32 boneCol = e.ai ? IM_COL32(120, 200, 255, 220) : IM_COL32(0, 255, 140, 230);
    ImU32 lineCol = e.ai ? IM_COL32(120, 200, 255, 200) : IM_COL32(255, 120, 120, 220);

    if (e.behind) {
      // 全景背敌（对齐 DrawView 默认）
      [self drawBehindArrow:dl angle:e.behindAngle dist:e.dist sw:(float)w sh:(float)h];
    }

    if (!e.onScreen || e.dist > _flags.drawDist) {
      continue;
    }

    if (_flags.line) {
      dl->AddLine(ImVec2((float)w * 0.5f, 10.0f), ImVec2(e.headX, e.headY - 70.0f), lineCol, 1.2f);
    }

    if (_flags.box && e.boxW >= 2 && e.boxH >= 4) {
      dl->AddRect(ImVec2(e.boxX, e.boxY), ImVec2(e.boxX + e.boxW, e.boxY + e.boxH), col, 0.0f, 0, 1.5f);
    }

    if (_flags.health && e.health > 0) {
      ImU32 bloodColor;
      if (e.health >= 70)
        bloodColor = IM_COL32(0, 255, 0, 255);
      else if (e.health >= 35)
        bloodColor = IM_COL32(255, 255, 0, 255);
      else
        bloodColor = IM_COL32(255, 0, 0, 255);
      float healthRatio = fminf(e.health / 100.0f, 1.0f);
      const float barWidth = 50.0f;
      ImVec2 barPos(e.headX - barWidth / 2.0f, e.headY - 10.0f);
      float healthWidth = barWidth * healthRatio;
      dl->AddRectFilled(barPos, ImVec2(barPos.x + healthWidth, barPos.y + 7.0f), bloodColor, 3.5f);
      dl->AddRect(barPos, ImVec2(barPos.x + barWidth, barPos.y + 7.0f), IM_COL32(0, 0, 0, 200), 3.5f, 0,
                  1.0f);
    }

    if (_flags.info) {
      if (e.name[0]) {
        dl->AddText(ImVec2(e.headX - 20.0f, e.headY - 36.0f), col, e.name);
      }
      char teamBuf[16];
      snprintf(teamBuf, sizeof(teamBuf), "%d", e.team);
      dl->AddText(ImVec2(e.headX - 8.0f, e.headY - 52.0f), IM_COL32(255, 220, 80, 255), teamBuf);
    }

    if (_flags.dist) {
      char distBuf[16];
      snprintf(distBuf, sizeof(distBuf), "%d", (int)e.dist);
      dl->AddText(ImVec2(e.headX + 12.0f, e.headY - 52.0f), col, distBuf);
    }

    if (_flags.weapon && e.weapon[0]) {
      dl->AddText(ImVec2(e.headX - 20.0f, e.headY - 68.0f), IM_COL32(255, 220, 60, 255), e.weapon);
    }

    if (_flags.bone) {
      for (int i = 0; i < e.boneSegCount; i++) {
        const Step19BoneSeg &s = e.bones[i];
        dl->AddLine(ImVec2(s.x0, s.y0), ImVec2(s.x1, s.y1), boneCol, 1.4f);
      }
    }
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
    CGFloat dw = self.canvasW > 1 ? self.canvasW : view.bounds.size.width;
    CGFloat dh = self.canvasH > 1 ? self.canvasH : view.bounds.size.height;
    BBZGUIIO &io = BBZGUI::GetIO();
    io.DisplaySize = ImVec2((float)dw, (float)dh);
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
