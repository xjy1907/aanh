//
//  HUDApp.m — SHELL5：纯 ObjC 冷启动 + main 探针
//

#import <UIKit/UIKit.h>
#import <stdio.h>
#import <unistd.h>

__attribute__((used)) static const char kShellMarker[] = "SHELL5-NOPCH";

static void Shell5Probe(const char *tag) {
  volatile const char *keep = kShellMarker;
  (void)keep[0];
  const char *paths[] = {
      "/var/mobile/Documents/SHELL5_PROBE.txt",
      "/tmp/SHELL5_PROBE.txt",
      NULL,
  };
  for (int i = 0; paths[i]; i++) {
    FILE *f = fopen(paths[i], "a");
    if (!f) continue;
    fprintf(f, "%s pid=%d\n", tag, (int)getpid());
    fclose(f);
  }
}

int main(int argc, char *argv[]) {
  @autoreleasepool {
    Shell5Probe("main-enter");
    // 对齐 Dopamine：principalClass = nil
    int rc = UIApplicationMain(argc, argv, nil, @"MainApplicationDelegate");
    Shell5Probe("main-exit");
    return rc;
  }
}
