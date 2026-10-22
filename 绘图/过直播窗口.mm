//
//  过直播窗口.mm - 直播/录屏隐藏功能
//

#import "过直播窗口.h"

@implementation 过直播窗口

- (instancetype)init {
    self = [super init];
    if (self) {
        [self 过直播方法];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self 过直播方法];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self 过直播方法];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self._UITextField.frame = self.bounds;
    self._UIView.frame = self.bounds;
    self._UIView.transform = self.transform;
    for (UIView* subview in self._UIView.subviews) {
        subview.frame = self._UIView.bounds;
    }
}

- (void)过直播方法 {
    [super addSubview:self._UITextField];
    self._UITextField.subviews.firstObject.userInteractionEnabled = YES;
    [self._UITextField.subviews.firstObject addSubview:self._UIView];
}

- (void)addSubview:(UIView *)view {
    [super addSubview:view];
    if (self._UITextField != view) {
        [self._UIView addSubview:view];
    }
}

- (UITextField *)_UITextField {
    if (!__UITextField) {
        __UITextField = [[UITextField alloc] init];
        __UITextField.secureTextEntry = YES;
        __UITextField.userInteractionEnabled = NO;
    }
    return __UITextField;
}

- (UIView *)_UIView {
    if (!__UIView) {
        __UIView = [[UIView alloc] init];
    }
    return __UIView;
}

@end
