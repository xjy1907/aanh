//
//  AimConfigViewController.mm — 自瞄功能（对标 qwer 自瞄功能页全部项）
//

#import "AimConfigViewController.h"
#import "NHIdentity.h"
#import "LFSenderIDViewController.h"

@interface AimRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) NSInteger kind; // 0 switch 1 slider int 2 action 3 segment
@property (nonatomic, assign) float minV, maxV, step;
@property (nonatomic, assign) float scale; // UI 值 → 存储：实际 = UI / scale（0 表示原样）
@property (nonatomic, copy) NSArray<NSString *> *options;
@end
@implementation AimRow
@end

@interface AimConfigViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<AimRow *> *rows;
@property (nonatomic, strong) NSMutableDictionary *prefs;
@end

@implementation AimConfigViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.title = @"自瞄功能";
  self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone
                                    target:self action:@selector(onClose)];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  self.navigationController.navigationBar.tintColor = [UIColor cyanColor];
  self.navigationController.navigationBar.titleTextAttributes =
    @{NSForegroundColorAttributeName: [UIColor cyanColor]};
  if (@available(iOS 13.0, *)) {
    UINavigationBarAppearance *app = [[UINavigationBarAppearance alloc] init];
    [app configureWithOpaqueBackground];
    app.backgroundColor = [UIColor blackColor];
    app.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor cyanColor]};
    self.navigationController.navigationBar.standardAppearance = app;
    self.navigationController.navigationBar.scrollEdgeAppearance = app;
  }

  self.prefs = [NSMutableDictionary dictionaryWithDictionary:NHPrefsRead() ?: @{}];
  [self buildRows];

  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.backgroundColor = [UIColor blackColor];
  self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:1];
  self.tableView.rowHeight = 78;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"aim"];
  [self.view addSubview:self.tableView];

  UILayoutGuide *g = self.view.safeAreaLayoutGuide;
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.topAnchor constraintEqualToAnchor:g.topAnchor],
    [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.prefs = [NSMutableDictionary dictionaryWithDictionary:NHPrefsRead() ?: @{}];
  [self.tableView reloadData];
}

- (void)onClose {
  if (self.presentingViewController) {
    [self dismissViewControllerAnimated:YES completion:nil];
  } else {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }
}

- (AimRow *)mkSwitch:(NSString *)title key:(NSString *)key subtitle:(NSString *)sub {
  AimRow *r = [AimRow new];
  r.title = title; r.key = key; r.subtitle = sub; r.kind = 0;
  return r;
}

- (AimRow *)mkSlider:(NSString *)title key:(NSString *)key subtitle:(NSString *)sub
                 min:(float)min max:(float)max step:(float)step scale:(float)scale {
  AimRow *r = [AimRow new];
  r.title = title; r.key = key; r.subtitle = sub;
  r.kind = 1; r.minV = min; r.maxV = max; r.step = step; r.scale = scale;
  return r;
}

- (AimRow *)mkAction:(NSString *)title key:(NSString *)key subtitle:(NSString *)sub {
  AimRow *r = [AimRow new];
  r.title = title; r.key = key; r.subtitle = sub; r.kind = 2;
  return r;
}

- (AimRow *)mkSeg:(NSString *)title key:(NSString *)key subtitle:(NSString *)sub options:(NSArray<NSString *> *)opts {
  AimRow *r = [AimRow new];
  r.title = title; r.key = key; r.subtitle = sub; r.options = opts; r.kind = 3;
  return r;
}

