//
//  MaterialConfigViewController.mm
//  物资功能配置（对齐 wasd wuzi.txt 逻辑）
//

#import "MaterialConfigViewController.h"
#import "ItemConfig.h"
#import "NHIdentity.h"
#import <objc/runtime.h>

static NSString *WuziPath(void) {
  return NHWuziPath();
}

static UIColor *MCColorFromHex(NSString *hex) {
  if (!hex || hex.length == 0) return [UIColor cyanColor];
  NSString *s = [[hex stringByTrimmingCharactersInSet:
                  [NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
  if ([s hasPrefix:@"#"]) s = [s substringFromIndex:1];
  if (s.length != 6) return [UIColor cyanColor];
  unsigned rgb = 0;
  NSScanner *sc = [NSScanner scannerWithString:s];
  [sc scanHexInt:&rgb];
  return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                         green:((rgb >> 8) & 0xFF) / 255.0
                          blue:(rgb & 0xFF) / 255.0
                         alpha:1.0];
}

static NSString *MCHexFromColor(UIColor *color) {
  CGFloat r = 0, g = 0, b = 0, a = 0;
  if (![color getRed:&r green:&g blue:&b alpha:&a]) {
    CIColor *ci = [[CIColor alloc] initWithColor:color];
    r = ci.red; g = ci.green; b = ci.blue;
  }
  return [NSString stringWithFormat:@"%02X%02X%02X",
          (int)(r * 255), (int)(g * 255), (int)(b * 255)];
}

// 每项运行时状态
@interface MCItemState : NSObject
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, assign) float minDistance;
@property (nonatomic, assign) float maxDistance;
@property (nonatomic, copy) NSString *hexColor;
@property (nonatomic, assign) int weaponID; // 0=拿枪隐藏 ON, 1=OFF
@property (nonatomic, assign) BOOL enabled;
@end
@implementation MCItemState
@end

@interface MaterialConfigViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIColorPickerViewControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIScrollView *categoryScroll;
@property (nonatomic, strong) UIView *categoryContent;
@property (nonatomic, strong) UISlider *sizeSlider;
@property (nonatomic, strong) UILabel *sizeValueLabel;
@property (nonatomic, strong) NSArray<NSString *> *categories;
@property (nonatomic, assign) NSInteger selectedCategoryIndex;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MCItemState *> *stateByClass; // className -> state
@property (nonatomic, strong) NSArray<MCItemState *> *currentItems;
@property (nonatomic, strong) NSMutableArray<UIButton *> *categoryButtons;
@end

@implementation MaterialConfigViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.title = @"物资功能";
  self.selectedCategoryIndex = 0;
  self.stateByClass = [NSMutableDictionary dictionary];
  self.categoryButtons = [NSMutableArray array];

  self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                     style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(onClose)];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  self.navigationController.navigationBar.tintColor = [UIColor cyanColor];
  self.navigationController.navigationBar.titleTextAttributes =
    @{NSForegroundColorAttributeName: [UIColor cyanColor]};
  self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
  if (@available(iOS 13.0, *)) {
    UINavigationBarAppearance *app = [[UINavigationBarAppearance alloc] init];
    [app configureWithOpaqueBackground];
    app.backgroundColor = [UIColor blackColor];
    app.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor cyanColor]};
    self.navigationController.navigationBar.standardAppearance = app;
    self.navigationController.navigationBar.scrollEdgeAppearance = app;
  }

  [self buildAllItemStates];
  [self loadFromWuzi];
  [self setupChrome];
  [self reloadCurrentCategory];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self loadFromWuzi];
  [self reloadLootSizeFromPrefs];
  [self.tableView reloadData];
}

- (void)onClose {
  if (self.presentingViewController) {
    [self dismissViewControllerAnimated:YES completion:nil];
  } else if (self.navigationController.presentingViewController) {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
  } else {
    [self.navigationController popViewControllerAnimated:YES];
  }
}

#pragma mark - Data

- (void)buildAllItemStates {
  self.categories = [ItemConfig getAllCategories];
  for (NSString *cat in self.categories) {
    NSDictionary *def = [ItemConfig getDefaultConfigForCategory:cat];
    NSArray *items = [ItemConfig getItemsForCategory:cat];
    for (NSDictionary *d in items) {
      NSString *cn = d[@"className"];
      if (!cn.length) continue;
      if (self.stateByClass[cn]) continue; // 同 className 只保留首次
      MCItemState *st = [[MCItemState alloc] init];
      st.className = cn;
      st.displayName = d[@"name"] ?: cn;
      st.category = cat;
      st.minDistance = [def[@"minDistance"] floatValue];
      st.maxDistance = [def[@"maxDistance"] floatValue];
      st.hexColor = def[@"hexColor"] ?: @"00FF00";
      st.weaponID = [def[@"weaponID"] intValue];
      st.enabled = NO;
      self.stateByClass[cn] = st;
    }
  }
}

