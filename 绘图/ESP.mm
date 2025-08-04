#include "ESP.hpp"
#include <atomic>
#include <chrono>
#include <cstdint>
#include <iostream>
#include <mach/mach.h>
#include <mutex>
#include <sys/sysctl.h>
#include <thread>
#include <unordered_map>

#include "Unity.hpp"
#include "UtfTool.hpp"

#import "DOJailbreaker.h"

#ifndef _SYS_PTRACE_H_
#define _SYS_PTRACE_H_
#include <sys/appleapiopts.h>
#include <sys/cdefs.h>

enum { ePtAttachDeprecated __deprecated_enum_msg("PT_ATTACH is deprecated. See PT_ATTACHEXC") = 10 };

#define PT_TRACE_ME 0                 /* child declares it's being traced */
#define PT_READ_I 1                   /* read word in child's I space */
#define PT_READ_D 2                   /* read word in child's D space */
#define PT_READ_U 3                   /* read word in child's user structure */
#define PT_WRITE_I 4                  /* write word in child's I space */
#define PT_WRITE_D 5                  /* write word in child's D space */
#define PT_WRITE_U 6                  /* write word in child's user structure */
#define PT_CONTINUE 7                 /* continue the child */
#define PT_KILL 8                     /* kill the child process */
#define PT_STEP 9                     /* single step the child */
#define PT_ATTACH ePtAttachDeprecated /* trace some running process */
#define PT_DETACH 11                  /* stop tracing a process */
#define PT_SIGEXC 12                  /* signals as exceptions for current_proc */
#define PT_THUPDATE 13                /* signal for thread# */
#define PT_ATTACHEXC 14               /* attach to running process with signal exception */
#define PT_FORCEQUOTA 30              /* Enforce quota for root */
#define PT_DENY_ATTACH 31
#define PT_FIRSTMACH 32 /* for machine-specific requests */
__BEGIN_DECLS
int ptrace(int _request, pid_t _pid, caddr_t _addr, int _data);
__END_DECLS
#endif /* !_SYS_PTRACE_H_ */

ImDrawList *imDrawList;
float Matrix[16];
string Name;
uintptr_t GWorld;

float 雷达大小, 雷达x, 雷达y, 物资距离, 范围大小;
bool 总开关, is射线, is信息, is骨骼, is血量, is手持, is雷达, is人机, is阵营, 资源名, is物资, is红, is金, is紫, is蓝,
is绿, is盒子, is盒子物资, is无后, is聚点, is躯体, is手臂, is加速;

char wzname[256];
char SafeName[256];
char BoxName[256];
char MySCGname[256];
char PlayerName[256];
char ChosenName[100];
std::vector<std::string> aimingEnemies;
static Vector2 markScreenPos, AimPosScreen, nextPoint, RootScreen;
Vector3 CharacterPos;
static bool isHookAngle = false, needAdjustAim = false, sniperrifle = false, bOffsetFindDNE = false;
static long libbase, Character, PlayerController, GName, MyWeaponBase;
static float tDis = 0, tDistance = 0, markDistance, markDis, Aimbot_Circle_Radius;
static int player = 0, robot = 0;
MinimalViewInfo pov;
pid_t gamePid;

static mach_port_t task;
extern "C" kern_return_t mach_vm_region(vm_map_t target_task, mach_vm_address_t *address, mach_vm_size_t *size,
                                        vm_region_flavor_t flavor, vm_region_info_t info,
                                        mach_msg_type_number_t *infoCnt, mach_port_t *object_name);

extern "C" kern_return_t mach_vm_region_recurse(vm_map_t map, mach_vm_address_t *address, mach_vm_size_t *size,
                                                uint32_t *depth, vm_region_recurse_info_t info,
                                                mach_msg_type_number_t *infoCnt);
vm_map_offset_t safegetBase(pid_t pid) {
  
  char path[64];
  snprintf(path, sizeof(path), "/proc/%d/maps", pid);
  FILE *maps = fopen(path, "r");
  if (maps) {
    vm_map_offset_t base = 0;
    char buffer[512];
    while (fgets(buffer, sizeof(buffer), maps)) {
      if (strstr(buffer, "r-xp")) { // 只获取可执行段
        sscanf(buffer, "%llx", &base);
        fclose(maps);
        return base;
      }
    }
    fclose(maps);
  }
  
  // 备用方案
  mach_vm_address_t vmoffset = 0; // 修改类型
  mach_vm_size_t vmsize = 0;
  uint32_t nesting_depth = 0;
  struct vm_region_submap_info_64 vbr;
  mach_msg_type_number_t vbrcount = 16;
  
  kern_return_t kret = mach_vm_region_recurse(task,
                                              &vmoffset, // 这里类型匹配
                                              &vmsize, &nesting_depth, (vm_region_recurse_info_t)&vbr, &vbrcount);
  
  return (kret == KERN_SUCCESS) ? vmoffset : 0;
  
  // kfd doesn't directly provide base address functionality like mach_vm_region_recurse
  // This function might need to be re-evaluated or replaced with a kfd-compatible alternative
  // For now, returning 0 as a placeholder.
  return 0;
}

pid_t getPid(NSString *GameName) {
  
  size_t length = 0;
  int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};                                 // 保持 name 数组类型为 int[]
  int err = sysctl(name, (sizeof(name) / sizeof(name[0])) - 1, NULL, &length, NULL, 0); // 不进行不必要的强制类型转换
  
  if (err == -1)
    err = errno;
  if (err == 0) {
    struct kinfo_proc *procBuffer = (struct kinfo_proc *)malloc(length); // 修正内存分配类型
    if (procBuffer == NULL) {
      free(procBuffer);
      return -1;
    }
    err = sysctl(name, (sizeof(name) / sizeof(name[0])) - 1, procBuffer, &length, NULL, 0); // 继续传递原始类型
    
    int count = (int)length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; ++i) {
      NSString *procname = [NSString stringWithUTF8String:procBuffer[i].kp_proc.p_comm]; // 使用 NSString* 类型
      pid_t pid = procBuffer[i].kp_proc.p_pid;
      if ([GameName rangeOfString:procname options:NSCaseInsensitiveSearch].location != NSNotFound) {
        free(procBuffer);
        return pid;
      }
    }
    free(procBuffer);
  }
  // kfd doesn't directly provide a PID lookup function.
  // This function might need to be replaced with a different method to get the target process's PID.
  // For now, returning -1 as a placeholder.
  return -1;
}

task_port_t task_for_pid_workaround(int Pid) {
  host_t myhost = mach_host_self();
  task_port_t psDefault, psDefault_control;
  task_array_t tasks;
  mach_msg_type_number_t numTasks;
  kern_return_t kr;
  
  kr = processor_set_default(myhost, &psDefault);
  if (kr != KERN_SUCCESS) {
    NSLog(@"processor_set_default failed: %x", kr);
    return MACH_PORT_NULL;
  }
  
  kr = host_processor_set_priv(myhost, psDefault, &psDefault_control);
  if (kr != KERN_SUCCESS) {
    NSLog(@"host_processor_set_priv failed: %x", kr);
    return MACH_PORT_NULL;
  }
  
  kr = processor_set_tasks(psDefault_control, &tasks, &numTasks);
  if (kr != KERN_SUCCESS) {
    NSLog(@"processor_set_tasks failed: %x", kr);
    return MACH_PORT_NULL;
  }
  
  for (int i = 0; i < numTasks; i++) {
    int pid;
    pid_for_task(tasks[i], &pid);
    if (pid == Pid)
      return tasks[i];
  }
  // kfd does not use task_port_t for memory operations. This function is no longer needed with kfd.
  return MACH_PORT_NULL;
}

bool getdfm() {
  if (!bOffsetFindDNE) {
    NSString *gameName = @"DeltaForceClient";
    gamePid = getPid(gameName);
    if (gamePid != -1) {
      task = task_for_pid_workaround(gamePid);
      if (task) {
        libbase = safegetBase(gamePid);
      }
    }
    bOffsetFindDNE = true;
  }
  return (task != MACH_PORT_NULL);
}

static bool IsValidAddress(long address) { return address > 0x100000000 && address < 0x3000000000; }

bool readMemory(mach_vm_address_t address, void *buffer, size_t size) {
  return exploit_kreadbuf(address, buffer, size);
}

bool safe_vm_read(mach_vm_address_t address, void *buffer, size_t size) {
  return exploit_kreadbuf(address, buffer, size) == 0;
}

void *safe_read_memory(mach_vm_address_t address, size_t size) {
  void *buffer = malloc(size);
  if (!buffer)
    return NULL;
  if (!readMemory(address, buffer, size)) {
    free(buffer);
    return NULL;
  }
  return buffer;
}

// 写内存前判断是否可写，避免触发 vm_protect
bool writeMemory(long address, void *buf, int length) {
  return exploit_kwritebuf(static_cast<uint64_t>(address), buf, static_cast<size_t>(length)) == 0;
}

