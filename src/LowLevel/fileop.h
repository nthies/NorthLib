//
//  fileop.h
//
//  Created by Norbert Thies on 15.07.1992.
//  Copyright © 1992 Norbert Thies. All rights reserved.
//

#ifndef fileop_h
#define fileop_h

#include  <stdarg.h>
#include  <stdio.h>
#include  <sys/types.h>
#include  <sys/stat.h>
#include  "sysdef.h"

/// File status
typedef struct stat stat_t;

/// File pointer
typedef FILE *fileptr_t;

BeginCLinkage

stat_t *stat_init(stat_t *st, mode_t mode);
int stat_read(stat_t *st, const char *path);
int stat_readlink(stat_t *st, const char *path);
int stat_write(stat_t *st, const char *path);
int stat_writelink(stat_t *st, const char *path);
int stat_isfifo(stat_t *st);
int stat_ischrdev(stat_t *st);
int stat_isblkdev(stat_t *st);
int stat_isdev(stat_t *st);
int stat_issock(stat_t *st);
int stat_isdir(stat_t *st);
int stat_isfile(stat_t *st);
int stat_islink(stat_t *st);
int stat_umode(stat_t *st);
int stat_gmode(stat_t *st);
int stat_wmode(stat_t *st);
int stat_mode(stat_t *st);
time_t stat_mtime(stat_t *st);
void stat_setmtime(stat_t *st, time_t mtime);
time_t stat_atime(stat_t *st);
void stat_setatime(stat_t *st, time_t atime);
time_t stat_ctime(stat_t *st);
int stat_istype(stat_t *st, const char *mode);

int fn_mkpathname(char *buff, int len, const char *dir, const char *fn);
int fn_base(char *buff, int len, const char *fn);
int fn_dir(char *buff, int len, const char *fn);
int fn_prefix(char *buff, int len, const char *fn);
int fn_ext(char *buff, int len, const char *path);
int fn_prog(char *buff, int len, const char *fn);
char *fn_repext(const char *fn, const char *next);
char *fn_basename(const char *fn);
char *fn_progname(const char *fn);
char *fn_dirname(const char *fn);
char *fn_extname(const char *fn);
char *fn_prefname(const char *fn);
char *fn_pathname(const char *dir, const char *fn);
int fn_mkpath(const char *dir, stat_t *st);
int fn_mkfpath (const char *path, stat_t *st);
int fn_access(const char *path, const char *amode);
char *fn_find(const char *path, const char *fname, const char *amode);
char *fn_pathfind ( const char *fname);
int fn_istype(const char *fn, const char *type);
int fn_getdir(char *buff, int len, const char *path);
char *fn_compress(char *fn);
int fn_getabs(char *buff, int len, const char *fname);
char *fn_abs(const char *fname);
char *fn_tmpdir();
char *fn_tmp (const char *str);
int fn_linkpath(char *buff, int len, const char *from, const char *to);
int fn_resolvelink(char *from, int flen, char *to, int tlen,
                   const char *fn, const char *link);
char *file_readlink(const char *path);
int file_link(const char *from, const char *to);
int file_unlink(const char *path);
int file_trymove( const char *src, const char *dest);
long file_copy(const char *src, const char *dest);
long file_move(const char *src, const char *dest);
int file_open(fileptr_t *rfp, const char *path, const char *mode);
int file_close(fileptr_t *rfp);
char *file_readline(fileptr_t fp);
int file_writeline(fileptr_t fp, const char *str);
int file_read(fileptr_t fp, void *buff, int nbytes);
int file_write(fileptr_t fp, const void *buff, int nbytes);
int file_flush(fileptr_t fp);

char **dir_content(const char *dir);
int dir_remove(const char *dir);

EndCLinkage

#endif /* fileop_h */
