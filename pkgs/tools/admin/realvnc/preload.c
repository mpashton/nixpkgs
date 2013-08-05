
#define _GNU_SOURCE
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <limits.h>

#ifndef OUT
#error Missing OUT define - path to the installation directory.
#endif

typedef FILE *(*fopen_func_t)(const char *path, const char *mode);

/*

/usr/share/vnc -> $OUT/share/vnc
/usr/X11R6/lib -> ?
/etc/vnc -> $OUT/etc/realvnc

*/

static const char *patterns[] = { 
        "/usr/share/vnc", OUT "/share/realvnc",
        "/etc/vnc/get_primary_ip4", OUT "/bin/get_primary_ip4",
        "/etc/vnc", "/home/data/.vnc",
        "/usr/X11R6/lib/X11", OUT "/share/realvnc/X11",
        0, 0 };

const char* rewrite(const char* path, char* buf)
{
        int l;
        const char** p;
        for (p = patterns; *p; p += 2) {
                //fprintf(stderr, "compare %s to %s\n", path, *p);
                l = strnlen(*p, PATH_MAX);
                if (strncmp(path, *p, l - 1) == 0) {
                        if (snprintf(buf, PATH_MAX, "%s%s", *(p+1), path + l) >= PATH_MAX) {
                                //fprintf(stderr, "abort!\n");
                                abort();
                        }
                        //fprintf(stderr, "match: %s\n", buf);
                        return buf;
                }
        }
        //fprintf(stderr, "no match\n");
        return path;
}

FILE *fopen(const char *pathname, const char *mode)
{
        char buf[PATH_MAX];
	FILE *fp;
	const char *path;
	fopen_func_t orig_fopen;

        //fprintf(stderr, "preload.c fopen()\n");

	orig_fopen = (fopen_func_t)dlsym(RTLD_NEXT, "fopen");
	path = rewrite(pathname, buf);
	fp = orig_fopen(path, mode);

	if (path != pathname && getenv("PRELOAD_DEBUG")) {
		fprintf(stderr, "preload.c: fopen(\"%s\", \"%s\") => \"%s\": fp=%p\n", pathname, mode, path, fp);
	}

	return fp;
}

FILE *fopen64(const char *pathname, const char *mode)
{
        char buf[PATH_MAX];
	FILE *fp;
	const char *path;
	fopen_func_t orig_fopen;

        //fprintf(stderr, "preload.c fopen64()\n");

	orig_fopen = (fopen_func_t)dlsym(RTLD_NEXT, "fopen64");
	path = rewrite(pathname, buf);
	fp = orig_fopen(path, mode);

	if (path != pathname && getenv("PRELOAD_DEBUG")) {
		fprintf(stderr, "preload.c: fopen64(\"%s\", \"%s\") => \"%s\": fp=%p\n", pathname, mode, path, fp);
	}

	return fp;
}

int open(const char *path, int flags, ...)
{
        char buf[PATH_MAX];
        const char* pathname;
        int (*_open) (const char *, int, mode_t) = dlsym(RTLD_NEXT, "open");
        mode_t mode = 0;
        int err;

        //fprintf(stderr, "preload.c open()\n");

        if (flags & O_CREAT) {
                va_list ap;
                va_start(ap, flags);
                mode = va_arg(ap, mode_t);
                va_end(ap);
        }

        pathname = rewrite(path, buf);
        err = _open(pathname, flags, mode);

	if (path != pathname && getenv("PRELOAD_DEBUG")) {
		fprintf(stderr, "preload_debug: open(\"%s\", \"%s\") => \"%s\": err=%d\n", pathname, mode, path, err);
	}
        
        return err;
}

int open64(const char *path, int flags, ...)
{
        char buf[PATH_MAX];
        const char* pathname;
        int (*_open) (const char *, int, mode_t) = dlsym(RTLD_NEXT, "open64");
        mode_t mode = 0;
        int err;

        //fprintf(stderr, "preload.c open64()\n");

        if (flags & O_CREAT) {
                va_list ap;
                va_start(ap, flags);
                mode = va_arg(ap, mode_t);
                va_end(ap);
        }

        pathname = rewrite(path, buf);
        err = _open(pathname, flags, mode);

	if (path != pathname && getenv("PRELOAD_DEBUG")) {
		fprintf(stderr, "preload_debug: open64(\"%s\", \"%s\") => \"%s\": err=%d\n", pathname, mode, path, err);
	}
        
        return err;
}

#if 0
int __xstat64(int ver, const char *path, struct stat64 *st)
{
        char buf[PATH_MAX];
        int (*___xstat64) (int ver, const char *, struct stat64 *) = dlsym(RTLD_NEXT, "__xstat64");
        int err = ___xstat64(ver, rewrite(path, buf), st);

        
}

int access(const char *path, int mode)
{
        char buf[PATH_MAX];
        int (*_access) (const char *path, int mode) = dlsym(RTLD_NEXT, "access");
        int err = _access(rewrite(path, buf), mode);

	if (path != pathname && getenv("PRELOAD_DEBUG")) {
		fprintf(stderr, "preload_debug: access(\"%s\", \"%s\") => \"%s\": err=%d\n", pathname, mode, path, err);
	}

        return err;
}
#endif