bool ReadRemoteBytes(void *buffer, uintptr_t addr, size_t size) { return exploit_kreadbuf(addr, buffer, size) == 0; }

template <typename T> T Read(long address) {
  T data;
  void *buffer = safe_read_memory(address, sizeof(T));
  if (buffer) {
    memcpy(&data, buffer, sizeof(T));
    free(buffer);
  } else {
    memset(&data, 0, sizeof(T));
  }
  return data;
}

template <typename T> void Write(long address, T buf) { writeMemory(address, &buf, sizeof(T)); };

static Vector3 GetRelativeLocation(uintptr_t actor) { return Read<Vector3>(Read<uintptr_t>(actor + 0x180) + 0x220); }

static bool GetInsideFov(float ScreenWidth, float ScreenHeight, Vector2 PlayerBone, float FovRadius) {
  Vector2 Cenpoint;
  Cenpoint.X = PlayerBone.X - (ScreenWidth / 2);
  Cenpoint.Y = PlayerBone.Y - (ScreenHeight / 2);
  if (Cenpoint.X * Cenpoint.X + Cenpoint.Y * Cenpoint.Y <= FovRadius * FovRadius)
    return true;
  return false;
}

static float GetCenterOffsetForVector(Vector2 point) {
  return sqrt(pow(point.X - CanvasSize.X / 2, 2.0) + pow(point.Y - CanvasSize.Y / 2, 2.0));
}

// 获取类名
string GetClassName(int classId, uintptr_t GName) {
  if (classId <= 0)
    return "";
  
  if (IsValidAddress(GName)) {
    uint32_t FNameID = classId;
    
    uintptr_t v5 = Read<uintptr_t>(GName + ((FNameID >> 15) & 0x1FFF8) + 200);
    uintptr_t v6 = (2 * FNameID) & 0x7FFFE;
    uintptr_t name_addr = v5 + v6;
    
    uint16_t rawHeader = Read<uint16_t>(name_addr);
    uint16_t nameLength = rawHeader >> 6;
    
    if (nameLength == 0 || nameLength >= 256)
      return "";
    
    char buf[256] = {0};
    readMemory(name_addr + 2, buf, nameLength);
    
    uint16_t key = 0;
    switch (nameLength % 9) {
      case 0:
        key = (((((rawHeader >> 6) & 0x1F) + nameLength) | 0x7F) + 0x80);
        break; // 藏
      case 1:
        key = (((nameLength ^ 0xDF) + nameLength) | 0x7F) + 0x80;
        break; // 藏
      case 2:
        key = (((nameLength | 0xCF) + nameLength) | 0x7F) + 0x80;
        break; // 藏
      case 3:
        key = ((33 * nameLength) | 0x7F) + 0x80;
        break; // 藏
      case 4:
        key = ((nameLength + (rawHeader >> 8)) | 0x7F) + 0x80;
        break; // 藏
      case 5:
        key = ((3 * nameLength + 5) | 0x7F) + 0x80;
        break; // 藏
      case 6:
        key = ((((4 * nameLength) | 5) + nameLength) | 0x7F) + 0x80;
        break; // 藏
      case 7:
        key = ((((rawHeader >> 10) | 7) + nameLength) | 0x7F) + 0x80;
        break; // 藏
      case 8:
        key = (((nameLength ^ 0xC) + nameLength) | 0x7F) + 0x80;
        break; // 藏
    }
    
    for (int i = 0; i < nameLength; i++) {
      buf[i] ^= key;
    }
    
    string my_Name(buf, nameLength);
    size_t n = my_Name.rfind('/');
    if (n != string::npos) {
      my_Name = my_Name.substr(n + 1);
    }
    
    return my_Name;
  }
  
  return "";
}

#pragma mark - 游戏数据

static void GetModuleBaseAddress(uintptr_t GWorld) {
  if (!IsValidAddress(GWorld))
    return;
  
  PlayerController = Read<uintptr_t>(Read<uintptr_t>(Read<uintptr_t>(Read<uintptr_t>(GWorld + 0x190) + 0x38) + 0x0) + 0x30);
  // 函数获取 EF69588
  if (!IsValidAddress(PlayerController))
    return;
  
  Character = Read<uintptr_t>(PlayerController + 0x3A0); // 函数获取
  if (!IsValidAddress(Character))
    return;
  
  CharacterPos = GetRelativeLocation(Character);
}

void getUTF8(UTF8 *buf, unsigned long namepy) {
  UTF16 buf16[16] = {0};
  readMemory(namepy, buf16, 28);
  UTF16 *pTempUTF16 = buf16;
  UTF8 *pTempUTF8 = buf;
  UTF8 *pUTF8End = pTempUTF8 + 32;
  while (pTempUTF16 < pTempUTF16 + 28) {
    if (*pTempUTF16 <= 0x007F && pTempUTF8 + 1 < pUTF8End) {
      *pTempUTF8++ = (UTF8)*pTempUTF16;
    } else if (*pTempUTF16 >= 0x0080 && *pTempUTF16 <= 0x07FF && pTempUTF8 + 2 < pUTF8End) {
      *pTempUTF8++ = (*pTempUTF16 >> 6) | 0xC0;
      *pTempUTF8++ = (*pTempUTF16 & 0x3F) | 0x80;
    } else if (*pTempUTF16 >= 0x0800 && *pTempUTF16 <= 0xFFFF && pTempUTF8 + 3 < pUTF8End) {
      *pTempUTF8++ = (*pTempUTF16 >> 12) | 0xE0;
      *pTempUTF8++ = ((*pTempUTF16 >> 6) & 0x3F) | 0x80;
      *pTempUTF8++ = (*pTempUTF16 & 0x3F) | 0x80;
    } else {
      break;
    }
    pTempUTF16++;
  }
}

string GetAIPlayerName(uintptr_t player) {
  string n = "";
  uintptr_t PlayerName =
  Read<long>(Read<long>(Read<long>(Read<long>(Read<long>(player + 0x2478) + 0x18) + 0x30) + 0x20) + 0x0); // 藏
  if (IsValidAddress(PlayerName)) {
    UTF8 name[32] = "";
    UTF16 buf16[16] = {0};
    readMemory(PlayerName, buf16, 28);
    Utf16_To_Utf8(buf16, name, 28, strictConversion);
    n = string((const char *)name);
  }
  return n;
}

string GetPickupName(uintptr_t Pickup) {
  string n = "";
  uintptr_t PlayerName = Read<long>(
                                    Read<long>(Read<long>(Read<long>(Read<long>(Read<long>(Pickup + 0xDB8) + 0x18) + 0x18) + 0x30) + 0x20) +
                                    0x0); // 藏
  if (IsValidAddress(PlayerName)) {
    UTF8 name[32] = "";
    UTF16 buf16[16] = {0};
    readMemory(PlayerName, buf16, 28);
    Utf16_To_Utf8(buf16, name, 28, strictConversion);
    n = string((const char *)name);
  }
  return n;
}

static bool isScreenVisible(Vector2 LocationScreen, Vector2 CanvasSize) {
  if (LocationScreen.X > 0 && LocationScreen.X < CanvasSize.X && LocationScreen.Y > 0 &&
      LocationScreen.Y < CanvasSize.Y)
    return true;
  else
    return false;
}

static FRotator CalcAngle(Vector3 aimPos) {
  float hyp = sqrt(aimPos.X * aimPos.X + aimPos.Y * aimPos.Y + aimPos.Z * aimPos.Z);
  float Yaw = atan2(aimPos.Y, aimPos.X) * 180 / M_PI;
  float Pitch = asin(aimPos.Z / hyp) * 180 / M_PI;
  FRotator aimRotation = {Pitch, Yaw, 0};
  return aimRotation;
}

static FRotator Clamp(FRotator Rotation) {
  if (Rotation.Yaw > 180.f)
    Rotation.Yaw -= 360.f;
  else if (Rotation.Yaw < -180.f)
    Rotation.Yaw += 360.f;
  
  if (Rotation.Pitch > 180.f)
    Rotation.Pitch -= 360.f;
  else if (Rotation.Pitch < -180.f)
    Rotation.Pitch += 360.f;
  
  if (Rotation.Pitch < -89.f)
    Rotation.Pitch = -89.f;
  else if (Rotation.Pitch > 89.f)
    Rotation.Pitch = 89.f;
  
  Rotation.Roll = 0.f;
  
  return Rotation;
}

static float get3dDistance(Vector3 self, Vector3 object, float divice) {
  Vector3 xyz;
  xyz.X = self.X - object.X;
  xyz.Y = self.Y - object.Y;
  xyz.Z = self.Z - object.Z;
  return sqrt(pow(xyz.X, 2) + pow(xyz.Y, 2) + pow(xyz.Z, 2)) / divice;
}

