//
//  Step2BusinessViewController.m
//  验收④：轻量面板 + 延后 dlopen；本步验证正式 entitlements 不秒退
//

#import "Step2BusinessViewController.h"
#import "JBDylibLoader.h"

@interface Step2BusinessViewController ()
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, assign) BOOL didTryDlopen;
@end

@implementation Step2BusinessViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor colorWithRed:18.0f / 255.0f
                                               green:10.0f / 255.0f
                                                blue:28.0f / 255.0f
                                               alpha:1.0f];

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = @"STEP4-FULL-ENT";
  title.textColor = [UIColor colorWithRed:200.0f / 255.0f
                                    green:120.0f / 255.0f
                                     blue:255.0f / 255.0f
                                    alpha:1.0f];
  title.font = [UIFont systemFontOfSize:22.0f weight:UIFontWeightBold];
  title.textAlignment = NSTextAlignmentCenter;

  UILabel *hint = [[UILabel alloc] init];
  hint.translatesAutoresizingMaskIntoConstraints = NO;
  hint.text = @"正式 entitlements.plist（含 HUD/HID 私有权限）\n轻量 UI + 延后 dlopen，仍不链 BBZView/PhysX\n能看见本页 = 验收④通过";
  hint.textColor = [UIColor colorWithWhite:0.78f alpha:1.0f];
  hint.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightMedium];
  hint.textAlignment = NSTextAlignmentCenter;
  hint.numberOfLines = 0;

  UILabel *status = [[UILabel alloc] init];
  status.translatesAutoresizingMaskIntoConstraints = NO;
  status.text = @"越狱库：等待首屏后加载…";
  status.textColor = [UIColor colorWithRed:255.0f / 255.0f
                                     green:210.0f / 255.0f
                                      blue:120.0f / 255.0f
                                     alpha:1.0f];
  status.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightSemibold];
  status.textAlignment = NSTextAlignmentCenter;
  status.numberOfLines = 0;
  self.statusLabel = status;

  UIButton *kernelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  kernelBtn.translatesAutoresizingMaskIntoConstraints = NO;
  [kernelBtn setTitle:@"初始化内核（占位）" forState:UIControlStateNormal];
  [kernelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  kernelBtn.backgroundColor = [UIColor colorWithRed:200.0f / 255.0f
                                               green:120.0f / 255.0f
                                                blue:255.0f / 255.0f
                                               alpha:0.35f];
  kernelBtn.layer.cornerRadius = 10.0;
  kernelBtn.titleLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightSemibold];
  [kernelBtn addTarget:self
                action:@selector(onPlaceholderTap:)
      forControlEvents:UIControlEventTouchUpInside];

  UIButton *readBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  readBtn.translatesAutoresizingMaskIntoConstraints = NO;
  [readBtn setTitle:@"开始读取（占位）" forState:UIControlStateNormal];
  [readBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  readBtn.backgroundColor = [UIColor colorWithRed:255.0f / 255.0f
                                             green:150.0f / 255.0f
                                              blue:200.0f / 255.0f
                                             alpha:0.30f];
  readBtn.layer.cornerRadius = 10.0;
  readBtn.titleLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightSemibold];
  [readBtn addTarget:self
                action:@selector(onPlaceholderTap:)
      forControlEvents:UIControlEventTouchUpInside];

  [self.view addSubview:title];
  [self.view addSubview:hint];
  [self.view addSubview:status];
  [self.view addSubview:kernelBtn];
  [self.view addSubview:readBtn];

  [NSLayoutConstraint activateConstraints:@[
    [title.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [title.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-96],
    [hint.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [hint.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
    [hint.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
    [hint.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],
    [status.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [status.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:16],
    [status.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
    [status.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],
    [kernelBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
    [kernelBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
    [kernelBtn.topAnchor constraintEqualToAnchor:status.bottomAnchor constant:24],
    [kernelBtn.heightAnchor constraintEqualToConstant:48],
    [readBtn.leadingAnchor constraintEqualToAnchor:kernelBtn.leadingAnchor],
    [readBtn.trailingAnchor constraintEqualToAnchor:kernelBtn.trailingAnchor],
    [readBtn.topAnchor constraintEqualToAnchor:kernelBtn.bottomAnchor constant:14],
    [readBtn.heightAnchor constraintEqualToConstant:48],
  ]];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (self.didTryDlopen) {
    return;
  }
  self.didTryDlopen = YES;

  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    BOOL ok = JBEnsureJailbreakDylibsLoaded();
    if (ok) {
      strongSelf.statusLabel.text = @"正式权限 + dlopen 成功（验收④通过）";
      strongSelf.statusLabel.textColor =
          [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
    } else {
      strongSelf.statusLabel.text = @"正式权限已启用，但 dlopen 失败";
      strongSelf.statusLabel.textColor =
          [UIColor colorWithRed:255.0f / 255.0f green:120.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
    }
  });
}

- (void)onPlaceholderTap:(UIButton *)sender {
  NSString *name = sender.currentTitle ?: @"操作";
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"验收④"
                       message:[NSString stringWithFormat:@"「%@」仅为 UI 占位，未调用 PhysX/BBZView。", name]
                preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
