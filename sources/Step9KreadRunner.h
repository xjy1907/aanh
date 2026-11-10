//
//  Step9KreadRunner.h
//  验收⑨：跑 kfd exploit +（arm64e）PPL + kread 探针；不链 BBZView/PhysX
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Step9KreadRunner : NSObject

/// 在已 dlopen 越狱三库的前提下执行。log 可为 nil。
/// 返回 YES 表示读到内核 Mach-O magic。
+ (BOOL)runExploitAndProbeKreadWithLog:(void (^_Nullable)(NSString *line))logBlock;

@end

NS_ASSUME_NONNULL_END
