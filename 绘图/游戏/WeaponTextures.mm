//
//  WeaponTextures.mm — 对标 wasd：stb_image 解码 + Shared MTLTexture
//

#import "WeaponTextures.h"
#import <UIKit/UIKit.h>
#include <map>
#include <mutex>

#include "stb/stb_image.h"

#include "images/head.h"

std::map<int, id<MTLTexture>> gWeaponTextures;
static std::mutex gWeaponTexMutex;
static BOOL gWeaponTexReady = NO;

static id<MTLTexture> LoadTexFromMemory(id<MTLDevice> device, const unsigned char *data, size_t length) {
    if (!device || !data || length == 0) return nil;
    int w = 0, h = 0, channels = 0;
    unsigned char *pixels = stbi_load_from_memory(data, (int)length, &w, &h, &channels, STBI_rgb_alpha);
    if (!pixels || w <= 0 || h <= 0) {
        if (pixels) stbi_image_free(pixels);
        return nil;
    }
    MTLTextureDescriptor *desc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                           width:w
                                                          height:h
                                                       mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead;
    desc.storageMode = MTLStorageModeShared;
    id<MTLTexture> texture = [device newTextureWithDescriptor:desc];
    if (!texture) {
        stbi_image_free(pixels);
        return nil;
    }
    MTLRegion region = MTLRegionMake2D(0, 0, (NSUInteger)w, (NSUInteger)h);
    [texture replaceRegion:region mipmapLevel:0 withBytes:pixels bytesPerRow:(NSUInteger)w * 4];
    stbi_image_free(pixels);
    return texture;
}

static void SetupTextureMappings(void) {
    auto &M = gWeaponTextures;
#define ALIAS(dst, src) do { auto it = M.find(src); if (it != M.end() && it->second) M[dst] = it->second; } while (0)
    ALIAS(9811015, 102003); ALIAS(9813064, 105015); ALIAS(9811057, 102003); ALIAS(9811058, 102003);
    ALIAS(9812130, 101010); ALIAS(9812125, 101004); ALIAS(9812126, 101005); ALIAS(9812127, 101006);
    ALIAS(9812124, 101003); ALIAS(9812131, 101012); ALIAS(9812143, 101013); ALIAS(9812129, 101008);
    ALIAS(9815094, 103014); ALIAS(9815091, 103007); ALIAS(9815092, 103009); ALIAS(9815090, 103004);
    ALIAS(9811067, 102007); ALIAS(9811068, 102105); ALIAS(9811066, 102003); ALIAS(9813056, 105013);
    ALIAS(9813053, 105010); ALIAS(9813054, 105012); ALIAS(9814074, 103012); ALIAS(9812153, 103100);
    ALIAS(9812154, 103100); ALIAS(9812155, 103100); ALIAS(9812156, 103100); ALIAS(9811036, 102007);
    ALIAS(9811043, 102008); ALIAS(9812143, 101014); ALIAS(9811050, 102105); ALIAS(9811061, 102105);
    ALIAS(9811062, 102105); ALIAS(9812002, 101001); ALIAS(9812123, 101001); ALIAS(9812015, 101003);
    ALIAS(9812023, 101004); ALIAS(9812029, 101005); ALIAS(9812099, 101005); ALIAS(9812100, 101005);
    ALIAS(9812036, 101006); ALIAS(9812101, 101006); ALIAS(9812102, 101006); ALIAS(9812043, 101007);
    ALIAS(9812103, 101007); ALIAS(9812104, 101007); ALIAS(9812050, 101008); ALIAS(9812105, 101008);
    ALIAS(9812106, 101008); ALIAS(9812064, 101010); ALIAS(9812107, 101010); ALIAS(9812108, 101010);
    ALIAS(9812078, 101012); ALIAS(9812109, 101012); ALIAS(9812110, 101012); ALIAS(9812085, 101013);
    ALIAS(9812111, 101013); ALIAS(9812112, 101013); ALIAS(9813001, 105001); ALIAS(9813035, 105001);
    ALIAS(9813036, 105001); ALIAS(9813022, 105010); ALIAS(9813037, 105010); ALIAS(9813038, 105010);
    ALIAS(9813029, 105012); ALIAS(9813039, 105012); ALIAS(9813040, 105012); ALIAS(9814008, 103002);
    ALIAS(9814015, 103003); ALIAS(9814060, 103003); ALIAS(9814061, 103003); ALIAS(9814036, 103012);
    ALIAS(9814062, 103012); ALIAS(9814063, 103012); ALIAS(103904, 103012); ALIAS(9814043, 103015);
    ALIAS(9814064, 103015); ALIAS(9814065, 103015); ALIAS(9815001, 103004); ALIAS(9815072, 103004);
    ALIAS(9815073, 103004); ALIAS(9815022, 103007); ALIAS(9815074, 103007); ALIAS(9815075, 103007);
    ALIAS(9815029, 103009); ALIAS(9815076, 103009); ALIAS(9815077, 103009); ALIAS(9815043, 103013);
    ALIAS(9815078, 103013); ALIAS(9815079, 103013); ALIAS(9815050, 103014); ALIAS(9815080, 103014);
    ALIAS(9815081, 103014); ALIAS(9815064, 103100); ALIAS(9815082, 103100); ALIAS(9815083, 103100);
    ALIAS(9825001, 602001); ALIAS(9825002, 602002); ALIAS(9825003, 602003); ALIAS(9825004, 602004);
    ALIAS(9826001, 602004); ALIAS(9826002, 602004); ALIAS(9810015, 104003); ALIAS(9810025, 104004);
    ALIAS(9810032, 104100); ALIAS(9810043, 104005); ALIAS(602104, 108001);
#undef ALIAS
}

