#include <stddef.h>
#include <stdbool.h>

/* Reuse Podium's actual iOS JIT allocator, including its StikDebug JIT26
 * debugger handshake and dual-mapped executable/writable memory path. */
#include "../../vendor/podium-a4/Podium/Emulator/CPU/DBT/Native/PodiumJIT.h"

static void *qemu_jit_executable_region;
static void *qemu_jit_writable_region;
static PodiumJITMode qemu_jit_mode = PodiumJITModeNone;

/* Allocate the same 64 MiB persistent code region used by Podium.
 * Keep it for the process lifetime; the QEMU TCG code cache must be wired
 * to these addresses before translated guest code can execute. */
int qemu_podium_jit_prepare(void) {
    if (qemu_jit_executable_region) return (int)qemu_jit_mode;
    qemu_jit_executable_region = podium_jit_allocate(
        64u * 1024u * 1024u, &qemu_jit_writable_region, &qemu_jit_mode);
    if (!qemu_jit_executable_region || !qemu_jit_writable_region) {
        qemu_jit_executable_region = NULL;
        qemu_jit_writable_region = NULL;
        qemu_jit_mode = PodiumJITModeNone;
        return -1;
    }
    return (int)qemu_jit_mode;
}

int qemu_podium_jit_debugger_attached(void) {
    return podium_jit_debugger_attached() ? 1 : 0;
}
