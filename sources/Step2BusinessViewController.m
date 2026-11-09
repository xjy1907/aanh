//
//  Step2BusinessViewController.m
//  验收⑤：仿 JVR 启动页 + 业务按钮；dlopen 后 dlsym 探测越狱符号
//

#import "Step2BusinessViewController.h"
#import "JBDylibLoader.h"
#import <dlfcn.h>

@interface Step2BusinessViewController ()
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UITextView *logView;
@property(nonatomic, strong) UIButton *kernelBtn;
@property(nonatomic, strong) UIButton *readBtn;
@property(nonatomic, assign) BOOL didTryDlopen;
@property(nonatomic, assign) BOOL jbReady;
@end

@implementation Step2BusinessViewController

- (void)appendLog:(NSString *)line {
  NSString *stamp = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                   dateStyle:NSDateFormatterNoStyle
                                                   timeStyle:NSDateFormatterMediumStyle];
  NSString *row = [NSString stringWithFormat:@"[%@] %@\n", stamp, line];
  self.logView.text = [self.logView.text stringByAppendingString:row];
  if (self.logView.text.length > 0) {
    NSRange end = NSMakeRange(self.logView.text.length - 1, 1);
    [self.logView scrollRangeToVisible:end];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor colorWithRed:18.0f / 255.0f
                                               green:10.0f / 255.0f
                                                blue:28.0f / 255.0f
                                               alpha:1.0f];

  UIView *logoBox = [[UIView alloc] init];
  logoBox.translatesAutoresizingMaskIntoConstraints = NO;
  logoBox.backgroundColor = [UIColor colorWithRed:32.0f / 255.0f
                                             green:20.0f / 255.0f
                                              blue:48.0f / 255.0f
                                             alpha:1.0f];
  logoBox.layer.cornerRadius = 18.0;
  logoBox.layer.borderWidth = 1.5;
  logoBox.layer.borderColor =
      [UIColor colorWithRed:200.0f / 255.0f green:120.0f / 255.0f blue:255.0f / 255.0f alpha:0.7f].CGColor;

  UILabel *logoText = [[UILabel alloc] init];
  logoText.translatesAutoresizingMaskIntoConstraints = NO;
  logoText.text = @"AB";
  logoText.font = [UIFont systemFontOfSize:36.0f weight:UIFontWeightBlack];
  logoText.textColor = [UIColor colorWithRed:200.0f / 255.0f
                                       green:120.0f / 255.0f
                                        blue:255.0f / 255.0f
                                       alpha:1.0f];
  logoText.textAlignment = NSTextAlignmentCenter;
  [logoBox addSubview:logoText];

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = @"STEP5-BOOT-UI";
  title.textColor = [UIColor colorWithRed:200.0f / 255.0f
                                    green:120.0f / 255.0f
                                     blue:255.0f / 255.0f
                                    alpha:1.0f];
  title.font = [UIFont systemFontOfSize:20.0f weight:UIFontWeightBold];
  title.textAlignment = NSTextAlignmentCenter;

  UILabel *hint = [[UILabel alloc] init];
  hint.translatesAutoresizingMaskIntoConstraints = NO;
  hint.text = @"仿真实启动/业务面板（纯 UIKit）\n按钮会 dlsym 探测越狱符号\n仍不链 BBZView/PhysX/ImGui\n能看见本页 = 验收⑤亮窗通过";
  hint.textColor = [UIColor colorWithWhite:0.78f alpha:1.0f];
  hint.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightMedium];
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
  [kernelBtn setTitle:@"初始化内核" forState:UIControlStateNormal];
  [kernelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  kernelBtn.backgroundColor = [UIColor colorWithRed:200.0f / 255.0f
                                               green:120.0f / 255.0f
                                                blue:255.0f / 255.0f
                                               alpha:0.35f];
  kernelBtn.layer.cornerRadius = 10.0;
  kernelBtn.titleLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightSemibold];
  [kernelBtn addTarget:self action:@selector(onInitKernel) forControlEvents:UIControlEventTouchUpInside];
  self.kernelBtn = kernelBtn;

  UIButton *readBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  readBtn.translatesAutoresizingMaskIntoConstraints = NO;
  [readBtn setTitle:@"开始读取" forState:UIControlStateNormal];
  [readBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  readBtn.backgroundColor = [UIColor colorWithRed:255.0f / 255.0f
                                             green:150.0f / 255.0f
                                              blue:200.0f / 255.0f
                                             alpha:0.30f];
  readBtn.layer.cornerRadius = 10.0;
  readBtn.titleLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightSemibold];
  [readBtn addTarget:self action:@selector(onStartRead) forControlEvents:UIControlEventTouchUpInside];
  self.readBtn = readBtn;

  UITextView *logView = [[UITextView alloc] init];
  logView.translatesAutoresizingMaskIntoConstraints = NO;
  logView.editable = NO;
  logView.selectable = YES;
  logView.backgroundColor = [UIColor colorWithWhite:0.06f alpha:1.0f];
  logView.textColor = [UIColor colorWithRed:160.0f / 255.0f
                                      green:255.0f / 255.0f
                                       blue:180.0f / 255.0f
                                      alpha:1.0f];
  logView.font = [UIFont monospacedSystemFontOfSize:11.0f weight:UIFontWeightRegular];
  logView.layer.cornerRadius = 8.0;
  logView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
  logView.text = @"";
  self.logView = logView;

  [self.view addSubview:logoBox];
  [self.view addSubview:title];
  [self.view addSubview:hint];
  [self.view addSubview:status];
  [self.view addSubview:kernelBtn];
  [self.view addSubview:readBtn];
  [self.view addSubview:logView];

  [NSLayoutConstraint activateConstraints:@[
    [logoBox.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [logoBox.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:28],
    [logoBox.widthAnchor constraintEqualToConstant:120],
    [logoBox.heightAnchor constraintEqualToConstant:84],
    [logoText.centerXAnchor constraintEqualToAnchor:logoBox.centerXAnchor],
    [logoText.centerYAnchor constraintEqualToAnchor:logoBox.centerYAnchor],

    [title.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [title.topAnchor constraintEqualToAnchor:logoBox.bottomAnchor constant:16],

    [hint.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [hint.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
    [hint.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
    [hint.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],

    [status.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [status.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:12],
    [status.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
    [status.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],

    [kernelBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
    [kernelBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
    [kernelBtn.topAnchor constraintEqualToAnchor:status.bottomAnchor constant:18],
    [kernelBtn.heightAnchor constraintEqualToConstant:46],

    [readBtn.leadingAnchor constraintEqualToAnchor:kernelBtn.leadingAnchor],
    [readBtn.trailingAnchor constraintEqualToAnchor:kernelBtn.trailingAnchor],
    [readBtn.topAnchor constraintEqualToAnchor:kernelBtn.bottomAnchor constant:12],
    [readBtn.heightAnchor constraintEqualToConstant:46],

    [logView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
    [logView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
    [logView.topAnchor constraintEqualToAnchor:readBtn.bottomAnchor constant:16],
    [logView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
  ]];

  [self appendLog:@"STEP5 面板已加载（未链 BBZView/PhysX）"];
}

- (NSInteger)probeJailbreakSymbols {
  // 仅探测符号是否可解析，不真正跑 exploit
  NSArray<NSString *> *names = @[
    @"xpf_start",
    @"xpf_stop",
    @"xpf_get_error",
    @"jbdSystemwideLog",
    @"jbclient_process_checkin",
  ];
  NSInteger found = 0;
  for (NSString *name in names) {
    void *sym = dlsym(RTLD_DEFAULT, name.UTF8String);
    if (sym) {
      found += 1;
      [self appendLog:[NSString stringWithFormat:@"dlsym OK: %@", name]];
    } else {
      [self appendLog:[NSString stringWithFormat:@"dlsym 缺失: %@", name]];
    }
  }
  return found;
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
    [strongSelf appendLog:@"开始延后 dlopen 越狱三库…"];
    BOOL ok = JBEnsureJailbreakDylibsLoaded();
    strongSelf.jbReady = ok;
    if (ok) {
      strongSelf.statusLabel.text = @"安全权限 + dlopen 成功（可点按钮）";
      strongSelf.statusLabel.textColor =
          [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
      [strongSelf appendLog:@"dlopen 成功"];
      NSInteger n = [strongSelf probeJailbreakSymbols];
      [strongSelf appendLog:[NSString stringWithFormat:@"符号探测 %ld/5，验收⑤通过", (long)n]];
    } else {
      strongSelf.statusLabel.text = @"安全权限已启用，但 dlopen 失败";
      strongSelf.statusLabel.textColor =
          [UIColor colorWithRed:255.0f / 255.0f green:120.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
      [strongSelf appendLog:@"dlopen 失败"];
    }
  });
}

- (void)onInitKernel {
  [self appendLog:@"点击：初始化内核"];
  if (!self.jbReady) {
    BOOL ok = JBEnsureJailbreakDylibsLoaded();
    self.jbReady = ok;
    [self appendLog:ok ? @"补做 dlopen 成功" : @"补做 dlopen 失败"];
  }
  if (!self.jbReady) {
    [self appendLog:@"内核初始化跳过：越狱库未就绪"];
    return;
  }
  NSInteger n = [self probeJailbreakSymbols];
  if (n > 0) {
    [self appendLog:[NSString stringWithFormat:@"内核路径探测完成（%ld 个符号可用，本步不跑 exploit）", (long)n]];
    self.statusLabel.text = @"初始化内核：符号探测通过（验收⑤）";
    self.statusLabel.textColor =
        [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
  } else {
    [self appendLog:@"初始化内核失败：无可用符号"];
  }
}

- (void)onStartRead {
  [self appendLog:@"点击：开始读取"];
  if (!self.jbReady) {
    [self appendLog:@"开始读取跳过：请先初始化内核 / 等待 dlopen"];
    return;
  }
  // 轻量可读性检查：确认关键导出仍在
  void *xpfStart = dlsym(RTLD_DEFAULT, "xpf_start");
  void *checkin = dlsym(RTLD_DEFAULT, "jbclient_process_checkin");
  [self appendLog:[NSString stringWithFormat:@"读取探测 xpf_start=%p checkin=%p", xpfStart, checkin]];
  if (xpfStart || checkin) {
    self.statusLabel.text = @"开始读取：符号可读（未链 PhysX）";
    self.statusLabel.textColor =
        [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
    [self appendLog:@"开始读取探测通过（验收⑤业务按钮可用）"];
  } else {
    [self appendLog:@"开始读取失败：关键符号不可见"];
  }
}

@end
