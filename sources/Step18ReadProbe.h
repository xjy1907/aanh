//
//  Step18ReadProbe.h
//  验收⑱：读取开关 + 游戏进程/模块基址探针；不链 PhysX / DrawView.mm
//

#import <Foundation/Foundation.h>
#import <sys/types.h>

NS_ASSUME_NONNULL_BEGIN

@interface Step18ReadProbe : NSObject

+ (void)setReadingEnabled:(BOOL)enabled;
+ (BOOL)isReadingEnabled;

+ (pid_t)gamePid;
+ (uint64_t)moduleBase;

/// 读目标游戏进程用户态内存（需已找到模块基址或至少 pid + 内核就绪）
+ (BOOL)readGameAt:(uint64_t)address size:(size_t)size into:(void *)buffer;

+ (BOOL)probeOnceWithLog:(void (^_Nullable)(NSString *line))logBlock;
+ (void)startPollingWithLog:(void (^_Nullable)(NSString *line))logBlock;
+ (void)stopPolling;

+ (NSString *)statusSummary;

@end

NS_ASSUME_NONNULL_END
