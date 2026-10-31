//
//  HUDHelper.h
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN BOOL IsHUDEnabled(void);
OBJC_EXTERN void SetHUDEnabled(BOOL isEnabled);
/// 先通知 HUD 硬拆叠层进程内核原语（握手），再 SetHUDEnabled(NO)；不碰主进程原语
OBJC_EXTERN void HardTeardownHUDOverlayThenDisable(void);
OBJC_EXTERN void fasongxuni(void);
#if DEBUG
OBJC_EXTERN void SimulateMemoryPressure(void);
#endif

OBJC_EXTERN NSUserDefaults *GetStandardUserDefaults(void);

NS_ASSUME_NONNULL_END
