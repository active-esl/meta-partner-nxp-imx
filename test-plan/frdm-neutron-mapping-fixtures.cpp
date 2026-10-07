#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <string>
#include <sys/mman.h>
#include <unistd.h>
#include <sys/wait.h>
#include <cassert>
static std::string maps_text;
static int unmaps = 0, unmap_result = 0;
static FILE * fake_fopen(const char * path, const char * mode) {
    assert(!strcmp(path,"/proc/self/maps") && !strcmp(mode,"r"));
    FILE * f = tmpfile(); assert(f); fwrite(maps_text.data(),1,maps_text.size(),f); rewind(f); return f;
}
static int fake_munmap(void * address, size_t bytes) {
    assert((uintptr_t)address == 0x10100000 && bytes == 536870912);
    ++unmaps;
    if (!unmap_result) maps_text.clear();
    return unmap_result;
}
static long fake_sysconf(int n) { assert(n == _SC_PAGESIZE); return 4096; }
#define fopen fake_fopen
#define munmap fake_munmap
#define sysconf fake_sysconf
#include "mapping-tail-guard.h"
#undef fopen
#undef munmap
#undef sysconf
static const char * original_line = "10000000-30100000 rw-s 00000000 00:0f 64 anon_inode:neutron-buffer\n";
static const char * tail_line = "10100000-30100000 rw-s 00100000 00:0f 64 anon_inode:neutron-buffer\n";
static int tests = 0;
template<class F> static void child_case(const char * name, int expected, F f) {
    fflush(nullptr); pid_t pid = fork(); assert(pid >= 0);
    if (!pid) { unmaps = 0; unmap_result = 0; f(); _exit(0); }
    int status; assert(waitpid(pid,&status,0) == pid);
    if (!WIFEXITED(status) || WEXITSTATUS(status) != expected) { fprintf(stderr,"FIXTURE_FAIL %s status=%d\n",name,status); exit(1); }
    ++tests;
}
int main() {
    bootstrap_map original{0x10000000,0x30100000,0,64,0,15};
    bootstrap_map tail{0x10100000,0x30100000,1048576,64,0,15};
    const uint64_t pointer = 0x30000000;
    assert(bootstrap_capture_valid(original,pointer));
    assert(bootstrap_tail_valid(original,pointer,tail)); tests += 2;
    for (int field = 0; field < 6; ++field) {
        auto bad = tail;
        if (field==0) ++bad.start;
        if (field==1) ++bad.end;
        if (field==2) ++bad.offset;
        if (field==3) ++bad.inode;
        if (field==4) ++bad.major;
        if (field==5) ++bad.minor;
        assert(!bootstrap_tail_valid(original,pointer,bad)); ++tests;
    }
    assert(!bootstrap_capture_valid(original,pointer+1)); ++tests;
    for (auto bad : {bootstrap_map{UINT64_MAX-4095,0,0,64,0,15},
                     bootstrap_map{0x10000000,0x30200000,0,64,0,15},
                     bootstrap_map{0x10000001,0x30100000,0,64,0,15},
                     bootstrap_map{0x10000000,0x30100000,1,64,0,15},
                     bootstrap_map{0x10000000,0x30100000,0,0,0,15},
                     bootstrap_map{0x10000000,0x10080000,0,64,0,15}}) {
        assert(!bootstrap_capture_valid(bad,bad.end-bootstrap_request)); ++tests;
    }
    child_case("capture",0,[&]{maps_text=original_line; auto m=bootstrap_capture((void*)pointer); assert(m.inode==64);});
    child_case("exact tail only",0,[&]{maps_text=tail_line; bootstrap_finish_release(original,(void*)pointer); assert(unmaps==1);});
    child_case("full release",0,[&]{maps_text.clear(); bootstrap_finish_release(original,(void*)pointer); assert(!unmaps);});
    child_case("unrelated map untouched",0,[&]{maps_text="40000000-40100000 rw-p 00000000 00:00 0 [heap]\n"; bootstrap_finish_release(original,(void*)pointer); assert(!unmaps);});
    child_case("munmap failure",2,[&]{maps_text=tail_line; unmap_result=-1; bootstrap_finish_release(original,(void*)pointer);});
    child_case("wrong tail identity",2,[&]{maps_text="10100000-30100000 rw-s 00100000 00:0f 65 anon_inode:neutron-buffer\n"; bootstrap_finish_release(original,(void*)pointer);});
    for (const std::string & bad : {std::string(original_line)+original_line,
         std::string("10000000-30100000 rw-p 00000000 00:0f 64 anon_inode:neutron-buffer\n"),
         std::string("10000000-30100000 rw-s 00000000 00:0f 64 anon_inode:neutron-buffer EXTRA\n"),
         std::string("10000000-30100000 rw-s 00000000 00:0f 18446744073709551616 anon_inode:neutron-buffer\n"),
         std::string("10000000-30100000 rw-s 00000000 00:100000000 64 anon_inode:neutron-buffer\n"),
         std::string("10000000-10000000000000000 rw-s 00000000 00:0f 64 anon_inode:neutron-buffer\n"),
         std::string(1100,'x')+"anon_inode:neutron-buffer\n",
         std::string("anon_inode:neutron-buffer\n"),
         std::string("10000000-30100000 rw-s 00000000 00:0f 64 anon_inode:neutron-buffer")}) {
        child_case("bad maps refuses before unmap",2,[&]{maps_text=bad; bootstrap_finish_release(original,(void*)pointer);});
    }
    printf("MAPPING_FIXTURES_PASS %d checks; mock unmap exact-owned-tail only\n",tests);
}
