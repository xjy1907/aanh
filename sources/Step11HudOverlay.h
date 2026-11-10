//
//  Step11HudOverlay.h
//  验收⑭：进程内 HUD + 过直播安全链宿主；不 spawn 子进程、不链 DrawView/PhysX
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Step11HudOverlay : NSObject

+ (instancetype)shared;

@property(nonatomic, assign, readonly, getter=isVisible) BOOL visible;

/// 显示/隐藏高窗级叠层；detail 显示在条带上（可空）
- (void)setVisible:(BOOL)visible detail:(NSString *_Nullable)detail;

- (void)updateDetail:(NSString *)detail;

@end

NS_ASSUME_NONNULL_END