- (void)loadFromWuzi {
  // 先全部关掉
  for (MCItemState *st in self.stateByClass.allValues) {
    st.enabled = NO;
  }
  NSString *path = WuziPath();
  NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
  if (!content.length) return;

  for (NSString *raw in [content componentsSeparatedByString:@"\n"]) {
    NSString *line = [raw stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!line.length || [line hasPrefix:@"#"]) continue;
    NSArray *parts = [line componentsSeparatedByString:@"|"];
    if (parts.count < 6) continue;
    NSString *cn = parts[0];
    MCItemState *st = self.stateByClass[cn];
    if (!st) {
      // 未知 className：挂到首分类以便显示可关
      st = [[MCItemState alloc] init];
      st.className = cn;
      st.displayName = parts[1];
      st.category = self.categories.firstObject ?: @"";
      self.stateByClass[cn] = st;
    }
    st.displayName = parts[1];
    st.minDistance = [parts[2] floatValue];
    st.maxDistance = [parts[3] floatValue];
    st.hexColor = parts[4];
    st.weaponID = [parts[5] intValue];
    st.enabled = YES;
  }
}

- (void)rewriteWuziFile {
  NSString *dir = NHConfigDirectory();
  NSFileManager *fm = [NSFileManager defaultManager];
  if (![fm fileExistsAtPath:dir]) {
    [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
  }
  NSMutableArray *lines = [NSMutableArray array];
  // 稳定顺序：按分类再按名称
  for (NSString *cat in self.categories) {
    NSMutableArray *bucket = [NSMutableArray array];
    for (MCItemState *st in self.stateByClass.allValues) {
      if (st.enabled && [st.category isEqualToString:cat]) {
        [bucket addObject:st];
      }
    }
    [bucket sortUsingComparator:^NSComparisonResult(MCItemState *a, MCItemState *b) {
      return [a.displayName compare:b.displayName];
    }];
    for (MCItemState *st in bucket) {
      [lines addObject:[NSString stringWithFormat:@"%@|%@|%.0f|%.0f|%@|%d",
                        st.className, st.displayName,
                        st.minDistance, st.maxDistance,
                        st.hexColor ?: @"00FF00", st.weaponID]];
    }
  }
  // 未归类但已启用
  for (MCItemState *st in self.stateByClass.allValues) {
    if (!st.enabled) continue;
    if ([self.categories containsObject:st.category]) continue;
    [lines addObject:[NSString stringWithFormat:@"%@|%@|%.0f|%.0f|%@|%d",
                      st.className, st.displayName,
                      st.minDistance, st.maxDistance,
                      st.hexColor ?: @"00FF00", st.weaponID]];
  }
  NSString *body = [lines componentsJoinedByString:@"\n"];
  if (lines.count > 0) body = [body stringByAppendingString:@"\n"];
  [body writeToFile:WuziPath() atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)upsertOrRemove:(MCItemState *)st {
  // enabled 决定写/删；其它字段已在 st 上
  [self rewriteWuziFile];
}

- (void)reloadCurrentCategory {
  if (self.selectedCategoryIndex < 0 ||
      self.selectedCategoryIndex >= (NSInteger)self.categories.count) {
    self.currentItems = @[];
    [self.tableView reloadData];
    return;
  }
  NSString *cat = self.categories[self.selectedCategoryIndex];
  NSMutableArray *arr = [NSMutableArray array];
  for (NSDictionary *d in [ItemConfig getItemsForCategory:cat]) {
    NSString *cn = d[@"className"];
    MCItemState *st = self.stateByClass[cn];
    if (st) [arr addObject:st];
  }
  self.currentItems = arr;
  [self.tableView reloadData];
  [self updateCategoryButtonStyles];
}

#pragma mark - lootSize

- (void)reloadLootSizeFromPrefs {
  NSDictionary *prefs = NHPrefsRead();
  int size = prefs[@"lootSize"] ? [prefs[@"lootSize"] intValue] : 12;
  if (size < 6) size = 6;
  if (size > 24) size = 24;
  self.sizeSlider.value = size;
  self.sizeValueLabel.text = [NSString stringWithFormat:@"%d", size];
}

- (void)onSizeSliderChanged:(UISlider *)sender {
  int size = (int)lroundf(sender.value);
  if (size < 6) size = 6;
  if (size > 24) size = 24;
  sender.value = size;
  self.sizeValueLabel.text = [NSString stringWithFormat:@"%d", size];
  NHPrefsWrite(@{@"lootSize": @(size)});
}

#pragma mark - UI

- (void)setupChrome {
  UIColor *cyan = [UIColor cyanColor];
  UIColor *rowBg = [UIColor colorWithWhite:0.08 alpha:1.0];

  // 物资大小行
  UIView *sizeRow = [[UIView alloc] init];
  sizeRow.translatesAutoresizingMaskIntoConstraints = NO;
  sizeRow.backgroundColor = rowBg;
  [self.view addSubview:sizeRow];

  UILabel *sizeTitle = [[UILabel alloc] init];
  sizeTitle.translatesAutoresizingMaskIntoConstraints = NO;
  sizeTitle.text = @"物资大小";
  sizeTitle.textColor = cyan;
  sizeTitle.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
  [sizeRow addSubview:sizeTitle];

  self.sizeValueLabel = [[UILabel alloc] init];
  self.sizeValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.sizeValueLabel.textColor = [UIColor whiteColor];
  self.sizeValueLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightRegular];
  self.sizeValueLabel.textAlignment = NSTextAlignmentRight;
  [sizeRow addSubview:self.sizeValueLabel];

  self.sizeSlider = [[UISlider alloc] init];
  self.sizeSlider.translatesAutoresizingMaskIntoConstraints = NO;
  self.sizeSlider.minimumValue = 6;
  self.sizeSlider.maximumValue = 24;
  self.sizeSlider.minimumTrackTintColor = cyan;
  self.sizeSlider.maximumTrackTintColor = [UIColor colorWithWhite:0.25 alpha:1];
  [self.sizeSlider addTarget:self action:@selector(onSizeSliderChanged:) forControlEvents:UIControlEventValueChanged];
  [sizeRow addSubview:self.sizeSlider];
  [self reloadLootSizeFromPrefs];

  // 分类横向 chips
  self.categoryScroll = [[UIScrollView alloc] init];
  self.categoryScroll.translatesAutoresizingMaskIntoConstraints = NO;
  self.categoryScroll.showsHorizontalScrollIndicator = NO;
  self.categoryScroll.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1];
  [self.view addSubview:self.categoryScroll];

  self.categoryContent = [[UIView alloc] init];
  self.categoryContent.translatesAutoresizingMaskIntoConstraints = NO;
  [self.categoryScroll addSubview:self.categoryContent];

  UIButton *prevBtn = nil;
  for (NSInteger i = 0; i < (NSInteger)self.categories.count; i++) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.tag = 1000 + i;
    [btn setTitle:self.categories[i] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    btn.layer.cornerRadius = 14;
    btn.layer.borderWidth = 1.0;
    btn.contentEdgeInsets = UIEdgeInsetsMake(6, 12, 6, 12);
    [btn addTarget:self action:@selector(onCategoryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.categoryContent addSubview:btn];
    [self.categoryButtons addObject:btn];

    [NSLayoutConstraint activateConstraints:@[
      [btn.topAnchor constraintEqualToAnchor:self.categoryContent.topAnchor constant:8],
      [btn.bottomAnchor constraintEqualToAnchor:self.categoryContent.bottomAnchor constant:-8],
      [btn.heightAnchor constraintEqualToConstant:28],
    ]];
    if (prevBtn) {
      [btn.leadingAnchor constraintEqualToAnchor:prevBtn.trailingAnchor constant:8].active = YES;
    } else {
      [btn.leadingAnchor constraintEqualToAnchor:self.categoryContent.leadingAnchor constant:12].active = YES;
    }
    prevBtn = btn;
  }
  if (prevBtn) {
    [prevBtn.trailingAnchor constraintEqualToAnchor:self.categoryContent.trailingAnchor constant:-12].active = YES;
  }
  [self updateCategoryButtonStyles];

  // 表头说明
  UIView *header = [[UIView alloc] init];
  header.translatesAutoresizingMaskIntoConstraints = NO;
  header.backgroundColor = [UIColor colorWithWhite:0.06 alpha:1];
  [self.view addSubview:header];

  NSArray *cols = @[@"开启", @"物资", @"距离", @"颜色", @"枪隐"];
  UILabel *last = nil;
  for (NSInteger i = 0; i < (NSInteger)cols.count; i++) {
    UILabel *lb = [[UILabel alloc] init];
    lb.translatesAutoresizingMaskIntoConstraints = NO;
    lb.text = cols[i];
    lb.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    lb.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    lb.textAlignment = (i == 1) ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    [header addSubview:lb];
    [lb.centerYAnchor constraintEqualToAnchor:header.centerYAnchor].active = YES;
    [lb.heightAnchor constraintEqualToConstant:20].active = YES;
    if (i == 0) {
      [lb.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:10].active = YES;
      [lb.widthAnchor constraintEqualToConstant:44].active = YES;
    } else if (i == 1) {
      [lb.leadingAnchor constraintEqualToAnchor:last.trailingAnchor constant:4].active = YES;
      [lb.widthAnchor constraintGreaterThanOrEqualToConstant:60].active = YES;
    } else if (i == 2) {
      [lb.leadingAnchor constraintEqualToAnchor:last.trailingAnchor constant:4].active = YES;
      [lb.widthAnchor constraintEqualToConstant:56].active = YES;
    } else if (i == 3) {
      [lb.leadingAnchor constraintEqualToAnchor:last.trailingAnchor constant:4].active = YES;
      [lb.widthAnchor constraintEqualToConstant:36].active = YES;
    } else {
      [lb.leadingAnchor constraintEqualToAnchor:last.trailingAnchor constant:4].active = YES;
      [lb.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-10].active = YES;
      [lb.widthAnchor constraintEqualToConstant:48].active = YES;
    }
    last = lb;
  }

  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.backgroundColor = [UIColor blackColor];
  self.tableView.separatorColor = [UIColor colorWithWhite:0.18 alpha:1];
  self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  self.tableView.rowHeight = 52;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"mc"];
  [self.view addSubview:self.tableView];

  UILayoutGuide *g = self.view.safeAreaLayoutGuide;
  [NSLayoutConstraint activateConstraints:@[
    [sizeRow.topAnchor constraintEqualToAnchor:g.topAnchor],
    [sizeRow.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [sizeRow.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [sizeRow.heightAnchor constraintEqualToConstant:56],

    [sizeTitle.leadingAnchor constraintEqualToAnchor:sizeRow.leadingAnchor constant:14],
    [sizeTitle.centerYAnchor constraintEqualToAnchor:sizeRow.centerYAnchor],
    [sizeTitle.widthAnchor constraintEqualToConstant:72],

    [self.sizeValueLabel.trailingAnchor constraintEqualToAnchor:sizeRow.trailingAnchor constant:-14],
    [self.sizeValueLabel.centerYAnchor constraintEqualToAnchor:sizeRow.centerYAnchor],
    [self.sizeValueLabel.widthAnchor constraintEqualToConstant:28],

    [self.sizeSlider.leadingAnchor constraintEqualToAnchor:sizeTitle.trailingAnchor constant:10],
    [self.sizeSlider.trailingAnchor constraintEqualToAnchor:self.sizeValueLabel.leadingAnchor constant:-8],
    [self.sizeSlider.centerYAnchor constraintEqualToAnchor:sizeRow.centerYAnchor],

    [self.categoryScroll.topAnchor constraintEqualToAnchor:sizeRow.bottomAnchor],
    [self.categoryScroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.categoryScroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.categoryScroll.heightAnchor constraintEqualToConstant:44],

    [self.categoryContent.topAnchor constraintEqualToAnchor:self.categoryScroll.topAnchor],
    [self.categoryContent.bottomAnchor constraintEqualToAnchor:self.categoryScroll.bottomAnchor],
    [self.categoryContent.leadingAnchor constraintEqualToAnchor:self.categoryScroll.leadingAnchor],
    [self.categoryContent.trailingAnchor constraintEqualToAnchor:self.categoryScroll.trailingAnchor],
    [self.categoryContent.heightAnchor constraintEqualToAnchor:self.categoryScroll.heightAnchor],

    [header.topAnchor constraintEqualToAnchor:self.categoryScroll.bottomAnchor],
    [header.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [header.heightAnchor constraintEqualToConstant:28],

    [self.tableView.topAnchor constraintEqualToAnchor:header.bottomAnchor],
    [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)updateCategoryButtonStyles {
  UIColor *cyan = [UIColor cyanColor];
  for (NSInteger i = 0; i < (NSInteger)self.categoryButtons.count; i++) {
    UIButton *btn = self.categoryButtons[i];
    BOOL on = (i == self.selectedCategoryIndex);
    if (on) {
      [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
      btn.backgroundColor = cyan;
      btn.layer.borderColor = cyan.CGColor;
    } else {
      [btn setTitleColor:cyan forState:UIControlStateNormal];
      btn.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1];
      btn.layer.borderColor = [cyan colorWithAlphaComponent:0.35].CGColor;
    }
  }
}

- (void)onCategoryTapped:(UIButton *)sender {
  NSInteger idx = sender.tag - 1000;
  if (idx == self.selectedCategoryIndex) return;
  self.selectedCategoryIndex = idx;
  [self reloadCurrentCategory];
  // 滚到可见
  CGRect f = [sender convertRect:sender.bounds toView:self.categoryScroll];
  [self.categoryScroll scrollRectToVisible:CGRectInset(f, -20, 0) animated:YES];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.currentItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mc" forIndexPath:indexPath];
  for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.backgroundColor = [UIColor colorWithWhite:0.07 alpha:1];
  cell.contentView.backgroundColor = cell.backgroundColor;

  MCItemState *st = self.currentItems[indexPath.row];
  UIColor *cyan = [UIColor cyanColor];

  UISwitch *en = [[UISwitch alloc] init];
  en.translatesAutoresizingMaskIntoConstraints = NO;
  en.transform = CGAffineTransformMakeScale(0.72, 0.72);
  en.on = st.enabled;
  en.onTintColor = cyan;
  en.tag = 9000 + indexPath.row;
  [en addTarget:self action:@selector(onEnableChanged:) forControlEvents:UIControlEventValueChanged];
  [cell.contentView addSubview:en];

  UILabel *name = [[UILabel alloc] init];
  name.translatesAutoresizingMaskIntoConstraints = NO;
  name.text = st.displayName;
  name.textColor = [UIColor whiteColor];
  name.font = [UIFont systemFontOfSize:13];
  name.lineBreakMode = NSLineBreakByTruncatingTail;
  [cell.contentView addSubview:name];

  UITextField *dist = [[UITextField alloc] init];
  dist.translatesAutoresizingMaskIntoConstraints = NO;
  dist.tag = 6000 + indexPath.row;
  dist.text = [NSString stringWithFormat:@"%.0f", st.maxDistance];
  dist.textColor = [UIColor whiteColor];
  dist.font = [UIFont systemFontOfSize:13];
  dist.textAlignment = NSTextAlignmentCenter;
  dist.keyboardType = UIKeyboardTypeNumberPad;
  dist.returnKeyType = UIReturnKeyDone;
  dist.backgroundColor = [UIColor colorWithWhite:0.14 alpha:1];
  dist.layer.cornerRadius = 5;
  dist.layer.borderWidth = 0.5;
  dist.layer.borderColor = [cyan colorWithAlphaComponent:0.35].CGColor;
  dist.delegate = self;
  [cell.contentView addSubview:dist];

  UIButton *colorBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  colorBtn.translatesAutoresizingMaskIntoConstraints = NO;
  colorBtn.tag = 7000 + indexPath.row;
  colorBtn.backgroundColor = MCColorFromHex(st.hexColor);
  colorBtn.layer.cornerRadius = 5;
  colorBtn.layer.borderWidth = 1;
  colorBtn.layer.borderColor = [UIColor colorWithWhite:0.4 alpha:1].CGColor;
  [colorBtn addTarget:self action:@selector(onColorTapped:) forControlEvents:UIControlEventTouchUpInside];
  [cell.contentView addSubview:colorBtn];

  UISwitch *hide = [[UISwitch alloc] init];
  hide.translatesAutoresizingMaskIntoConstraints = NO;
  hide.transform = CGAffineTransformMakeScale(0.68, 0.68);
  hide.on = (st.weaponID == 0);
  hide.onTintColor = [UIColor colorWithRed:1 green:0.55 blue:0.2 alpha:1];
  hide.tag = 8000 + indexPath.row;
  [hide addTarget:self action:@selector(onHideChanged:) forControlEvents:UIControlEventValueChanged];
  [cell.contentView addSubview:hide];

  [NSLayoutConstraint activateConstraints:@[
    [en.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:8],
    [en.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    [en.widthAnchor constraintEqualToConstant:48],

    [name.leadingAnchor constraintEqualToAnchor:en.trailingAnchor constant:2],
    [name.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    [name.widthAnchor constraintGreaterThanOrEqualToConstant:56],

    [dist.leadingAnchor constraintEqualToAnchor:name.trailingAnchor constant:6],
    [dist.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    [dist.widthAnchor constraintEqualToConstant:56],
    [dist.heightAnchor constraintEqualToConstant:28],

    [colorBtn.leadingAnchor constraintEqualToAnchor:dist.trailingAnchor constant:6],
    [colorBtn.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    [colorBtn.widthAnchor constraintEqualToConstant:32],
    [colorBtn.heightAnchor constraintEqualToConstant:24],

    [hide.leadingAnchor constraintEqualToAnchor:colorBtn.trailingAnchor constant:6],
    [hide.trailingAnchor constraintLessThanOrEqualToAnchor:cell.contentView.trailingAnchor constant:-8],
    [hide.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
  ]];

  return cell;
}

#pragma mark - Actions

- (void)onEnableChanged:(UISwitch *)sender {
  NSInteger row = sender.tag - 9000;
  if (row < 0 || row >= (NSInteger)self.currentItems.count) return;
  MCItemState *st = self.currentItems[row];
  st.enabled = sender.on;
  [self upsertOrRemove:st];
}

- (void)onHideChanged:(UISwitch *)sender {
  NSInteger row = sender.tag - 8000;
  if (row < 0 || row >= (NSInteger)self.currentItems.count) return;
  MCItemState *st = self.currentItems[row];
  st.weaponID = sender.on ? 0 : 1;
  if (st.enabled) [self upsertOrRemove:st];
}

- (void)onColorTapped:(UIButton *)sender {
  NSInteger row = sender.tag - 7000;
  if (row < 0 || row >= (NSInteger)self.currentItems.count) return;
  MCItemState *st = self.currentItems[row];

  UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"物资颜色"
                                        message:@"输入 6 位十六进制颜色，如 0099FF"
                                 preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
    tf.text = st.hexColor ?: @"00FF00";
    tf.placeholder = @"RRGGBB";
    tf.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
  }];
  __weak typeof(self) weakSelf = self;
  [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    NSString *hex = alert.textFields.firstObject.text ?: @"";
    hex = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([hex hasPrefix:@"#"]) hex = [hex substringFromIndex:1];
    if (hex.length != 6) return;
    st.hexColor = hex;
    sender.backgroundColor = MCColorFromHex(hex);
    if (st.enabled) [weakSelf upsertOrRemove:st];
  }]];

  if (@available(iOS 14.0, *)) {
    [alert addAction:[UIAlertAction actionWithTitle:@"取色器" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      UIColorPickerViewController *picker = [[UIColorPickerViewController alloc] init];
      picker.selectedColor = MCColorFromHex(st.hexColor);
      picker.supportsAlpha = NO;
      objc_setAssociatedObject(picker, "mc_item", st, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      objc_setAssociatedObject(picker, "mc_btn", sender, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      picker.delegate = (id<UIColorPickerViewControllerDelegate>)weakSelf;
      [weakSelf presentViewController:picker animated:YES completion:nil];
    }]];
  }

  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController API_AVAILABLE(ios(14.0)) {
  MCItemState *st = objc_getAssociatedObject(viewController, "mc_item");
  UIButton *btn = objc_getAssociatedObject(viewController, "mc_btn");
  if (!st) return;
  UIColor *color = viewController.selectedColor;
  NSString *hex = MCHexFromColor(color);
  st.hexColor = hex;
  if (btn) btn.backgroundColor = color;
  if (st.enabled) [self upsertOrRemove:st];
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController API_AVAILABLE(ios(14.0)) {
  [self colorPickerViewControllerDidSelectColor:viewController];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
  NSInteger row = textField.tag - 6000;
  if (row < 0 || row >= (NSInteger)self.currentItems.count) return;
  MCItemState *st = self.currentItems[row];
  float v = [textField.text floatValue];
  if (v < 0) v = 0;
  if (v > 9999) v = 9999;
  st.maxDistance = v;
  textField.text = [NSString stringWithFormat:@"%.0f", v];
  if (st.enabled) [self upsertOrRemove:st];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
  if (string.length == 0) return YES;
  NSCharacterSet *ok = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
  return [ok isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:string]];
}

@end
