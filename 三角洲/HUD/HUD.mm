#import <spawn.h>
#import <mach-o/dyld.h>
#import <_types/_uint32_t.h>
#import <sys/_types/_uid_t.h>

#import <objc/message.h>

#import "伪装.h"
#import "绘制/HUD控制器.h"
#import "绘制/内核/kfd.h"

extern "C" {
    char** 环境变量;
    int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
    int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
    int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);
};

OBJC_EXTERN void 开启或关闭HUD(bool 标识符);
void 开启或关闭HUD(bool 标识符) {
    static char* 路径 = nullptr;
    uint32_t 长度 = 0;
    _NSGetExecutablePath(nullptr, &长度);
    路径 = (char*)calloc(1, 长度);
    _NSGetExecutablePath(路径, &长度);
    
    posix_spawnattr_t 进程;
    posix_spawnattr_init(&进程);
    
    posix_spawnattr_set_persona_np(&进程, 99, 1);
    posix_spawnattr_set_persona_uid_np(&进程, 0);
    posix_spawnattr_set_persona_gid_np(&进程, 0);
    
    pid_t 进程ID;
    if (标识符) {
        posix_spawnattr_setpgroup(&进程, 0);
        posix_spawnattr_setflags(&进程, POSIX_SPAWN_SETPGROUP);

        const char* 路径参数[] = {路径, "开启HUD", nullptr};
        posix_spawn(&进程ID, 路径, nullptr, &进程, (char**)路径参数, 环境变量);
        posix_spawnattr_destroy(&进程);
    } else {
        const char* 路径参数[] = {路径, "关闭HUD", nullptr};
        posix_spawn(&进程ID, 路径, nullptr, &进程, (char**)路径参数, 环境变量);
        posix_spawnattr_destroy(&进程);
    };
};

@interface UIApplication (Private)

- (void)suspend;
- (void)terminateWithSuccess;

@end

@interface UIWindow (Private)

- (unsigned int)_contextId;

@end

#pragma mark -- 应用

@interface HUD : UIApplication

@end

@implementation HUD

@end

@interface 窗口 : UIWindow

@end

@implementation 窗口

- (BOOL)_ignoresHitTest { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }

@end

@interface 注册图层方法 : NSObject
- (void) registerWindowWithContextID:(unsigned)标识符 atLevel:(double)窗口等级;
@end

@interface HUD挂载方法 : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) 窗口* HUD窗口;
@property (nonatomic, strong) UIWindow* 菜单窗口;
@end

@implementation HUD挂载方法

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    
    初始化环境隐藏系统();
    执行完整环境检测();
    执行完整环境隐藏();
    
    self.HUD窗口 = [[窗口 alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.HUD窗口.backgroundColor = UIColor.clearColor;
    self.HUD窗口.rootViewController = [[HUD控制器 alloc] init];
    self.HUD窗口.windowLevel = UIWindowLevelNormal + 1;
    [self.HUD窗口 makeKeyAndVisible];
    
    ((void (*)(id, SEL, unsigned int, double))objc_msgSend)([[objc_getClass("SBSAccessibilityWindowHostingController") alloc] init], NSSelectorFromString(@"registerWindowWithContextID:atLevel:"), [self.HUD窗口 _contextId], [self.HUD窗口 windowLevel]);
    return YES;
};

@end
