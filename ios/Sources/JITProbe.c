#include <errno.h>
#include <stddef.h>
#include <sys/mman.h>
#include <unistd.h>

/*
 * Probe whether this process can allocate an executable JIT mapping.
 * This is only a host capability probe; it does not prove that QEMU's TCG
 * code cache has been ported to Apple's MAP_JIT write-protection API.
 */
int qemu_jit_probe(void) {
#if defined(__APPLE__) && defined(MAP_JIT)
    long page_size = sysconf(_SC_PAGESIZE);
    if (page_size <= 0) {
        return errno ? errno : -1;
    }

    void *region = mmap(NULL, (size_t)page_size,
                        PROT_READ | PROT_WRITE | PROT_EXEC,
                        MAP_PRIVATE | MAP_ANON | MAP_JIT, -1, 0);
    if (region == MAP_FAILED) {
        return errno ? errno : -1;
    }

    (void)munmap(region, (size_t)page_size);
    return 1;
#else
    return -2;
#endif
}
