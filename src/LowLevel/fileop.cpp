//
//  fileop.cpp
//
//  Created by Norbert Thies on 15.07.1992.
//  Copyright © 1992 Norbert Thies. All rights reserved.
//

#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#include <utime.h>
#include <stdlib.h>
#include <stdio.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include "strext.h"
#include "mapfile.h"
#include "fileop.h"

// MARK: struct stat macros

/*
 *  Permission flags in struct stat st_mode:
 *    It seems to be safe to define the pure permission flags if not
 *    already defined. However the file type flags may be architecture
 *    dependend and if not defined are set to 0.
 */
#ifndef S_IRUSR
#  define S_IRUSR 00400
#endif
#ifndef S_IWUSR
#  define S_IWUSR 00200
#endif
#ifndef S_IXUSR
#  define S_IXUSR 00100
#endif
#ifndef S_IRWXU
#  define S_IRWXU 00700
#endif
#ifndef S_IRGRP
#  define S_IRGRP 00040
#endif
#ifndef S_IWGRP
#  define S_IWGRP 00020
#endif
#ifndef S_IXGRP
#  define S_IXGRP 00010
#endif
#ifndef S_IRWXG
#  define S_IRWXG 00070
#endif
#ifndef S_IROTH
#  define S_IROTH 00004
#endif
#ifndef S_IWOTH
#  define S_IWOTH 00002
#endif
#ifndef S_IXOTH
#  define S_IXOTH 00001
#endif
#ifndef S_IRWXO
#  define S_IRWXO 00007
#endif
#ifndef S_ISUID
#  define S_ISUID         04000   /* set uid bit */
#endif
#ifndef S_ISGID
#  define S_ISGID         02000   /* set gid bit */
#endif
#ifndef S_ISVTX
#  define S_ISVTX         01000   /* sticky bit */
#endif
#ifndef S_IAMB
#  define S_IAMB          0777    /* permission mask */
#endif
#ifndef S_MBITS
#  define S_MBITS  (S_IAMB | S_ISUID | S_ISGID | S_ISVTX)
#endif

/*
 *  file types:
 */
#ifndef S_IFIFO
#  define S_IFIFO         0   /* type: fifo */
#endif
#ifndef S_IFCHR
#  define S_IFCHR         0   /* type: char special */
#endif
#ifndef S_IFDIR
#  define S_IFDIR         0   /* type: directory */
#endif
#ifndef S_IFBLK
#  define S_IFBLK         0   /* type: block special */
#endif
#ifndef S_IFREG
#  define S_IFREG         0  /* type: regular file */
#endif
#ifndef S_IFLNK
#  define S_IFLNK         0  /* type: symbolic link */
#endif
#ifndef S_IFSOCK
#  define S_IFSOCK        0  /* type: socket */
#endif
#ifndef S_IFMT /* file type mask */
#  define S_IFMT ( S_IFIFO|S_IFCHR|S_IFDIR|S_IFBLK|S_IFREG|S_IFLNK|S_IFSOCK )
#endif

// Some stat handling macros
#define  _stat_isfifo(st) \
  ( ( ( (st).st_mode & S_IFMT ) == S_IFIFO )? 1 : 0 )
#define  _stat_ischrdev(st) \
  ( ( ( (st).st_mode & S_IFMT ) == S_IFCHR )? 1 : 0 )
#define  _stat_isblkdev(st) \
  ( ( ( (st).st_mode & S_IFMT ) == S_IFBLK )? 1 : 0 )
#define  _stat_isdev(st) \
  ( _stat_ischrdev ( st ) || _stat_isblkdev ( st ) )
#define  _stat_issock(st) \
  ( ( ( (st).st_mode & S_IFMT ) == S_IFSOCK )? 1 : 0 )
#define  _stat_isdir(st) \
  ( ( ( (st).st_mode & S_IFMT ) == S_IFDIR )? 1 : 0 )
#define  _stat_isfile(st) \
  ( ( ( (st).st_mode & S_IFMT ) == S_IFREG )? 1 : 0 )
#define  _stat_islink(st) \
  ( ( ( (st).st_mode & S_IFMT ) == S_IFLNK )? 1 : 0 )
#define  _stat_umode(st) ( ( (st).st_mode & S_IRWXU ) >> 6 )
#define  _stat_gmode(st) ( ( (st).st_mode & S_IRWXG ) >> 3 )
#define  _stat_wmode(st) ( ( (st).st_mode & S_IRWXO ) )
#define  _stat_mode(st) ( ( (st).st_mode & S_MBITS ) )
#define  _stat_atime(st) ((st).st_atime)
#define  _stat_ctime(st) ((st).st_ctime)
#define  _stat_mtime(st) ((st).st_mtime)

// MARK: - stat handling functions

/**
 * stat_init initializes a stat structure.
 * 
 * All fields are cleared and the passed file mode is set to the mode field.
 * In addition the UID/GID and time stamps are set to the current values.
 * 
 * @Returns 'st'
 */