static Vector3 GetBoneFTransform(uintptr_t Mesh, const int Id) {
  uintptr_t BoneActor = Read<long>(Mesh + 0x700); // 藏
  FTransform lpFTransform = Read<FTransform>(BoneActor + Id * 0x30);
  FTransform ComponentToWorld = Read<FTransform>(Mesh + 0x210); // 藏
  D3DXMATRIX Matrix =
  FTransform::MatrixMultiplication(lpFTransform.ToMatrixWithScale(), ComponentToWorld.ToMatrixWithScale());
  return Vector3(Matrix._41, Matrix._42, Matrix._43);
}

static Vector3 WorldToRadar(float Yaw, Vector3 Origin, Vector3 LocalOrigin, float PosX, float PosY, Vector3 Size,
                            bool &outbuff) {
  bool flag = false;
  double num = (double)Yaw;
  double num2 = num * 0.017453292519943295;
  float num3 = (float)cosl(num2);
  float num4 = (float)sin(num2);
  float num5 = Origin.X - LocalOrigin.X;
  float num6 = Origin.Y - LocalOrigin.Y;
  
  Vector3 vector;
  vector.X = (num6 * num3 - num5 * num4) / 150.f;
  vector.Y = (num5 * num3 + num6 * num4) / 150.f;
  
  Vector3 vector2;
  vector2.X = vector.X + PosX + Size.X / 2.f;
  vector2.Y = -vector.Y + PosY + Size.Y / 2.f;
  
  bool flag2 = vector2.X > PosX + Size.X;
  if (flag2) {
    vector2.X = PosX + Size.X;
  } else {
    bool flag3 = vector2.X < PosX;
    if (flag3) {
      vector2.X = PosX;
    }
  }
  bool flag4 = vector2.Y > PosY + Size.Y;
  if (flag4) {
    vector2.Y = PosY + Size.Y;
  } else {
    bool flag5 = vector2.Y < PosY;
    if (flag5) {
      vector2.Y = PosY;
    }
  }
  bool flag6 = vector2.Y == PosY || vector2.X == PosX;
  if (flag6) {
    flag = true;
  }
  outbuff = flag;
  return vector2;
}
Vector2 GetScreenEdgeIntersectionImVec2(Vector2 objectScreenImVec2, Vector2 edgePointOneImVec2,
                                        Vector2 edgePointTwoImVec2, Vector2 screenCenterImVec2) {
  int intersectionDirection = 0;
  Vector2 intersectionImVec2;
  if (abs(screenCenterImVec2.X - objectScreenImVec2.X) > 0.0f) {
    intersectionImVec2.X =
    (objectScreenImVec2.Y - screenCenterImVec2.Y) / (objectScreenImVec2.X - screenCenterImVec2.X);
    intersectionDirection |= 1;
  }
  if (abs(edgePointOneImVec2.X - edgePointTwoImVec2.X) > 0.0f) {
    intersectionImVec2.Y =
    (edgePointTwoImVec2.Y - edgePointOneImVec2.Y) / (edgePointTwoImVec2.X - edgePointOneImVec2.X);
    intersectionDirection |= 2;
  }
  switch (intersectionDirection) {
    case 0:
      return {0.0f, 0.0f};
    case 1:
      return {
        edgePointOneImVec2.X,
        (screenCenterImVec2.X - edgePointOneImVec2.X) * (-intersectionImVec2.X) + screenCenterImVec2.X,
      };
    case 2:
      return {
        screenCenterImVec2.X,
        (edgePointOneImVec2.X - screenCenterImVec2.X) * (-intersectionImVec2.Y) + edgePointOneImVec2.Y,
      };
    case 3: {
      if (abs(intersectionImVec2.X - intersectionImVec2.Y) < 0.0f) {
        return {0.0f, 0.0f};
      }
      return {
        (intersectionImVec2.X * screenCenterImVec2.X - intersectionImVec2.Y * edgePointOneImVec2.X -
         screenCenterImVec2.Y + edgePointOneImVec2.Y) /
        (intersectionImVec2.X - intersectionImVec2.Y),
        intersectionImVec2.X *
        ((intersectionImVec2.X * screenCenterImVec2.X - intersectionImVec2.Y * edgePointOneImVec2.X -
          screenCenterImVec2.Y + edgePointOneImVec2.Y) /
         (intersectionImVec2.X - intersectionImVec2.Y)) -
        intersectionImVec2.X * screenCenterImVec2.X + screenCenterImVec2.Y,
      };
    }
    default:
      break;
  }
  return {0.0f, 0.0f};
}

Vector2 GetScreenEdgeImVec2(Vector2 objectScreenImVec2, Vector2 screenImVec2, float reservedValue) {
  Vector2 screenTopLeftImVec2 = {0.0f, 0.0f};
  Vector2 screenBottomLeftImVec2 = {0.0f, screenImVec2.Y};
  Vector2 screenTopRightImVec2 = {screenImVec2.X, 0.0f};
  Vector2 screenCenterImVec2 = {screenImVec2.X / 2.0f, screenImVec2.Y / 2.0f};
  if (objectScreenImVec2.X < reservedValue) {
    Vector2 screenEdgeIntersectionImVec2 = GetScreenEdgeIntersectionImVec2(
                                                                           objectScreenImVec2, screenTopLeftImVec2, screenBottomLeftImVec2, screenCenterImVec2);
    if (screenEdgeIntersectionImVec2.Y >= reservedValue && screenEdgeIntersectionImVec2.Y <= screenImVec2.Y) {
      return {reservedValue, screenEdgeIntersectionImVec2.Y - reservedValue};
    }
    if (objectScreenImVec2.Y < reservedValue) {
      screenEdgeIntersectionImVec2 = GetScreenEdgeIntersectionImVec2(objectScreenImVec2, screenTopLeftImVec2,
                                                                     screenTopRightImVec2, screenCenterImVec2);
      if (screenEdgeIntersectionImVec2.X >= reservedValue && screenEdgeIntersectionImVec2.X <= screenImVec2.X) {
        return {screenEdgeIntersectionImVec2.X - reservedValue, reservedValue};
      }
      return {reservedValue, reservedValue};
    } else if (objectScreenImVec2.Y > screenImVec2.Y) {
      screenEdgeIntersectionImVec2 = GetScreenEdgeIntersectionImVec2(objectScreenImVec2, screenBottomLeftImVec2,
                                                                     screenImVec2, screenCenterImVec2);
      if (screenEdgeIntersectionImVec2.X >= reservedValue && screenEdgeIntersectionImVec2.X <= screenImVec2.X) {
        return {screenEdgeIntersectionImVec2.X - reservedValue, screenImVec2.Y - reservedValue};
      }
      return {reservedValue, screenImVec2.Y - reservedValue};
    } else {
      return {reservedValue, objectScreenImVec2.Y - reservedValue};
    }
  } else if (objectScreenImVec2.X > screenImVec2.X) {
    Vector2 screenEdgeIntersectionImVec2 =
    GetScreenEdgeIntersectionImVec2(objectScreenImVec2, screenTopRightImVec2, screenImVec2, screenCenterImVec2);
    if (screenEdgeIntersectionImVec2.Y >= reservedValue && screenEdgeIntersectionImVec2.Y <= screenImVec2.Y) {
      return {screenImVec2.X - reservedValue, screenEdgeIntersectionImVec2.Y - reservedValue};
    }
    if (screenEdgeIntersectionImVec2.Y < reservedValue) {
      screenEdgeIntersectionImVec2 = GetScreenEdgeIntersectionImVec2(objectScreenImVec2, screenTopLeftImVec2,
                                                                     screenTopRightImVec2, screenCenterImVec2);
      if (screenEdgeIntersectionImVec2.X >= reservedValue && screenEdgeIntersectionImVec2.X <= screenImVec2.X) {
        return {screenEdgeIntersectionImVec2.X - reservedValue, reservedValue};
      }
      return {screenImVec2.X - reservedValue, reservedValue};
    } else if (objectScreenImVec2.Y > screenImVec2.Y) {
      screenEdgeIntersectionImVec2 = GetScreenEdgeIntersectionImVec2(objectScreenImVec2, screenBottomLeftImVec2,
                                                                     screenImVec2, screenCenterImVec2);
      if (screenEdgeIntersectionImVec2.X >= reservedValue && screenEdgeIntersectionImVec2.X <= screenImVec2.X) {
        return {screenEdgeIntersectionImVec2.X - reservedValue, screenImVec2.Y - reservedValue};
      }
      return {screenImVec2.X - reservedValue, screenImVec2.Y - reservedValue};
    } else {
      return {screenImVec2.X - reservedValue, objectScreenImVec2.Y - reservedValue};
    }
  } else {
    if (objectScreenImVec2.Y < reservedValue) {
      Vector2 screenEdgeIntersectionImVec2 = GetScreenEdgeIntersectionImVec2(
                                                                             objectScreenImVec2, screenTopLeftImVec2, screenTopRightImVec2, screenCenterImVec2);
      if (screenEdgeIntersectionImVec2.X >= reservedValue && screenEdgeIntersectionImVec2.X <= screenImVec2.X) {
        return {screenEdgeIntersectionImVec2.X - reservedValue, reservedValue};
      }
      return {objectScreenImVec2.X - reservedValue, reservedValue};
    } else if (objectScreenImVec2.Y > screenImVec2.Y) {
      Vector2 screenEdgeIntersectionImVec2 = GetScreenEdgeIntersectionImVec2(
                                                                             objectScreenImVec2, screenTopLeftImVec2, screenTopRightImVec2, screenCenterImVec2);
      if (screenEdgeIntersectionImVec2.X >= reservedValue && screenEdgeIntersectionImVec2.X <= screenImVec2.X) {
        return {screenEdgeIntersectionImVec2.X - reservedValue, screenImVec2.Y - reservedValue};
      }
      return {objectScreenImVec2.X - reservedValue, screenImVec2.Y - reservedValue};
    } else {
      return {objectScreenImVec2.X - reservedValue, objectScreenImVec2.Y - reservedValue};
    }
  }
  return {reservedValue, reservedValue};
}

