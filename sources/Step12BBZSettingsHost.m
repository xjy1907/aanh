//
//  Step12BBZSettingsHost.m
//

#import "Step12BBZSettingsHost.h"
#import "DrawSettingsViewController.h"
#import "AimConfigViewController.h"
#import "AimHumanizeConfigViewController.h"
#import "AimBezierConfigViewController.h"
#import "MaterialConfigViewController.h"

__attribute__((used)) static const char kStep12Marker[] = "STEP12-BBZVCS";

@interface Step12BBZSettingsHost () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray<NSDictionary *> *rows;
@end

@implementation Step12BBZSettingsHost

- (void)viewDidLoad {
  [super viewDidLoad];
  volatile const char *keep = kStep12Marker;
  (void)keep[0];

  self.view.backgroundColor = [UIColor colorWithRed:18.0f / 255.0f
                                               green:10.0f / 255.0f
                                                blue:28.0f / 255.0f
                                               alpha:1.0f];
  self.title = @"STEP12-BBZ 设置";
  self.navigationItem.leftBarButtonItem =
      [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                       style:UIBarButtonItemStyleDone
                                      target:self
                                      action:@selector(onClose)];
  if (@available(iOS 13.0, *)) {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor =
        [UIColor colorWithRed:200.0f / 255.0f green:120.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f];
    self.navigationController.navigationBar.titleTextAttributes =
        @{NSForegroundColorAttributeName : [UIColor colorWithRed:200.0f / 255.0f
                                                           green:120.0f / 255.0f
                                                            blue:255.0f / 255.0f
                                                           alpha:1.0f]};
  }

  self.rows = @[
    @{@"title" : @"绘制设置", @"kind" : @"draw"},
    @{@"title" : @"自瞄功能", @"kind" : @"aim"},
    @{@"title" : @"自瞄拟人", @"kind" : @"human"},
    @{@"title" : @"自瞄贝塞尔", @"kind" : @"bezier"},
    @{@"title" : @"物资/材质", @"kind" : @"material"},
  ];

  UILabel *hint = [[UILabel alloc] init];
  hint.translatesAutoresizingMaskIntoConstraints = NO;
  hint.text = @"⑪已过：进程内 HUD 叠层\n⑫：挂载 BBZ 真实设置 ViewController\n仍不链 BBZView.mm / PhysX / DrawView";
  hint.textColor = [UIColor colorWithWhite:0.78f alpha:1.0f];
  hint.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightMedium];
  hint.textAlignment = NSTextAlignmentCenter;
  hint.numberOfLines = 0;

  UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
  table.translatesAutoresizingMaskIntoConstraints = NO;
  table.dataSource = self;
  table.delegate = self;
  table.backgroundColor = [UIColor clearColor];
  if (@available(iOS 13.0, *)) {
    table.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
  }
  [table registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
  self.tableView = table;

  [self.view addSubview:hint];
  [self.view addSubview:table];
  [NSLayoutConstraint activateConstraints:@[
    [hint.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
    [hint.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
    [hint.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    [table.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:12],
    [table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)onClose {
  if (self.presentingViewController) {
    [self dismissViewControllerAnimated:YES completion:nil];
  } else if (self.navigationController.presentingViewController) {
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  return (NSInteger)self.rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
  cell.textLabel.text = self.rows[(NSUInteger)indexPath.row][@"title"];
  cell.textLabel.textColor = [UIColor whiteColor];
  cell.backgroundColor = [UIColor colorWithRed:30.0f / 255.0f green:18.0f / 255.0f blue:45.0f / 255.0f alpha:0.95f];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  NSString *kind = self.rows[(NSUInteger)indexPath.row][@"kind"];
  UIViewController *vc = nil;
  if ([kind isEqualToString:@"draw"]) {
    vc = [[DrawSettingsViewController alloc] init];
  } else if ([kind isEqualToString:@"aim"]) {
    vc = [[AimConfigViewController alloc] init];
  } else if ([kind isEqualToString:@"human"]) {
    vc = [[AimHumanizeConfigViewController alloc] init];
  } else if ([kind isEqualToString:@"bezier"]) {
    vc = [[AimBezierConfigViewController alloc] init];
  } else if ([kind isEqualToString:@"material"]) {
    vc = [[MaterialConfigViewController alloc] init];
  }
  if (vc) {
    [self.navigationController pushViewController:vc animated:YES];
  }
}

@end
