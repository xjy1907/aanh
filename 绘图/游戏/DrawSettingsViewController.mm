//
//  DrawSettingsViewController.mm — 绘制设置（对标 wasd/qwer，含颜色与漏打距离）
//

#import "DrawSettingsViewController.h"
#import "NHIdentity.h"
#import <objc/runtime.h>

@interface DSRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) NSInteger kind; // 0 slider float 1 slider int 2 segment 3 color
@property (nonatomic, assign) float minV, maxV, step;
@property (nonatomic, strong) NSArray<NSString *> *options;
@property (nonatomic, copy) NSString *defaultHex;
@end
@implementation DSRow
@end

@interface DrawSettingsViewController () <UITableViewDataSource, UITableViewDelegate, UIColorPickerViewControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<DSRow *> *rows;
@property (nonatomic, strong) NSMutableDictionary *prefs;
@end

@implementation DrawSettingsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.title = @"绘制设置";
  self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone
                                    target:self action:@selector(onClose)];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  self.navigationController.navigationBar.tintColor = [UIColor cyanColor];
  self.navigationController.navigationBar.titleTextAttributes =
    @{NSForegroundColorAttributeName: [UIColor cyanColor]};

  self.prefs = [NSMutableDictionary dictionaryWithDictionary:NHPrefsRead() ?: @{}];
  [self buildRows];

  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.backgroundColor = [UIColor blackColor];
  self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:1];
  self.tableView.rowHeight = 72;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ds"];
  [self.view addSubview:self.tableView];

  UILayoutGuide *g = self.view.safeAreaLayoutGuide;
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.topAnchor constraintEqualToAnchor:g.topAnchor],
    [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)onClose {
  if (self.presentingViewController) {
    [self dismissViewControllerAnimated:YES completion:nil];
  } else {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  }
}

- (DSRow *)mkSlider:(NSString *)title key:(NSString *)key min:(float)min max:(float)max step:(float)step kind:(NSInteger)kind {
  DSRow *r = [DSRow new];
  r.title = title; r.key = key; r.minV = min; r.maxV = max; r.step = step; r.kind = kind;
  return r;
}

- (DSRow *)mkSeg:(NSString *)title key:(NSString *)key options:(NSArray *)opts {
  DSRow *r = [DSRow new];
  r.title = title; r.key = key; r.options = opts; r.kind = 2;
  return r;
}

- (DSRow *)mkColor:(NSString *)title key:(NSString *)key defaultHex:(NSString *)hex {
  DSRow *r = [DSRow new];
  r.title = title; r.key = key; r.defaultHex = hex; r.kind = 3;
  return r;
}

- (void)buildRows {
  // 颜色项置于「物资显示模式」之上（对标 qwer 绘制设置同名项）
  self.rows = @[
    [self mkColor:@"人机颜色" key:@"人机颜色" defaultHex:@"C8FF0000"],
    [self mkColor:@"名字颜色" key:@"名字颜色" defaultHex:@"FFFFFF"],
    [self mkColor:@"射线颜色" key:@"射线颜色" defaultHex:@"F0F000"],
    [self mkColor:@"掩体颜色" key:@"掩体颜色" defaultHex:@"FF0000"],
    [self mkColor:@"距离颜色" key:@"距离颜色" defaultHex:@"F0F0F0"],
    [self mkColor:@"队伍颜色" key:@"队伍颜色" defaultHex:@"FFDF00"],
    [self mkColor:@"骨骼颜色" key:@"骨骼颜色" defaultHex:@"00C800"],
    [self mkSeg:@"物资显示模式" key:@"lootMode" options:@[@"正常显示", @"空手显示"]],
    [self mkSeg:@"血量样式" key:@"healthStyle" options:@[@"圆弧", @"经典", @"花祭"]],
    [self mkSeg:@"背敌样式" key:@"behindStyle" options:@[@"雷达", @"箭头", @"花祭"]],
    [self mkSeg:@"背敌模式" key:@"behindMode" options:@[@"背后模式", @"全景模式"]],
    [self mkSlider:@"绘制距离" key:@"drawDist" min:0 max:500 step:1 kind:1],
    [self mkSlider:@"背敌距离" key:@"behindDist" min:0 max:500 step:1 kind:1],
    [self mkSlider:@"骨骼距离" key:@"boneDist" min:0 max:500 step:1 kind:1],
    [self mkSlider:@"骨骼粗细" key:@"boneThick" min:0.5 max:4 step:0.1 kind:0],
    [self mkSlider:@"射线粗细" key:@"rayThick" min:0.5 max:4 step:0.1 kind:0],
    [self mkSlider:@"物资大小" key:@"lootSize" min:6 max:24 step:1 kind:1],
    [self mkSlider:@"信息大小" key:@"infoSize" min:6 max:24 step:1 kind:1],
    // 对标 qwer：模型漏打独立距离（与「模型渲染」联动，供自瞄不打墙）
    [self mkSlider:@"漏打距离" key:@"漏打距离" min:0 max:500 step:1 kind:1],
  ];
}