- (void)buildRows {
  // 对标 qwer MainRootViewController 自瞄功能分类全部项
  self.rows = @[
    [self mkAction:@"标识符管理" key:@"__open_sender_id__" subtitle:@"点击进入标识符获取界面"],
    [self mkSwitch:@"开启自瞄" key:@"开启自瞄" subtitle:nil],
    [self mkSwitch:@"自瞄连线" key:@"自瞄连线" subtitle:nil],
    [self mkSwitch:@"显示范围" key:@"显示范围" subtitle:nil],
    [self mkSwitch:@"悬浮球" key:@"悬浮球" subtitle:@"HUD 自瞄快捷悬浮球显示（默认开）"],
    [self mkSlider:@"悬浮球大小" key:@"悬浮球大小" subtitle:@"自瞄快捷悬浮球直径（长按切换开关）"
               min:28 max:96 step:1 scale:0],
    [self mkSlider:@"自瞄速度" key:@"自瞄速度" subtitle:@"数值越大速度越慢"
               min:20 max:100 step:1 scale:0],
    [self mkSlider:@"1" key:@"抖动幅度" subtitle:@"模拟真人的上下抖动幅度 (0.0-2.0)"
               min:0 max:20 step:1 scale:10],
    [self mkSlider:@"2" key:@"抖动频率" subtitle:@"抖动的频率快慢"
               min:1 max:50 step:1 scale:100],
    [self mkSlider:@"3" key:@"抖动波动" subtitle:@"抖动幅度的随机波动范围 (0.00-0.10)"
               min:0 max:10 step:1 scale:100],
    [self mkSwitch:@"显示触摸区域" key:@"显示触摸区域" subtitle:@"在屏幕上显示触摸起始点区域"],
    [self mkSlider:@"触摸区域宽度" key:@"触摸区域宽度" subtitle:@"触摸起始点区域的宽度"
               min:50 max:500 step:1 scale:0],
    [self mkSlider:@"触摸区域高度" key:@"触摸区域高度" subtitle:@"触摸起始点区域的高度"
               min:50 max:500 step:1 scale:0],
    [self mkSlider:@"触摸区域X偏移" key:@"触摸区域X" subtitle:@"触摸起始点区域的X轴偏移（相对中心）"
               min:-500 max:500 step:1 scale:0],
    [self mkSlider:@"触摸区域Y偏移" key:@"触摸区域Y" subtitle:@"触摸起始点区域的Y轴偏移（相对中心）"
               min:-500 max:500 step:1 scale:0],
    [self mkSlider:@"自瞄范围" key:@"自瞄大小" subtitle:@"自瞄圆圈大小（动态圈的最大半径）"
               min:10 max:250 step:1 scale:0],
    [self mkSwitch:@"动态圈" key:@"动态圈" subtitle:@"腰射：按准心距离线性缩扩，边沿最大、贴脸最小"],
    [self mkSlider:@"动态圈最小" key:@"动态圈最小" subtitle:@"准心对准敌人时圆圈缩到的最小值（可为0，腰射开镜共用）"
               min:0 max:150 step:1 scale:0],
    [self mkSlider:@"动态圈速度" key:@"动态圈速度" subtitle:@"固定步长=每帧像素；指数平滑=响应快慢，越大越快"
               min:1 max:30 step:1 scale:0],
    [self mkSeg:@"动态圈插值方式" key:@"动态圈插值方式"
       subtitle:@"固定步长对标旧版硬步进；指数平滑更丝滑（默认）"
        options:@[@"固定步长", @"指数平滑"]],
    [self mkSlider:@"开镜自瞄范围" key:@"开镜自瞄范围" subtitle:@"开镜时自瞄圆圈的最大半径"
               min:10 max:250 step:1 scale:0],
    [self mkSwitch:@"开镜动态圈" key:@"开镜动态圈" subtitle:@"开镜时同样按准心距离动态缩扩（共用最小/速度）"],
    [self mkSwitch:@"显示开镜自瞄范围" key:@"显示开镜自瞄范围" subtitle:@"开镜时显示自瞄范围圆圈"],
    [self mkSlider:@"内圈大小" key:@"内圈大小" subtitle:@"准心内圈半径，进入后自瞄失效（0关闭）"
               min:0 max:150 step:1 scale:0],
    [self mkSwitch:@"显示内圈" key:@"显示内圈" subtitle:@"绘制橙色内圈，便于观察死区范围"],
    [self mkSwitch:@"烟雾不瞄" key:@"烟雾不瞄" subtitle:@"敌人在烟雾中时不触发自瞄"],
    [self mkSlider:@"烟雾范围" key:@"烟雾范围" subtitle:@"烟雾不瞄的检测半径（米）"
               min:0 max:30 step:1 scale:0],
    [self mkSlider:@"自瞄距离" key:@"自瞄距离" subtitle:@"有效作用距离"
               min:0 max:200 step:1 scale:0],
    [self mkSlider:@"腰射距离" key:@"腰射距离" subtitle:@"未开镜时的自瞄距离"
               min:0 max:100 step:1 scale:0],
    [self mkSlider:@"压枪力度" key:@"压枪力度" subtitle:@"后坐力补偿强度 (0.0-2.0)"
               min:0 max:20 step:1 scale:10],
    [self mkSlider:@"自瞄血量" key:@"自瞄血量" subtitle:@"远距离只瞄准血量≤此值的敌人"
               min:0 max:100 step:1 scale:0],
    [self mkSlider:@"满血距离" key:@"满血距离" subtitle:@"距离≤此值时无视血量直接自瞄"
               min:0 max:150 step:1 scale:0],
  ];
}

