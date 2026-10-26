//
//  HUDHelper.mm
//  DZ
//
//  Created by Lessica on 2024/1/24.
//

#import <spawn.h>
#import <notify.h>
#import <signal.h>
#import <mach-o/dyld.h>

#import "HUDHelper.h"
#import "NSUserDefaults+Private.h"

extern "C" char **environ;

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern "C" int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern "C" int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern "C" int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

static pid_t NHResolveHudPid(void)
{
    pid_t pid = NHReadPid();
    if (pid > 0) {
        return pid;
    }
    NSString *pidString = [NSString stringWithContentsOfFile:NHPidPath()
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    if (pidString.length > 0) {
        return (pid_t)[pidString intValue];
    }
    return 0;
}

BOOL IsHUDEnabled(void)
{
    // 本地查 pid，不再 persona spawn -check（减半 elevated 子进程）
    pid_t pid = NHResolveHudPid();
    if (pid <= 0) {
        return NO;
    }
    return kill(pid, 0) == 0;
}

#define LAUNCH_DAEMON_PATH ROOT_PATH("/Library/LaunchDaemons/com.nh.hudservices.plist")

void SetHUDEnabled(BOOL isEnabled)
{
    notify_post(NOTIFY_DISMISSAL_HUD);

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    if (access(LAUNCH_DAEMON_PATH, F_OK) == 0)
    {
        if (!isEnabled) {
            [NSThread sleepForTimeInterval:FADE_OUT_DURATION];
        }

        pid_t task_pid;
        static const char *executablePath = ROOT_PATH("/usr/bin/launchctl");
        const char *args[] = { executablePath, isEnabled ? "load" : "unload", LAUNCH_DAEMON_PATH, NULL };
        posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);
        log_debug(OS_LOG_DEFAULT, "spawned launchctl pid = %{public}d", task_pid);

        int status;
        do {
            if (waitpid(task_pid, &status, 0) != -1)
            {
                log_debug(OS_LOG_DEFAULT, "child status %d", WEXITSTATUS(status));
            }
        } while (!WIFEXITED(status) && !WIFSIGNALED(status));

        return;
    }

    static char *executablePath = NULL;
    uint32_t executablePathSize = 0;
    _NSGetExecutablePath(NULL, &executablePathSize);
    executablePath = (char *)calloc(1, executablePathSize);
    _NSGetExecutablePath(executablePath, &executablePathSize);

    if (isEnabled)
    {
        posix_spawnattr_setpgroup(&attr, 0);
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);

        // 仅 argv[0]，角色靠每机派生 env；绘制仍走同一套 Accessibility HUD 启动链
        NHMarkOverlayRole();
        pid_t task_pid = 0;
        const char *args[] = { executablePath, NULL };
        int ret = posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
        NHClearOverlayRole();
        posix_spawnattr_destroy(&attr);
        log_debug(OS_LOG_DEFAULT, "spawned overlay ret=%{public}d pid=%{public}d", ret, task_pid);
    }
    else
    {
        posix_spawnattr_destroy(&attr);
        [NSThread sleepForTimeInterval:FADE_OUT_DURATION];

        // 关叠层：notify 已发；本地 kill，不再 persona spawn -exit
        pid_t pid = NHResolveHudPid();
        if (pid > 0) {
            kill(pid, SIGKILL);
        }
        NHClearPid();
        unlink([NHPidPath() UTF8String]);
    }
}

#if DEBUG
void SimulateMemoryPressure(void)
{
    static NSString *nsExecutablePath = nil;
    static const char *executablePath = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *mainBundle = [NSBundle mainBundle];
        nsExecutablePath = [mainBundle pathForResource:@"memory_pressure" ofType:nil];
        if (nsExecutablePath) {
            executablePath = [nsExecutablePath UTF8String];
        }
    });

    if (!executablePath) {
        return;
    }

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);

    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    pid_t task_pid;
    const char *args[] = { executablePath, "-l", "critical", NULL };
    posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
    posix_spawnattr_destroy(&attr);

    log_debug(OS_LOG_DEFAULT, "spawned memory_pressure pid = %{public}d", task_pid);
}
#endif

NSUserDefaults *GetStandardUserDefaults(void)
{
    static NSUserDefaults *_userDefaults = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *containerPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByDeletingLastPathComponent];
        NSURL *containerURL = [NSURL fileURLWithPath:containerPath];
        _userDefaults = [[NSUserDefaults alloc] _initWithSuiteName:nil container:containerURL];
        [_userDefaults registerDefaults:@{
            HUDUserDefaultsKeyUsesCustomOffset: @NO,
            HUDUserDefaultsKeyRealCustomOffsetX: @0,
            HUDUserDefaultsKeyRealCustomOffsetY: @0,
            HUDUserDefaultsKeyUsesCustomFontSize: @NO,
            HUDUserDefaultsKeyRealCustomFontSize: @9,
        }];
    });
    return _userDefaults;
}

void fasongxuni(void)
{
    // 不再单独 persona spawn「HIDDevice」：该 argv 本就无入口，只会多一条 elevated 特征。
    // SenderID / 触摸逻辑改由当前进程或 HUD 进程内处理。
}
