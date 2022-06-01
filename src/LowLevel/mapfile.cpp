/*
 *  mapfile.cc
 *
 *    offers a class for handling of memory mapped files
 */

#include  <stdio.h>
#include  <stdlib.h>
#include  <unistd.h>
#include  <fcntl.h>
#include  <sys/types.h>
#include  <sys/stat.h>
#include  <sys/mman.h>
#include  "sysdef.h"
#include  "strext.h"
#include  "fileop.h"
#include  "mapfile.h"

#ifdef MMAPPTR_T
  typedef MMAPPTR_T mmapptr_t;
#else
  typedef void *mmapptr_t;
#endif

#define AError		((mmapptr_t) (-1))
#define AValid( d )	( ((d) == AError)? 0 : 1 )
#define AInValid( d )	( ((d) == AError)? 1 : 0 )
#define DefaultMapSize	(1024 * 1024)


/*
 *  mapfile_t methods:
 */

int mapfile_t:: ok ( void ) const { return (mf_fd < 0)? 0 : 1; }

void *mapfile_t:: data ( unsigned long idx ) {
  return AValid ( mf_data )? (void *) ( ( (char *) mf_data ) + idx ) : 0;
}

void mapfile_t:: init ( void ) { 
  mf_flags =  0;
  mf_len =  0;
  mf_data =  AError;
  mf_fd =  -1;
  mf_tmpfn =  0;
}

int mapfile_t:: unmap ( void ) {
  if ( AValid ( mf_data ) ) munmap ( (mmapptr_t) mf_data, mf_len );
  if ( mf_flags & MF_OPENED ) ::close ( mf_fd );
  if ( mf_flags & MF_TMP ) {
    ::unlink ( mf_tmpfn );
    free ( mf_tmpfn );
  }
  init ();
  return 0;
}

int mapfile_t:: remap ( unsigned long len ) {
  mmapptr_t ptr =  AError;
  int prot =  0;
  if ( len == (unsigned long) -1 ) {
    struct stat st;
    if ( !fstat ( mf_fd, &st ) && stat_isfile ( &st ) )
      len =  (unsigned long) ( st.st_size );
    else return -1;
  }   
  if ( mf_flags & MF_READ ) prot |=  PROT_READ;
  if ( mf_flags & MF_WRITE ) prot |=  PROT_WRITE;
  if ( !len || 
       ( ptr =  (mmapptr_t) mmap ( 0, len, prot, MAP_SHARED, mf_fd, 0 ) )
         != AError ) {
    if ( AValid ( mf_data ) ) munmap ( (mmapptr_t) mf_data, mf_len );
    mf_len =  len;
    mf_data =  (void *) ptr;
    return 0;
  }
  return -1;
}

/*
 *  map:
 *  if no size is given, the current length of the file is used
 */

int mapfile_t:: map ( int fd, unsigned long size ) { 
  int ofl =  fcntl ( fd, F_GETFL );
  if ( ofl != -1 ) {
    struct stat st;
    unsigned long len =  size;
    if ( !fstat ( fd, &st ) ) {
      int mfl =  0;
      if ( stat_isfile ( &st ) ) len =  (unsigned long) ( st.st_size );
      else mfl |=  MF_NOFILE;
      if ( size && ( size > len ) ) {
	if ( ftruncate ( fd, size ) ) return -1;
	len =  size;
      }
      mfl |=  MF_READ;
      if ( ofl & ( O_WRONLY | O_RDWR ) ) mfl |=  MF_WRITE;
      if ( AValid ( mf_data ) ) unmap ();
      mf_fd =  fd;
      mf_flags =  mfl;
      return remap ( len );
  } }
  return -1;
}

/*
 *  map open modes:
 *    "r" :  open and map for read access
 *    "w" :  open and map for write access
 *  both modes can be combined (eg: "rw")
 */

int mapfile_t:: map ( const char *fn, const char *mode, unsigned long len ) { 
  if ( fn && *fn ) {
    int omode =  0, ofl;
    if ( !str_cmp ( fn, "-" ) ) {
      if ( !maptmp () )
        return (read ( 0 ) < 0)? -1 : 0;
      else return -1;
    }
    while ( *mode ) switch ( *mode++ ) {
      case 'r' :  omode |=  MF_READ; break;
      case 'w' :  omode |=  MF_WRITE; break;
    }
    if ( !omode ) omode =  MF_READ | MF_WRITE;
    if ( omode & MF_READ ) 
      if ( omode & MF_WRITE ) ofl =  O_RDWR;
      else ofl =  O_RDONLY;
    else ofl =  O_WRONLY;
    if (omode & MF_WRITE) ofl |=  O_CREAT;
    int fd =  open ( fn, ofl, 0666 );
    if ( fd >= 0 ) {
      if ( !map ( fd, len ) ) {
        mf_flags |=  MF_OPENED;
	return 0;
      }
      else close ( fd );
  } }
  return -1;
}

