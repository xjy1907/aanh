#import "LFSenderIDViewController.h"
#import "LFSenderIDMonitor.h"
#import "NHIdentity.h"
#import "HUDHelper.h"
#import "LFVirtualDigitizer.h"
#import "MBProgressHUD.h" // 用于轻提示
#import <dlfcn.h>

@interface LFSenderIDViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, copy)   NSArray<NSNumber *> *data;
@property (nonatomic, assign) uint64_t selectedSID;

// Header
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *headerTitle;
@property (nonatomic, strong) UILabel *headerSubtitle;
@property (nonatomic, strong) UISwitch *listenSwitch;   // 监听开关
@property (nonatomic, strong) UISwitch *loadSwitch;     // 加载内核开关（触发型）
@end

@implementation LFSenderIDViewController

- (instancetype)init {
    if ((self = [super init])) {
        _dismissOnSelect = YES; // 逻辑保留，但不再自动关闭
    }
    return self;
}

#pragma mark - Helpers
static inline NSString *BinaryString(uint64_t sid) {
    // 以 4 位一组插空格，美观易读（64 位共 71 字符）
    NSMutableString *s = [NSMutableString stringWithCapacity:71];
    for (NSInteger i = 63; i >= 0; i--) {
        [s appendString:((sid >> i) & 1) ? @"1" : @"0"];
        if (i % 4 == 0 && i != 0) [s appendString:@" "];
    }
    return s;
}

// 轻提示：文本 1.2s 自动消失
static inline void LFToast(UIView *view, NSString *text) {
    if (!view) return;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = text;
    hud.margin = 12;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:1.2];
}

#pragma mark - iCloud 存取（UI 不显示 16 进制；仅 iCloud 额外存 16 进制字符串）
static inline NSString *HexString(uint64_t sid) {
    return [NSString stringWithFormat:@"0x%llX", sid];
}

static inline void SaveSIDToICloud(uint64_t sid) {
    NSUbiquitousKeyValueStore *store = NSUbiquitousKeyValueStore.defaultStore;
    // 兼容保留：LongLong（老逻辑可能在用）
    [store setLongLong:(long long)sid forKey:@"TouchSenderID"];
    // 仅用于“其他模块读取”：保存 16 进制字符串；UI 不显示
    [store setString:HexString(sid) forKey:@"TouchSenderIDHex"];
    [store synchronize];
    // 同步写入 NHPrefs/drx，供 HUD 绘制进程跨进程读取（对标 qwer settings.plist）
    NSMutableDictionary *cfg = [NSMutableDictionary dictionaryWithDictionary:NHPrefsRead() ?: @{}];
    cfg[@"TouchSenderID"] = @((unsigned long long)sid);
    cfg[@"TouchSenderIDHex"] = HexString(sid);
    NHPrefsWrite(cfg);
}

static inline uint64_t LoadSIDFromICloud(void) {
    NSUbiquitousKeyValueStore *store = NSUbiquitousKeyValueStore.defaultStore;
    long long v = [store longLongForKey:@"TouchSenderID"]; // 没有则为 0
    if (v != 0) return (uint64_t)v;
    // 兼容：如仅有十六进制字符串，则解析
    NSString *hex = [store stringForKey:@"TouchSenderIDHex"];
    if (hex.length > 0) {
        const char *c = hex.UTF8String;
        char *end = NULL;
        unsigned long long val = strtoull(c, &end, 0); // 支持 0x 前缀
        return (uint64_t)val;
    }
    return 0;
}

static inline void ClearSIDFromICloud(void) {
    NSUbiquitousKeyValueStore *store = NSUbiquitousKeyValueStore.defaultStore;
    [store removeObjectForKey:@"TouchSenderID"];
    [store removeObjectForKey:@"TouchSenderIDHex"];
    [store synchronize];
}

#pragma mark - 生成 SenderID（以 dlsym 动态查找，避免强链接）
static bool CallExternalGenerateSenderID(void) {
    fasongxuni();
    return true;
}

