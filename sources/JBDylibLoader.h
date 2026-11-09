//
//  JBDylibLoader.h
//  按需 dlopen 越狱三库（验收③：冷启动不硬链，首屏后再加载）。
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
