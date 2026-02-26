
#import <mach/task.h>
#import <mach-o/dyld_images.h>
#import <string>
#import <vector>

#import "libproc.h"
#import "proc_info.h"

using namespace std;

inline bool g_kfd已初始化 = false;

extern "C" {
    int jbclient_initialize_primitives(void);
    uint64_t proc_self(void);
    uint64_t proc_find(pid_t);
    uint64_t proc_task(uint64_t);
    void proc_rele(uint64_t);
    int proc_vreadbuf(uint64_t proc, uint64_t va, void* buf, size_t size);
    int kreadbuf(uint64_t kaddr, void* buf, size_t size);
    int proc_csflags_set(uint64_t proc, uint32_t flags);
    int proc_csflags_clear(uint64_t proc, uint32_t flags);
    uint32_t proc_getcsflags(uint64_t proc);
}

struct dyld_image_info64 {
    mach_vm_address_t imageLoadAddress;
    mach_vm_address_t imageFilePath;
    mach_vm_size_t    imageFileModDate;
};

struct dyld_all_image_infos64 {
    uint32_t            version;
    uint32_t            infoArrayCount;
    mach_vm_address_t   infoArray;
    dyld_image_notifier notification;
    bool                processDetachedFromSharedRegion;
    bool                libSystemInitialized;
    mach_vm_address_t   dyldImageLoadAddress;
    mach_vm_address_t   jitInfo;
    mach_vm_address_t   dyldVersion;
    mach_vm_address_t   errorMessage;
    uint64_t            terminationFlags;
    mach_vm_address_t   coreSymbolicationShmPage;
    uint64_t            systemOrderFlag;
    uint64_t            uuidArrayCount;
    mach_vm_address_t   uuidArray;
    mach_vm_address_t   dyldAllImageInfosAddress;
    uint64_t            initialImageCount;
    uint64_t            errorKind;
    mach_vm_address_t   errorClientOfDylibPath;
    mach_vm_address_t   errorTargetDylibPath;
    mach_vm_address_t   errorSymbol;
    uint64_t            sharedCacheSlide;
};

struct {
    pid_t 目标进程ID;
    uint64_t proc地址;
    uint64_t task地址;
    bool 已初始化 = false;
    int64_t 偏移_pid = -1;
    int64_t 偏移_comm = -1;
    int64_t 偏移_list_next = -1;
    
    template<typename 类型> 类型 取kreadbuf(uint64_t 地址) {
        类型 内存 = {};
        if (kreadbuf(地址, &内存, sizeof(类型)) == 0) return 内存;
        return 类型{};
    };
    
    template<typename 类型> 类型 取vreadbuf(uint64_t 地址) {
        类型 内存 = {};
        if (proc_vreadbuf(this->proc地址, 地址, &内存, sizeof(类型)) == 0) return 内存;
        return 类型{};
    };
    
    bool 地址判断(uint64_t 地址) {
        return (地址 > 0x100000000 && 地址 < 0x300000000);
    };
    
    bool 取vreadbuf列表(uint64_t 地址, void* 内存, size_t 长度) {
        return proc_vreadbuf(this->proc地址, 地址, 内存, 长度) == 0;
    };
    
    bool 取安全读取列表(uint64_t 地址, void* 内存, size_t 长度) {
        return 取vreadbuf列表(地址, 内存, 长度);
    };
    
    template<typename 类型> 类型 取安全读取(uint64_t 地址) {
        return 取vreadbuf<类型>(地址);
    };
    
    bool 探测偏移() {
        uint64_t self_proc = proc_self();
        if (self_proc == 0) return false;
        
        pid_t my_pid = getpid();
        
        uint8_t buf[0x400] = {0};
        if (kreadbuf(self_proc, buf, sizeof(buf)) != 0) return false;
        
        偏移_pid = -1;
        for (int i = 0; i < 0x400 - 4; i += 4) {
            if (*(pid_t*)(buf + i) == my_pid) { 偏移_pid = i; break; }
        }
        if (偏移_pid < 0) return false;
        
        extern const char *__progname;
        size_t 名字长度 = strlen(__progname);
        if (名字长度 == 0 || 名字长度 > 16) return false;
        
        偏移_comm = -1;
        for (int i = 0; i < 0x400 - 16; i += 1) {
            if (memcmp(buf + i, __progname, 名字长度) == 0 && buf[i + 名字长度] == 0) {
                偏移_comm = i; break;
            }
        }
        if (偏移_comm < 0) return false;
        
        偏移_list_next = -1;
        for (int i = 0; i < 0x80; i += 8) {
            uint64_t 原始指针 = *(uint64_t*)(buf + i);
            if (原始指针 == 0 || 原始指针 == self_proc) continue;
            
            uint64_t 候选列表[2] = { 原始指针, 原始指针 | 0xffffff8000000000 };
            for (int j = 0; j < 2; j++) {
                uint64_t 候选指针 = 候选列表[j];
                if ((候选指针 >> 40) != 0xffffff && (候选指针 >> 40) != 0xfffffe) continue;
                
                pid_t 候选pid = 0;
                if (kreadbuf(候选指针 + 偏移_pid, &候选pid, sizeof(pid_t)) == 0) {
                    if (候选pid >= 0 && 候选pid < 65536) {
                        char 验证名[17] = {0};
                        if (kreadbuf(候选指针 + 偏移_comm, 验证名, 16) == 0) {
                            if (验证名[0] != 0 || 候选pid == 0) {
                                偏移_list_next = i;
                                break;
                            }
                        }
                    }
                }
            }
            if (偏移_list_next >= 0) break;
        }
        if (偏移_list_next < 0) return false;
        
        return true;
    };
    
