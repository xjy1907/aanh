#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <sys/stat.h>
#import <objc/runtime.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <stdio.h>
#import <spawn.h>
#include <sys/syscall.h>
#import <CommonCrypto/CommonDigest.h>
#import <mach-o/dyld.h>
#import <Security/Security.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <dlfcn.h>
#include <vector>
#include <string>


extern "C" char **environ;
#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern "C" int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern "C" int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern "C" int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

#pragma mark - ==== 白苹果 ====
void sub_56987(){
    char* (^getExecutablePath)(void) = ^{
        static char *executablePath = NULL;
        uint32_t executablePathSize = 0;
        _NSGetExecutablePath(NULL, &executablePathSize);
        executablePath = (char *)calloc(1, executablePathSize);
        _NSGetExecutablePath(executablePath, &executablePathSize);
        return executablePath;
    };
    NSArray *SystemPath = @[@"/private", @"/var", @"/usr", @"/System", @"/bin", @"/sbin", @"/etc", @"/Library", @"/Applications", @"/dev", @"/tmp"];
    char* (^md5HashForString)(const char*) = ^(const char *input) {
        unsigned char result[CC_MD5_DIGEST_LENGTH];
        CC_MD5(input, (CC_LONG)strlen(input), result);
        static char hash[CC_MD5_DIGEST_LENGTH * 2 + 1];
        for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            sprintf(&hash[i * 2], "%02x", result[i]);
        }
        return hash;
    };
    NSMutableDictionary *pathMD5Dict = [NSMutableDictionary dictionary];
    for (NSString *path in SystemPath) {
        const char *md5Hash = md5HashForString([path UTF8String]);
        [pathMD5Dict setObject:[NSString stringWithUTF8String:md5Hash] forKey:path];
    }
    NSMutableDictionary *oldPathMD5Dict = [@{
        @"/private": @"770b76f7b7b90b1c020ff5111c7b62af",
        @"/var": @"ca905eb4a00d34150573153a09e2e79b",
        @"/usr": @"7d8fdfd7c15a233be456f2a7a7f5337a",
        @"/System": @"65434fc2911ecf2484bc33faec5b69df",
        @"/bin": @"1e80cb7e0fbfc9f5c0509a465ecdf6cf",
        @"/sbin": @"d9c3798c24c3214b3d0847559ab67d13",
        @"/etc": @"182f153bd94803955c2043e6f2581d5d",
        @"/Library": @"6c803e6d59cbeb467aea0a02dc85e822",
        @"/Applications": @"99c6f258f11a8f14a4d460f8e1c9fc4d",
        @"/dev": @"5a500f0368bd01ae8dc965a89133d5b3",
        @"/tmp": @"d42b9c57d24cf5db3bd8d332dc35437f"
    } mutableCopy];
    for (NSString *path in pathMD5Dict) {
        NSString *newHash = pathMD5Dict[path];
        NSString *oldHash = oldPathMD5Dict[path];
        if (![newHash isEqualToString:oldHash]) exit(-1);
    }
    const char *executablePath = getExecutablePath();
    if (executablePath == NULL || SystemPath.count == 0) exit(-1);
    for (NSString *path in SystemPath) {
        posix_spawnattr_t attr;
        posix_spawnattr_init(&attr);
        posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
        posix_spawnattr_set_persona_uid_np(&attr, 0);
        posix_spawnattr_set_persona_gid_np(&attr, 0);
        pid_t task_pid;
        posix_spawnattr_setpgroup(&attr, 0);
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);
        std::string str = std::to_string(50);
        const char* cstr = str.c_str();
        const char *args[] = {executablePath, "-PermThread", path.UTF8String, cstr, NULL};
        for (int i = 0; args[i] != NULL; i++) {
            if (args[i] == NULL) exit(-1);
        }
        int spawnResult = posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);
        if (spawnResult != 0) return;
        int status;
        do {
            if (waitpid(task_pid, &status, 0) != -1) {}
        } while (!WIFEXITED(status) && !WIFSIGNALED(status));
    }
    syscall(SYS_kill, getpid(), SIGKILL);
    __builtin_trap();
}
#pragma mark - ==== 白名单（可修改 4 个） ====
static const char *WHITE_LIST[12] = {
    "libchoma.dylib",
    "libjailbreak.dylib",
    "rm",
    "forkfix.dylib",
    "libswift_Concurrency.dylib",
    "badRecovery.framework",
    "dmaFail.framework",
    "kfd.framework",
    "multicast_bytecopy.framework",
    "weightBufs.framework",
    "Books.app/Books",
    "libxpf.dylib"
};

static bool isInWhiteList(const char *name)
{
    if (!name) return false;
    for (auto &it : WHITE_LIST)
        if (it && strstr(name, it))
            return true;
    return false;
}

#pragma mark - ==== 不检测系统路径 ====
static bool isSystemPath(const char *name)
{
    if (!name) return true;

    return
        strstr(name, "/usr/lib/") ||
        strstr(name, "/System/Library/") ||
        strstr(name, "/usr/lib/systemhook");   // systemhook-xxxx.dylib
}

#pragma mark - ==== 自定义 strstr（防 Hook）====
static bool gd_strstr(const char *hay, const char *needle)
{
    if (!hay || !needle) return false;
    const char *h = hay;
    const char *n = needle;

    while (*h)
    {
        const char *p1 = h;
        const char *p2 = n;
        while (*p1 && *p2 && *p1 == *p2)
        { p1++; p2++; }
        if (*p2 == 0) return true;
        h++;
    }
    return false;
}

#pragma mark - ==== 动态库注入检测 ====
static void reportInjected(const char *name)
{
    if (!name) return;
    if (isSystemPath(name)) return;
    if (isInWhiteList(name)) return;

    if (gd_strstr(name, "/Library/MobileSubstrate") ||
        gd_strstr(name, "/usr/lib/TweakInject")     ||
        gd_strstr(name, ".dylib"))
    {
        exit(1337);
        //sub_56987();
    }
}

#pragma mark - ==== dyld 回调 ====
static void imageAdded(const struct mach_header *mh, intptr_t slide)
{
    uint32_t count = _dyld_image_count();
    const char *name = _dyld_get_image_name(count - 1);


    reportInjected(name);
}

#pragma mark - ==== 自身隐藏 ====
static const char *(*orig_getImageName)(uint32_t);

static const char *my_getImageName(uint32_t idx)
{
    const char *ret = orig_getImageName(idx);
    if (!ret) return ret;

    if (gd_strstr(ret, "AntiInjectPlus.dylib"))
        return "/System/Library/Frameworks/UIKit.framework/UIKit";

    return ret;
}

#pragma mark - ==== 初始化 ====
__attribute__((constructor))
static void AntiInjectInit()
{
    orig_getImageName = (decltype(orig_getImageName))dlsym(RTLD_DEFAULT, "_dyld_get_image_name");
    _dyld_register_func_for_add_image(imageAdded);
    uint32_t count = _dyld_image_count();
  
    for (uint32_t i = 0; i < count; i++)
        reportInjected(_dyld_get_image_name(i));

    
}