Vector2 RevolveCoordinatesSystem(float RevolveAngle, Vector2 OriginPos, Vector2 DestPos) {
  Vector2 ResultPos;
  if (RevolveAngle == 0)
    return DestPos;
  ResultPos.X = OriginPos.X + (DestPos.X - OriginPos.X) * cos(RevolveAngle * M_PI / 180) +
  (DestPos.Y - OriginPos.Y) * sin(RevolveAngle * M_PI / 180);
  ResultPos.Y = OriginPos.Y - (DestPos.X - OriginPos.X) * sin(RevolveAngle * M_PI / 180) +
  (DestPos.Y - OriginPos.Y) * cos(RevolveAngle * M_PI / 180);
  return ResultPos;
}

void DrawRadar(uintptr_t player, int radarX, int radarY, int radarWidth, int radarHeight, float yaw) {
  // 获取目标位置和距离
  Vector3 EntityLocation = GetRelativeLocation(player);
  FRotator RelativeRotation = Read<FRotator>(Read<uintptr_t>(Character + 0x180) + 0x170);
  float Distance = Vector3::Distance(EntityLocation, CharacterPos) / 100;
  
  // 雷达的中心点
  Vector2 pos = Vector2(radarX, radarY);
  Vector2 size = Vector2(radarWidth, radarHeight);
  Vector2 RadarCenter = Vector2(pos.X + (size.X / 2), pos.Y + (size.Y / 2));
  
  // 绘制雷达边框
  Draw::DrawRect(ImVec2(pos.X, pos.Y), ImVec2(pos.X + size.X, pos.Y + size.Y), Colour_橙色, 1.0f);
  
  // 绘制雷达中心十字线
  Draw::DrawLine(ImVec2(RadarCenter.X, RadarCenter.Y), ImVec2(pos.X + size.X, pos.Y), Colour_透明绿色, 0.5f); // 右上
  Draw::DrawLine(ImVec2(pos.X, RadarCenter.Y), ImVec2(pos.X + size.X, RadarCenter.Y), Colour_透明绿色,
                 0.5f); // 水平线
  Draw::DrawLine(ImVec2(RadarCenter.X, pos.Y), ImVec2(RadarCenter.X, pos.Y + size.Y), Colour_透明绿色,
                 0.5f); // 垂直线
  Draw::DrawLine(ImVec2(RadarCenter.X, RadarCenter.Y), ImVec2(pos.X, pos.Y + size.Y), Colour_透明绿色, 0.5f); // 左下
  Draw::DrawLine(ImVec2(RadarCenter.X, RadarCenter.Y), ImVec2(pos.X + size.X, pos.Y + size.Y), Colour_透明绿色,
                 0.5f);                                                                              // 右下
  Draw::DrawLine(ImVec2(RadarCenter.X, RadarCenter.Y), ImVec2(pos.X, pos.Y), Colour_透明绿色, 0.5f); // 左上
  
  // 绘制雷达中心点
  Draw::DrawCircleFilled(ImVec2(RadarCenter.X, RadarCenter.Y), 5, Colour_橙色);
  
  // 将目标位置转换为雷达坐标
  bool out = true;
  Vector3 single =
  WorldToRadar(RelativeRotation.Yaw, EntityLocation, CharacterPos, pos.X, pos.Y, Vector3(size.X, size.Y, 0), out);
  
  // 绘制目标点
  if (Distance >= 0.f && Distance < 200) {
    
    // float Angle = (RelativeRotation.Yaw - yaw) + 180.f;
    Vector2 directionEnd = Vector2(single.X + 25 * cosf(DEG2RAD(yaw)), single.Y + 25 * sinf(DEG2RAD(yaw)));
    
    Draw::DrawLine(ImVec2(single.X, single.Y), ImVec2(directionEnd.X, directionEnd.Y), Colour_红色, 4);
    Draw::DrawCircleFilled(ImVec2(single.X, single.Y), 7, Colour_红色);
    Draw::DrawCircle(ImVec2(single.X, single.Y), 8, Colour_白色);
  }
}

float currentAimRadius = 300;
float targetAimRadius = 300;
float transitionSpeed = 3;

void SetAimRadius(float distance) {
  
  if (distance <= 1) {
    targetAimRadius = 300;
  } else if (distance >= 100) {
    targetAimRadius = 70;
  } else {
    float t = (distance - 1) / (100 - 1);
    targetAimRadius = 300 - t * (300 - 70);
  }
  
  if (currentAimRadius != targetAimRadius) {
    // 根据过渡速度调整半径
    float step = transitionSpeed;
    if (currentAimRadius < targetAimRadius) {
      currentAimRadius = fmin(currentAimRadius + step, targetAimRadius);
    } else {
      currentAimRadius = fmax(currentAimRadius - step, targetAimRadius);
    }
    Aimbot_Circle_Radius = currentAimRadius;
  }
}

void GetDBMapScreenPos(Mapinfo Map, Vector2 DisplaySize, Vector3 Pos, float Pitch, Vector2 &ScreenPos,
                       Vector2 &Direction) {
  Vector2 MapPos = {float(Map.MapX) + Pos.X - Map.x, float(Map.MapY) + Pos.Y - Map.y};
  ScreenPos = {MapPos.X / Map.w * DisplaySize.X, MapPos.Y / Map.h * DisplaySize.Y};
  Direction = Vector2(ScreenPos.X + cos(Pitch * M_PI / 180) * 35, ScreenPos.Y + sin(Pitch * M_PI / 180) * 35);
}

void GetCGMapScreenPos(Mapinfo Map, Vector2 DisplaySize, Vector3 Pos, float Pitch, Vector2 &ScreenPos,
                       Vector2 &Direction) {
  ImVec2 MapPos = {float(Map.MapX) * 1.00675f - Pos.Y - Map.x, float(Map.MapY) * 0.99805f + Pos.X - Map.y};
  ScreenPos = {MapPos.x / Map.w * DisplaySize.X, MapPos.y / Map.h * DisplaySize.Y};
  Direction = Vector2(ScreenPos.X + cos(Pitch * M_PI / 180) * 35, ScreenPos.Y + sin(Pitch * M_PI / 180) * 35);
}

bool isEnemyFacingMe(float playerFace, const float enemyPosX, const float enemyPosY, const float myPosX,
                     const float myPosY) {
  // 计算方向向量
  const float dx = myPosX - enemyPosX;
  const float dy = myPosY - enemyPosY;
  
  // 计算目标方向弧度（atan2）
  const float targetRad = std::atan2(dy, dx);
  
  // 将玩家当前朝向角度转换为弧度
  const float facingRad = playerFace * (M_PI / 180.0f);
  
  // 计算弧度差值并处理周期性（等效角度差）
  float diff = std::abs(targetRad - facingRad);
  constexpr float tolerance = 15.0f * (M_PI / 180.0f); // 15度的弧度值
  
  // 处理超过π的情况（如355度与5度的差值实为10度）
  if (diff > M_PI) {
    diff = 2 * M_PI - diff;
  }
  
  return diff < tolerance;
}

