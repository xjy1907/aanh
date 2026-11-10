//
//  Step10ABPanelViewController.m
//  验收⑪：AB 三按钮 + 进程内真实 HUD 叠层；仍不链 BBZView.mm / PhysX / DrawView
//

#import "Step10ABPanelViewController.h"
#import "JBDylibLoader.h"
#import "Step9KreadRunner.h"
#import "Step11HudOverlay.h"
#import "Step12BBZSettingsHost.h"

@interface Step10ABPanelViewController ()
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UITextView *logView;
@property(nonatomic, strong) UIButton *kernelBtn;
@property(nonatomic, strong) UIButton *resetBtn;
@property(nonatomic, strong) UIButton *readBtn;
@property(nonatomic, strong) UIButton *hudBtn;
@property(nonatomic, strong) UIButton *settingsBtn;
@property(nonatomic, assign) BOOL kernelReady;
@property(nonatomic, assign) BOOL reading;
@property(nonatomic, assign) BOOL hudOn;
@end

@implementation Step10ABPanelViewController

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

- (UIButton *)makeButton:(NSString *)title color:(UIColor *)bg action:(SEL)action {
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
  btn.translatesAutoresizingMaskIntoConstraints = NO;
  [btn setTitle:title forState:UIControlStateNormal];
  [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  btn.backgroundColor = bg;
  btn.layer.cornerRadius = 10.0;
  btn.titleLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightSemibold];
  [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  return btn;
}

- (void)refreshReadButtonTitle {
  NSString *t = self.reading ? @"停止读取" : @"开始读取";
  [self.readBtn setTitle:t forState:UIControlStateNormal];
}

- (void)refreshHudButtonTitle {
  NSString *t = self.hudOn ? @"关闭 HUD 叠层" : @"开启 HUD 叠层";
  [self.hudBtn setTitle:t forState:UIControlStateNormal];
}

- (NSString *)hudDetailText {
  if (self.reading) {
    return @"reading=1 · 轻量绘制面";
  }
  if (self.kernelReady) {
    return @"kread OK · 轻量绘制面";
  }
  return @"轻量绘制面（无 DrawView.mm/PhysX）";
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor colorWithRed:18.0f / 255.0f
                                               green:10.0f / 255.0f
                                                blue:28.0f / 255.0f
                                               alpha:1.0f];

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = @"STEP13-绘制面板";
  title.textColor = [UIColor colorWithRed:200.0f / 255.0f
                                    green:120.0f / 255.0f
                                     blue:255.0f / 255.0f
                                    alpha:1.0f];
  title.font = [UIFont systemFontOfSize:20.0f weight:UIFontWeightBold];
  title.textAlignment = NSTextAlignmentCenter;

  UILabel *hint = [[UILabel alloc] init];
  hint.translatesAutoresizingMaskIntoConstraints = NO;
  hint.text = @"⑫已过：BBZ 设置页可进\n⑬：开启 HUD 应见准星/框/FPS 绘制面\n仍不链 DrawView.mm / PhysX\n点「开启 HUD 叠层」= 验收⑬";
  hint.textColor = [UIColor colorWithWhite:0.78f alpha:1.0f];
  hint.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightMedium];
  hint.textAlignment = NSTextAlignmentCenter;
  hint.numberOfLines = 0;

  UILabel *status = [[UILabel alloc] init];
  status.translatesAutoresizingMaskIntoConstraints = NO;
  status.text = @"内核：未初始化";
  status.textColor = [UIColor colorWithRed:255.0f / 255.0f
                                     green:210.0f / 255.0f
                                      blue:120.0f / 255.0f
                                     alpha:1.0f];
  status.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightSemibold];
  status.textAlignment = NSTextAlignmentCenter;
  status.numberOfLines = 0;
  self.statusLabel = status;

  self.kernelBtn = [self makeButton:@"初始化内核"
                            color:[UIColor colorWithRed:200.0f / 255.0f
                                                  green:120.0f / 255.0f
                                                   blue:255.0f / 255.0f
                                                  alpha:0.35f]
                           action:@selector(onInitKernel)];
  self.resetBtn = [self makeButton:@"重置内核状态"
                             color:[UIColor colorWithRed:120.0f / 255.0f
                                                   green:160.0f / 255.0f
                                                    blue:255.0f / 255.0f
                                                   alpha:0.30f]
                            action:@selector(onResetKernel)];
  self.readBtn = [self makeButton:@"开始读取"
                            color:[UIColor colorWithRed:255.0f / 255.0f
                                                  green:150.0f / 255.0f
                                                   blue:200.0f / 255.0f
                                                  alpha:0.30f]
                           action:@selector(onToggleReading)];
  self.hudBtn = [self makeButton:@"开启 HUD 叠层"
                           color:[UIColor colorWithRed:100.0f / 255.0f
                                                 green:200.0f / 255.0f
                                                  blue:180.0f / 255.0f
                                                 alpha:0.28f]
                          action:@selector(onToggleHud)];
  self.settingsBtn = [self makeButton:@"打开 BBZ 设置（⑫）"
                                color:[UIColor colorWithRed:255.0f / 255.0f
                                                      green:180.0f / 255.0f
                                                       blue:80.0f / 255.0f
                                                      alpha:0.30f]
                               action:@selector(onOpenBBZSettings)];

  UIButton *backBtn = [self makeButton:@"返回 STEP13 诊断页"
                                 color:[UIColor colorWithWhite:0.25f alpha:0.9f]
                                action:@selector(onBack)];

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

  [self.view addSubview:title];
  [self.view addSubview:hint];
  [self.view addSubview:status];
  [self.view addSubview:self.kernelBtn];
  [self.view addSubview:self.resetBtn];
  [self.view addSubview:self.readBtn];
  [self.view addSubview:self.hudBtn];
  [self.view addSubview:self.settingsBtn];
  [self.view addSubview:backBtn];
  [self.view addSubview:logView];

  [NSLayoutConstraint activateConstraints:@[
    [title.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [title.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],

    [hint.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [hint.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
    [hint.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
    [hint.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],

    [status.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [status.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:10],
    [status.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
    [status.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],

    [self.kernelBtn.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
    [self.kernelBtn.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
    [self.kernelBtn.topAnchor constraintEqualToAnchor:status.bottomAnchor constant:14],
    [self.kernelBtn.heightAnchor constraintEqualToConstant:44],

    [self.resetBtn.leadingAnchor constraintEqualToAnchor:self.kernelBtn.leadingAnchor],
    [self.resetBtn.trailingAnchor constraintEqualToAnchor:self.kernelBtn.trailingAnchor],
    [self.resetBtn.topAnchor constraintEqualToAnchor:self.kernelBtn.bottomAnchor constant:10],
    [self.resetBtn.heightAnchor constraintEqualToConstant:44],

    [self.readBtn.leadingAnchor constraintEqualToAnchor:self.kernelBtn.leadingAnchor],
    [self.readBtn.trailingAnchor constraintEqualToAnchor:self.kernelBtn.trailingAnchor],
    [self.readBtn.topAnchor constraintEqualToAnchor:self.resetBtn.bottomAnchor constant:10],
    [self.readBtn.heightAnchor constraintEqualToConstant:44],

    [self.hudBtn.leadingAnchor constraintEqualToAnchor:self.kernelBtn.leadingAnchor],
    [self.hudBtn.trailingAnchor constraintEqualToAnchor:self.kernelBtn.trailingAnchor],
    [self.hudBtn.topAnchor constraintEqualToAnchor:self.readBtn.bottomAnchor constant:10],
    [self.hudBtn.heightAnchor constraintEqualToConstant:40],

    [self.settingsBtn.leadingAnchor constraintEqualToAnchor:self.kernelBtn.leadingAnchor],
    [self.settingsBtn.trailingAnchor constraintEqualToAnchor:self.kernelBtn.trailingAnchor],
    [self.settingsBtn.topAnchor constraintEqualToAnchor:self.hudBtn.bottomAnchor constant:8],
    [self.settingsBtn.heightAnchor constraintEqualToConstant:40],

    [backBtn.leadingAnchor constraintEqualToAnchor:self.kernelBtn.leadingAnchor],
    [backBtn.trailingAnchor constraintEqualToAnchor:self.kernelBtn.trailingAnchor],
    [backBtn.topAnchor constraintEqualToAnchor:self.settingsBtn.bottomAnchor constant:8],
    [backBtn.heightAnchor constraintEqualToConstant:36],

    [logView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
    [logView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
    [logView.topAnchor constraintEqualToAnchor:backBtn.bottomAnchor constant:12],
    [logView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
  ]];

  [self refreshReadButtonTitle];
  [self refreshHudButtonTitle];
  [self appendLog:@"STEP13 面板已挂载（未链 DrawView.mm / PhysX）"];
  [self appendLog:@"验收⑬：点「开启 HUD 叠层」应出现准星/框/STEP13-DRAWSURF"];
}

- (void)onInitKernel {
  [self appendLog:@"点击：初始化内核（复用 Step9KreadRunner）"];
  if (!JBEnsureJailbreakDylibsLoaded()) {
    self.statusLabel.text = @"越狱库未就绪";
    self.statusLabel.textColor =
        [UIColor colorWithRed:255.0f / 255.0f green:120.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
    [self appendLog:@"dlopen 失败"];
    return;
  }

  self.statusLabel.text = @"正在 exploit / kread…";
  self.statusLabel.textColor =
      [UIColor colorWithRed:255.0f / 255.0f green:210.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];

  __weak typeof(self) weakSelf = self;
  BOOL ok = [Step9KreadRunner runExploitAndProbeKreadWithLog:^(NSString *line) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    [strongSelf appendLog:line];
  }];
  self.kernelReady = ok;
  if (ok) {
    self.statusLabel.text = @"内核就绪（kread OK）";
    self.statusLabel.textColor =
        [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
    [self appendLog:@"初始化内核：成功"];
    if (self.hudOn) {
      [[Step11HudOverlay shared] updateDetail:[self hudDetailText]];
    }
  } else {
    self.statusLabel.text = @"初始化失败（见日志）";
    self.statusLabel.textColor =
        [UIColor colorWithRed:255.0f / 255.0f green:120.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
    [self appendLog:@"初始化内核：失败"];
  }
}

- (void)onResetKernel {
  [self appendLog:@"点击：重置内核状态"];
  self.kernelReady = NO;
  self.reading = NO;
  if (self.hudOn) {
    self.hudOn = NO;
    [[Step11HudOverlay shared] setVisible:NO detail:nil];
    [self appendLog:@"HUD 叠层已关（重置）"];
  }
  [self refreshReadButtonTitle];
  [self refreshHudButtonTitle];
  self.statusLabel.text = @"内核：已重置（须重新初始化）";
  self.statusLabel.textColor =
      [UIColor colorWithRed:255.0f / 255.0f green:210.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
  [self appendLog:@"重置完成（未调 PhysX/DrawView teardown）"];
}

- (void)onToggleReading {
  if (!self.kernelReady) {
    [self appendLog:@"开始读取：拒绝，内核未就绪"];
    self.statusLabel.text = @"请先初始化内核";
    self.statusLabel.textColor =
        [UIColor colorWithRed:255.0f / 255.0f green:120.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
    return;
  }
  self.reading = !self.reading;
  [self refreshReadButtonTitle];
  if (self.reading) {
    [self appendLog:@"开始读取：reading=1（未链 DrawView）"];
    if (!self.hudOn) {
      self.hudOn = YES;
      [self refreshHudButtonTitle];
      [[Step11HudOverlay shared] setVisible:YES detail:[self hudDetailText]];
      [self appendLog:@"auto HUD 叠层=ON（验收⑪）"];
    } else {
      [[Step11HudOverlay shared] updateDetail:[self hudDetailText]];
    }
    self.statusLabel.text = @"读取中 + HUD 叠层";
    self.statusLabel.textColor =
        [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
  } else {
    [self appendLog:@"停止读取：reading=0"];
    if (self.hudOn) {
      [[Step11HudOverlay shared] updateDetail:[self hudDetailText]];
    }
    self.statusLabel.text = @"已停止读取";
    self.statusLabel.textColor =
        [UIColor colorWithRed:255.0f / 255.0f green:210.0f / 255.0f blue:120.0f / 255.0f alpha:1.0f];
  }
}

- (void)onToggleHud {
  self.hudOn = !self.hudOn;
  [self refreshHudButtonTitle];
  if (self.hudOn) {
    [[Step11HudOverlay shared] setVisible:YES detail:[self hudDetailText]];
    [self appendLog:@"HUD 叠层开启（应见准星/框/FPS，验收⑬）"];
    self.statusLabel.text = @"绘制面=ON（验收⑬）";
  } else {
    [[Step11HudOverlay shared] setVisible:NO detail:nil];
    [self appendLog:@"HUD 叠层关闭"];
    if (self.reading) {
      self.reading = NO;
      [self refreshReadButtonTitle];
      [self appendLog:@"连带停止读取"];
    }
    self.statusLabel.text = @"绘制面=OFF";
  }
  self.statusLabel.textColor =
      [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
}

- (void)onOpenBBZSettings {
  [self appendLog:@"点击：打开 BBZ 设置（验收⑫）"];
  Step12BBZSettingsHost *host = [[Step12BBZSettingsHost alloc] init];
  UINavigationController *nav =
      [[UINavigationController alloc] initWithRootViewController:host];
  nav.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:nav animated:YES completion:^{
    [self appendLog:@"验收⑫：BBZ 设置宿主已 present（真实 VC，未链 PhysX）"];
    self.statusLabel.text = @"BBZ 设置已打开（验收⑫）";
    self.statusLabel.textColor =
        [UIColor colorWithRed:120.0f / 255.0f green:220.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
  }];
}

- (void)onBack {
  [self appendLog:@"返回诊断页"];
  if (self.hudOn) {
    self.hudOn = NO;
    [[Step11HudOverlay shared] setVisible:NO detail:nil];
  }
  if (self.presentingViewController) {
    [self dismissViewControllerAnimated:YES completion:nil];
  } else if (self.navigationController) {
    [self.navigationController popViewControllerAnimated:YES];
  }
}

@end
