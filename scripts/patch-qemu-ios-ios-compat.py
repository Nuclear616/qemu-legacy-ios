#!/usr/bin/env python3
"""Add the iOS-only pipe2 compatibility symbol required by static GLib."""
from pathlib import Path
import sys

engine = Path(sys.argv[1])
util_dir = engine / "util"
meson = util_dir / "meson.build"
source = util_dir / "ios-compat.c"
if not meson.is_file():
    raise SystemExit(f"Missing QEMU util Meson file: {meson}")

source.write_text(r'''/*
 * iOS compatibility functions needed by the static dependency bundle.
 * GLib's g_unix_open_pipe references pipe2, which is not exported by the
 * iOS SDK. Implement the supported O_CLOEXEC/O_NONBLOCK flags using pipe()
 * and fcntl(). This is compiled only for iOS, not the macOS bootstrap build.
 */
#include "qemu/osdep.h"

#if defined(__APPLE__) && defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__)
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

int pipe2(int pipefd[2], int flags)
{
    int supported = 0;
#ifdef O_CLOEXEC
    supported |= O_CLOEXEC;
#endif
#ifdef O_NONBLOCK
    supported |= O_NONBLOCK;
#endif
    if (flags & ~supported) {
        errno = EINVAL;
        return -1;
    }
    if (pipe(pipefd) < 0) {
        return -1;
    }
    for (int i = 0; i < 2; ++i) {
        if (flags & O_CLOEXEC) {
            int current = fcntl(pipefd[i], F_GETFD);
            if (current < 0 || fcntl(pipefd[i], F_SETFD, current | FD_CLOEXEC) < 0) {
                goto fail;
            }
        }
        if (flags & O_NONBLOCK) {
            int current = fcntl(pipefd[i], F_GETFL);
            if (current < 0 || fcntl(pipefd[i], F_SETFL, current | O_NONBLOCK) < 0) {
                goto fail;
            }
        }
    }
    return 0;

fail:
    {
        int saved_errno = errno;
        close(pipefd[0]);
        close(pipefd[1]);
        errno = saved_errno;
    }
    return -1;
}
#endif
''')

text = meson.read_text()
if "'ios-compat.c'" not in text:
    text = text.replace(
        "util_ss.add(files('osdep.c', 'cutils.c', 'unicode.c', 'qemu-timer-common.c'))",
        "util_ss.add(files('osdep.c', 'cutils.c', 'unicode.c', 'qemu-timer-common.c', 'ios-compat.c'))",
        1,
    )
    if "'ios-compat.c'" not in text:
        raise SystemExit("Could not add ios-compat.c to util_ss in util/meson.build")
    meson.write_text(text)
print("Installed iOS pipe2 compatibility source in QEMU util build")