stat_t *stat_init(stat_t *st, mode_t mode) {
  mem_set(st, 0, sizeof(stat_t));
  st->st_mode = mode;
  st->st_uid = getuid();
  st->st_gid = getgid();
  time_t now;
  time(&now);
  st->st_mtime = st->st_atime = now;
  return st;
}

/**
 * stat_read reads a stat structure into the passed stat_t.
 * 
 * In essence this function simply calls the stat library function.
 */
int stat_read(stat_t *st, const char *path) {
  return stat(path, st);
}

/**
 * stat_readlink reads a stat structure into the passed stat_t.
 * 
 * In essence this function simply calls the lstat library function.
 * If 'path' points to a symbolic link, then the status of the symbolic
 * link is returned. Otherwise it behaves like 'stat_read'.
 */
int stat_readlink(stat_t *st, const char *path) {
  return lstat(path, st);
}

/**
 * stat_write set's a file's status to the passed stat_t.
 * 
 * The following status items are changed:
 *   - file mode
 *   - uid/gid
 *   - atime/mtime
 */
int stat_write(stat_t *st, const char *path) {
  struct timeval tvs[2];
  tvs[0].tv_sec = st->st_atime;
  tvs[1].tv_sec = st->st_mtime;
  tvs[0].tv_usec = tvs[1].tv_usec = 0;
  return chmod(path, st->st_mode) ||
         chown(path, st->st_uid, st->st_gid) ||
         utimes(path, tvs);
}

/**
 * stat_writelink set's a file's status to the passed stat_t.
 * 
 * Unlike stat_write this function changes the link's status and
 * not the status of the file pointed to.
 */
int stat_writelink(stat_t *st, const char *path) {
  struct timeval tvs[2];
  tvs[0].tv_sec = st->st_atime;
  tvs[1].tv_sec = st->st_mtime;
  tvs[0].tv_usec = tvs[1].tv_usec = 0;
  return lchmod(path, st->st_mode) ||
         lchown(path, st->st_uid, st->st_gid) ||
         lutimes(path, tvs);
}

/// stat_isfifo returns TRUE when 'st' refers to a FIFO.
int stat_isfifo(stat_t *st) { return _stat_isfifo(*st); }

/// stat_ischrdev returns TRUE when 'st' refers to a character device.
int stat_ischrdev(stat_t *st) { return _stat_ischrdev(*st); }

/// stat_isblkdev returns TRUE when 'st' refers to a block device.
int stat_isblkdev(stat_t *st) { return _stat_isblkdev(*st); }

/// stat_isdev returns TRUE when 'st' refers to a device.
int stat_isdev(stat_t *st) { return _stat_isdev(*st); }

/// stat_issock returns TRUE when 'st' refers to a socket.
int stat_issock(stat_t *st) { return _stat_issock(*st); }

/// stat_isdir returns TRUE when 'st' refers to a directory.
int stat_isdir(stat_t *st) { return _stat_isdir(*st); }

/// stat_isfile returns TRUE when 'st' refers to a regular file.
int stat_isfile(stat_t *st) { return _stat_isfile(*st); }

/// stat_islink returns TRUE when 'st' refers to a symbolic link.
int stat_islink(stat_t *st) { return _stat_islink(*st); }

/// stat_umode returns the user mode portion of 'st's mode field.
int stat_umode(stat_t *st) { return _stat_umode(*st); }

/// stat_gmode returns the group mode portion of 'st's mode field.
int stat_gmode(stat_t *st) { return _stat_gmode(*st); }

/// stat_wmode returns the world (others) mode portion of 'st's mode field.
int stat_wmode(stat_t *st) { return _stat_wmode(*st); }

 /// stat_mode returns the file permissions.
 int stat_mode(stat_t *st) { return _stat_wmode(*st); }

/// stat_mtime simply returns the modification time
time_t stat_mtime(stat_t *st) { return st->st_mtime; }

/// stat_setmtime sets a new modification time
void stat_setmtime(stat_t *st, time_t mtime) { st->st_mtime = mtime; }

/// stat_atime simply returns the access time
time_t stat_atime(stat_t *st) { return st->st_atime; }

/// stat_setatime sets a new access time
void stat_setatime(stat_t *st, time_t atime) { st->st_atime = atime; }

/// stat_ctime simply returns the mode change time
time_t stat_ctime(stat_t *st) { return st->st_ctime; }

/**
 * stat_istype checks the type of a file.
 * 
 * stat_istype is used to check whether a given file is of the
 * file type specified by 'mode'. The following file types may be checked
 * (using 'mode' flags):
 *    "-", "f"  :  regular (normal) file
 *     "d"      :  directory
 *     "c"      :  character special device
 *     "b"      :  block special device
 *     "D"      :  any (block- or char- special) device
 *     "p"      :  named pipe (FIFO)
 *     "s"      :  UNIX domain socket
 *     "l"      :  symbolic link
 *   If more than one mode flag is given, theis is interpreted as
 *   implicit 'or', eg. "fp" will query whether the file is an
 *   ordinary file or a named pipe.
 *   If the mode string is prefixed by a "!", then the negation of the 
 *   following mode is returned, eg. "!fp" will return 1 if the file
 *   is not an ordinary file and not a named pipe.
 *   
 *   @Returns 1 => is of type, 0 otherwise
 */
