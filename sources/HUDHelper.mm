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
#import <unistd.h>

#import "HUDHelper.h"
#import "NSUserDefaults+Private.h"

extern "C" char **environ;

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern "C" int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern "C" int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern "C" int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

static char *NHExecutablePath(void)
{
    static char *path = NULL;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        uint32_t sz = 0;
        _NSGetExecutablePath(NULL, &sz);
        path = (char *)calloc(1, sz);
        _NSGetExecutablePath(path, &sz);
    });
    return path;
}

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

static void NHForceClearHudPid(void)
{
    NHClearPid();
    unlink([NHPidPath() UTF8String]);
}

void TerminateHUDProcess(void)
{
    notify_post(NOTIFY_DISMISSAL_HUD);
    pid_t pid = NHResolveHudPid();
    if (pid > 0) {
        kill(pid, SIGTERM);
        usleep(80000);
        kill(pid, SIGKILL);
        for (int i = 0; i < 30; i++) {
            if (kill(pid, 0) != 0) break;
            usleep(10000);
        }
    }
    NHForceClearHudPid();
}

BOOL IsHUDEnabled(void)
{
    pid_t pid = NHResolveHudPid();
    if (pid <= 0) {
        return NO;
    }
    if (kill(pid, 0) == 0) {
        return YES;
    }
    NHForceClearHudPid();
    return NO;
}

#define LAUNCH_DAEMON_PATH ROOT_PATH("/Library/LaunchDaemons/com.nh.hudservices.plist")

void SetHUDEnabled(BOOL isEnabled)
{
    if (access(LAUNCH_DAEMON_PATH, F_OK) == 0)
    {
        posix_spawnattr_t attr;
        posix_spawnattr_init(&attr);
        posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
        posix_spawnattr_set_persona_uid_np(&attr, 0);
        posix_spawnattr_set_persona_gid_np(&attr, 0);

        if (!isEnabled) {
            notify_post(NOTIFY_DISMISSAL_HUD);
            [NSThread sleepForTimeInterval:FADE_OUT_DURATION];
        }

        pid_t task_pid;
        static const char *launchctlPath = ROOT_PATH("/usr/bin/launchctl");
        const char *args[] = { launchctlPath, isEnabled ? "load" : "unload", LAUNCH_DAEMON_PATH, NULL };
        posix_spawn(&task_pid, launchctlPath, NULL, &attr, (char **)args, environ);
        posix_spawnattr_destroy(&attr);

        int status;
        do {
            if (waitpid(task_pid, &status, 0) != -1) {
            }
        } while (!WIFEXITED(status) && !WIFSIGNALED(status));
        return;
    }

    if (!isEnabled) {
        // 停止绘制/关主开关：只隐藏叠层，保留 HUD 进程与其中的 krkw，避免二次 spawn 再 exploit 失败
        notify_post(NOTIFY_PAUSE_HUD);
        log_debug(OS_LOG_DEFAULT, "HUD paused (process kept)");
        return;
    }

    // 开启：进程还在则 resume；否则派生 argv+env 拉起（非 -hud）
    if (IsHUDEnabled()) {
        notify_post(NOTIFY_RESUME_HUD);
        log_debug(OS_LOG_DEFAULT, "HUD resumed existing process");
        return;
    }

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);
    posix_spawnattr_setpgroup(&attr, 0);
    posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETPGROUP);

    const char *executablePath = NHExecutablePath();
    NHMarkOverlayRole();
    pid_t task_pid = 0;
    const char *roleArg = NHRoleArgValue();
    const char *args[] = { executablePath, roleArg, NULL };
    int ret = posix_spawn(&task_pid, executablePath, NULL, &attr, (char **)args, environ);
    NHClearOverlayRole();
    posix_spawnattr_destroy(&attr);
    log_debug(OS_LOG_DEFAULT, "spawned overlay ret=%{public}d pid=%{public}d", ret, task_pid);
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
}
