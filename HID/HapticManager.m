

#import "HapticManager.h"
#import <CoreHaptics/CoreHaptics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <os/log.h>
#import "rootless.h"
#import "NSUserDefaults+Private.h"
#if DEBUG
    #define log_debug os_log_debug
    #define log_info os_log_info
    #define log_error os_log_error
#else
    #define log_debug(...)
    #define log_info(...)
    #define log_error(...)
#endif
#if !NO_TROLL
    #define USER_DEFAULTS_PATH @"/var/mobile/Library/Preferences/com.Laote.YuanBao.plist"
#else
    #define USER_DEFAULTS_PATH ([[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"com.Laote.YuanBao.plist"])
#endif
@interface HapticManager ()

@property (nonatomic, strong) CHHapticEngine *engine;

@end

@implementation HapticManager
static CHHapticEngine *_hapticEngine = nil;
+ (instancetype)sharedManager {
    static HapticManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}
 void InitHapticEngineIfNeeded(void) {
    if (@available(iOS 13.0, *)) {
        if (_hapticEngine) return;

        if (![CHHapticEngine capabilitiesForHardware].supportsHaptics) return;

        NSError *error = nil;
        _hapticEngine = [[CHHapticEngine alloc] initAndReturnError:&error];
        if (error) {
            NSLog(@"HapticEngine init error: %@", error);
            _hapticEngine = nil;
            return;
        }

        [_hapticEngine startWithCompletionHandler:^(NSError * _Nullable error) {
            if (error) NSLog(@"HapticEngine start error: %@", error);
        }];
    }
}
void PlayHapticIfEnabled(void) {
    if (@available(iOS 13.0, *)) {
        InitHapticEngineIfNeeded();
        if (!_hapticEngine) return;

        // 读取你的自定义 Plist 配置
        NSString *plistPath = [NSString stringWithFormat:USER_DEFAULTS_PATH]; // USER_DEFAULTS_PATH 是 const char *
        NSDictionary *zimiao = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        if (![zimiao isKindOfClass:[NSDictionary class]]) return;

        NSNumber *enabledNum = [zimiao objectForKey:@"vibrationEnabled"];
        if (![enabledNum boolValue]) return;

        NSNumber *strengthNum = [zimiao objectForKey:@"hapticsStrength"];
        float strength = MAX(0.05, MIN(1.0, [strengthNum floatValue]));

        // 构造震动事件
        CHHapticEventParameter *intensity = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:strength];
        CHHapticEventParameter *sharpness = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:strength];

        CHHapticEvent *event = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticTransient
                                                              parameters:@[intensity, sharpness]
                                                             relativeTime:0];

        NSError *patternError = nil;
        CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithEvents:@[event] parameters:@[] error:&patternError];
        if (patternError) {
            NSLog(@"Haptic pattern error: %@", patternError);
            return;
        }

        id<CHHapticPatternPlayer> player = [_hapticEngine createPlayerWithPattern:pattern error:&patternError];
        if (patternError) {
            NSLog(@"Haptic player error: %@", patternError);
            return;
        }

        [player startAtTime:0 error:nil];
    }
}

@end
