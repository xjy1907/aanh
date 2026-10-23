//
//  过直播窗口.mm — 完全参照 wasd sources/DrawRootViewController.mm
//

#import "过直播窗口.h"

@implementation 过直播窗口 {
    UIView *_attachedDrawView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildWasdStyleCovers];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)buildWasdStyleCovers {
    // —— 逐行对照 wasd DrawRootViewController viewDidLoad ——
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
    self.opaque = NO;

    // CoverView1 = [[UITextField alloc] init];
    _coverView1 = [[UITextField alloc] init];

    // CoverView = [[UITextField alloc] initWithFrame:...];
    _coverView = [[UITextField alloc] initWithFrame:self.bounds];
    _coverView.frame = self.bounds;

    // CoverView.subviews.firstObject.userInteractionEnabled = YES;  // 须在 add CoverView1 之前
    if (_coverView.subviews.count > 0) {
        _coverView.subviews.firstObject.userInteractionEnabled = YES;
    }
    _coverView.userInteractionEnabled = YES;
    _coverView.backgroundColor = [UIColor clearColor];

    // [CoverView addSubview:CoverView1];
    [_coverView addSubview:_coverView1];
    // [self.view addSubview:CoverView];
    [self addSubview:_coverView];

    _coverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _coverView1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _coverView1.frame = _coverView.bounds;
    _coverView1.backgroundColor = [UIColor clearColor];

    // 对标 wasd ImGuiDraw : UITextField —— MTKView 必须挂在 UITextField 上，不能直接挂 canvas
    _drawHost = [[UITextField alloc] initWithFrame:_coverView1.bounds];
    _drawHost.backgroundColor = [UIColor clearColor];
    _drawHost.opaque = NO;
    _drawHost.userInteractionEnabled = NO;
    _drawHost.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _coverView.frame = self.bounds;
    _coverView1.frame = _coverView.bounds;
    UIView *canvas = [self cover1Canvas];
    if (canvas) {
        _drawHost.frame = canvas.bounds;
    } else {
        _drawHost.frame = _coverView1.bounds;
    }
    // 横屏时 MetalView 由 BBZViewController 设 transform+bounds，这里不要用 frame 覆盖
    if (_attachedDrawView && CGAffineTransformIsIdentity(_attachedDrawView.transform)) {
        _attachedDrawView.frame = _drawHost.bounds;
    }
}

- (UIView *)cover1Canvas {
    // CoverView1 的内部 canvas；跳过我们手动加的 drawHost
    for (UIView *v in _coverView1.subviews) {
        if (v == _drawHost) continue;
        return v;
    }
    return nil;
}

- (void)attachDrawView:(UIView *)drawView {
    if (!drawView) return;
    _attachedDrawView = drawView;

    drawView.translatesAutoresizingMaskIntoConstraints = YES;
    drawView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // wasd: [CoverView1.subviews.firstObject addSubview:DrawView];
    // DrawView(=ImGuiDraw) 本身是 UITextField，再 [self addSubview:mtkView]
    [_coverView1 layoutIfNeeded];
    UIView *canvas = [self cover1Canvas];
    if (!canvas && _coverView1.subviews.count > 0) {
        canvas = _coverView1.subviews.firstObject;
        if (canvas == _drawHost) canvas = nil;
    }

    if (canvas) {
        canvas.userInteractionEnabled = YES;
        if (_drawHost.superview != canvas) {
            [canvas addSubview:_drawHost];
        }
        _drawHost.frame = canvas.bounds;
    } else {
        // canvas 尚未创建时先挂到 CoverView1，secure 切换后会再挪
        if (_drawHost.superview != _coverView1) {
            [_coverView1 addSubview:_drawHost];
        }
        _drawHost.frame = _coverView1.bounds;
    }

    if (drawView.superview != _drawHost) {
        [_drawHost addSubview:drawView];
    }
    drawView.frame = _drawHost.bounds;
}

- (void)setLiveHidden:(BOOL)hidden {
    // wasd:
    //   CoverView.secureTextEntry = live;
    //   CoverView1.secureTextEntry = live;
    _coverView.secureTextEntry = hidden;
    _coverView1.secureTextEntry = hidden;

    if (_coverView.subviews.firstObject) {
        _coverView.subviews.firstObject.userInteractionEnabled = YES;
    }

    // secure 切换会重建内部 canvas，必须把 drawHost / Metal 重新挂回去
    [_coverView1 layoutIfNeeded];
    [self attachDrawView:_attachedDrawView];
}

@end