int mapfile_t:: maptmp ( void ) {
  if ( !mf_tmpfn ) {
    if ( (mf_tmpfn =  fn_tmp ( "tmp.map" )) ) {
      if ( !map ( mf_tmpfn ) ) {
	mf_flags |=  MF_TMP;
	return 0;
      }
      free ( mf_tmpfn );
      mf_tmpfn =  0;
  } }
  return -1;
}

int mapfile_t:: sync ( int is_wait ) {
  return msync ( (mmapptr_t) mf_data, mf_len, is_wait? MS_SYNC : MS_ASYNC );
}

int mapfile_t:: resize ( unsigned long newsize ) {
  if ( ok () ) {
    if ( ( mf_flags & MF_NOFILE ) || !ftruncate ( mf_fd, newsize ) )
      return remap ( newsize );
  }
  return -1;
}

long mapfile_t:: read ( int fd, unsigned long nbytes, unsigned long off ) {
  unsigned long n =  nbytes, pos =  off;
  long ret;
  int resized = 0;
  if ( nbytes == (unsigned long) -1 ) n =  8*1024;
  while ( n > 0 ) {
    if ( (pos + n) > mf_len ) {
      if ( resize ( pos + n ) ) return -1;
      else resized++;
    }
    ret =  ::read ( fd, data ( pos ), n );
    if ( ret > 0 ) {
      pos +=  ret;
      if ( nbytes != (unsigned long) -1 ) n -=  ret;
    }
    else break;
  }
  if ( resized ) resize ( pos );
  if ( ret < 0 ) return -1;
  return pos - off;
}


#ifdef dCfgVerify

#include  <unistd.h>
#include  <rsn/sysdef.h>
#include  <rsn/verify.h>

const char test_data [] =  "this is a test";
const char *fn  =  "./test.map",
           *fn2 =  "./test2.map";


vrf_start ( "mapfile_t: memory mapped file operations" )
  mapfile_t m1, m2;
  char buff [1024];
  int ret;
  vrf_item ( ret =  m1.map ( fn ) );
  vrf_verify ( ret == 0 );
  vrf_item ( ret =  m1.resize ( 1000 ) );
  vrf_verify ( (ret == 0) && (m1.size () == 1000) );
  vrf_item ( ret =  m2.map ( fn ) );
  vrf_verify ( (ret == 0) && (m2.size () == 1000) );
  vrf_item ( ( mem_cpy ( m1.data ( 10 ), test_data, sizeof test_data ),
               mem_cpy ( buff, m2.data ( 10 ), sizeof test_data ) ) );
  vrf_verify ( !str_cmp ( test_data, buff ) );
  vrf_item ( ret =  m2.resize ( 20000 ) );
  vrf_verify ( (ret == 0) && (m2.size () == 20000) );
  vrf_item ( mem_cpy ( buff, m2.data ( 10 ), sizeof test_data ) );
  vrf_verify ( !str_cmp ( test_data, buff ) );
  m1.unmap (); 
  m2.unmap ();
  mapfile_t m3 ( fn );
  vrf_verify ( m3.ok () );
  vrf_item ( mem_cpy ( buff, m3.data ( 10 ), sizeof test_data ) );
  vrf_verify ( !str_cmp ( test_data, buff ) );
  m3.sync ();
  mapfile_t m4;
  vrf_item ( ret =  m4.map ( fn2 ) );
  vrf_verify ( ret == 0 );
  vrf_verify ( m4.ok () );
  vrf_item ( m4.read ( m3.fd () ) );
  vrf_item ( mem_cpy ( buff, m4.data ( 10 ), sizeof test_data ) );
  vrf_verify ( !str_cmp ( test_data, buff ) );
  lseek ( m3.fd (), 0, SEEK_SET );
  vrf_item ( m4.read ( m3.fd (), (unsigned long) -1, 2000 ) );
  vrf_item ( mem_cpy ( buff, m4.data ( 2010 ), sizeof test_data ) );
  vrf_verify ( !str_cmp ( test_data, buff ) );
  vrf_item ( mem_cpy ( buff, m4.data ( 10 ), sizeof test_data ) );
  vrf_verify ( !str_cmp ( test_data, buff ) );
  m3.unmap ();
  m4.unmap ();
  mapfile_t m5;
  vrf_item ( ret =  m5.map ( fn ) );
  vrf_verify ( ret == 0 );
  vrf_verify ( m5.ok () );
  vrf_item ( ret =  m5.resize ( 1000 ) );
  vrf_verify ( (ret == 0) && (m5.size () == 1000) );
  char cmd [512];
  snprintf ( cmd, 511, "echo 0123 > %s", fn );
  system ( cmd );
  vrf_item ( m5.remap () );
  vrf_verify ( m5.size () == 5 );
  vrf_item ( mem_cpy ( buff, m5.data ( 0 ), 4 ) );
  vrf_verify ( !str_ncmp ( "0123", buff, 4 ) );
  unlink ( fn );
  unlink ( fn2 );
vrf_end ( vrf.errors () )

#endif /* dCfgVerify */