#pragma mark - Lifecycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"GetSenderID";
    
    // 柔和渐变背景 - 浅色系柔和配色
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.95 green:0.95 blue:0.98 alpha:1.0].CGColor,  // 浅灰蓝
        (id)[UIColor colorWithRed:0.92 green:0.94 blue:0.97 alpha:1.0].CGColor,  // 更浅的灰蓝
        (id)[UIColor colorWithRed:0.98 green:0.96 blue:0.94 alpha:1.0].CGColor   // 浅米色
    ];
    gradient.locations = @[@0, @0.6, @1];
    gradient.startPoint = CGPointMake(0.5, 0);
    gradient.endPoint = CGPointMake(0.5, 1);
    [self.view.layer insertSublayer:gradient atIndex:0];
    
    // 导航栏设置 - 浅色主题
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    // 优化导航栏配色 - 浅色半透明
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.85];
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]
        };
        appearance.largeTitleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0],
            NSFontAttributeName: [UIFont systemFontOfSize:34 weight:UIFontWeightBold]
        };
        
        // 添加底部阴影线
        appearance.shadowColor = [UIColor colorWithWhite:0 alpha:0.08];
        
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
    
    // 左侧返回按钮 - 深色以适应浅色背景
    if (!self.navigationItem.leftBarButtonItem) {
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
        [backButton setTitle:@" 返回" forState:UIControlStateNormal];
        backButton.tintColor = [UIColor colorWithRed:0.3 green:0.5 blue:0.8 alpha:1.0];
        backButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    
    // 右侧清空按钮
    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"trash"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(onClear)];
    clearItem.tintColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.3 alpha:1.0];
    self.navigationItem.rightBarButtonItems = @[clearItem];
    
    // Header
    [self buildHeader];
    
    // Table
    self.table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.table.translatesAutoresizingMaskIntoConstraints = NO;
    self.table.dataSource = self;
    self.table.delegate   = self;
    self.table.rowHeight  = 60;
    self.table.backgroundColor = UIColor.clearColor;
    self.table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.table.separatorColor = [UIColor colorWithWhite:0 alpha:0.1]; // 浅色分隔线
    self.table.tableHeaderView = self.headerView;
    self.table.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
    [self.view addSubview:self.table];
    
    // 优化约束
    [NSLayoutConstraint activateConstraints:@[
        [self.table.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [self.table.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [self.table.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
    
    // 数据
    self.data = LFSenderIDMonitor.shared.senderIDs;
    self.selectedSID = LoadSIDFromICloud();
    [self refreshHeader];
    [self updateEmptyState];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onUpdate:)
                                                 name:kLFSenderIDMonitorDidUpdate
                                               object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // tableHeader 自适应
    if (self.table.tableHeaderView) {
        UIView *header = self.table.tableHeaderView;
        CGSize size = [header systemLayoutSizeFittingSize:CGSizeMake(self.view.bounds.size.width, UILayoutFittingCompressedSize.height)];
        if (fabs(header.frame.size.height - size.height) > 0.5) {
            header.frame = CGRectMake(0, 0, size.width, size.height);
            self.table.tableHeaderView = header;
        }
    }
    
    // Header 入场动画
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.headerView.alpha = 0;
        self.headerView.transform = CGAffineTransformMakeTranslation(0, -30);
        [UIView animateWithDuration:0.8
                              delay:0.2
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.headerView.alpha = 1;
            self.headerView.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}

#pragma mark - Header UI
- (UILabel *)smallLabel:(NSString *)text {
    UILabel *lb = [UILabel new];
    lb.translatesAutoresizingMaskIntoConstraints = NO;
    lb.text = text;
    lb.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    lb.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.5 alpha:1.0]; // 中灰色
    lb.textAlignment = NSTextAlignmentCenter;
    return lb;
}

- (void)buildHeader {
    
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 220)];
    
    // 毛玻璃背景 - 浅色主题
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]];
    blur.translatesAutoresizingMaskIntoConstraints = NO;
    blur.layer.cornerRadius = 16;
    blur.layer.masksToBounds = YES;
    blur.layer.borderWidth = 1;
    blur.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.6].CGColor;
    
    // 柔和阴影
    blur.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1].CGColor;
    blur.layer.shadowOpacity = 0.3;
    blur.layer.shadowRadius = 12;
    blur.layer.shadowOffset = CGSizeMake(0, 3);
    
    // 标题 - 深色文字以适应浅色背景
    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"快速控制";
    title.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBlack];
    title.textColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0]; // 深灰色
    title.textAlignment = NSTextAlignmentCenter;
    
    UILabel *sub = [UILabel new];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    sub.textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.5 alpha:1.0]; // 中灰色
    sub.numberOfLines = 2;
    sub.textAlignment = NSTextAlignmentCenter;
    sub.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    
    // 开关控件 - 更新标签颜色
    UILabel *lbListen = [self smallLabel:@"监听模式"];
    UISwitch *swListen = [UISwitch new];
    swListen.translatesAutoresizingMaskIntoConstraints = NO;
    swListen.onTintColor = [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0];
    [swListen addTarget:self action:@selector(onListenToggle:) forControlEvents:UIControlEventValueChanged];
    [swListen addTarget:self action:@selector(toggleAnimation:) forControlEvents:UIControlEventValueChanged];
    
    UILabel *lbLoad = [self smallLabel:@"加载SenderID"];
    UISwitch *swLoad = [UISwitch new];
    swLoad.translatesAutoresizingMaskIntoConstraints = NO;
    swLoad.onTintColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.4 alpha:1.0];
    [swLoad addTarget:self action:@selector(onLoadToggle:) forControlEvents:UIControlEventValueChanged];
    [swLoad addTarget:self action:@selector(toggleAnimation:) forControlEvents:UIControlEventValueChanged];
    
    // 创建垂直堆栈，让标签和开关居中
    UIStackView *colLeft = [[UIStackView alloc] initWithArrangedSubviews:@[lbListen, swListen]];
    colLeft.axis = UILayoutConstraintAxisVertical;
    colLeft.spacing = 12;
    colLeft.alignment = UIStackViewAlignmentCenter;
    
    UIStackView *colRight = [[UIStackView alloc] initWithArrangedSubviews:@[lbLoad, swLoad]];
    colRight.axis = UILayoutConstraintAxisVertical;
    colRight.spacing = 12;
    colRight.alignment = UIStackViewAlignmentCenter;
    
    // 水平堆栈，均匀分布
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[colLeft, colRight]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 40;
    row.distribution = UIStackViewDistributionFillEqually;
    row.alignment = UIStackViewAlignmentCenter;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    
    [blur.contentView addSubview:title];
    [blur.contentView addSubview:sub];
    [blur.contentView addSubview:row];
    [container addSubview:blur];
    
    // 优化约束，让内容居中
    [NSLayoutConstraint activateConstraints:@[
        // 毛玻璃背景约束
        [blur.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:20],
        [blur.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-20],
        [blur.topAnchor constraintEqualToAnchor:container.topAnchor constant:15],
        [blur.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-15],
        
        // 标题约束 - 居中
        [title.leadingAnchor constraintEqualToAnchor:blur.contentView.leadingAnchor constant:20],
        [title.trailingAnchor constraintEqualToAnchor:blur.contentView.trailingAnchor constant:-20],
        [title.topAnchor constraintEqualToAnchor:blur.contentView.topAnchor constant:20],
        [title.centerXAnchor constraintEqualToAnchor:blur.contentView.centerXAnchor],
        
        // 副标题约束 - 居中
        [sub.leadingAnchor constraintEqualToAnchor:blur.contentView.leadingAnchor constant:20],
        [sub.trailingAnchor constraintEqualToAnchor:blur.contentView.trailingAnchor constant:-20],
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [sub.centerXAnchor constraintEqualToAnchor:blur.contentView.centerXAnchor],
        
        // 开关行约束 - 居中
        [row.leadingAnchor constraintEqualToAnchor:blur.contentView.leadingAnchor constant:20],
        [row.trailingAnchor constraintEqualToAnchor:blur.contentView.trailingAnchor constant:-20],
        [row.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:20],
        [row.bottomAnchor constraintEqualToAnchor:blur.contentView.bottomAnchor constant:-20],
        [row.centerXAnchor constraintEqualToAnchor:blur.contentView.centerXAnchor]
    ]];
    
    self.headerView = container;
    self.headerTitle = title;
    self.headerSubtitle = sub;
    self.listenSwitch = swListen;
    self.loadSwitch = swLoad;
}

