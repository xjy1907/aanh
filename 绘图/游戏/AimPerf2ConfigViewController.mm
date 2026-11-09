//
//  AimPerf2ConfigViewController.mm — 实验-模型性能2
//

#import "AimPerf2ConfigViewController.h"
#import "NHIdentity.h"

@interface Pf2Row : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) NSInteger kind; // 0 switch 1 slider
@property (nonatomic, assign) float minV, maxV, step;
@property (nonatomic, assign) float scale;
@end
@implementation Pf2Row
@end

@interface AimPerf2ConfigViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<Pf2Row *> *rows;
@property (nonatomic, strong) NSMutableDictionary *prefs;
@end

@implementation AimPerf2ConfigViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.title = @"实验-模型性能2";
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
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"pf2"];
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
  if (self.navigationController.viewControllers.count > 1) {
    [self.navigationController popViewControllerAnimated:YES];
  } else if (self.presentingViewController) {
    [self dismissViewControllerAnimated:YES completion:nil];
  } else {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }
}

- (Pf2Row *)mkSwitch:(NSString *)title key:(NSString *)key subtitle:(NSString *)sub {
  Pf2Row *r = [Pf2Row new];
  r.title = title; r.key = key; r.subtitle = sub; r.kind = 0;
  return r;
}

- (Pf2Row *)mkSlider:(NSString *)title key:(NSString *)key subtitle:(NSString *)sub
                 min:(float)min max:(float)max step:(float)step scale:(float)scale {
  Pf2Row *r = [Pf2Row new];
  r.title = title; r.key = key; r.subtitle = sub;
  r.kind = 1; r.minV = min; r.maxV = max; r.step = step; r.scale = scale;
  return r;
}

- (void)buildRows {
  // 默认相对原写死 Range2000 / Rigid1800 再降一档；遮挡圈跟自瞄圈
  self.rows = @[
    [self mkSwitch:@"启用性能2" key:@"实验-模型性能2"
          subtitle:@"开：应用下方降频与圈内遮挡（需同时开模型渲染）"],
    [self mkSwitch:@"仅圈内遮挡" key:@"仅圈内遮挡"
          subtitle:@"只对遮挡圈内目标做 LineTrace/唤醒三线；默认开"],
    [self mkSlider:@"遮挡圈倍率" key:@"遮挡圈倍率" subtitle:@"×当前自瞄大小（1.00=跟自瞄圈一致）"
               min:50 max:150 step:5 scale:100],
    [self mkSlider:@"Range刷新间隔" key:@"性能2_Range间隔" subtitle:@"毫秒；原默认2000，降一档默认3000"
               min:1500 max:5000 step:100 scale:0],
    [self mkSlider:@"Rigid刷新间隔" key:@"性能2_Rigid间隔" subtitle:@"毫秒；原默认1800，降一档默认2700"
               min:1200 max:5000 step:100 scale:0],
  ];
}

- (float)defaultForKey:(NSString *)key {
  static NSDictionary *defs;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    defs = @{
      @"实验-模型性能2": @0,
      @"仅圈内遮挡": @1,
      @"遮挡圈倍率": @100,
      @"性能2_Range间隔": @3000,
      @"性能2_Rigid间隔": @2700,
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
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pf2" forIndexPath:indexPath];
  for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.backgroundColor = [UIColor colorWithWhite:0.07 alpha:1];
  cell.contentView.backgroundColor = cell.backgroundColor;
  cell.accessoryType = UITableViewCellAccessoryNone;

  Pf2Row *row = self.rows[indexPath.row];
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

  if (row.kind == 0) {
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

- (void)onSwitch:(UISwitch *)sw {
  NSInteger row = sw.tag - 1000;
  if (row < 0 || row >= (NSInteger)self.rows.count) return;
  Pf2Row *r = self.rows[row];
  [self saveKey:r.key value:@(sw.on)];
}

- (void)onSlider:(UISlider *)sl {
  NSInteger row = sl.tag - 2000;
  if (row < 0 || row >= (NSInteger)self.rows.count) return;
  Pf2Row *r = self.rows[row];
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
