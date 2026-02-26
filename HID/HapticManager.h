
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface HapticManager : NSObject

+ (instancetype)sharedManager;


@end
#if __cplusplus
extern "C" {
#endif
void PlayHapticIfEnabled(void);
void InitHapticEngineIfNeeded(void);
#ifdef __cplusplus
}
#endif