// 优化开关动画
- (void)toggleAnimation:(UISwitch *)sw {
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        sw.transform = CGAffineTransformMakeScale(1.15, 1.15);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.15
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            sw.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

- (void)refreshHeader {
    // 状态文案：一眼能懂
    BOOL listening = LFSenderIDMonitor.shared.isListening;
    self.listenSwitch.on = listening;

    NSUInteger idx = [self.data indexOfObject:@(self.selectedSID)];
    NSString *selectLine = @"未选择";
    if (self.selectedSID != 0 && idx != NSNotFound) {
        selectLine = [NSString stringWithFormat:@"已选：SenderID %lu", (unsigned long)(idx + 1)];
    }

    if (listening) {
        self.headerSubtitle.text = [NSString stringWithFormat:@"监听中 · 列表自动更新 选择完后关闭\n%@", selectLine];
    } else {
        self.headerSubtitle.text = [NSString stringWithFormat:@"未监听 · 打开上方“监听”开始\n%@", selectLine];
    }
}

#pragma mark - 空状态
- (void)updateEmptyState {
    if (self.data.count == 0) {
        UILabel *empty = [UILabel new];
        empty.textAlignment = NSTextAlignmentCenter;
        empty.textColor = UIColor.secondaryLabelColor;
        empty.numberOfLines = 0;
        empty.text = @"暂无SenderID\n打开上方‘监听’获取列表";
        empty.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.table.backgroundView = empty;
    } else {
        self.table.backgroundView = nil;
    }
}

#pragma mark - Actions
- (void)onListenToggle:(UISwitch *)sw {
    if (sw.isOn) {
        [LFSenderIDMonitor.shared start];
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [gen impactOccurred];
        LFToast(self.view, @"已开始监听");
    } else {
        [LFSenderIDMonitor.shared stop];
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [gen impactOccurred];
        LFToast(self.view, @"已停止监听");
    }
    [self refreshHeader];
}

- (void)onLoadToggle:(UISwitch *)sw {
    // 触发型：拨到 ON 触发加载，随后自动回弹为 OFF
    if (sw.isOn) {
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [gen impactOccurred];
        if (CallExternalGenerateSenderID()) {
            LFToast(self.view, @"已触发加载SenderID");
        } else {
            LFToast(self.view, @"未找到加载函数");
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [sw setOn:NO animated:YES];
        });
    }
}