int stat_istype(stat_t *st, const char *mode) {
  int ret =  0, is_negate =  0;
  if ( !mode || !*mode ) mode =  "f";
  if ( *mode == '!' ) { is_negate++; mode++; }
  switch ( *mode ) {
    case '-' :
    case 'f' :  ret +=  _stat_isfile ( *st ); break;
    case 'd' :  ret +=  _stat_isdir ( *st ); break;
    case 'c' :  ret +=  _stat_ischrdev ( *st ); break;
    case 'b' :  ret +=  _stat_isblkdev ( *st ); break;
    case 'D' :  ret +=  _stat_isdev ( *st ); break;
    case 'p' :  ret +=  _stat_isfifo ( *st ); break;
    case 's' :  ret +=  _stat_issock ( *st ); break;
    case 'l' :  ret +=  _stat_islink ( *st ); break;
    default  :  return 0;
  }
  if ( is_negate ) ret =  !ret;
  return ret? 1 : 0;
}

// MARK: - File name handling functions

/**
 *  fn_mkpathname is used to construct a new pathname from given directory 
 *  name and filename part.
 *  
 *  Remark: a leading './' in 'dir' is skipped.
 *  
 *  @Returns #char written 'to buff'
 */
int fn_mkpathname(char *buff, int len, const char *dir, const char *fn) {
  if ( buff && dir && fn ) {
    int l;
    char *p =  buff;
    const char *s =  fn, *d =  dir;
    int n =  0;
    if ( *d == '.' ) {
      if ( *(d+1) == '/' ) d += 2;
      else if ( !*(d+1) ) d++;
    }
    l =  str_len ( d );
    if ( *s ) {
      if ( l ) {
        if ( d [l-1] == '/' ) p += n = str_cpy( buff, len, d );
        else p += n = str_mcpy( buff, len, d, "/", (const char *) 0 );
      }
      while ( *s && (*s == '/') ) s++;
      if ( *s ) {
        n +=  str_cpy( p, len - n, s );
        return n;
      } }
    else return str_cpy( buff, len, d );
  }
  return -1;
}
 
/**
 *  fn_base writes the basename of 'path' to 'buff'.
 *  
 *  Eg let path be "/usr/xxx", then fn_base( buff, len, path) writes "xxx"
 *  to buff.
 *  
 *  @Returns #char written to buff
 */
int fn_base(char *buff, int len, const char *fn) {
  if ( buff && fn ) {
    const char *p =  str_rchr ( fn, '/' );
    if ( !p || ( ( p == fn ) && !*( p + 1 ) ) ) p =  fn;
    else p++;
    return str_cpy ( buff, len, p );
  }
  else return 0;
}
 
/**
 *  fn_dir writes the dirname of 'path' to 'buff'.
 *  
 *  Eg let path be "/usr/xxx", then fn_dir( buff, len, path) writes "/usr"
 *  to buff.
 *  
 *  @Returns #char written to buff
 */
int fn_dir(char *buff, int len, const char *fn) {
  if ( buff && fn ) {
    const char *p =  str_rchr ( fn, '/' );
    if ( !p ) return str_cpy ( buff, len, "." );
    else if ( p == fn ) return str_cpy ( buff, len, "/." );
    else return str_ncpy( buff, len, fn, (int)(p - fn) );
  }
  else return 0;
}

/**
 *  fn_prefix writes the prefix of 'path', which is a complete pathname without 
 *  extension, to 'buff'.
 *  
 *  Eg let path be "/usr/xxx.yy", then fn_prefix(buff, len, path) writes 
 *  "/usr/xx" to buff.
 *  
 *  @Returns #char written to buff
 */
int fn_prefix(char *buff, int len, const char *fn) {
  if ( buff && fn ) {
    char *p1, *p2;
    str_cpy ( buff, len, fn );
    p1 =  (char *) str_rchr ( buff, '.' );
    p2 =  (char *) str_rchr ( buff, '/' );
    if ( p1 && ( !p2 || ( p1 > p2 ) ) ) *p1 =  '\0';
    return str_len ( buff );
  }
  else return 0;
}

/**
 *  fn_ext writes the extension of 'path' to 'buff'.
 *  
 *  Eg let path be "/usr/xxx.yy", then fn_ext(buff, len, path) writes 
 *  "yy" to buff.
 *  
 *  @Returns #char written to buff
 */
int fn_ext(char *buff, int len, const char *path) {
  if ( buff && path ) {
    const char *p =  str_rchr ( path, '.' ),
               *d =  str_rchr ( path, '/' );
    if ( p && ( p > d ) ) return str_cpy ( buff, len, p + 1 );
    else return str_cpy(buff, len, str_empty_c);
  }
  else return 0;
}

/**
 * fn_has_ext returns 1 if the passed file has an extension.
 * 
 * @Returns 1 if 'fn' has extension, 0 otherwise
 */

