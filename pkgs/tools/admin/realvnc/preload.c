/* preload.c for RealVNC

Most of this code was taken from pkgs/tools/misc/saleae-logic and the various aangifte packages, particularly aangifte-2012.

Author: Michael Ashton <data@gtf.org>, 2013-08
*/

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

const char* rewrite(const char* path, char* buf)
{
        /* Redirection table: A list of pairs of strings.  If the first string
         * in each pair matches all of the first characters in the path under
         * test, they are replaced with the characters in the second string.
         * OUT is the Nix output directory.  The table is terminated with zeroes. */

        static const char *patterns[] = { 
                "/usr/share/vnc", OUT "/share/realvnc",
                "/etc/vnc/get_primary_ip4", OUT "/bin/get_primary_ip4",
                // this is for the license key, which is written by vnclicense.  there is probably a better way to do this
                "/etc/vnc", "~/.vnc",
                "/usr/X11R6/lib/X11", OUT "/share/realvnc/X11",
                0, 0 };

        int l;
        const char** p;
        for (p = patterns; *p; p += 2) {
                //fprintf(stderr, "compare %s to %s\n", path, *p);
                l = strnlen(*p, PATH_MAX);
                if (strncmp(path, *p, l - 1) == 0) {
                        if (**(p+1) == '~') {
                                // prefix with home directory
                                //!!!TODO is there a better way to get HOME?
                                if (snprintf(buf, PATH_MAX, "%s%s%s", getenv("HOME"), *(p+1) + 1, path + l) >= PATH_MAX) {
                                        abort();
                                }
                        }
                        else if (snprintf(buf, PATH_MAX, "%s%s", *(p+1), path + l) >= PATH_MAX) {
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
