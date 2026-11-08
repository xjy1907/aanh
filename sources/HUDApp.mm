//
//  HUDApp.mm — iPadOS15.3 诊断壳：冷启动只进 UI，不拉 HUD/越狱路径
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
  @autoreleasepool {
    // 对齐 Dopamine：principalClass = nil
    return UIApplicationMain(argc, argv, nil, @"MainApplicationDelegate");
  }
}