int fn_has_ext(const char *fn) {
  if (fn) {
    const char *p =  str_rchr(fn, '.'),
               *d =  str_rchr(fn, '/');
    if (p && p > d) return 1;
  }
  return 0;
}

/**
 *  fn_prog writes the program name of 'path' to 'buff'.
 *  
 *  Eg let path be "/usr/xxx.yy", then fn_prog(buff, len, path) writes 
 *  "xxx" to buff.
 *  
 *  @Returns #char written to buff
 */
int fn_prog(char *buff, int len, const char *fn) {
  char prg [1000];
  fn_base ( prg, 1000, fn );
  return fn_prefix(buff, len, prg);
}

/**
 *  fn_repext replaces an optional extension of 'fn' by 'next'.
 *  
 *  The allocated result is returned.
 *  Eg. assume fn = "/usr/local/test.ext" and next = "next",
 *  then the result will be "/usr/local/test.next" (the same as when
 *  fn = "/usr/local/test" ).
 *  
 *  @Returns allocated new filename
 */
char *fn_repext(const char *fn, const char *next) {
  char *ret =  0;
  if ( fn && next ) {
    int l =  str_len ( fn ) + str_len ( next ) + 2;
    if ( (ret =  (char *) malloc ( l )) ) {
      int n = fn_prefix(ret, l, fn);
      str_mcpy(ret + n, l - n, ".", next, (const char *) 0);
  } }
  return ret;
}

/// fn_basename applies 'fn_base' and returns the allocated result.
char *fn_basename(const char *fn) {
  char f [1000];
  fn_base(f, 1000, fn);
  return str_heap(f, 0);
}

/// fn_progname applies 'fn_prog' and returns the allocated result.
char *fn_progname(const char *fn) {
  char f [1000];
  fn_prog(f, 1000, fn);
  return str_heap(f, 0);
}

/// fn_dirname applies 'fn_dir' and returns the allocated result.
char *fn_dirname(const char *fn) {
  char f [1000];
  fn_dir(f, 1000, fn);
  return str_heap(f, 0);
}

/// fn_prefname applies 'fn_prefix' and returns the allocated result.
char *fn_prefname(const char *fn) {
  char f [1000];
  fn_prefix(f, 1000, fn);
  return str_heap(f, 0);
}

/// fn_extname applies 'fn_ext' and returns the allocated result.
char *fn_extname(const char *fn) {
  char f [1000];
  fn_ext(f, 1000, fn);
  return str_heap(f, 0);
}

/// fn_pathname applies 'fn_mkpathname' and returns the allocated result.
char *fn_pathname(const char *dir, const char *fn) {
  char f [1000];
  fn_mkpathname(f, 1000, dir, fn);
  return str_heap(f, 0);
}

/**
 * fn_mkpath creates a directory 'dir' and all preceeding directories if necessary.
 * 
 * If the optional struct stat is passed, then mode, UID/GID, time stamps are
 * set accordingly.
 * 
 * - arguments:
 *   - dir: path of directory to create
 *   - st:  pointer to stat structure for mode, ...
 *          if st == 0, mode is set to 777
 */
int fn_mkpath(const char *dir, stat_t *st) {
  stat_t tmp;
  if ( !dir ) return -1;
  if ( stat_read( &tmp, dir) != 0 ) {
    const char *p =  str_rchr ( dir, '/' );
    mode_t mode = 0777;
    if ( st ) mode = _stat_mode(*st);
    if ( p && ( p != dir ) ) {
      char subdir [1000];
      int l =  (int) ( p - dir );
      str_ncpy(subdir, 1000, dir, l );
      if ( fn_mkpath(subdir, st) ) return -1;
    }
    if ( mkdir(dir, mode) ) return -1;
    if ( st && (stat_write(st, dir) != 0) ) return -1;
  }
  else if ( !stat_isdir(&tmp) ) return -1;
  return 0;
}

/// fn_mkfpath uses 'fn_mkpath' to create the direcory containing file 'path'.
int fn_mkfpath (const char *path, stat_t *st) {
  char dir [1000];
  fn_dir ( dir, 1000, path );
  return fn_mkpath (dir, st);
}

/**
 * fn_access checks whether a file is accessible in some way.
 * 
 * - arguments
 *   - path: pathname of file
 *   - amode: string consisting of the following letters
 *            "f"|"e": is file existing
 *            "r"    : is file readable
 *            "w"    : is file writable
 *            "x"    : is file executable
 * @Returns 0: OK, -1: Error (no access)
 */
int fn_access(const char *path, const char *amode) {
  mode_t mode = 0;
  if (amode) while (*amode) {
    switch (*amode++) {
      case 'e': // fall through
      case 'f': mode |= F_OK; break;
      case 'r': mode |= R_OK; break;
      case 'w': mode |= W_OK; break;
      case 'x': mode |= X_OK; break;
    }
  } 
  return access(path, mode);
}

