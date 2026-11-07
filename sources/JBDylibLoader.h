//
//  JBDylibLoader.h
//  对齐 Dopamine：主程序可硬链 jailbreak dylib；未加载时再按需 dlopen。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// 确保 libchoma / libxpf / libjailbreak 已加载（含打包后的 libNH*）。
BOOL JBEnsureJailbreakDylibsLoaded(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
