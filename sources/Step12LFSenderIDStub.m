//
//  Step12LFSenderIDStub.m
//  验收⑫：为 AimConfig 提供 LFSenderID 占位实现，避免链入 HID/Digitizer/MBProgressHUD
//

#import "LFSenderIDViewController.h"

@implementation LFSenderIDViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.title = @"SenderID（⑫桩）";
  UILabel *label = [[UILabel alloc] init];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.text = @"STEP12：SenderID/HID 尚未挂载\n返回即可";
  label.textColor = [UIColor cyanColor];
  label.numberOfLines = 0;
  label.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:label];
  [NSLayoutConstraint activateConstraints:@[
    [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24],
    [label.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24],
  ]];
  self.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithTitle:@"关闭"
                                       style:UIBarButtonItemStyleDone
                                      target:self
                                      action:@selector(onClose)];
}

- (void)onClose {
  if (self.dismissOnSelect || self.presentingViewController || self.navigationController) {
    if (self.navigationController.viewControllers.firstObject == self && self.presentingViewController) {
      [self dismissViewControllerAnimated:YES completion:nil];
    } else {
      [self.navigationController popViewControllerAnimated:YES];
    }
  }
}

@end