/**
 * fn_find searches for a file in a list of directories.
 * 
 *  The list of directories is defined using a search path which must be 
 *  constructed as follows:
 *
 *       path =  { directory | ":" }.
 *
 *  as known from the environment variable PATH.
 *  If 'fname' is an absolute path (ie it starts with '/') then a
 *  new allocated copy of 'fname' is returned (instead of looking for it
 *  in 'path'). If 'amode == 0', then amode="f" is implied.
 * 
 *  @Returns allocated pathname if found, 0 otherwise
 */
char *fn_find(const char *path, const char *fname, const char *amode) {
  char *ret =  0;
  if ( path && fname ) {
    if (!amode) amode = "f";
    if ( *fname == '/' ) ret =  str_heap(fname, 0);
    else {
      char **av = av_a2av(path, ':');
      if ( av ) {
        char **p =  av;
        char buff [1000];
        while ( *p ) {
          const char *dir =  **p? *p : ".";
          if ( fn_mkpathname(buff, 1000, dir, fname) > 0 ) {
            if ( !fn_access(buff, amode) ) {
              ret =  str_heap(buff, 0);
              break;
            } }
          p++;
        }
        av_release ( av );
  } } }
  return ret;
}

/// fn_pathfind looks for an executable file in PATH 
char *fn_pathfind (const char *fname) {
  return fn_find(getenv("PATH"), fname, "x");
}

/// fn_istype uses stat_istype to check for a file type.
int fn_istype(const char *fn, const char *type) {
  stat_t st;
  if ( stat_read(&st, fn) ) return 0;
  return stat_istype(&st, type);
}

#ifdef _DARWIN_FEATURE_64_BIT_INODE
# define  d_ino  d_fileno
#endif

/**
 * fn_getdir evaluates the absolute pathname of a given directory.
 *
 * Remark: The passed directory 'path' must exist!
 * 
 * @Returns #char written to buff
 */
int fn_getdir(char *buff, int len, const char *path) {
  if ( path ) {
    char dir [1000], pdir [1000], *d =  buff;
    stat_t s, ps, st;
    DIR *fde;
    struct dirent *de;
    int l =  len;
    if ( !fn_istype ( path, "d" ) ) 
      return -1;
    *d =  '\0';
    str_cpy ( dir, 1000, path );
    str_mcpy ( pdir, 1000, dir, "/..", (const char *) 0 );
    if ( stat ( dir, &s ) < 0 ) return 0;
    for (;;) {
      if ( stat ( pdir, &ps ) < 0 ) return 0;
      if ( s.st_dev == ps.st_dev ) {
        if ( s.st_ino == ps.st_ino ) break;
        else {
          if ( !( fde =  opendir ( pdir ) ) ) 
            return 0;
          while ( (de =  readdir ( fde )) ) {
            if ( s.st_ino == de -> d_ino ) {
              l -=  str_rmcpy ( &d, l, str_reverse ( de -> d_name ), "/",
                               (const char *) 0 );
              break;
            } }
          closedir ( fde );
        } }
      else {
        char name [1000];
        if ( !( fde =  opendir ( pdir ) ) ) 
          return 0;
        while ( (de =  readdir ( fde )) ) {
          str_mcpy ( name, 1000, pdir, "/", de -> d_name, (const char *) 0 );
          if ( stat ( name, &st ) < 0 ) continue;
          if ( ( s.st_ino == st.st_ino ) && ( s.st_dev == st.st_dev ) ) {
            l -=  str_rmcpy ( &d, l, str_reverse ( de -> d_name ), "/",
                             (const char *) 0 );
            break;
          } }
        closedir ( fde );
      }  
      str_cat ( dir, 1000, "/.." );
      str_cat ( pdir, 1000, "/.." );
      mem_cpy ( &s, &ps, sizeof s );
    }
    if ( d == buff ) return str_cpy ( buff, len, "/" );
    else {
      str_reverse ( buff );
      return len - l;
  } }
  return -1;
}

/**
 * fn_compress compresses a file name.
 * 
 * fn_compress is used to eliminate redundant parts froma pathname. 
 * E.g. /usr/tom/../mail is replaced by /usr/mail.
 * This is only possible if the /../ sections don't point higher (in directory 
 * structure) than the first directory specified. So fn_compress ( ../x ) cannot
 * be compressed, it results in returning the unchanged 'fn'.
 * 
 * @Returns fn
 */