void GetPlayerData(uintptr_t Player) {
  
  // 人物骨骼
  uintptr_t Mesh = Read<uintptr_t>(Player + 0x3D0); // 藏
  if (!IsValidAddress(Mesh))
    return;
  
  Vector3 LocationWorldPos = GetRelativeLocation(Player);
  Vector2 LocationScreen = WorldToScreen(LocationWorldPos, Matrix);
  
  AimPosScreen = LocationScreen;
  
  FRotator PlayerRotation = Read<FRotator>(Read<uintptr_t>(Player + 0x180) + 0x170);
  
  // 宽度和高度
  Vector2 width = WorldToScreen(Vector3(LocationWorldPos.X, LocationWorldPos.Y, LocationWorldPos.Z + 100), Matrix);
  Vector2 height = WorldToScreen(Vector3(LocationWorldPos.X, LocationWorldPos.Y, LocationWorldPos.Z + 100), Matrix);
  
  Vector2 Playersize;
  Playersize.X = (LocationScreen.Y - width.Y) / 2;
  Playersize.Y = LocationScreen.Y - height.Y;
  
  FDeathInfo DeathInfo = Read<FDeathInfo>(Player + 0xC18); // 藏
  bool bDead = DeathInfo.bIsDead & 1;
  if (bDead)
    return;
  
  uintptr_t PlayerComponent = Read<uintptr_t>(Player + 0x390); // 藏
  
  bool bFinishGame = Read<bool>(PlayerComponent + 0x4c0) & 1;
  if (bFinishGame)
    return;
  
  long GPTeamComponent = Read<long>(Player + 0xed0);
  if (!IsValidAddress(GPTeamComponent))
    return;
  
  int Team = Read<int>(GPTeamComponent + 0x108);
  
  long MyGPTeamComponent = Read<long>(Character + 0xed0);
  if (!IsValidAddress(MyGPTeamComponent))
    return;
  
  int MyTeam = Read<int>(MyGPTeamComponent + 0x108);
  
  if (Team == MyTeam)
    return;
  
  if (is阵营) {
    
    int CampId = Read<int>(GPTeamComponent + 0x10C);
    int MyCampId = Read<int>(MyGPTeamComponent + 0x10C);
    
    if (CampId == MyCampId) {
      return;
    }
  }
  
  bool bIsBoos = false;
  
  // 判断人机
  bool bIsAI = false;
  
  long isrobot = Read<bool>(PlayerComponent + 0x39E);
  bIsAI = isrobot == 0;
  
  if (is手持) {
    if (bIsAI) {
      string NpcName = GetAIPlayerName(Player);
      
      bIsBoos = (isContain(NpcName, "[卫队长官]赛伊德") || isContain(NpcName, "[地域黑鲨]雷斯") ||
                 isContain(NpcName, "[安全总监]德穆兰") || isContain(NpcName, "哈夫克自动战车")) &
      1;
      
      if (!bIsBoos)
        return;
    }
  }
  
  float distance = Vector3::Distance(LocationWorldPos, CharacterPos) / 100;
  if (distance > 300)
    return;
  
  if (bIsAI) {
    robot++;
  } else {
    player++;
  }
  
  if (is人机)
    if (bIsAI)
      return;
  
  VectorRect rect;
  BoxConversion(LocationWorldPos, &rect, Matrix);
  
  float Health = 0.0;
  float HealthMax = 0.0;
  
  float DeathHealth = 0.0;
  float MaxDeathHealth = 0.0;
  
  MyWeaponBase = Read<uintptr_t>(Character + 0x14c0); // 藏
  
  uintptr_t CachedAttributeSetChangeClip = Read<uintptr_t>(MyWeaponBase + 0x1120); // 藏
  
  if (is聚点) {
    if (IsValidAddress(MyWeaponBase)) {
      // uintptr_t 聚点指针 = Read<uintptr_t>(Read<uintptr_t>(Read<uintptr_t>(MyWeaponBase + 0x4b0) + 0x1D8) +
      // 0x188); struct UWeaponFuncComponentSpread* FuncComponentSpread; struct UGPWeaponFireSpreadBase*
      // FireSpreadMethod; Write<float>(聚点指针 + 0x26C,0);
      Write<float>(CachedAttributeSetChangeClip + 0x68 + 0xC, 0.0); // 藏
      Write<float>(CachedAttributeSetChangeClip + 0x78 + 0xC, 0.0); // 藏
    }
  }
  
  // GetRange(范围大小, is躯体||is手臂);
  // GetRange(范围大小, is躯体);
  
  if (is加速) {
    if (Read<float>(Character + 0x1788) != 1.1f)
      Write<float>(Character + 0x1788, 1.1); // float MovementVelocityScaler;
    
  } else {
    float js = Read<float>(Character + 0x1788);
    if (js != 1.0f)
      Write<float>(Character + 0x1788, 1.0f);
  }
  
  if (is无后) {
    uintptr_t WeaponFuncComponent = Read<uintptr_t>(MyWeaponBase + 0x1308);
    // struct UWeaponDataComponentFiring* WeaponDataComponentFiring; // 藏
    if (WeaponFuncComponent) {
      uintptr_t FireRecoilMethod = Read<uintptr_t>(WeaponFuncComponent + 0x500); // 藏
      if (FireRecoilMethod) {
        Write<float>(FireRecoilMethod + 0x1024, 0.0f); // 藏
        Write<float>(FireRecoilMethod + 0x1028, 0.0f); // 藏
      }
    }
  }
  
  float HelmetHealth = 0.0f;
  float ArmorHealth = 0.0f;
  int Armorlevel = 0;
  int HelmetArmorlevel = 0;
  
  if (isScreenVisible(LocationScreen, Vector2(CanvasSize.X, CanvasSize.Y))) {
    
    tDis = GetCenterOffsetForVector(Vector2(rect.x, rect.y));
    if (tDistance <= CanvasSize.Y && tDis < markDis) {
      markDis = tDis;
      SetAimRadius(distance);
    }
    
    long GPHealthDataComponent = Read<long>(Player + 0xec8);
    if (IsValidAddress(GPHealthDataComponent)) {
      long HealthSet = Read<long>(GPHealthDataComponent + 0x248);
      if (IsValidAddress(HealthSet)) {
        
        Health = Read<float>(HealthSet + 0x40);
        HealthMax = Read<float>(HealthSet + 0x50);
        DeathHealth = Read<float>(HealthSet + 0xD0);
        MaxDeathHealth = Read<float>(HealthSet + 0xE0);
      }
    }
    
    int Bone[18] = {31, 30, 5, 3, 2, 1, 6, 7, 8, 34, 35, 36, 58, 59, 60, 62, 63, 64};
    
    Vector2 Bones_Pos[18];
    Vector3 Hitpart[18];
    
    Vector2 打击点屏幕坐标;
    Vector3 打击点世界坐标, root;
    
    for (int i = 0; i < 18; i++) {
      @autoreleasepool {
        Vector3 pos = GetBoneFTransform(Mesh, Bone[i]);
        Hitpart[i] = pos;
        Bones_Pos[i] = WorldToScreen(pos, Matrix);
        // NSLog(@"dh666 Bones_Pos[i] %f",Bones_Pos[i].X);
      }
    }
    
    Vector2 RootScreen = WorldToScreen(GetBoneFTransform(Mesh, 0), Matrix);
    
    // Unused
    // Vector3 Head = GetBoneFTransform(Mesh, 31);
    // Vector2 HeadScreen = WorldToScreen(Head, Matrix);
    
    if (is骨骼) {
      Draw::DrawLine(ImVec2(Bones_Pos[1].X, Bones_Pos[1].Y), ImVec2(Bones_Pos[2].X, Bones_Pos[2].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[2].X, Bones_Pos[2].Y), ImVec2(Bones_Pos[3].X, Bones_Pos[3].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[3].X, Bones_Pos[3].Y), ImVec2(Bones_Pos[4].X, Bones_Pos[4].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[4].X, Bones_Pos[4].Y), ImVec2(Bones_Pos[5].X, Bones_Pos[5].Y),
                     BoneColos(bIsAI), 2);
      
      Draw::DrawLine(ImVec2(Bones_Pos[2].X, Bones_Pos[2].Y), ImVec2(Bones_Pos[6].X, Bones_Pos[6].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[6].X, Bones_Pos[6].Y), ImVec2(Bones_Pos[7].X, Bones_Pos[7].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[7].X, Bones_Pos[7].Y), ImVec2(Bones_Pos[8].X, Bones_Pos[8].Y),
                     BoneColos(bIsAI), 2);
      
      Draw::DrawLine(ImVec2(Bones_Pos[2].X, Bones_Pos[2].Y), ImVec2(Bones_Pos[9].X, Bones_Pos[9].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[9].X, Bones_Pos[9].Y), ImVec2(Bones_Pos[10].X, Bones_Pos[10].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[10].X, Bones_Pos[10].Y), ImVec2(Bones_Pos[11].X, Bones_Pos[11].Y),
                     BoneColos(bIsAI), 2);
      
      Draw::DrawLine(ImVec2(Bones_Pos[5].X, Bones_Pos[5].Y), ImVec2(Bones_Pos[12].X, Bones_Pos[12].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[12].X, Bones_Pos[12].Y), ImVec2(Bones_Pos[13].X, Bones_Pos[13].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[13].X, Bones_Pos[13].Y), ImVec2(Bones_Pos[14].X, Bones_Pos[14].Y),
                     BoneColos(bIsAI), 2);
      
      Draw::DrawLine(ImVec2(Bones_Pos[5].X, Bones_Pos[5].Y), ImVec2(Bones_Pos[15].X, Bones_Pos[15].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[15].X, Bones_Pos[15].Y), ImVec2(Bones_Pos[16].X, Bones_Pos[16].Y),
                     BoneColos(bIsAI), 2);
      Draw::DrawLine(ImVec2(Bones_Pos[16].X, Bones_Pos[16].Y), ImVec2(Bones_Pos[17].X, Bones_Pos[17].Y),
                     BoneColos(bIsAI), 2);
    }
    
    float dw = 120;                                  // 矩形的宽度
    float lineHeight = 3;                            // 线条的高度
    float spaceHeight = 1.0;                         // 空白的高度
    float rectHeight = lineHeight * 2 + spaceHeight; // 矩形的总高度
    float dx = rect.x + rect.w * 0.5 - dw * 0.5;     // 矩形的x坐标位置
    float dy = rect.y - rectHeight * 2;              // 矩形的y坐标位置
    float caczcds = Health / HealthMax * 100;
    float HealthRatio = caczcds / 100;
    float percent = dw * HealthRatio;
    
    float Deathcaczcds = DeathHealth / MaxDeathHealth * 100;
    
    float DeathHealthRatio = Deathcaczcds / 100;
    
    float Deathpercent = dw * DeathHealthRatio;
    //
    if (is血量) {
      // 绘制外部圆角矩形（固定大小）
      Draw::DrawRect(ImVec2(dx - 1.0, dy - 1.0), ImVec2(dx + 1.0 + dw, dy + 1.0 + rectHeight), Colour_黑色, 1);
      
      // 绘制填充圆角矩形（随血量变化）
      if (Health > 0) {
        Draw::DrawRectFilled(ImVec2(dx, dy), ImVec2(dx + percent, dy + rectHeight),
                             bIsAI ? Colour_绿色 : Colour_红色);
      } else {
        Draw::DrawRectFilled(ImVec2(dx, dy), ImVec2(dx + Deathpercent, dy + rectHeight), Colour_黄色);
      }
    }
    if (is信息) {
      uintptr_t WeaponBase = Read<uintptr_t>(Player + 0x14c0);
      if (IsValidAddress(WeaponBase)) {
        // uintptr_t CachedAttributeSetWeaponAmmo = Read<uintptr_t>(WeaponBase + 0x1018);
        // if (IsValidAddress(CachedAttributeSetWeaponAmmo)){
        //   float WeaponAmmoCount = Read<float>(CachedAttributeSetWeaponAmmo + 0x48);
        //   float WeaponCarriedAmmoCount = Read<float>(CachedAttributeSetWeaponAmmo + 0x4C);
        string WeaponName = GetWeaponIDName(Read<int>(WeaponBase + 0x818));
        
        string text = string_format("%s", WeaponName.c_str());
        if (!WeaponName.empty()) {
          Draw::DrawText(text, ImVec2(rect.x + rect.w / 2, rect.y - 63), true,
                         bIsAI ? Colour_白色 : Colour_黄色, true, 20);
        }
      }
      // }
      if (bIsAI) {
        string NpcName = GetAIPlayerName(Player);
        Draw::DrawText(NpcName.c_str(), ImVec2(rect.x + rect.w / 2, rect.y - 40), true, Colour_白色, true, 22);
      } else {
        long name = Read<long>(PlayerComponent + 0x470);
        if (!IsValidAddress(name))
          return;
        
        getUTF8(PlayerName, name);
        
        Name = PlayerName;
        string a = "";
        a += to_string((int)Team);
        a += "·";
        a += Name.c_str();
        
        Draw::DrawText(a.c_str(), ImVec2(rect.x + rect.w / 2, rect.y - 40), true, Colour_黄色, true, 22);
        
        long DFMAttributesCenter = Read<long>(Player + 0x1ef8); // 藏
        if (IsValidAddress(DFMAttributesCenter)) {
          
          HelmetHealth = Read<float>(DFMAttributesCenter + 0x2e8 + 0x8 + 0x4); // 藏
          ArmorHealth = Read<float>(DFMAttributesCenter + 0x2e8 + 0x8);        // 藏
        }
        //
        long EquipmentInfoArray = Read<long>(Read<long>(Player + 0x1de0) + 0x1d8);
        // Class DFMGameplay.CharacterEquipComponent->TArray<struct FEquipmentInfo> EquipmentInfoArray//藏
        
        FEquipmentInfo EquipPawn;
        
        for (int i = 0; i < 6; i++) {
          @autoreleasepool {
            readMemory(EquipmentInfoArray + i * sizeof(FEquipmentInfo), &EquipPawn, sizeof(FEquipmentInfo));
            
            FArmorInfo2 fArmorInfo2 = GetArmorInfo2(EquipPawn);
            // NSLog(@"dh666 ArmorHealth %d",fArmorInfo2.AttachPosition);
            if (fArmorInfo2.AttachPosition == EAttachPosition::Attach_BreastPlate) {
              Armorlevel = fArmorInfo2.ArmorLevel;
            } else if (fArmorInfo2.AttachPosition == EAttachPosition::Attach_Helmet) {
              HelmetArmorlevel = fArmorInfo2.ArmorLevel;
            }
          }
        }
        Draw::DrawText(
                       string_format("%d:%.0f | %d:%.0f", HelmetArmorlevel, HelmetHealth, Armorlevel, ArmorHealth),
                       ImVec2(rect.x + rect.w / 2, RootScreen.Y + 30), true, Colour_黄色, true, 25);
      }
      //
      Draw::DrawText(string_format("%.0fm", distance), ImVec2(rect.x + rect.w / 2, RootScreen.Y + 10), true,
                     bIsAI ? Colour_白色 : Colour_黄色, true, 25);
    }
    
    if (is射线)
      Draw::DrawLine(ImVec2(CanvasSize.X / 2, 10), ImVec2(rect.x + rect.w / 2, rect.y - 65),
                     bIsAI ? Colour_白色 : Colour_红色);
    
    //    if(is躯体){
    //      if(is手臂){
    //        if(Read<float>(Read<long>(Read<long>(Player + 0xec8) + 0x248) + 0x40) < 0.5) {//藏
    //          return;
    //        }
    //      }
    //      if (GetInsideFov(CanvasSize.X, CanvasSize.Y, HeadScreen,Aimbot_Circle_Radius)) {
    //        tDistance = GetCenterOffsetForVector(HeadScreen);
    //        if (tDistance <= Aimbot_Circle_Radius && distance < 范围大小) {
    //          // 仅当当前目标比已记录目标更近时更新
    //          if (tDistance < markDistance) {
    //            needAdjustAim = true;
    //            if (needAdjustAim) {
    //              markDistance = tDistance;
    //              markScreenPos = HeadScreen;
    //              SetControlRotation(Player,Head);
    //            }
    //          }
    //        }
    //      }
    //    }
    
  } else {
    
    Vector2 EntityScreen = GetScreenEdgeImVec2(LocationScreen, Vector2(CanvasSize.X, CanvasSize.Y), 70.0f);
    Draw::DrawCircleFilled(ImVec2(EntityScreen.X, EntityScreen.Y), 40, bIsAI ? Colour_绿色 : Colour_红色);
    Draw::DrawText(string_format("%.0f", distance), ImVec2(EntityScreen.X, EntityScreen.Y - 15), true, Colour_白色,
                   true, 35);
  }
  
  if (!bIsAI &&
      isEnemyFacingMe(PlayerRotation.Yaw, LocationWorldPos.X, LocationWorldPos.Y, CharacterPos.X, CharacterPos.Y)) {
    Draw::DrawText(string_format("瞄准"), ImVec2(rect.x + rect.w / 2, rect.y - 83), true, Colour_红色, true, 25);
    string aimingName;
    aimingName = Name;
    aimingName += "正在看着你";
    aimingName += "(";
    aimingName += to_string((int)distance);
    aimingName += "M)";
    
    aimingEnemies.push_back(aimingName);
  }
  
  float startY = CanvasSize.Y * 0.02f + 150;
  float lineHeight = 45;
  
  for (size_t i = 0; i < aimingEnemies.size(); i++) {
    Draw::DrawText(string_format("%s", aimingEnemies[i].c_str()), ImVec2(CanvasSize.X / 2, startY + i * lineHeight),
                   true, Colour_红色, true, 40);
  }
  
  ////    char preShouldDraw = Read<char>(MapObjPtr + 0x8fc);
  ////
  ////        if (preShouldDraw)
  ////        {
  ////            int teamColor;
  ////            switch (Team) {
  ////                case 1: teamColor = Colour_紫色; break;
  ////                case 2: teamColor = Colour_蓝色; break;
  ////                case 3: teamColor = Colour_珊瑚红; break;
  ////                case 4: teamColor = Colour_黄色; break;
  ////                case 5: teamColor = Colour_草绿; break;
  ////                case 6: teamColor = Colour_青色; break;
  ////                case 7: teamColor = Colour_橙色; break;
  ////                case 8: teamColor = Colour_橙黄; break;
  ////                case 9: teamColor = Colour_绿黄; break;
  ////                case 10: teamColor = Colour_白色; break;
  ////                default: teamColor = Colour_绿色; break;
  ////            }
  ////
  ////            Vector2 ScreenPos, DirectionPos;
  ////
  ////            Mapinfo radar = Read<Mapinfo>(MapObjPtr + 0x828);
  ////
  ////            Vector2 DisplaySize = { (float)CanvasSize.X,(float)CanvasSize.Y};
  ////            if (radar.MapX == 330062)
  ////            {
  ////                GetCGMapScreenPos(radar, DisplaySize, LocationWorldPos, PlayerRotation.Yaw, ScreenPos,
  /// DirectionPos); /            } /            else /            { /                GetDBMapScreenPos(radar,
  /// DisplaySize, LocationWorldPos, PlayerRotation.Yaw, ScreenPos, DirectionPos); /            }
  ////
  ////            Draw::DrawCircleFilled(ImVec2(ScreenPos.X, ScreenPos.Y), 15, teamColor);
  ////            Draw::DrawCircle(ImVec2(ScreenPos.X, ScreenPos.Y), 16, Colour_白色);
  ////
  ////            Draw::DrawLine({ ScreenPos.X, ScreenPos.Y }, { DirectionPos.X, DirectionPos.Y }, teamColor, 5.f);
  ////
  ////            if (!bIsAI) Draw::DrawText(string_format("%d", Team), ImVec2(ScreenPos.X, ScreenPos.Y - 9), true,
  /// Colour_白色, true,26); /        }
  
  if (is雷达) {
    DrawRadar(Player, 雷达x, 雷达y, 雷达大小, 雷达大小, PlayerRotation.Yaw);
  }
}