- (float)defaultForKey:(NSString *)key {
  static NSDictionary *defs;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    defs = @{
      @"开启自瞄": @0, @"自瞄连线": @0, @"显示范围": @0,
      @"悬浮球": @1,
      @"悬浮球大小": @90, @"自瞄速度": @26,
      @"抖动幅度": @5, @"抖动频率": @10, @"抖动波动": @1,
      @"显示触摸区域": @0,
      @"触摸区域宽度": @120, @"触摸区域高度": @60,
      @"触摸区域X": @0, @"触摸区域Y": @0,
      @"自瞄大小": @60, @"动态圈": @0, @"动态圈最小": @0, @"动态圈速度": @12,
      @"动态圈插值方式": @1,
      @"开镜自瞄范围": @60, @"开镜动态圈": @0, @"显示开镜自瞄范围": @0,
      @"内圈大小": @5, @"显示内圈": @0,
      @"烟雾不瞄": @0, @"烟雾范围": @10,
      @"自瞄距离": @100, @"腰射距离": @30, @"压枪力度": @7,
      @"自瞄血量": @100, @"满血距离": @50,
    };
  });
  return [defs[key] floatValue];
}

- (float)floatForKey:(NSString *)key {
  id v = self.prefs[key];
  return v ? [v floatValue] : [self defaultForKey:key];
}

- (BOOL)boolForKey:(NSString *)key {
  id v = self.prefs[key];
  return v ? [v boolValue] : ([self defaultForKey:key] != 0);
}

