//
//  KernelcacheLocator.h
//  验收⑦：对齐 Dopamine accessibleKernelPath（可读检测 + preboot + 下载回退）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KernelcacheLocator : NSObject

/// 返回真正可读、可 open 的 kernelcache 路径；失败返回 nil。
/// logBlock 可为 nil。
+ (nullable NSString *)accessibleKernelPathWithLog:(void (^_Nullable)(NSString *line))logBlock;

@end

NS_ASSUME_NONNULL_END
