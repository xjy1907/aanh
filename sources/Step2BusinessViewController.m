//
//  Step2BusinessViewController.m
//  验收⑦：用 Dopamine 方式拿可读 kernelcache，再调 XPF
//

#import "Step2BusinessViewController.h"
#import "JBDylibLoader.h"
#import "KernelcacheLocator.h"
#import <dlfcn.h>

typedef int (*XpfStartFn)(const char *kernelPath);
typedef void (*XpfStopFn)(void);
typedef const char *(*XpfGetErrorFn)(void);
typedef char *(*JbGetBootUuidFn)(void);
typedef char *(*JbGetJbrootFn)(void);
typedef int (*JbProcessCheckinFn)(char **rootPathOut, char **bootUUIDOut,
                                  char **sandboxExtensionsOut, bool *fullyDebuggedOut);

@interface Step2BusinessViewController ()
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UITextView *logView;
@property(nonatomic, strong) UIButton *kernelBtn;
@property(nonatomic, strong) UIButton *readBtn;
@property(nonatomic, assign) BOOL didTryDlopen;
@property(nonatomic, assign) BOOL jbReady;
@property(nonatomic, assign) BOOL xpfStarted;
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

- (void *)sym:(NSString *)name {
  void *p = dlsym(RTLD_DEFAULT, name.UTF8String);
  if (!p && name.length > 0 && [name characterAtIndex:0] != '_') {
    p = dlsym(RTLD_DEFAULT, [@"_" stringByAppendingString:name].UTF8String);
  }
  return p;
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
  title.text = @"STEP7-KERNELCACHE";
  title.textColor = [UIColor colorWithRed:200.0f / 255.0f
                                    green:120.0f / 255.0f
                                     blue:255.0f / 255.0f
                                    alpha:1.0f];
  title.font = [UIFont systemFontOfSize:20.0f weight:UIFontWeightBold];
  title.textAlignment = NSTextAlignmentCenter;

  UILabel *hint = [[UILabel alloc] init];
  hint.translatesAutoresizingMaskIntoConstraints = NO;
  hint.text = @"对齐 Dopamine 取可读 kernelcache\npreboot/可读检测/grab 下载回退\n仍不链 BBZView/PhysX/DOJailbreaker\n能看见本页 = 验收⑦亮窗通过";
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
  [kernelBtn setTitle:@"初始化内核（XPF）" forState:UIControlStateNormal];
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
  [readBtn setTitle:@"开始读取（jbclient）" forState:UIControlStateNormal];
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

  [self appendLog:@"STEP7 面板已加载（未链 BBZView/PhysX）"];
}

- (NSInteger)probeJailbreakSymbols {
  // 使用库内真实导出名（⑤ 误用了 xpf_start / jbdSystemwideLog）
  NSArray<NSString *> *names = @[
    @"xpf_start_with_kernel_path",
    @"xpf_stop",
    @"xpf_get_error",
    @"jbclient_get_boot_uuid",
    @"jbclient_process_checkin",
  ];
  NSInteger found = 0;
  for (NSString *name in names) {
    void *sym = [self sym:name];
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
      [strongSelf appendLog:[NSString stringWithFormat:@"符号探测 %ld/5", (long)n]];
    } else {
      strongSelf.statusLabel.text = @"安全权限已启用，但 dlopen 失败";
      strongSelf.statusLabel.textColor =
          [UIColor colorWithRed:255.0f / 255.0f green:120.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
      [strongSelf appendLog:@"dlopen 失败"];
    }
  });
}

