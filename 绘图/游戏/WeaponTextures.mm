//
//  WeaponTextures.mm — 从 wasd 嵌入 PNG 加载 MTLTexture
//

#import "WeaponTextures.h"
#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>
#include <map>

#include "images/head.h"

std::map<int, id<MTLTexture>> gWeaponTextures;

static id<MTLTexture> LoadTexFromMemory(id<MTLDevice> device, const unsigned char *data, size_t length) {
    if (!device || !data || length == 0) return nil;
    @autoreleasepool {
        NSData *ns = [NSData dataWithBytesNoCopy:(void *)data length:length freeWhenDone:NO];
        UIImage *img = [UIImage imageWithData:ns];
        if (!img || !img.CGImage) return nil;
        MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:device];
        NSError *err = nil;
        NSDictionary *opts = @{
            MTKTextureLoaderOptionSRGB : @NO,
            MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
        };
        id<MTLTexture> tex = [loader newTextureWithCGImage:img.CGImage options:opts error:&err];
        return tex;
    }
}

static void SetupTextureMappings(void) {
    auto &M = gWeaponTextures;
    M[9811015] = M[102003];
    M[9813064] = M[105015];
    M[9811057] = M[102003];
    M[9811058] = M[102003];
    M[9812130] = M[101010];
    M[9812125] = M[101004];
    M[9812126] = M[101005];
    M[9812127] = M[101006];
    M[9812124] = M[101003];
    M[9812131] = M[101012];
    M[9812143] = M[101013];
    M[9812129] = M[101008];
    M[9815094] = M[103014];
    M[9815091] = M[103007];
    M[9815092] = M[103009];
    M[9815090] = M[103004];
    M[9811067] = M[102007];
    M[9811068] = M[102105];
    M[9811066] = M[102003];
    M[9813056] = M[105013];
    M[9813053] = M[105010];
    M[9813054] = M[105012];
    M[9814074] = M[103012];
    M[9812153] = M[103100];
    M[9812154] = M[103100];
    M[9812155] = M[103100];
    M[9812156] = M[103100];
    M[9811036] = M[102007];
    M[9811043] = M[102008];
    M[9812143] = M[101014];
    M[9811050] = M[102105];
    M[9811061] = M[102105];
    M[9811062] = M[102105];
    M[9812002] = M[101001];
    M[9812123] = M[101001];
    M[9812015] = M[101003];
    M[9812023] = M[101004];
    M[9812029] = M[101005];
    M[9812099] = M[101005];
    M[9812100] = M[101005];
    M[9812036] = M[101006];
    M[9812101] = M[101006];
    M[9812102] = M[101006];
    M[9812043] = M[101007];
    M[9812103] = M[101007];
    M[9812104] = M[101007];
    M[9812050] = M[101008];
    M[9812105] = M[101008];
    M[9812106] = M[101008];
    M[9812064] = M[101010];
    M[9812107] = M[101010];
    M[9812108] = M[101010];
    M[9812078] = M[101012];
    M[9812109] = M[101012];
    M[9812110] = M[101012];
    M[9812085] = M[101013];
    M[9812111] = M[101013];
    M[9812112] = M[101013];
    M[9813001] = M[105001];
    M[9813035] = M[105001];
    M[9813036] = M[105001];
    M[9813022] = M[105010];
    M[9813037] = M[105010];
    M[9813038] = M[105010];
    M[9813029] = M[105012];
    M[9813039] = M[105012];
    M[9813040] = M[105012];
    M[9814008] = M[103002];
    M[9814015] = M[103003];
    M[9814060] = M[103003];
    M[9814061] = M[103003];
    M[9814036] = M[103012];
    M[9814062] = M[103012];
    M[9814063] = M[103012];
    M[103904] = M[103012];
    M[9814043] = M[103015];
    M[9814064] = M[103015];
    M[9814065] = M[103015];
    M[9815001] = M[103004];
    M[9815072] = M[103004];
    M[9815073] = M[103004];
    M[9815022] = M[103007];
    M[9815074] = M[103007];
    M[9815075] = M[103007];
    M[9815029] = M[103009];
    M[9815076] = M[103009];
    M[9815077] = M[103009];
    M[9815043] = M[103013];
    M[9815078] = M[103013];
    M[9815079] = M[103013];
    M[9815050] = M[103014];
    M[9815080] = M[103014];
    M[9815081] = M[103014];
    M[9815064] = M[103100];
    M[9815082] = M[103100];
    M[9815083] = M[103100];
    M[9825001] = M[602001];
    M[9825002] = M[602002];
    M[9825003] = M[602003];
    M[9825004] = M[602004];
    M[9826001] = M[602004];
    M[9826002] = M[602004];
    M[9810015] = M[104003];
    M[9810025] = M[104004];
    M[9810032] = M[104100];
    M[9810043] = M[104005];
    M[602104] = M[108001];
}

extern "C" void InitWeaponTextures(id<MTLDevice> device) {
    if (!device) return;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
#define L(id) gWeaponTextures[id] = LoadTexFromMemory(device, picture_##id##_png, sizeof(picture_##id##_png))
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
            SetupTextureMappings();
        });
    });
}

extern "C" bool GetWeaponTexture(int weaponId, id<MTLTexture> *outTex) {
    if (!outTex || weaponId <= 0) return false;
    auto it = gWeaponTextures.find(weaponId);
    if (it == gWeaponTextures.end() || !it->second) return false;
    *outTex = it->second;
    return true;
}