- (void)onClear {
    if (self.selectedSID == 0 && self.data.count == 0) {
        LFToast(self.view, @"没有可清空的数据");
        return;
    }

    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"确认清空？"
                                                                message:@"将清除已监听的SenderID列表，并移除已选择的记录。"
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [ac addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [LFSenderIDMonitor.shared clear];
        weakSelf.selectedSID = 0;
        ClearSIDFromICloud();
        [weakSelf.table reloadData];
        [weakSelf refreshHeader];
        [weakSelf updateEmptyState];
        LFToast(weakSelf.view, @"已清空");
    }]];

    ac.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.firstObject; // iPad 适配（锚定右上角“删除”）
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)onGenerate { // 兼容旧调用（目前不在 UI 中直接使用）
    if (CallExternalGenerateSenderID()) {
        LFToast(self.view, @"已触发加载SenderID");
    } else {
        LFToast(self.view, @"未找到加载函数");
    }
}

- (void)back {
    if (self.presentingViewController && self.navigationController.viewControllers.firstObject == self) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Notification
- (void)onUpdate:(NSNotification *)note {
    self.data = LFSenderIDMonitor.shared.senderIDs;
    [self.table reloadData];
    [self updateEmptyState];
    [self refreshHeader];
}

#pragma mark - Table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"已监听到的SenderID（%lu）", (unsigned long)self.data.count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *ID = @"sid.cell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
        
        // 单元格通用样式设置
        cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
        cell.layer.cornerRadius = 12;
        cell.layer.masksToBounds = YES;
        
        // 选中背景色
        UIView *selectedBgView = [[UIView alloc] init];
        selectedBgView.backgroundColor = [UIColor colorWithRed:0.1 green:0.3 blue:0.8 alpha:0.3];
        selectedBgView.layer.cornerRadius = 12;
        cell.selectedBackgroundView = selectedBgView;
    }

    uint64_t sid = self.data[ip.row].unsignedLongLongValue;
    BOOL selected = (sid == self.selectedSID);

    // 主标题 - 标识符编号
    cell.textLabel.text = [NSString stringWithFormat:@"SenderID #%ld", (long)ip.row + 1];
    cell.textLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    cell.textLabel.textColor = UIColor.blackColor;

    // 副标题 - 显示简化的16进制ID，便于识别
    NSString *hexString = [NSString stringWithFormat:@"%llX", sid];
