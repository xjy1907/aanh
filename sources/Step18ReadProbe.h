//
//  Step18ReadProbe.h
//  验收⑱：读取开关 + 游戏进程/模块基址探针；不链 PhysX / DrawView.mm
//

#import <Foundation/Foundation.h>
#import <sys/types.h>

NS_ASSUME_NONNULL_BEGIN

@interface Step18ReadProbe : NSObject

/// 内存 + NSUserDefaults 持久化的读取开关
+ (void)setReadingEnabled:(BOOL)enabled;
+ (BOOL)isReadingEnabled;

+ (pid_t)gamePid;
+ (uint64_t)moduleBase;

/// 在后台扫 ShadowTrackerExt 进程与主模块 Mach-O 基址。
/// 需已跑过 Step9（kread/physrw 原语就绪）。log 可为 nil。
/// 返回 YES 表示开关已开且（找到 pid+基址，或明确报告「游戏未启动」）。
+ (BOOL)probeOnceWithLog:(void (^_Nullable)(NSString *line))logBlock;

/// 开启读取后周期性探针（每 ~5s）；关闭读取时停止。
+ (void)startPollingWithLog:(void (^_Nullable)(NSString *line))logBlock;
+ (void)stopPolling;

+ (NSString *)statusSummary;

@end

NS_ASSUME_NONNULL_END
