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
/// 真正杀掉叠层进程（重置内核等场景）；普通「停止绘制」只 pause，不调用此函数
OBJC_EXTERN void TerminateHUDProcess(void);
OBJC_EXTERN void fasongxuni(void);
#if DEBUG
OBJC_EXTERN void SimulateMemoryPressure(void);
#endif

OBJC_EXTERN NSUserDefaults *GetStandardUserDefaults(void);

NS_ASSUME_NONNULL_END