char *fn_compress(char *fn) {
  if ( fn && *fn ) {
    int l =  str_len ( fn ) + 1, was_rescan = 0;
    char *buff =  (char *) calloc ( l, sizeof ( char ) );
    char *p =  fn, *d =  buff;
    if ( !buff ) return fn;
    while ( *p ) {
      if ( *p == '/' ) {
        switch ( *( p + 1 ) ) {
          case '\0' :  
          case '/'  :  p++; continue;
          case '.'  :  {
            switch ( *( p + 2 ) ) {
              case '\0' :
              case '/'  :  p += 2; continue;
              case '.'  :  {
                if ( !*(p + 3) || ( *(p + 3) == '/' ) ) {
                  if ( d == buff ) {
                    if ( was_rescan )
                      if ( *d != '/' ) { p++; continue; }
                    if ( !*( p + 3 ) ) *d++ =  '/';
                  }
                  else {
                    int ld =  (int) ( d - buff ),
                    is_pp =  ( ld >= 2 ) && ( *(d-1) == '.' ) &&
                    ( *(d-2) == '.' ),
                    is_spp =  is_pp && ( ld > 2 ) && ( *(d-3) == '/' );
                    if ( is_spp || ( is_pp && ( ld == 2 ) ) ) break;
                    else {
                      while ( ( d > buff ) && ( *--d != '/' ) );
                      was_rescan ++;
                      if ( !*( p + 3 ) || !*( p + 4 ) ) {
                        if ( d == buff ) {
                          if ( *d == '/' ) { d++; }
                          else { *d++ =  '.'; }
                        }
                        if ( !*( p + 3 ) ) p += 3;
                        else { p += 4; }
                        continue;
                      }
                      else if ( *d != '/' ) {
                        p += 4;
                        continue;
                  } } }
                  p +=  3;
                  continue;
      } } } } } }
      else if ( ( *p == '.' ) && ( *(p + 1) == '/' ) &&
               ( ( d == buff ) || ( *(d-1) != '.' ) ) ) {
        p += 2;
        continue;
      }
      *(d++) =  *(p++);
    }
    if ( d == buff ) {
      if ( *fn == '/' ) *d++ =  '/';
      else *d++ =  '.';
    }
    *d =  '\0';
    str_cpy ( fn, l, buff );
    free ( buff );
  }
  return fn;
}

/**
 * fn_getabs writes an absolute pathname of a given file to 'buff'
 * 
 * @Returns #chars written to 'buff'
 */
int fn_getabs(char *buff, int len, const char *fname) {
  int ret =  -1;
  if ( fname ) {
    if ( *fname == '/' ) str_cpy(buff, len, fname);
    else {
      char dot [257];
      fn_getdir(dot, 256, ".");
      str_mcpy(buff, len, dot, "/", fname, (const char *) 0);
    }
    fn_compress(buff);
    ret =  str_len(buff);
  }
  return ret;
}

/**
 * fn_abs returns an absolute pathname of a given file 'fname'
 * 
 * @Returns allocated pathname
 */
char *fn_abs(const char *fname) {
  char buff [1000];
  if ( fn_getabs ( buff, 1000, fname ) < 0 ) return 0;
  else return str_heap(buff, 0);
}

/**
 * fn_tmpdir returns the pathname of the default directory for storing
 * temporary files.
 *
 * @Returns allocated pathname of temporary directory.
 */
char *fn_tmpdir() {
  const char *dir;
  if (!(dir = getenv("TMPDIR")))
    if (!(dir = getenv("TEMP")))
      if (!(dir = getenv("TMP")))
        dir = "/tmp";
  int l = str_len(dir);
  if ( dir[l-1] == '/' ) l--;
  return str_heap(dir, l);
}

/**
 * fn_tmp is used to return a temporary file name currently
 * not in use.
 *
 * The returned filename looks like:
 *
 *    /tmp/<pid>-<idx>-<str>
 *
 * where <pid> is the process id of the running process and <idx>
 * is a sequential number 0, 1, ...
 *
 * In addition to returning the file name, the file is also created.
 *
 * @Returns allocated filename if file can be created,
 *          0 if file can't be created
 */
char *fn_tmp ( const char *str ) {
  char buff [1024];
  char *tmpdir = fn_tmpdir();
  char *ret = 0;
  pid_t pid =  getpid ();
  for (int i = 0;; i++ ) {
    int fd;
    snprintf ( buff, 1023, "%s/%d-%d-%s", tmpdir, pid, i, str );
    fd =  open ( buff, O_RDWR | O_CREAT | O_EXCL, 0666 );
    if ( fd >= 0 ) {
      close ( fd );
      ret = str_heap ( buff, 0 );
      break;
    }
    else if ( errno != EEXIST ) break;
  }
  return ret;
}

/**
 * fn_linkpath evaluates the relative link path of two files.
 * 
 * This is used when constructing a relative symbolic link, which in most
 * cases is preferable to an absolute symbolic link.
 * Imagine you have a file "/usr/bin/foo" and want to create a symbolic link
 * "/bin/lfoo" to this file, then 'fn_linkpath' may be used to evaluate
 * the relative path from "/bin/lfoo" to "/usr/bin/foo".
 * Eg. fn_linkpath ( buff, len, "/usr/bin/foo", "/bin/lfoo" ) would write
 * "../usr/bin/foo" to 'buff' and hence symlink ( buff, "/bin/lfoo" )
 * would create the desired symbolic link.
 *
 *   @param from: absolute pathname of original file
 *   @param to:   absolute pathname of symbolic link
 * 
 *   @return #chars written to buff
 */
