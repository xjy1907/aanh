//
//  WeaponTextures.h — 手持武器 Metal 纹理（对标 wasd 手持图片）
//

#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

#ifdef __cplusplus
#include <map>

extern std::map<int, id<MTLTexture>> gWeaponTextures;

/// 在 HUD Metal 设备就绪后调用（异步加载）
extern "C" void InitWeaponTextures(id<MTLDevice> device);

/// 按武器 ID 取纹理；成功返回 true
extern "C" bool GetWeaponTexture(int weaponId, id<MTLTexture> *outTex);
#endif