#pragma mark - 物资
void GetSuppliesData(long Object) {
  
  Vector3 worldLocation = GetRelativeLocation(Object);
  Vector2 screenLocation = WorldToScreen(worldLocation, Matrix);
  
  if (isScreenVisible(screenLocation, Vector2(CanvasSize.X, CanvasSize.Y))) { // 屏幕内
    float distance = Vector3::Distance(worldLocation, CharacterPos) / 100;
    if (distance > 1 && distance <= 物资距离) {
      
      long ItemRecycle = Read<long>(Object + 0xDB8); // 藏
      if (!IsValidAddress(ItemRecycle))
        return;
      
      int ItemRecyclePricePercent = Read<int>(ItemRecycle + 0xD8);
      
      long jiazhi = Read<uintptr_t>(Object + 0xDB8); // 藏
      if (!IsValidAddress(jiazhi))
        return;
      ;
      
      int Quality = Read<int>(jiazhi + 0x68);
      
      if (Quality < 2)
        return;
      
      int Inventory = Read<int>(Object + 0xbe0); // 藏
      string InventoryIdname = GetClassName(Inventory, GName);
      ItemInfo itemInfo = InventoryId(InventoryIdname.c_str());
      string InventoryName = itemInfo.name;
      
      // int color = itemInfo.color;
      // string InventoryName = GetPickupName(Object); // 提取公共逻辑
      
      if (is红 && Quality >= 6) {
        Draw::DrawText(
                       string_format("%s\n[价值:%d][%.0fM]", InventoryName.c_str(), ItemRecyclePricePercent, distance),
                       ImVec2(screenLocation.X, screenLocation.Y), true, Colour_红色, true, 22);
      } else if (is金 && Quality == 5) {
        Draw::DrawText(
                       string_format("%s\n[价值:%d][%.0fM]", InventoryName.c_str(), ItemRecyclePricePercent, distance),
                       ImVec2(screenLocation.X, screenLocation.Y), true, Colour_橙色, true, 22);
      } else if (is紫 && Quality == 4) {
        Draw::DrawText(
                       string_format("%s\n[价值:%d][%.0fM]", InventoryName.c_str(), ItemRecyclePricePercent, distance),
                       ImVec2(screenLocation.X, screenLocation.Y), true, Colour_紫色, true, 22);
      } else if (is蓝 && Quality == 3) {
        Draw::DrawText(
                       string_format("%s\n[价值:%d][%.0fM]", InventoryName.c_str(), ItemRecyclePricePercent, distance),
                       ImVec2(screenLocation.X, screenLocation.Y), true, Colour_蓝色, true, 22);
      } else if (is绿 && Quality == 2) {
        Draw::DrawText(
                       string_format("%s\n[价值:%d][%.0fM]", InventoryName.c_str(), ItemRecyclePricePercent, distance),
                       ImVec2(screenLocation.X, screenLocation.Y), true, Colour_绿色, true, 22);
      }
    }
  }
}