extern "C" void InitWeaponTextures(id<MTLDevice> device) {
    if (!device) return;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        id<MTLDevice> retainedDevice = device;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            std::map<int, id<MTLTexture>> local;
#define L(wid) do { id<MTLTexture> t = LoadTexFromMemory(retainedDevice, picture_##wid##_png, sizeof(picture_##wid##_png)); if (t) local[wid] = t; } while (0)
            L(101001); L(101002); L(101003); L(101004); L(101005); L(101006); L(101007); L(101008);
            L(101009); L(101010); L(101011); L(101012); L(101013); L(101014); L(101016);
            L(102001); L(102002); L(102003); L(102004); L(102005); L(102007); L(102008); L(102009);
            L(102010); L(102105);
            L(103001); L(103002); L(103003); L(103004); L(103005); L(103006); L(103007); L(103008);
            L(103009); L(103010); L(103011); L(103012); L(103013); L(103014); L(103015); L(103016);
            L(103017); L(103018); L(103100); L(103101); L(103901); L(103902); L(103903);
            L(104001); L(104002); L(104003); L(104004); L(104005); L(104100);
            L(105001); L(105002); L(105010); L(105012); L(105013); L(105015);
            L(106001); L(106002); L(106003); L(106004); L(106005); L(106006); L(106007); L(106008);
            L(106010); L(106011); L(106013);
            L(107001); L(107006); L(107007); L(107008); L(107010); L(107100); L(107909); L(107910);
            L(108001); L(108002); L(108003); L(108004);
            L(602001); L(602002); L(602003); L(602004); L(602075); L(603201);
#undef L
            {
                std::lock_guard<std::mutex> lock(gWeaponTexMutex);
                gWeaponTextures.swap(local);
                SetupTextureMappings();
                gWeaponTexReady = YES;
            }
            NSLog(@"[WeaponTextures] loaded %zu textures", gWeaponTextures.size());
        });
    });
}

extern "C" bool GetWeaponTexture(int weaponId, id<MTLTexture> *outTex) {
    if (!outTex || weaponId <= 0) return false;
    std::lock_guard<std::mutex> lock(gWeaponTexMutex);
    if (!gWeaponTexReady) return false;
    auto it = gWeaponTextures.find(weaponId);
    if (it == gWeaponTextures.end() || !it->second) return false;
    *outTex = it->second;
    return true;
}