int fn_linkpath(char *buff, int len, const char *from, const char *to) {
  if ( buff && from && to ) {
    char dir_from [256], dir_to [256], fbuff [256], tbuff [256],
    base_from [256];
    char *f =  dir_from, *t =  dir_to, *ptr_f = 0, *ptr_t = 0, *p =  buff;
    int l =  len;
    fn_getabs ( fbuff, 256, from );
    fn_getabs ( tbuff, 256, to );
    fn_dir ( dir_from, 256, fbuff );
    fn_base ( base_from, 256, fbuff );
    fn_dir ( dir_to, 256, tbuff );
    while ( *f && ( *f == *t ) ) {
      if ( *f == '/' ) { ptr_f =  f; ptr_t =  t; }
      f++; t++;
    }
    if ( !*f ) {
      if ( *t )
        if ( *t != '/' ) { f =  ptr_f; t =  ptr_t; }
    }
    else if ( !*t ) {
      if ( *f != '/' ) 
      { f =  ptr_f; t =  ptr_t; }
    }
    else { t =  ptr_t; f =  ptr_f; }
    if ( *f == '/' ) f++;
    while ( *t ) {
      if ( *t == '/' ) l -=  str_rcpy ( &p, l, "../" );
      t++;
    }
    if ( *f ) l -=  str_mcpy ( p, l, f, "/", base_from, (const char *) 0 );
    else l-=  str_cpy ( p, l, base_from );
    return len - l;
  }
  return -1;
}

/**
 *  fn_resolvelink is used to evaluate a link name (if possible) to a
 *  given file 'fn' from a relative pathname 'link'. 'link' is interpreted
 *  relative to 'fn'. The result may be passed to 'symlink' for creating
 *  a symbolic link. Eg. if you want to link the path "/bin/test/foo" to 
 *  the file "/bin/etc/file" relative you have to call:
 *     symlink ( "../etc/file", "/bin/test/foo" )
 *  Ie. the file you want to link to has to be specified relative to the
 *  link to create.
 *  Often it is more convenient to specify the 'link' relative to the file
 *  it points to (eg. link "../test/foo" to "/bin/etc/file").
 *  Hence 'fn_resolvelink' is used to evaluate the pathanme to pass to
 *  'symlink' based on a link name relative to 'fn'.
 *  Ie. fn_resolvelink ( from, flen, to, tlen, "/bin/etc/file", "../test/foo" )
 *  writes "../etc/file" to 'from' and "/bin/test/foo" to 'to'.
 *  
 *  - arguments: 
 *    - from:  buffer to write relative file name to
 *    - flen:  length of 'from' buffer
 *    - to:    buffer to write link path name to
 *    - tlen:  length of 'to' buffer
 *    - fn:    path of file to link to
 *    - link:  relative link path
 */

int fn_resolvelink(char *from, int flen, char *to, int tlen,
                   const char *fn, const char *link) {
  int ret =  -1;
  if ( to && from && fn && link ) {
    if ( *link == '/' ) str_cpy ( to, tlen, link );
    else {
      char dir_fn [256];
      fn_dir ( dir_fn, 256, fn );
      str_mcpy ( to, tlen, dir_fn, "/", link, (const char *) 0 );
    }
    fn_compress ( to );
    if ( ( ret =  fn_linkpath( from, flen, fn, to )) >= 0 ) ret = 0;
  }
  return ret;
}

// MARK: - File operations

/**
 * file_link links an existing path 'from' to a symbolic link 'to'.
 * 
 * Both, 'from' and 'to' must be absolute pathnames. If possible the link
 * created is made relative.
 *
 * @param from: absolute pathname of existing file
 * @param to: absolute pathname of symbolic link to create
 *
 * @return 0: OK,
 *        -1: Error
 */
int file_link(const char *from, const char *to) {
  char buff[1000];
  if ( fn_linkpath(buff, 1000, from, to) > 0 ) {
    return symlink(buff, to);
  }
  return -1;
}

/**
 * file_readlink returns the file a given 'path' links to symbollically.
 *
 * If the given path is not a symbolic link, 0 is returned.
 *
 * @param path: pathname pointing to symbolic link
 *
 * @return 0: path is not a symbolic link,
 *         allocated pathname of file 'path' points to
 */
char *file_readlink(const char *path) {
  char buff[1001];
  int ret = (int)readlink(path, buff, 1000);
  if ( ret < 0 ) return 0;
  buff[ret] = 0;
  return str_heap(buff, 0);
}

/**
 * file_unlink simply uses unlink(2) to remove a file
 * 
 * @param path pathname of file/directory to remove, the directory must be empty
 * @return 0 => OK, -1 => Error 
 */
int file_unlink(const char *path) {
  stat_t tmp;
  if ( stat_readlink(&tmp, path) != 0 ) return -1;
  if ( stat_isdir(&tmp) ) return rmdir(path);
  else return unlink(path);
}

/**
 * file_trymove tries to move a file via link/unlink.
 *
 * If the file 'src' cannot be linked to 'dest' (ie. the given pathes are not
 * on the same filesystem) 1 is returned. This function fails if 'dest' is
 * already existing.
 *
 * @param src: source file to move
 * @param dest: destination path (ehere to move to)
 *
 * @return 0: OK (file has been moved)
 * @return 1: file can't be linked,
 *        -1: Error
 */
int file_trymove( const char *src, const char *dest) {
  if ( link(src, dest) != 0 ) {
    if ( errno == EXDEV ) return 1;
    else return -1;
  }
  return unlink(src);
}

