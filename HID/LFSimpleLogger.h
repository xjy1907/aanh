
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 每次追加日志都会触发的通知；userInfo 里通常包含 @{ @"line": <NSString*> }；清空时为 @{ @"clear": @YES }
FOUNDATION_EXPORT NSNotificationName const LFSimpleLoggerDidAppendNotification;

@interface LFSimpleLogger : NSObject

/// 单例
+ (instancetype)shared;

/// 追加一行日志（自动加时间戳）
- (void)logLine:(NSString *)line;

/// 获取全部日志（数组内为 NSString；按写入顺序）
- (NSArray<NSString *> *)allLines;

/// 清空日志（会发 LFSimpleLoggerDidAppendNotification，userInfo= @{@"clear":@YES}）
- (void)clear;

/// 导出日志到 Documents/*.txt，返回文件 URL；失败时返回 nil 并通过 error 回传
- (nullable NSURL *)exportToFileWithError:(NSError **)error;

/// 可选：设置最大缓存行数（默认 2000）
- (void)setMaxLines:(NSUInteger)maxLines;

@end

/// 便捷写日志宏（用法与 NSLog 类似）
#define LFDLog(fmt, ...) [[LFSimpleLogger shared] logLine:[NSString stringWithFormat:(fmt), ##__VA_ARGS__]]

#pragma mark - 日志页面

@interface LFLogsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

NS_ASSUME_NONNULL_END