- (float)floatForKey:(NSString *)key def:(float)def {
  id v = self.prefs[key];
  return v ? [v floatValue] : def;
}

- (NSInteger)intForKey:(NSString *)key def:(NSInteger)def {
  id v = self.prefs[key];
  return v ? [v integerValue] : def;
}

- (NSString *)hexForKey:(NSString *)key def:(NSString *)def {
  id v = self.prefs[key];
  if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0) return v;
  return def ?: @"FFFFFF";
}

- (void)saveKey:(NSString *)key value:(id)value {
  self.prefs[key] = value;
  NSMutableDictionary *cur = [NSMutableDictionary dictionaryWithDictionary:NHPrefsRead() ?: @{}];
  [cur addEntriesFromDictionary:self.prefs];
  cur[key] = value;
  NHPrefsWrite(cur);
}

- (UIColor *)colorFromHex:(NSString *)hexString {
  if (!hexString.length) return [UIColor whiteColor];
  NSString *clean = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
  unsigned int r = 255, g = 255, b = 255, a = 255;
  if (clean.length == 8) {
    [[NSScanner scannerWithString:[clean substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&r];
    [[NSScanner scannerWithString:[clean substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&g];
    [[NSScanner scannerWithString:[clean substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&b];
    [[NSScanner scannerWithString:[clean substringWithRange:NSMakeRange(6, 2)]] scanHexInt:&a];
  } else if (clean.length >= 6) {
    [[NSScanner scannerWithString:[clean substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&r];
    [[NSScanner scannerWithString:[clean substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&g];
    [[NSScanner scannerWithString:[clean substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&b];
  }
  return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a / 255.0];
}

- (NSString *)hexFromColor:(UIColor *)color {
  CIColor *ci = [[CIColor alloc] initWithColor:color];
  return [NSString stringWithFormat:@"%02X%02X%02X",
          (int)(ci.red * 255), (int)(ci.green * 255), (int)(ci.blue * 255)];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ds" forIndexPath:indexPath];
  for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.backgroundColor = [UIColor colorWithWhite:0.07 alpha:1];
  cell.contentView.backgroundColor = cell.backgroundColor;
  cell.accessoryView = nil;

  DSRow *row = self.rows[indexPath.row];
  UIColor *cyan = [UIColor cyanColor];

  UILabel *title = [[UILabel alloc] init];
  title.translatesAutoresizingMaskIntoConstraints = NO;
  title.text = row.title;
  title.textColor = cyan;
  title.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
  [cell.contentView addSubview:title];

  if (row.kind == 3) {
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    NSString *hex = [self hexForKey:row.key def:row.defaultHex];
    UIView *preview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    preview.backgroundColor = [self colorFromHex:hex];
    preview.layer.cornerRadius = 15;
    preview.layer.borderWidth = 1;
    preview.layer.borderColor = [UIColor colorWithWhite:0.45 alpha:1].CGColor;
    cell.accessoryView = preview;
    [NSLayoutConstraint activateConstraints:@[
      [title.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [title.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
      [title.trailingAnchor constraintLessThanOrEqualToAnchor:cell.contentView.trailingAnchor constant:-56],
    ]];
  } else if (row.kind == 2) {
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:row.options];
    seg.translatesAutoresizingMaskIntoConstraints = NO;
    NSInteger cur = [self intForKey:row.key def:0];
    if (cur < 0) cur = 0;
    if (cur >= (NSInteger)row.options.count) cur = 0;
    // 默认：物资正常 / 血量经典 / 背敌箭头 / 背敌全景
    if (self.prefs[row.key] == nil) {
      if ([row.key isEqualToString:@"lootMode"]) cur = 0;
      else if ([row.key isEqualToString:@"healthStyle"]) cur = 1;
      else if ([row.key isEqualToString:@"behindStyle"]) cur = 1;
      else if ([row.key isEqualToString:@"behindMode"]) cur = 1;
    }
    seg.selectedSegmentIndex = cur;
    if (@available(iOS 13.0, *)) {
      seg.selectedSegmentTintColor = [cyan colorWithAlphaComponent:0.45];
      [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    }
    seg.tag = 2000 + indexPath.row;
    [seg addTarget:self action:@selector(onSeg:) forControlEvents:UIControlEventValueChanged];
    [cell.contentView addSubview:seg];
    [NSLayoutConstraint activateConstraints:@[
      [title.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [title.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:10],
      [seg.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [seg.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-14],
      [seg.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
      [seg.heightAnchor constraintEqualToConstant:30],
    ]];
  } else {
    float defV = 300;
    if ([row.key isEqualToString:@"boneThick"] || [row.key isEqualToString:@"rayThick"]) defV = 1.0f;
    if ([row.key isEqualToString:@"lootSize"]) defV = 13;
    if ([row.key isEqualToString:@"infoSize"]) defV = 12;
    if ([row.key isEqualToString:@"drawDist"]) defV = 252;
    if ([row.key isEqualToString:@"behindDist"]) defV = 252;
    if ([row.key isEqualToString:@"boneDist"]) defV = 30;
    if ([row.key isEqualToString:@"漏打距离"]) defV = 120;
    float cur = [self floatForKey:row.key def:defV];

    UILabel *val = [[UILabel alloc] init];
    val.translatesAutoresizingMaskIntoConstraints = NO;
    val.tag = 3000 + indexPath.row;
    val.textColor = [UIColor whiteColor];
    val.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    val.textAlignment = NSTextAlignmentRight;
    if (row.kind == 1) val.text = [NSString stringWithFormat:@"%.0f", cur];
    else val.text = [NSString stringWithFormat:@"%.1f", cur];
    [cell.contentView addSubview:val];

    UISlider *sl = [[UISlider alloc] init];
    sl.translatesAutoresizingMaskIntoConstraints = NO;
    sl.minimumValue = row.minV;
    sl.maximumValue = row.maxV;
    sl.value = cur;
    sl.minimumTrackTintColor = cyan;
    sl.tag = 1000 + indexPath.row;
    [sl addTarget:self action:@selector(onSlider:) forControlEvents:UIControlEventValueChanged];
    [cell.contentView addSubview:sl];

    [NSLayoutConstraint activateConstraints:@[
      [title.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [title.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:10],
      [val.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-14],
      [val.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
      [val.widthAnchor constraintEqualToConstant:48],
      [sl.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:14],
      [sl.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-14],
      [sl.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
    ]];
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  DSRow *row = self.rows[indexPath.row];
  if (row.kind != 3) return;
  if (@available(iOS 14.0, *)) {
    UIColorPickerViewController *picker = [[UIColorPickerViewController alloc] init];
    picker.delegate = self;
    picker.title = row.title;
    picker.selectedColor = [self colorFromHex:[self hexForKey:row.key def:row.defaultHex]];
    objc_setAssociatedObject(picker, "dsColorKey", row.key, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(picker, "dsColorIndexPath", indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self presentViewController:picker animated:YES completion:nil];
  }
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController API_AVAILABLE(ios(14.0)) {
  NSString *key = objc_getAssociatedObject(viewController, "dsColorKey");
  NSIndexPath *indexPath = objc_getAssociatedObject(viewController, "dsColorIndexPath");
  if (!key.length) return;
  NSString *hex = [self hexFromColor:viewController.selectedColor];
  [self saveKey:key value:hex];
  if (indexPath) {
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
  }
}

- (void)colorPickerViewController:(UIColorPickerViewController *)viewController
                   didSelectColor:(UIColor *)color API_AVAILABLE(ios(14.0)) {
  NSString *key = objc_getAssociatedObject(viewController, "dsColorKey");
  if (!key.length) return;
  [self saveKey:key value:[self hexFromColor:color]];
}

- (void)onSeg:(UISegmentedControl *)seg {
  NSInteger row = seg.tag - 2000;
  if (row < 0 || row >= (NSInteger)self.rows.count) return;
  DSRow *r = self.rows[row];
  [self saveKey:r.key value:@(seg.selectedSegmentIndex)];
}

- (void)onSlider:(UISlider *)sl {
  NSInteger row = sl.tag - 1000;
  if (row < 0 || row >= (NSInteger)self.rows.count) return;
  DSRow *r = self.rows[row];
  float v = sl.value;
  if (r.step > 0) {
    v = roundf(v / r.step) * r.step;
    sl.value = v;
  }
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
  for (UIView *sub in cell.contentView.subviews) {
    if (sub.tag == 3000 + row && [sub isKindOfClass:[UILabel class]]) {
      ((UILabel *)sub).text = (r.kind == 1)
        ? [NSString stringWithFormat:@"%.0f", v]
        : [NSString stringWithFormat:@"%.1f", v];
    }
  }
  if (r.kind == 1) [self saveKey:r.key value:@((int)lroundf(v))];
  else [self saveKey:r.key value:@(v)];
}

@end