/**
 * file_copy copies the contents of file 'src' to file 'dest'.
 *
 * If 'dest' is already existing this function will fail.
 *
 * @param src: source file to copy
 * @param dest: destination path (where to copy to)
 *
 * @return >=0: #bytes copied,
 *         Error otherwise
 */
long file_copy(const char *src, const char *dest) {
  stat_t tmp;
  if ( (stat_readlink(&tmp, src) != 0) ||
       !stat_isfile(&tmp) ||
       (stat_readlink(&tmp, dest) == 0)
     ) return -1;
  mapfile_t msrc(src), mdest(dest);
  if ( msrc.ok() && mdest.ok() ) {
    mdest.resize(msrc.size());
    mem_cpy(mdest.data(), msrc.data(), msrc.size());
    return msrc.size();
  }
  return -1;
}

/**
 * file_move moves the file 'src' to a new place at 'dest'.
 *
 * This function fails if 'dest' exists. If 'dest' resides on a different
 * file system, 'src' is copied to 'dest' and then removed.
 *
 * @param src: source file to move
 * @param dest: destination path (where to move to)
 *
 * @return 0: OK (file moved),
 *            #bytes copied (different filesystems),
 *            Error otherwise
 */
long file_move(const char *src, const char *dest) {
  long ret = file_trymove(src, dest);
  if (ret != 0) {
    if ( ret == 1 ) {
      if ( (ret = file_copy(src, dest)) >= 0 ) {
        unlink(src);
        return ret;
  } } }
  else return 0;
  return -1;
}

/// Open a file pointer and write it to *fp
int file_open(fileptr_t *rfp, const char *path, const char *mode) {
  fileptr_t tmp = fopen(path, mode);
  if (tmp) { *rfp = tmp; return 0; }
  return -1;
}

/// Close the file pointer
int file_close(fileptr_t *fp) {
  int ret = fclose(*fp);
  *fp = 0;
  return ret;
}

/// Reads one line of data and returns the allocated result, trailing \n, \r
/// are removed.
char *file_readline(fileptr_t fp) {
  char buff[2001];
  if (fgets(buff, 2000, fp)) {
    char *p = buff;
    int l = str_len(buff);
    if (l > 0) {
      p += l-1;
      while (*p == '\n' || *p == '\r') p--;
      *(p+1) = '\0';
    }
    return str_heap(buff, 0);
  }
  else return 0;
}

/**
 * Writes one line to the file pointer (a missing \\n is appended)
 *
 * @param fp: file pointer to write to
 * @param str: string to write to 'fp'
 *
 * @return >=0 the number of bytes written,
 *         -1 Error
 */
int file_writeline(fileptr_t fp, const char *str) {
  if ( fputs(str, fp) >= 0 ) {
    int l = str_len(str);
    if (str[l-1] != '\n') { fputc('\n', fp); l++; }
    return l;
  }
  return -1;
}

/// file_read reads a buffer full of data from the passed file pointer
int file_read(fileptr_t fp, void *buff, int nbytes) {
  size_t ret = fread(buff, 1, (size_t) nbytes, fp);
  return (int) ret;
}

/// file_write writes a given buffer to the passed file pointer
int file_write(fileptr_t fp, const void *buff, int nbytes) {
  size_t ret = fwrite(buff, 1, (size_t) nbytes, fp);
  return (int) ret;
}

/// Flushes input/output buffers
int file_flush(fileptr_t fp) { return fflush(fp); }

/**
 * dir_content returns an array of file names
 *
 * @param dir pathname of directory
 * @return array of file names, 0 if error
 */
char **dir_content(const char *dir) {
  DIR *d = opendir(dir);
  if (d) {
    int n = 0;
    struct dirent *de;
    while ((de = readdir(d))) {
      if (str_cmp(de->d_name, ".") != 0 && str_cmp(de->d_name, "..") != 0) n++;
    }
    char **ret = av_alloc(n + 1);
    char **ap = ret;
    rewinddir(d);
    while ((de = readdir(d))) {
      if (str_cmp(de->d_name, ".") != 0 && str_cmp(de->d_name, "..") != 0) {
        *(ap++) = str_heap(de->d_name, 0);
      }
    }
    *ap = 0;
    return ret;
  }
  else return 0;
}

/**
 * dir_remove removes a directory and all contents below
 *
 * @param dir pathname of directory
 * @return 0 => OK, Error else
 */
int dir_remove(const char *dir) {
  DIR *d = opendir(dir);
  if (d) {
    struct dirent *de;
    while ((de = readdir(d))) {
      if (str_cmp(de->d_name, ".") != 0 && str_cmp(de->d_name, "..") != 0) {
        stat_t tmp;
        char path[1025];
        fn_mkpathname(path, 1024, dir, de->d_name);
        if ( stat_readlink(&tmp, path) ) {
          perror(path);
          continue;
        }
        if ( stat_isdir(&tmp) ) dir_remove(path);
        else file_unlink(path);
      }
    }
    return file_unlink(dir);
  }
  else return -1;
}

