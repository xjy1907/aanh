//
//  Step16TfMetalHost.m
//

#import "Step16TfMetalHost.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>

__attribute__((used)) static const char kStep16Marker[] = "STEP16-TFHOST";

@interface Step16TfMetalHost () <MTKViewDelegate>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) MTKView *mtkView;
@property(nonatomic, strong) CADisplayLink *link;
@property(nonatomic, strong) CAShapeLayer *crossLayer;
@property(nonatomic, strong) CAShapeLayer *boxLayer;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *subLabel;
@property(nonatomic, assign) CFTimeInterval startTime;
@property(nonatomic, assign) NSInteger frameCount;
@property(nonatomic, assign) CGFloat fps;
@property(nonatomic, assign) BOOL metalOK;
@end

@implementation Step16TfMetalHost

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    volatile const char *keep = kStep16Marker;
    (void)keep[0];

    // 对标 wasd ImGuiDraw : UITextField
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.userInteractionEnabled = NO;
    self.enabled = NO;
    self.borderStyle = UITextBorderStyleNone;
    self.startTime = CACurrentMediaTime();
    self.fps = 0;

    self.device = MTLCreateSystemDefaultDevice();
    self.metalOK = (self.device != nil);
    if (self.metalOK) {
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
      // wasd: MTKView 必须挂在 UITextField 上
      [self addSubview:mtk];
      self.mtkView = mtk;
    }

    self.crossLayer = [CAShapeLayer layer];
    self.crossLayer.fillColor = [UIColor clearColor].CGColor;
    self.crossLayer.strokeColor =
        [UIColor colorWithRed:0.35f green:1.0f blue:0.75f alpha:0.95f].CGColor;
    self.crossLayer.lineWidth = 2.0;
    [self.layer addSublayer:self.crossLayer];

    self.boxLayer = [CAShapeLayer layer];
    self.boxLayer.fillColor = [UIColor clearColor].CGColor;
    self.boxLayer.strokeColor =
        [UIColor colorWithRed:0.85f green:0.45f blue:1.0f alpha:0.95f].CGColor;
    self.boxLayer.lineWidth = 1.5;
    [self.layer addSublayer:self.boxLayer];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.font = [UIFont monospacedSystemFontOfSize:11.0f weight:UIFontWeightBold];
    title.textColor = [UIColor colorWithRed:0.6f green:1.0f blue:0.7f alpha:1.0f];
    title.text = @"STEP16-TFHOST  fps=0";
    [self addSubview:title];
    self.titleLabel = title;

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectZero];
    sub.font = [UIFont systemFontOfSize:10.0f weight:UIFontWeightMedium];
    sub.textColor = [UIColor colorWithWhite:0.85f alpha:0.9f];
    sub.text = self.metalOK
                   ? @"UITextField+MTKView（未链 ImGui / PhysX / DrawView.mm）"
                   : @"Metal 不可用，降级几何层（仍不链 ImGui/PhysX）";
    [self addSubview:sub];
    self.subLabel = sub;
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.mtkView.frame = self.bounds;
  CGFloat top = self.safeAreaInsets.top + 56.0f;
  self.titleLabel.frame = CGRectMake(16.0f, top, self.bounds.size.width - 32.0f, 16.0f);
  self.subLabel.frame = CGRectMake(16.0f, top + 16.0f, self.bounds.size.width - 32.0f, 16.0f);
  [self refreshGeometry];
}

- (void)refreshGeometry {
  CGFloat w = CGRectGetWidth(self.bounds);
  CGFloat h = CGRectGetHeight(self.bounds);
  if (w < 1 || h < 1) {
    return;
  }
  CGFloat cx = w * 0.5f;
  CGFloat cy = h * 0.45f;
  CGFloat t = (CGFloat)CACurrentMediaTime();
  CGFloat pulse = 0.5f + 0.5f * sinf((float)t * 3.0f);
  CGFloat arm = 28.0f + 6.0f * pulse;

  UIBezierPath *cross = [UIBezierPath bezierPath];
  [cross moveToPoint:CGPointMake(cx - arm, cy)];
  [cross addLineToPoint:CGPointMake(cx + arm, cy)];
  [cross moveToPoint:CGPointMake(cx, cy - arm)];
  [cross addLineToPoint:CGPointMake(cx, cy + arm)];
  self.crossLayer.path = cross.CGPath;
  self.crossLayer.frame = self.bounds;

  CGFloat boxW = 90.0f + 10.0f * pulse;
  CGFloat boxH = 140.0f;
  CGRect box = CGRectMake(cx - boxW * 0.5f, cy - boxH * 0.55f, boxW, boxH);
  self.boxLayer.path = [UIBezierPath bezierPathWithRect:box].CGPath;
  self.boxLayer.frame = self.bounds;
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
    self.titleLabel.text =
        [NSString stringWithFormat:@"STEP16-TFHOST  fps=%.0f", self.fps];
  }
  [self refreshGeometry];
  if (self.mtkView) {
    [self.mtkView setNeedsDisplay];
  }
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
  (void)view;
  (void)size;
}

- (void)drawInMTKView:(MTKView *)view {
  if (!self.commandQueue) {
    return;
  }
  CGFloat t = (CGFloat)CACurrentMediaTime();
  CGFloat pulse = 0.5f + 0.5f * sinf((float)t * 2.2f);
  view.clearColor = MTLClearColorMake(0.08 * pulse, 0.12 * pulse, 0.22 * pulse, 0.08 * pulse);

  id<MTLCommandBuffer> cmd = [self.commandQueue commandBuffer];
  MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
  if (!pass) {
    return;
  }
  id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:pass];
  [enc endEncoding];
  id<MTLDrawable> drawable = view.currentDrawable;
  if (drawable) {
    [cmd presentDrawable:drawable];
  }
  [cmd commit];
}

- (void)dealloc {
  [self.link invalidate];
}

@end