#pragma mark - 箱子
static void GetData(uintptr_t Object, const char *name, int color) {
  
  Vector3 worldLocation = GetRelativeLocation(Object);
  Vector2 screenLocation = WorldToScreen(worldLocation, Matrix);
  
  if (isScreenVisible(screenLocation, Vector2(CanvasSize.X, CanvasSize.Y))) { // 屏幕内
    float distance = Vector3::Distance(worldLocation, CharacterPos) / 100;
    if (distance > 1 && distance <= 物资距离) {
      
      // FDeadBodyBoxInfo DeadBodyBoxInfo = Read<FDeadBodyBoxInfo>(Object + 0x1d90);
      // EDeadBodySkeletalMeshType MeshType = DeadBodyBoxInfo.DeadBodySkeletalMeshType;
      
      Draw::DrawText(string_format("%s[%.0fM]", name, distance), ImVec2(screenLocation.X, screenLocation.Y), true,
                     color, true, 22);
      
      if (is盒子物资) {
        if (distance > 25)
          return;
        
        Vector2 goodsListScreen = WorldToScreen(worldLocation, Matrix);
        
        if (GetCenterOffsetForVector(goodsListScreen) < 250) {
          int goodsListValidCount = 0;
          
          int InventoryListCount = Read<int>(Object + 0x1828 + sizeof(uintptr_t)); // 藏
          // 开始遍历
          for (int index = 0; index < InventoryListCount; index++) {
            @autoreleasepool {
              screenLocation = goodsListScreen; // 确保每次循环都从基准坐标开始计算
              if (index > 100) {
                break;
              }
              
              long int InventoryItemInfo;
              InventoryItemInfo = Read<uintptr_t>(Object + 0x1828) + 0x10 + index * 0x5b8; // 藏
              
              long ItemRecycle = Read<long>(InventoryItemInfo + 0x530); // 藏
              if (!IsValidAddress(ItemRecycle))
                return;
              
              int ItemRecyclePricePercent = Read<int>(ItemRecycle + 0xD8);
              
              if (ItemRecyclePricePercent <= 9999)
                continue;
              
              getUTF8(wzname,
                      Read<uintptr_t>(
                                      Read<uintptr_t>(
                                                      Read<uintptr_t>(
                                                                      Read<uintptr_t>(
                                                                                      Read<uintptr_t>(Read<uintptr_t>(InventoryItemInfo + 0x530) + 0x18) +
                                                                                      0x18) +
                                                                      0x30) +
                                                      0x20) +
                                      0x0)); // 藏
              
              goodsListValidCount++;
              
              screenLocation.X = goodsListScreen.X;
              screenLocation.Y = goodsListScreen.Y - 20 * goodsListValidCount;
              
              string name;
              name = wzname;
              name += "[¥:";
              name += std::to_string((int)ItemRecyclePricePercent);
              name += "]";
              
              if (is红 && ItemRecyclePricePercent >= 500000) {
                Draw::DrawText(name.c_str(), ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                               Colour_红色, true, 20);
              } else if (is金 && ItemRecyclePricePercent > 100000 && ItemRecyclePricePercent <= 500000) {
                Draw::DrawText(name.c_str(), ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                               Colour_橙色, true, 20);
              } else if (is紫 && ItemRecyclePricePercent > 50000 && ItemRecyclePricePercent <= 100000) {
                Draw::DrawText(name.c_str(), ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                               Colour_紫色, true, 20);
              } else if (is蓝 && ItemRecyclePricePercent > 30000 && ItemRecyclePricePercent <= 50000) {
                Draw::DrawText(name.c_str(), ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                               Colour_蓝色, true, 20);
              } else if (is绿 && ItemRecyclePricePercent > 10000 && ItemRecyclePricePercent <= 30000) {
                Draw::DrawText(name.c_str(), ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                               Colour_绿色, true, 20);
              }
            }
          }
        }
      }
    }
  }
}

