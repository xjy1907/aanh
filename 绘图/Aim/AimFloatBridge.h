//
//  AimFloatBridge.h — 自瞄悬浮球开关桥（对标 qwer ImGuiDraw isAimEnabled/toggleAimEnabled）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AimFloatBridge : NSObject
+ (BOOL)isAimEnabled;
+ (BOOL)toggleAimEnabled;
@end

NS_ASSUME_NONNULL_END