- (void)onInitKernel {
  [self appendLog:@"点击：初始化内核（XPF）"];
  if (!self.jbReady) {
    self.jbReady = JBEnsureJailbreakDylibsLoaded();
    [self appendLog:self.jbReady ? @"补做 dlopen 成功" : @"补做 dlopen 失败"];
  }
  if (!self.jbReady) {
    [self appendLog:@"跳过：越狱库未就绪"];
    return;
  }

  XpfStartFn startFn = (XpfStartFn)[self sym:@"xpf_start_with_kernel_path"];
  XpfStopFn stopFn = (XpfStopFn)[self sym:@"xpf_stop"];
  XpfGetErrorFn errFn = (XpfGetErrorFn)[self sym:@"xpf_get_error"];
  if (!startFn) {
    [self appendLog:@"失败：找不到 xpf_start_with_kernel_path"];
    return;
  }

  __weak typeof(self) weakSelf = self;
  NSString *path = [KernelcacheLocator accessibleKernelPathWithLog:^(NSString *line) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    [strongSelf appendLog:line];
  }];
  if (!path) {
    self.statusLabel.text = @"无可用 kernelcache（见日志）";
    self.statusLabel.textColor =
        [UIColor colorWithRed:255.0f / 255.0f green:120.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
    [self appendLog:@"验收⑦：未能拿到可读 kernelcache"];
    return;
  }
  [self appendLog:[NSString stringWithFormat:@"最终 kernelcache=%@", path]];

  if (self.xpfStarted && stopFn) {
    stopFn();
    self.xpfStarted = NO;
    [self appendLog:@"已 xpf_stop 旧会话"];
  }

  int rc = startFn(path.fileSystemRepresentation);
  const char *err = errFn ? errFn() : NULL;
  [self appendLog:[NSString stringWithFormat:@"xpf_start_with_kernel_path rc=%d err=%s", rc,
                                             (err && err[0]) ? err : "(null)"]];

  if (rc == 0) {
    self.xpfStarted = YES;
    self.statusLabel.text = @"可读核 + XPF 成功（验收⑦）";
    self.statusLabel.textColor =
        [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
    [self appendLog:@"验收⑦：kernelcache 可读且 XPF 启动成功"];
  } else {
    self.statusLabel.text = @"XPF 启动失败（见日志）";
    self.statusLabel.textColor =
        [UIColor colorWithRed:255.0f / 255.0f green:120.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
  }
}

- (void)onStartRead {
  [self appendLog:@"点击：开始读取（jbclient）"];
  if (!self.jbReady) {
    [self appendLog:@"跳过：请先 dlopen / 初始化"];
    return;
  }

  JbGetBootUuidFn uuidFn = (JbGetBootUuidFn)[self sym:@"jbclient_get_boot_uuid"];
  JbGetJbrootFn rootFn = (JbGetJbrootFn)[self sym:@"jbclient_get_jbroot"];
  JbProcessCheckinFn checkinFn = (JbProcessCheckinFn)[self sym:@"jbclient_process_checkin"];

  if (uuidFn) {
    char *uuid = uuidFn();
    [self appendLog:[NSString stringWithFormat:@"boot_uuid=%s", uuid ? uuid : "(null)"]];
  } else {
    [self appendLog:@"jbclient_get_boot_uuid 不可用"];
  }

  if (rootFn) {
    char *root = rootFn();
    [self appendLog:[NSString stringWithFormat:@"jbroot=%s", root ? root : "(null)"]];
  } else {
    [self appendLog:@"jbclient_get_jbroot 不可用"];
  }

  if (checkinFn) {
    char *rootOut = NULL;
    char *bootOut = NULL;
    char *sandboxOut = NULL;
    bool fullyDebugged = false;
    int rc = checkinFn(&rootOut, &bootOut, &sandboxOut, &fullyDebugged);
    [self appendLog:[NSString stringWithFormat:
                                  @"process_checkin rc=%d root=%s boot=%s dbg=%d", rc,
                                  rootOut ? rootOut : "(null)", bootOut ? bootOut : "(null)",
                                  fullyDebugged ? 1 : 0]];
    free(rootOut);
    free(bootOut);
    free(sandboxOut);
  } else {
    [self appendLog:@"jbclient_process_checkin 不可用"];
  }

  self.statusLabel.text = @"jbclient 读取探测完成（验收⑥）";
  self.statusLabel.textColor =
      [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
  [self appendLog:@"验收⑥：jbclient 实调完成（未链 PhysX）"];
}

@end