void GetSafeData() {
  
  uintptr_t Safelevel = Read<uintptr_t>(libbase + 0xF8B7040); // 藏
  if (!IsValidAddress(Safelevel))
    return;
  
  int SafelevelCount = Read<int>(libbase + 0xF8B7048); // 藏
  
  for (int i = 0; i < SafelevelCount; ++i) {
    @autoreleasepool {
      long SafeActor = Read<long>(Safelevel + 0x18 * i);
      
      int SafeID = Read<float>(SafeActor + 0x760); // 藏
      
      if (SafeID > 10 && SafeID < 151) {
        
        Vector3 worldLocation = GetRelativeLocation(SafeActor);
        Vector2 screenLocation = WorldToScreen(worldLocation, Matrix);
        ;
        if (isScreenVisible(screenLocation, Vector2(CanvasSize.X, CanvasSize.Y))) {
          
          float distance = Vector3::Distance(worldLocation, CharacterPos) / 100;
          if (distance > 1 && distance <= 80) {
            
            //            long Name = Read<long>(Read<long>(Read<long>(SafeActor + 0xDB8) + 0x18) +
            //                                   0x28); if (!IsValidAddress(Name)) continue;
            //
            //            getUTF8(SafeName, Name);
            //
            //            string NName = SafeName;
            //
            //            // 检查是否是特定的箱子类型
            //            if (NName == "保险箱" || NName == "航空储物箱" || NName == "电脑机箱")
            //            {
            //              const char* status = (IsOpen == 0) ? "[未开启]" : "[已开启]";
            //              int color = (IsOpen == 0) ? Colour_黄色 : Colour_红色;
            //
            //              DrawText(string_format("%s\n%s[%.0fM]", NName.c_str(), status,
            //                                     distance),
            //                       ImVec2(screenLocation.X, screenLocation.Y), true, color,
            //                       true, 25);
            //            }
            
            Vector2 goodsListScreen = WorldToScreen(worldLocation, Matrix);
            
            if (is盒子物资 && distance <= 25) {
              if (GetCenterOffsetForVector(goodsListScreen) < 250) {
                int goodsListValidCount = 0;
                
                int InventoryListCount = Read<int>(SafeActor + 0x1828 + sizeof(uintptr_t)); // 藏
                // 开始遍历
                for (int index = 0; index < InventoryListCount; index++) {
                  @autoreleasepool {
                    if (index > 100) {
                      break;
                    }
                    
                    long int InventoryItemInfo;
                    InventoryItemInfo = Read<long>(SafeActor + 0x1828) + 0x10 + index * 0x5b8; // 藏
                    
                    // int InventoryCount = Read<int>(Read<long>(Object + 0x15D0) + 0x30 + index *
                    // 0x528);
                    
                    long ItemRecycle = Read<long>(InventoryItemInfo + 0x530); // 藏
                    if (!IsValidAddress(ItemRecycle))
                      return;
                    
                    int ItemRecyclePricePercent = Read<int>(ItemRecycle + 0xD8);
                    
                    long jiazhi = Read<uintptr_t>(InventoryItemInfo + 0x530); // 藏
                    if (!IsValidAddress(jiazhi))
                      return;
                    ;
                    
                    int Quality = Read<int>(jiazhi + 0x68);
                    
                    if (Quality < 2)
                      continue;
                    
                    long Name = Read<long>(
                                           Read<long>(
                                                      Read<long>(Read<long>(Read<long>(Read<long>(InventoryItemInfo + 0x530) +
                                                                                       0x18) +
                                                                            0x18) +
                                                                 0x30) +
                                                      0x20) +
                                           0x0); // 藏
                    // if (!IsValidAddress(Name)) continue;
                    
                    getUTF8(BoxName, Name);
                    
                    goodsListValidCount++;
                    
                    screenLocation.X = goodsListScreen.X;
                    screenLocation.Y = goodsListScreen.Y - 20 * goodsListValidCount;
                    
                    string name;
                    name = BoxName;
                    name += "[¥:";
                    name += std::to_string((int)ItemRecyclePricePercent);
                    name += "]";
                    
                    if (Quality >= 6) {
                      Draw::DrawText(name.c_str(),
                                     ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                                     Colour_红色, true, 20);
                    } else if (Quality == 5) {
                      Draw::DrawText(name.c_str(),
                                     ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                                     Colour_橙色, true, 20);
                    } else if (Quality == 4) {
                      Draw::DrawText(name.c_str(),
                                     ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                                     Colour_紫色, true, 20);
                    } else if (Quality == 3) {
                      Draw::DrawText(name.c_str(),
                                     ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                                     Colour_蓝色, true, 20);
                    } else {
                      Draw::DrawText(name.c_str(),
                                     ImVec2(screenLocation.X - 40, screenLocation.Y - 2), false,
                                     Colour_绿色, true, 20);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

std::unordered_map<uintptr_t, std::chrono::steady_clock::time_point> drawTimeMap;

void GetWarningData(uintptr_t Object, const char *name, int color) {
  using namespace std::chrono;
  
  // 获取当前时间
  auto now = steady_clock::now();
  
  // 如果对象不在map中，添加记录
  if (drawTimeMap.find(Object) == drawTimeMap.end()) {
    drawTimeMap[Object] = now;
  }
  
  // 计算时间差
  auto elapsed = duration_cast<seconds>(now - drawTimeMap[Object]).count();
  
  // 超过 10 秒则不绘制
  if (elapsed > 10) {
    return;
  }
  
  Vector3 worldLocation = GetRelativeLocation(Object);
  Vector2 screenLocation = WorldToScreen(worldLocation, Matrix);
  
  float distance = Vector3::Distance(worldLocation, CharacterPos) / 100;
  if (distance > 1 && distance <= 150) {
    Draw::DrawCircleFilled(ImVec2(screenLocation.X, screenLocation.Y), 15, Colour_红色);
    Draw::DrawText(string_format("%s[%.0fM]", name, distance), ImVec2(screenLocation.X, screenLocation.Y + 20),
                   true, color, true, 22);
  }
}

bool bFindDNF = false;
BOOL shouldKeepDeleting = NO;

void Draw::Startdfm() {
  ImGuiIO &io = ImGui::GetIO();
  
  CanvasSize.X = io.DisplaySize.x;
  CanvasSize.Y = io.DisplaySize.y;
  
  isHookAngle = false;
  sniperrifle = false;
  robot = 0;
  player = 0;
  aimingEnemies.clear();
  tDistance = 0;
  needAdjustAim = false;
  markDistance = CanvasSize.X;
  markScreenPos = Vector2(CanvasSize.X / 2, CanvasSize.Y / 2);
  AimPosScreen = Vector2(CanvasSize.X, CanvasSize.Y);
  markDis = CanvasSize.X;
  tDis = 0;
  
  getdfm();
  if (总开关) {
    NSLog(@"[DOJailbreaker] start machPIDGword (pid:%x base:%lx)", gamePid, libbase);
    GWorld = exploit_machPIDGword(gamePid, libbase);
    NSLog(@"[DOJailbreaker] ended machPIDGword: %lx", GWorld);
  }
  if (!IsValidAddress(GWorld))
    return;
  GetModuleBaseAddress(GWorld);
  
  uintptr_t MatrixAddr = Read<uintptr_t>(libbase + 0xF66ACB0); // 藏
  if (!IsValidAddress(MatrixAddr))
    return;
  
  uintptr_t MatrixSize = Read<uintptr_t>(MatrixAddr + 0x20) + 0x280; // 藏
  memset(Matrix, 0, sizeof(Matrix));
  readMemory(MatrixSize, Matrix, sizeof(Matrix));
  
  GName = libbase + 0xF472A40;
  if (!IsValidAddress(GName))
    return;
  
  uintptr_t PersistentLevel = Read<uintptr_t>(GWorld + 0xF8); // 藏
  if (!IsValidAddress(PersistentLevel))
    return;
  
  uintptr_t ActorArray = Read<uintptr_t>(PersistentLevel + 0x1F0); // 藏
  
  int ActorCount = Read<int>(PersistentLevel + 0x1F8); // 藏
  if (!IsValidAddress(ActorArray) || ActorCount <= 0 || ActorCount > 1000)
    return;
  
  std::vector<uintptr_t> actorList(ActorCount);
  if (!ReadRemoteBytes(actorList.data(), ActorArray, ActorCount * sizeof(uintptr_t)))
    return;
  
  for (auto Actor : actorList) {
    if (!IsValidAddress(Actor))
      continue;
    
    int ClassID = Read<int>(Actor + 0x1C);
    if (ClassID <= 0)
      continue;
    
    string ClassName = GetClassName(ClassID, GName);
    if (ClassName.empty())
      continue;
    
    if (isContain(ClassName, "DFMCharacter") || isContain(ClassName, "DFMAICharacter") ||
        isContain(ClassName, "DFM_Character") || isContain(ClassName, "Character"))
      GetPlayerData(Actor);
    
    if (is盒子) {
      if (isContain(ClassName, "Inventory_DeadBody"))
        GetData(Actor, "谷辉合", Colour_青色);
    }
  }
  
  GetSafeData();
  
  if (is人机) {
    DrawText(string_format("%d", player), ImVec2(CanvasSize.X / 2, CanvasSize.Y * 0.02f - 10), true, Colour_红色,
             true, 40);
  } else {
    DrawText(string_format("真人:%d | %d:爱坤", player, robot), ImVec2(CanvasSize.X / 2, CanvasSize.Y * 0.02f - 10),
             true, Colour_红色, true, 40);
  }
  thread_local static char fpsText[32];
  snprintf(fpsText, sizeof(fpsText), "FPS: %.1f", Read<float>(libbase + 0x109459C4)); // 藏
  DrawText(fpsText, ImVec2(CanvasSize.X * 0.2f, CanvasSize.Y * 0.08f), true, Colour_白色, true, 30);
}