- (void)saveKey:(NSString *)key value:(id)value {
  self.prefs[key] = value;
  NSMutableDictionary *cur = [NSMutableDictionary dictionaryWithDictionary:NHPrefsRead() ?: @{}];
  [cur addEntriesFromDictionary:self.prefs];
  cur[key] = value;
  NHPrefsWrite(cur);
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"aim" forIndexPath:indexPath];
  for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.backgroundColor = [UIColor colorWithWhite:0.07 alpha:1];
  cell.contentView.backgroundColor = cell.backgroundColor;
  cell.accessoryType = UITableViewCellAccessoryNone;

  AimRow *row = self.rows[indexPath.row];
  UIColor *cyan = [UIColor cyanColor];

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = row.title;
  title.textColor = cyan;
  title.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
  [cell.contentView addSubview:title];

  UILabel *sub = nil;
  if (row.subtitle.length) {
    sub = [[UILabel alloc] init];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    sub.text = row.subtitle;
    sub.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    sub.font = [UIFont systemFontOfSize:11];
    sub.numberOfLines = 2;
    [cell.contentView addSubview:sub];
  }

  if (row.kind == 2) {
    // 标识符管理
    long long sid = 0;
    id sidVal = self.prefs[@"TouchSenderID"];
    if ([sidVal respondsToSelector:@selector(longLongValue)]) sid = [sidVal longLongValue];
    if (sid == 0) {
      NSNumber *icloud = [[NSUbiquitousKeyValueStore defaultStore] objectForKey:@"TouchSenderID"];
      if (icloud) sid = [icloud longLongValue];
    }
    UILabel *detail = [[UILabel alloc] init];
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    detail.textColor = [UIColor colorWithWhite:0.7 alpha:1];
    detail.font = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightRegular];
    detail.text = sid ? [NSString stringWithFormat:@"已设置: 0x%llX", (unsigned long long)sid]
                      : @"点击进入标识符获取界面";
    detail.tag = 4000 + indexPath.row;
    [cell.contentView addSubview:detail];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    [NSLayoutConstraint activateConstraints:@[
      [title.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [title.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:12],
      [detail.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
      [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
      [detail.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-36],
    ]];
  } else if (row.kind == 3) {
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:row.options];
    seg.translatesAutoresizingMaskIntoConstraints = NO;
    NSInteger cur = (NSInteger)lroundf([self floatForKey:row.key]);
    if (cur < 0 || cur >= (NSInteger)row.options.count) cur = (NSInteger)lroundf([self defaultForKey:row.key]);
    if (cur < 0 || cur >= (NSInteger)row.options.count) cur = 0;
    seg.selectedSegmentIndex = cur;
    if (@available(iOS 13.0, *)) {
      seg.selectedSegmentTintColor = [cyan colorWithAlphaComponent:0.45];
      [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    }
    seg.tag = 5000 + indexPath.row;
    [seg addTarget:self action:@selector(onSeg:) forControlEvents:UIControlEventValueChanged];
    [cell.contentView addSubview:seg];
    NSMutableArray *cs = [NSMutableArray arrayWithArray:@[
      [title.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [title.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:6],
      [title.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-14],
      [seg.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [seg.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-14],
      [seg.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-6],
      [seg.heightAnchor constraintEqualToConstant:28],
    ]];
    if (sub) {
      [cs addObject:[sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor]];
      [cs addObject:[sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:1]];
      [cs addObject:[sub.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-14]];
      [cs addObject:[seg.topAnchor constraintGreaterThanOrEqualToAnchor:sub.bottomAnchor constant:4]];
    } else {
      [cs addObject:[seg.topAnchor constraintGreaterThanOrEqualToAnchor:title.bottomAnchor constant:6]];
    }
    [NSLayoutConstraint activateConstraints:cs];
  } else if (row.kind == 0) {
    UISwitch *sw = [[UISwitch alloc] init];
    sw.translatesAutoresizingMaskIntoConstraints = NO;
    sw.on = [self boolForKey:row.key];
    sw.onTintColor = cyan;
    sw.tag = 1000 + indexPath.row;
    [sw addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
    [cell.contentView addSubview:sw];
    NSMutableArray *cs = [NSMutableArray arrayWithArray:@[
      [title.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [title.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:12],
      [sw.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-14],
      [sw.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    ]];
    if (sub) {
      [cs addObject:[sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor]];
      [cs addObject:[sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4]];
      [cs addObject:[sub.trailingAnchor constraintEqualToAnchor:sw.leadingAnchor constant:-8]];
    }
    [NSLayoutConstraint activateConstraints:cs];
  } else {
    float curUI = [self floatForKey:row.key];
    UILabel *val = [[UILabel alloc] init];
    val.translatesAutoresizingMaskIntoConstraints = NO;
    val.tag = 3000 + indexPath.row;
    val.textColor = [UIColor whiteColor];
    val.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    val.textAlignment = NSTextAlignmentRight;
    if (row.scale > 0) {
      val.text = [NSString stringWithFormat:@"%.2f", curUI / row.scale];
    } else {
      val.text = [NSString stringWithFormat:@"%.0f", curUI];
    }
    [cell.contentView addSubview:val];

    UISlider *sl = [[UISlider alloc] init];
    sl.translatesAutoresizingMaskIntoConstraints = NO;
    sl.minimumValue = row.minV;
    sl.maximumValue = row.maxV;
    sl.value = curUI;
    sl.minimumTrackTintColor = cyan;
    sl.tag = 2000 + indexPath.row;
    [sl addTarget:self action:@selector(onSlider:) forControlEvents:UIControlEventValueChanged];
    [cell.contentView addSubview:sl];

    NSMutableArray *cs = [NSMutableArray arrayWithArray:@[
      [title.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [title.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:8],
      [val.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-14],
      [val.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
      [val.widthAnchor constraintEqualToConstant:56],
      [sl.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [sl.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-14],
      [sl.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-8],
    ]];
    if (sub) {
      [cs addObject:[sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor]];
      [cs addObject:[sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2]];
      [cs addObject:[sub.trailingAnchor constraintEqualToAnchor:val.leadingAnchor constant:-6]];
    }
    [NSLayoutConstraint activateConstraints:cs];
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  AimRow *row = self.rows[indexPath.row];
  if (row.kind != 2) return;
  LFSenderIDViewController *vc = [LFSenderIDViewController new];
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)onSwitch:(UISwitch *)sw {
  NSInteger row = sw.tag - 1000;
  if (row < 0 || row >= (NSInteger)self.rows.count) return;
  AimRow *r = self.rows[row];
  [self saveKey:r.key value:@(sw.on)];
}

- (void)onSeg:(UISegmentedControl *)seg {
  NSInteger row = seg.tag - 5000;
  if (row < 0 || row >= (NSInteger)self.rows.count) return;
  AimRow *r = self.rows[row];
  [self saveKey:r.key value:@(seg.selectedSegmentIndex)];
}

- (void)onSlider:(UISlider *)sl {
  NSInteger row = sl.tag - 2000;
  if (row < 0 || row >= (NSInteger)self.rows.count) return;
  AimRow *r = self.rows[row];
  float v = sl.value;
  if (r.step > 0) {
    v = roundf(v / r.step) * r.step;
    sl.value = v;
  }
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
  for (UIView *sub in cell.contentView.subviews) {
    if (sub.tag == 3000 + row && [sub isKindOfClass:[UILabel class]]) {
      if (r.scale > 0) {
        ((UILabel *)sub).text = [NSString stringWithFormat:@"%.2f", v / r.scale];
      } else {
        ((UILabel *)sub).text = [NSString stringWithFormat:@"%.0f", v];
      }
    }
  }
  [self saveKey:r.key value:@((int)lroundf(v))];
}

@end
