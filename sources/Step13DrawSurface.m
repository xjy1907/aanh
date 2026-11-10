//
//  Step13DrawSurface.m
//

#import "Step13DrawSurface.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

__attribute__((used)) static const char kStep13Marker[] = "STEP13-DRAWSURF";

@interface Step13DrawSurface ()
@property(nonatomic, strong) CADisplayLink *link;
@property(nonatomic, assign) CFTimeInterval startTime;
@property(nonatomic, assign) NSInteger frameCount;
@property(nonatomic, assign) CGFloat fps;
@end

@implementation Step13DrawSurface

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    volatile const char *keep = kStep13Marker;
    (void)keep[0];
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
    self.opaque = NO;
    self.contentMode = UIViewContentModeRedraw;
    self.startTime = CACurrentMediaTime();
    self.fps = 0;
  }
  return self;
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
  [self setNeedsDisplay];
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
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  if (!ctx) {
    return;
  }

  CGFloat w = CGRectGetWidth(self.bounds);
  CGFloat h = CGRectGetHeight(self.bounds);
  CGFloat cx = w * 0.5f;
  CGFloat cy = h * 0.45f;
  CGFloat t = (CGFloat)CACurrentMediaTime();
  CGFloat pulse = 0.5f + 0.5f * sinf((float)t * 3.0f);

  // 半透明准星
  CGContextSetStrokeColorWithColor(
      ctx, [UIColor colorWithRed:0.4f green:1.0f blue:0.6f alpha:0.85f].CGColor);
  CGContextSetLineWidth(ctx, 2.0);
  CGFloat arm = 28.0f + 6.0f * pulse;
  CGContextMoveToPoint(ctx, cx - arm, cy);
  CGContextAddLineToPoint(ctx, cx + arm, cy);
  CGContextMoveToPoint(ctx, cx, cy - arm);
  CGContextAddLineToPoint(ctx, cx, cy + arm);
  CGContextStrokePath(ctx);

  // 演示框（模拟 ESP 盒子）
  CGFloat boxW = 90.0f + 10.0f * pulse;
  CGFloat boxH = 140.0f;
  CGRect box = CGRectMake(cx - boxW * 0.5f, cy - boxH * 0.55f, boxW, boxH);
  CGContextSetStrokeColorWithColor(
      ctx, [UIColor colorWithRed:0.85f green:0.45f blue:1.0f alpha:0.9f].CGColor);
  CGContextSetLineWidth(ctx, 1.5);
  CGContextStrokeRect(ctx, box);

  // 角标文字
  NSString *title = [NSString stringWithFormat:@"STEP13-DRAWSURF  fps=%.0f", self.fps];
  NSDictionary *attrs = @{
    NSFontAttributeName : [UIFont monospacedSystemFontOfSize:11.0f weight:UIFontWeightBold],
    NSForegroundColorAttributeName : [UIColor colorWithRed:0.6f green:1.0f blue:0.7f alpha:1.0f],
  };
  CGSize sz = [title sizeWithAttributes:attrs];
  [title drawAtPoint:CGPointMake(16.0f, self.safeAreaInsets.top + 56.0f) withAttributes:attrs];
  (void)sz;

  NSString *sub = @"轻量绘制面（未链 DrawView.mm / PhysX）";
  NSDictionary *subAttrs = @{
    NSFontAttributeName : [UIFont systemFontOfSize:10.0f weight:UIFontWeightMedium],
    NSForegroundColorAttributeName : [UIColor colorWithWhite:0.85f alpha:0.9f],
  };
  [sub drawAtPoint:CGPointMake(16.0f, self.safeAreaInsets.top + 72.0f) withAttributes:subAttrs];
}

- (void)dealloc {
  [self.link invalidate];
}

@end
