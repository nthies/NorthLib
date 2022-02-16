/*
 *  mapfile.h
 *
 *    offers a class for handling of memory mapped files
 */


#ifndef __mapfile_h
#define __mapfile_h

#ifdef __cplusplus

#define MF_OPENED	1	// mf_fd has been opened in class
#define MF_READ		2	// read acces to mf_fd
#define MF_WRITE	4	// write acces to mf_fd
#define MF_NOFILE	8	// mapped object is not a plain file
#define MF_TMP		16	// temporary object

class mapfile_t {
  private: 
    unsigned       mf_flags;
    int            mf_fd;	// file descriptor of mapped file
    void          *mf_data;	// pointer to file contents
    unsigned long  mf_len;	// length of mapped section
    char          *mf_tmpfn;	// name of temporary file
    void init ( void );
  public:
    int unmap ( void );
    int map ( int fd, unsigned long len = 0 );
    int map ( const char *fn, const char *mode = "rw", unsigned long len = 0 );
    int remap ( unsigned long len = (unsigned long) -1 );
    int maptmp ( void );
    int sync ( int is_wait = 1 );
    mapfile_t ( const char *fn ) { init (); map ( fn ); }
    mapfile_t ( void ) { init (); }
    ~mapfile_t () { unmap (); }
    int ok ( void ) const;
    int resize ( unsigned long newsize );
    long read ( int fd, unsigned long nbytes = (unsigned long) -1,
                unsigned long off = 0 );
    void *data ( unsigned long idx = 0 );
    unsigned long size ( void ) const { return mf_len; }
    const char *fntmp ( void ) const { return mf_tmpfn; }
    int fd ( void ) const { return mf_fd; }
};

#endif /* __cplusplus */

#endif /* __mapfile_h */
