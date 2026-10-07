#pragma once
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <cerrno>
#include <climits>
#include <sys/mman.h>
#include <unistd.h>

struct bootstrap_map {
    uint64_t start = 0, end = 0, offset = 0, inode = 0;
    unsigned major = 0, minor = 0;
};
static constexpr uint64_t bootstrap_request = 1048576;
static constexpr uint64_t bootstrap_max_mapping = 537919488;

static bool bootstrap_number(const char *& p, unsigned base, uint64_t & out) {
    if (!((*p >= '0' && *p <= '9') ||
          (base == 16 && ((*p >= 'a' && *p <= 'f') || (*p >= 'A' && *p <= 'F'))))) return false;
    errno = 0; char * end = nullptr;
    out = strtoull(p, &end, base);
    if (errno || end == p) return false;
    p = end; return true;
}
static bool bootstrap_parse(const char * p, bootstrap_map & m) {
    uint64_t major, minor;
    if (!bootstrap_number(p,16,m.start) || *p++ != '-' ||
        !bootstrap_number(p,16,m.end) || *p++ != ' ') return false;
    while (*p == ' ') ++p;
    if (strncmp(p,"rw-s ",5)) return false;
    p += 5; while (*p == ' ') ++p;
    if (!bootstrap_number(p,16,m.offset) || *p++ != ' ') return false;
    while (*p == ' ') ++p;
    if (!bootstrap_number(p,16,major) || *p++ != ':' ||
        !bootstrap_number(p,16,minor) || *p++ != ' ' || major > UINT_MAX || minor > UINT_MAX) return false;
    while (*p == ' ') ++p;
    if (!bootstrap_number(p,10,m.inode) || *p++ != ' ') return false;
    while (*p == ' ') ++p;
    if (strcmp(p,"anon_inode:neutron-buffer\n")) return false;
    m.major = (unsigned)major; m.minor = (unsigned)minor; return true;
}

static bool bootstrap_capture_valid(const bootstrap_map & m, uint64_t pointer) {
    if (m.start >= m.end || m.offset || !m.inode) return false;
    const uint64_t bytes = m.end - m.start;
    if (bytes < bootstrap_request || bytes > bootstrap_max_mapping) return false;
    if ((m.start | m.end) & 4095) return false;
    // Track precisely the requested final1MiB behind the returned aligned pointer.
    return pointer == m.end - bootstrap_request;
}
static bool bootstrap_tail_valid(const bootstrap_map & original, uint64_t pointer,
                                 const bootstrap_map & tail) {
    if (!bootstrap_capture_valid(original, pointer)) return false;
    if (original.end - original.start <= bootstrap_request) return false;
    // Checked original length guarantees these additions cannot overflow.
    return tail.start == original.start + bootstrap_request &&
           tail.end == original.end && tail.offset == bootstrap_request &&
           tail.inode == original.inode && tail.major == original.major &&
           tail.minor == original.minor && tail.start < tail.end;
}
static unsigned bootstrap_read_map(bootstrap_map & out) {
    FILE * f = fopen("/proc/self/maps", "r");
    if (!f) { fprintf(stderr, "GUARD_FAIL own maps open\n"); exit(2); }
    char line[1024]; unsigned count = 0;
    while (fgets(line, sizeof(line), f)) {
        // Do not allow a truncated unrelated line to hide a matching continuation.
        if (!strchr(line, '\n')) { fprintf(stderr, "GUARD_FAIL truncated maps line\n"); exit(2); }
        if (!strstr(line, "neutron-buffer")) continue;
        bootstrap_map parsed;
        if (!bootstrap_parse(line, parsed) || ++count > 1) {
            fprintf(stderr, "GUARD_FAIL ambiguous DMA mapping\n"); exit(2);
        }
        out = parsed;
    }
    bool bad = ferror(f); fclose(f);
    if (bad) { fprintf(stderr, "GUARD_FAIL own maps read\n"); exit(2); }
    return count;
}
static bootstrap_map bootstrap_capture(void * pointer) {
    bootstrap_map m;
    if (sysconf(_SC_PAGESIZE) != 4096 || bootstrap_read_map(m) != 1 ||
        !bootstrap_capture_valid(m, (uint64_t)(uintptr_t)pointer)) {
        fprintf(stderr, "GUARD_FAIL bootstrap mapping ownership/bounds\n"); exit(2);
    }
    fprintf(stderr, "TRACK_BOOTSTRAP base=%#llx bytes=%llu inode=%llu pointer=%p\n",
            (unsigned long long)m.start, (unsigned long long)(m.end-m.start),
            (unsigned long long)m.inode, pointer);
    return m;
}
static void bootstrap_finish_release(const bootstrap_map & original, void * pointer) {
    bootstrap_map tail;
    unsigned count = bootstrap_read_map(tail);
    if (!count) {
        fprintf(stderr, "BOOTSTRAP_MAPPING already_fully_released\n"); return;
    }
    if (!bootstrap_tail_valid(original, (uint64_t)(uintptr_t)pointer, tail)) {
        fprintf(stderr, "GUARD_FAIL surviving mapping changed\n"); exit(2);
    }
    const size_t bytes = (size_t)(tail.end - tail.start);
    // Exactly observed, identity-checked surviving vendor mapping; never infer a range.
    if (munmap((void *)(uintptr_t)tail.start, bytes)) {
        perror("GUARD_FAIL tracked tail munmap"); exit(2);
    }
    fprintf(stderr, "CORRECTED_BOOTSTRAP_TAIL base=%#llx bytes=%zu inode=%llu\n",
            (unsigned long long)tail.start, bytes, (unsigned long long)tail.inode);
    if (bootstrap_read_map(tail)) {
        fprintf(stderr, "GUARD_FAIL DMA mapping remains\n"); exit(2);
    }
}
