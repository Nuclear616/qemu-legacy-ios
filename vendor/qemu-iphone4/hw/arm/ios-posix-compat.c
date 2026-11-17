/*
 * Darwin/iOS compatibility for GLib builds which reference pipe2().
 * iOS exposes pipe() and fcntl(), so implement the small flag subset GLib
 * needs without depending on a non-existent libSystem pipe2 symbol.
 */
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

int pipe2(int pipefd[2], int flags)
{
    if (pipe(pipefd) != 0) {
        return -1;
    }

    if (flags & O_CLOEXEC) {
        for (int i = 0; i < 2; ++i) {
            int fdflags = fcntl(pipefd[i], F_GETFD);
            if (fdflags < 0 || fcntl(pipefd[i], F_SETFD, fdflags | FD_CLOEXEC) < 0) {
                int saved_errno = errno;
                close(pipefd[0]);
                close(pipefd[1]);
                errno = saved_errno;
                return -1;
            }
        }
    }

    if (flags & O_NONBLOCK) {
        for (int i = 0; i < 2; ++i) {
            int status = fcntl(pipefd[i], F_GETFL);
            if (status < 0 || fcntl(pipefd[i], F_SETFL, status | O_NONBLOCK) < 0) {
                int saved_errno = errno;
                close(pipefd[0]);
                close(pipefd[1]);
                errno = saved_errno;
                return -1;
            }
        }
    }

    return 0;
}