    uint64_t 取目标模块地址(string 模块名) {
        uint64_t all_image_info_addr = 0;
        
        for (uint64_t offset = 0x200; offset < 0x400; offset += 0x8) {
            uint64_t 候选地址 = 取kreadbuf<uint64_t>(this->task地址 + offset);
            if (候选地址 > 0x100000000 && 候选地址 < 0x300000000) {
                dyld_all_image_infos64 测试;
                if (取安全读取列表(候选地址, &测试, sizeof(测试))) {
                    if (测试.version > 0 && 测试.version < 20 && 
                        测试.infoArrayCount > 0 && 测试.infoArrayCount < 10000) {
                        all_image_info_addr = 候选地址;
                        break;
                    }
                }
            }
        }
        
        if (all_image_info_addr == 0) return 0;
        
        dyld_all_image_infos64 all_image_infos64;
        if (取安全读取列表(all_image_info_addr, &all_image_infos64, sizeof(all_image_infos64))) {
            vector<dyld_image_info64> infoArray(all_image_infos64.infoArrayCount);
            if (取安全读取列表(all_image_infos64.infoArray, infoArray.data(), 
                            all_image_infos64.infoArrayCount * sizeof(dyld_image_info64))) {
                for (uint32_t i = 0; i < all_image_infos64.infoArrayCount; i++) {
                    char 当前模块名[PATH_MAX] = {0};
                    if (!取安全读取列表(infoArray[i].imageFilePath, 当前模块名, PATH_MAX - 1)) break;
                    if (strstr(当前模块名, 模块名.c_str())) return infoArray[i].imageLoadAddress;
                };
            }
        }
        
        return 0;
    };
    
    bool 取目标进程ID(string 进程名) {
        if (偏移_pid < 0 || 偏移_comm < 0 || 偏移_list_next < 0) {
            if (!探测偏移()) return false;
        }
        
        uint64_t self_proc = proc_self();
        if (self_proc == 0) return false;
        
        uint64_t 当前proc = self_proc;
        int 计数 = 0;
        
        do {
            char 当前进程名[17] = {0};
            if (kreadbuf(当前proc + 偏移_comm, 当前进程名, 16) != 0) break;
            
            if (string(当前进程名) == 进程名) {
                pid_t pid = 0;
                if (kreadbuf(当前proc + 偏移_pid, &pid, sizeof(pid)) != 0) break;
                this->目标进程ID = pid;
                this->proc地址 = 当前proc;
                this->task地址 = proc_task(当前proc);
                return this->proc地址 != 0;
            }
            
            uint64_t 原始指针 = 取kreadbuf<uint64_t>(当前proc + 偏移_list_next);
            if (原始指针 == 0) break;
            uint64_t 下一个 = 原始指针;
            if ((下一个 >> 40) != 0xffffff && (下一个 >> 40) != 0xfffffe) {
                下一个 = 原始指针 | 0xffffff8000000000;
            }
            if (下一个 == self_proc || 下一个 == 当前proc) break;
            当前proc = 下一个;
            计数++;
        } while (计数 < 10000);
        
        return false;
    };
    
    bool 调用kfd() {
        if (g_kfd已初始化) return true;
        int ret = jbclient_initialize_primitives();
        if (ret != 0) return false;
        g_kfd已初始化 = true;
        this->已初始化 = true;
        return true;
    };
    
    bool patch目标进程() {
        if (this->proc地址 == 0) return false;
        uint32_t 原始csflags = proc_getcsflags(this->proc地址);
        proc_csflags_clear(this->proc地址, 0x10000000 | 0x20000000);
        proc_csflags_set(this->proc地址, 0x1 | 0x4000000);
        return proc_getcsflags(this->proc地址) != 原始csflags;
    };
    
    void 释放kfd() {
        if (this->proc地址) {
            proc_rele(this->proc地址);
            this->proc地址 = 0;
        }
    };
} kfd;
