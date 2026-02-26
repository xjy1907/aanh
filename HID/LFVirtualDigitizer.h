
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface LFVirtualDigitizer : NSObject

/// 单例
+ (instancetype)shared;

/// 启动：每 2 秒“按下→1 秒后抬起”一次（若已启动则无操作）
- (void)jiazai;

/// 停止周期点击
- (void)stop;

/// 一次性点击：在 [0,1] 归一化坐标按下并在 duration 秒后抬起
- (void)pressAtX:(float)x y:(float)y duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