//    if (hexString.length > 8) {
//        hexString = [NSString stringWithFormat:@"%@...%@",
//                    [hexString substringToIndex:4],
//                    [hexString substringFromIndex:hexString.length - 4]];
//    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"ID: %@", hexString];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.8 alpha:0.9];

    // 右侧状态显示
    if (selected) {
        cell.detailTextLabel.text = @"✅ 当前使用中";
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        
        // 选中状态的背景色
        cell.backgroundColor = [UIColor colorWithRed:0.1 green:0.2 blue:0.4 alpha:0.4];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"ID: %@ • 点击选择", hexString];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.7 alpha:0.9];
        cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
    }

    // 右侧指示器
    cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.tintColor = [UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0];

    // 添加图标
    cell.imageView.image = [UIImage systemImageNamed:selected ? @"checkmark.circle.fill" : @"number.circle"];
    cell.imageView.tintColor = selected ?
        [UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0] :
        [UIColor colorWithWhite:0.6 alpha:0.8];

    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];

    uint64_t newSID = self.data[ip.row].unsignedLongLongValue;

    uint64_t oldSID = self.selectedSID;
    self.selectedSID = newSID;

    SaveSIDToICloud(newSID); // 保存：十进制（兼容）+ 十六进制字符串（供其他模块读取）；UI 不显示 16 进制

    [self refreshHeader];

    NSMutableArray<NSIndexPath *> *toReload = [NSMutableArray arrayWithObject:ip];
    if (oldSID != 0 && oldSID != newSID) {
        NSUInteger oldIndex = [self.data indexOfObject:@(oldSID)];
        if (oldIndex != NSNotFound) {
            [toReload addObject:[NSIndexPath indexPathForRow:oldIndex inSection:0]];
        }
    }
    [tv reloadRowsAtIndexPaths:toReload withRowAnimation:UITableViewRowAnimationNone];

    UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [gen impactOccurred];
    LFToast(self.view, [NSString stringWithFormat:@"已选择：SenderID %ld", (long)ip.row+1]);

    // 不自动关闭
}

// 按需求：移除长按复制功能（不再提供复制二进制/十进制的菜单）

@end
