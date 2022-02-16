/*
 * A simple string buffer class
 */

#include  <stdarg.h>
#include  <stdlib.h>
#include  "strext.h"


/*
 *  The String Buffer class:
 *  The class _strbuff_t is used for storing the 'real' data, when 
 *  assigning one strbuff_t object to another only the pointer to 
 *  the _strbuff_t structure is copied and the refcount incremented.
 *  When changing an strbuff_t object, the underling _strbuff_t class
 *  is cloned if refcount > 1.
 */

#define sb_is_fixed_c	1
#define sb_is_static_c	2

class _strbuff_t {
  friend class strbuff_t;
  private:
    char     *b_buffer;         // the actual buffer
    int       b_size;           // buffer size - 1 (without zero byte)
    int       b_pos;            // actual read/write position
    int       b_len;            // #chars written to buffer (without zero byte)
    unsigned short b_refcount;  // nb. of objects referencing this class
    unsigned short b_flags;     // nb. of objects referencing this class
    void destruct ( void );
  public:
    _strbuff_t ( void );
    ~_strbuff_t ( void ) { destruct (); }
    int ok ( void ) const { return b_buffer? 1 : 0; }
    int is_fixed ( void ) const { return ( b_flags & sb_is_fixed_c )? 1 : 0; }
    int is_static ( void ) const { return ( b_flags & sb_is_static_c )? 1 : 0; }
    int position ( int newpos = -1 );
    int size ( int newsize = -1 );
    int length ( void ) const { return b_len; }
    int reserve ( int nbytes ) 
      { return (nbytes <= b_size)? b_size : size ( nbytes + nbytes/2 ); }
    int reserve_at_pos ( int nbytes ) { return reserve ( nbytes + b_pos ); }
    void setstatic ( char *buff, int len );
    int put ( const char *str, int len = -1, int isupdate = 0 );
    int put ( char ch, int n = 1, int isupdate = 0 );
    void truncate ( void ) { ok () && ( b_buffer [b_len=b_pos] = '\0' ); }
    void fix ( int dofix = 1 )  {
     if ( dofix ) b_flags |= sb_is_fixed_c;
     else if ( !is_static () ) b_flags &= ~sb_is_fixed_c;
    }
    _strbuff_t *clone ( void );
};

void _strbuff_t:: destruct ( void ) {
  if ( !is_static () && b_buffer ) free ( b_buffer );
  b_buffer =  0;
  b_size = b_pos = b_len = b_flags =  0;
}

int _strbuff_t:: position ( int newpos ) {
  if ( newpos >= 0 ) b_pos =  min ( b_len, newpos );
  return b_pos;
}

int _strbuff_t:: size ( int newsize ) {
  char *newbuff;
  if ( newsize < 0 ) return b_size;
  if ( !newsize ) { destruct (); return 0; }
  if ( !is_fixed () ) {
    if ( b_buffer ) newbuff =  (char *) realloc ( b_buffer, newsize + 1 );
    else newbuff =  (char *) malloc ( newsize + 1 );
    if ( newbuff ) {
      b_buffer =  newbuff;
      b_size =  newsize;
      b_buffer [newsize] =  '\0';
      b_len =  min ( b_len, newsize );
      b_pos =  min ( b_pos, b_len );
      return newsize;
  } }
  return -1;
}

void _strbuff_t:: setstatic ( char *buff, int len ) {
  if ( buff && ( len > 0 ) ) {
    destruct ();
    b_buffer =  buff;
    b_size =  len - 1;
    b_flags =  sb_is_fixed_c | sb_is_static_c;
    *b_buffer =  '\0';
    b_buffer [b_size] =  '\0';
} }

int _strbuff_t:: put ( const char *str, int len, int isupdate ) {
  if ( str && len ) {
    if ( len < 0 ) len =  str_len ( str );
    if ( reserve_at_pos ( len ) > 0 ) {
      mem_cpy ( b_buffer + b_pos, str, len );
      if ( b_len < ( b_pos + len ) ) {
        b_len =  b_pos + len;
	b_buffer [ b_len ] =  '\0';
      }
      if ( isupdate ) b_pos += len;
      return len;
  } }
  return -1;
}

int _strbuff_t:: put ( char ch, int len, int isupdate ) {
  if ( len > 0 ) {
    if ( reserve_at_pos ( len ) > 0 ) {
      register char *p =  b_buffer + b_pos;
      register int n =  len;
      while ( n-- ) *p++ =  ch;
      if ( b_len < ( b_pos + len ) ) {
        b_len =  b_pos + len;
	b_buffer [ b_len ] =  '\0';
      }
      if ( isupdate ) b_pos += len;
      return len;
  } }
  return -1;
}

_strbuff_t:: _strbuff_t ( void ) {
  b_buffer =  0;
  b_size =  b_pos =  b_len =  b_flags =  0;
  b_refcount =  1;
}

_strbuff_t *_strbuff_t:: clone ( void ) {
  _strbuff_t *sb =  new _strbuff_t;
  if ( sb ) {
    sb -> put ( b_buffer, b_size );
    sb -> b_pos =  b_pos;
  }
  return sb;
}


/*
 *  PRIVATE  void strbuff_t:: chkwrite ( void )
 *           ==================================
 *
 *  'chkwrite' is used to check whether the _strbuff_t structure is
 *  referenced by more than one object. If so (for write purposes)
 *  the buffer is duplicated.
 */

void *strbuff_t:: chkwrite ( void ) {
  if ( ok () ) {
    _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
    if ( bp -> b_refcount > 1 ) {
      _strbuff_t *sb =  bp -> clone ();
      if ( sb ) {
	bp -> b_refcount--;
	return sb_buffer =  sb;
    } }
    else return bp;
  }
  return 0;
}


/*
 *  PRIVATE  void strbuff_t:: destruct ( void )
 *           ==================================
 *
 *  'destruct' is used to remove an _strbuff_t object if the refcount = 1.
 */

void strbuff_t:: destruct ( void ) {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp -> b_refcount == 1 ) delete bp;
  else bp -> b_refcount--;
  sb_buffer =  0;
}


/*
 *  PRIVATE  void strbuff_t:: setbuff ( void *sb )
 *           =====================================
 *
 *           _strbuff_t *sb :  buffer to assign;
 *
 *  'setbuff' is used to set the buffer field to the passed structure pointer.
 *  The refcount of 'sb' is incremented.
 */

void strbuff_t:: setbuff ( void *ptr ) {
  _strbuff_t *bp =  (_strbuff_t *) ptr;
  if ( sb_buffer ) destruct ();
  bp -> b_refcount++;
  sb_buffer =  bp;
}


/*
 *  PUBLIC  int strbuff_t:: put ( const char *str, int len = -1 )
 *          =====================================================
 *
 *          const char *str :  string to copy to buffer;
 *          int len         :  #chars to copy (until zero-byte by default);
 *          VALUE           :  #chars copied;
 *
 *  'put' is used to write a string (or part of it) to the current position
 *  in the buffer (without writing a zero byte after 'str'). The read/write
 *  pointer of the buffer remains unchanged.
 */

int strbuff_t:: put ( const char *str, int len ) {
  _strbuff_t *bp =  (_strbuff_t *) chkwrite ();
  if ( bp ) return bp -> put ( str, len );
  else return -1;
}


/*
 *  PUBLIC  int strbuff_t:: put ( char ch, int nchars = 1 )
 *          ===============================================
 *
 *          char ch    :  character to write to buffer;
 *          int nchars :  number of times to write 'ch';
 *          VALUE      :  #chars written;
 *
 *  'put' is used to copy a character to the current position
 *  in the buffer (without writing a zero byte after it).
 *  The read/write pointer of the buffer remains unchanged.
 */

int strbuff_t:: put ( char ch, int nchar ) {
  _strbuff_t *bp =  (_strbuff_t *) chkwrite ();
  if ( bp ) return bp -> put ( ch, nchar );
  else return -1;
}


/*
 *  PUBLIC  int strbuff_t:: raw_write ( const void *ptr, int len )
 *          ======================================================
 *
 *          const void *ptr :  pointer to data to write to buffer;
 *          int len         :  #bytes to write;
 *          VALUE           :  #bytes written;
 *
 *  'write' is used to copy a memory area to the buffer. In addition 
 *  to the data a zero byte is written after the data. The read/write
 *  pointer of the buffer points to the trailing zero byte.
 */

int strbuff_t:: raw_write ( const void *ptr, int len ) {
  _strbuff_t *bp =  (_strbuff_t *) chkwrite ();
  if ( bp ) {
    int ret =  bp -> put ( (const char *) ptr, len, 1 );
    if ( ret >= 0 ) truncate ();
    return ret;
  }
  else return -1;
}


/*
 *  PUBLIC  int strbuff_t:: raw_write ( char ch, int nchar )
 *          ================================================
 *
 *          char ch    :  character to write to buffer;
 *          int nchars :  number of times to write 'ch';
 *          VALUE      :  #chars written;
 *
 *  'write' is used to copy a character to the current position
 *  in the buffer followed by a zero byte.
 *  The read/write pointer of the buffer is set to the trailing zero byte.
 */

int strbuff_t:: raw_write ( char ch, int nchar ) {
  _strbuff_t *bp =  (_strbuff_t *) chkwrite ();
  if ( bp ) {
    int ret =  bp -> put ( ch, nchar, 1 );
    if ( ret >= 0 ) truncate ();
    return ret;
  }
  else return -1;
}


/*
 *  PUBLIC  int strbuff_t:: raw_read ( void *ptr, int len )
 *          ===============================================
 *
 *          void *ptr :  buffer to read into;
 *          int len   :  #bytes to read;
 *          VALIE     :  #bytes written to 'buff';
 *
 *  'read' reads the next 'len' bytes from the read/write pointer.
 */

int strbuff_t:: raw_read ( void *ptr, int len ) {
  if ( ptr && ok () && (len > 0) ) {
    _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
    if ( bp -> ok () ) {
      int l =  bp -> b_len - bp -> b_pos;
      if ( len < l ) l =  len;
      mem_cpy ( ptr, bp -> b_buffer + bp -> b_pos, l );
      bp -> b_pos +=  l;
      return l;
  } }
  return -1;
}


/*
 *  PUBLIC  int strbuff_t:: getch ( void ) {
 *          ==================================
 *
 *          VALUE :  next char from buffer
 *                   or -1 for end of string indication;
 *
 *  'getch' returns the next character from the buffer.
 */

int strbuff_t:: getch ( void ) {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && ( bp -> b_pos < bp -> b_len ) )
    return bp -> b_buffer [ bp -> b_pos++ ];
  return -1;
}


/*
 *  PUBLIC  int strbuff_t:: ungetch ( char ch )
 *          =====================================
 *
 *          char ch :  character to put back to buffer;
 *
 *  'ungetch' puts the given character back to the buffer while
 *  decrementing the read/write pointer.
 */

int strbuff_t:: ungetch ( char ch ) {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && ( bp -> b_pos > 0 ) )
    return bp -> b_buffer [ --(bp -> b_pos) ] =  ch;
  return -1;
}


/*
 *  PUBLIC  void truncate ( void )
 *          ======================
 *
 *  'truncate' truncates the string in the buffer at the current
 *  read/write position.
 */

void strbuff_t:: truncate ( void ) {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && bp -> ok () ) bp -> truncate ();
}


/*
 *  PUBLIC  int length ( void )
 *          ===================
 *
 *          VALUE :  length of string in buffer;
 *
 *  'length' returns the actual length of the string in the buffer.
 */

int strbuff_t:: length ( void ) const {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && bp -> ok () ) return bp -> length ();
}


/*
 *  PUBLIC  int refcount ( void ) const
 *          ===========================
 *
 *          VALUE :  #references to this buffer;
 *
 *  'refcount' returns the number of references to this buffer (ie. the
 *  underlying _strbuff -class.
 */

int strbuff_t:: refcount ( void ) const {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && bp -> ok () ) return bp -> b_refcount;
}


/*
 *  PUBLIC  int size ( int newsize = -1 )
 *          =============================
 *
 *          int newsize :  specifies the new size of the buffer;
 *          VALUE       :  current size of buffer;
 *
 *  'size' either returns the current buffer size (default argument)
 *  or resizes the buffer to 'newsize' bytes.
 */

int strbuff_t:: size ( int newsize ) {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && bp -> ok () ) return bp -> size ( newsize );
}


/*
 *  PUBLIC  int position ( int newpos = -1 )
 *          ================================
 *
 *          int newpos :  specifies the new read/write position;
 *          VALUE      :  current position;
 *
 *  'position' either returns the current read/write position
 *  (default argument) or sets the read/write pointer to 'newpos'.
 */

int strbuff_t:: position ( int newpos ) {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && bp -> ok () ) return bp -> position ( newpos );
}


/*
 *  PUBLIC  int is_fixed ( void )
 *          =====================
 *
 *          VALUE :  1 ==> size of buffer is fixed;
 *                   0 otherwise;
 *
 *  'is_fixed' checks whether a buffer is fixed in size.
 */

int strbuff_t:: is_fixed ( void ) const {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && bp -> ok () ) return bp -> is_fixed ();
}


/*
 *  PUBLIC  int is_static ( void )
 *          ======================
 *
 *          VALUE :  1 ==> buffer is static,
 *                   0 otherwise;
 *
 *  'is_static' checks whether a buffer is static (not dynamically
 *  allocated).
 */

int strbuff_t:: is_static ( void ) const {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && bp -> ok () ) return bp -> is_static ();
}


/*
 *  PUBLIC  void fix ( int dofix = 1 )
 *          ==========================
 *
 *          int dofix :  fix/unfix buffer size;
 *
 *  'fix' is used to fix a buffer in size (or not).
 */

void strbuff_t:: fix ( int dofix ) {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && bp -> ok () ) return bp -> fix ( dofix );
}


/*
 *  PUBLIC  const char *strbuff_t:: value ( int atpos = 0 )
 *          ===============================================
 *
 *          int atpos :  from start of buffer or from the current position?;
 *          VALUE     :  contents of buffer;
 *
 *  'value' is used to return the contents of the buffer (either from the
 *  start (atpos == 0) or from the current read/write position).
 */

const char *strbuff_t:: value ( int atpos ) const {
  _strbuff_t *bp =  (_strbuff_t *) sb_buffer;
  if ( bp && bp -> ok () ) 
    return bp -> b_buffer + ( atpos? bp -> b_pos : 0 );
}
  

/*
 *  PUBLIC  strbuff_t:: strbuff_t ( int len = strb_size_c )
 *          ===============================================
 *
 *          int len :  initial size of buffer;
 *
 *  This constructor is used to allocate an empty _strbuff_t structure
 *  for further operations. 'len' is used as initial buffer size.
 */

strbuff_t:: strbuff_t ( int len ) : buffer_t () {
  _strbuff_t *bp =  new _strbuff_t;
  if ( bp ) bp -> size ( len );
  sb_buffer =  bp;
}


/*
 *  PUBLIC  strbuff_t:: strbuff_t ( char *buff, int len )
 *          =============================================
 *
 *          char *buff :  where to write the data to;
 *          int len    :  length of buffer;
 *
 *  This constructor is used to initialize the object with a fixed sized
 *  string buffer which must be able to hold len bytes.
 *  There are no more than 'len' characters (incl.  terminating zero byte)
 *  written to 'buff'.
 */

strbuff_t:: strbuff_t ( char *buff, int len ) : buffer_t () {
  _strbuff_t *bp =  new _strbuff_t;
  if ( bp ) bp -> setstatic ( buff, len );
  sb_buffer =  bp;
}


/*
 *  PROTECTED  int strbuff_t:: copy ( const char *str, int len = -1 )
 *             =======================================================
 *
 *             const char *str :  string to copy;
 *             int len         :  length of 'str';
 *             VALUE           :  >= 0 ==> nb. of bytes copied,
 *                               -1 ==> Error detected;
 *
 *  'copy' is used to copy the passed string of length 'len' to 
 *  the string buffer. This is extended automatically if necessary.
 *  If the buffer is defined as static or fixed, there may be not enough
 *  space for copying the complete string 'str'. For this reason the
 *  return value (ie. the number of bytes copied) should be checked.
 *  If len = -1, 'str' is assumed to be terminated by a zero byte
 *  and 'len' is calculated as the length of 'str'.
 *  When specifying 'len' 'str' may contain zero bytes to copy to
 *  the string buffer. There are no specific checks for zero bytes.
 *  The read/write pointer is positioned to the first char in the buffer
 *  after copying and a previously available string is truncated.
 */

int strbuff_t:: copy ( const char *str, int len ) {
  int ret =  write ( str, len );
  if ( ret >= 0 ) position ( 0 );
  return ret;
}


/*
 *  PROTECTED  int strbuff_t:: cat ( const char *str, int len = -1 )
 *             ======================================================
 *
 *             const char *str :  string to concatenate;
 *             int len         :  length of 'str';
 *             VALUE           :  >= 0 ==> nb. of bytes copied,
 *                               -1 ==> Error detected;
 *
 *  'cat' is used to concatenate the passed string of length 'len' to 
 *  the string buffer. This is extended automatically if necessary.
 *  If the buffer is defined as static or fixed, there may be not enough
 *  space for copying the complete string 'str'. For this reason the
 *  return value (ie. the number of bytes copied) should be checked.
 *  If len = -1, 'str' is assumed to be terminated by a zero byte
 *  and 'len' is calculated as the length of 'str'.
 *  When specifying 'len' 'str' may contain zero bytes to copy to
 *  the string buffer. There are no specific checks for zero bytes.
 *  The read/write pointer is positioned to the first char in the buffer.
 */

int strbuff_t:: cat ( const char *str, int len ) {
  int ret =  -1;
  if ( ok () ) {
    position ( length () );
    if ( ( ret =  write ( str, len ) ) >= 0 ) position ( 0 );
  }
  return ret;
}


/*
 *  PUBLIC  strbuff_t &strbuff_t:: operator = ( const strbuff_t &sb )
 *          ============================================================
 *
 *          const strbuff_t &sb :  string buffer to assign;
 *          VALUE                :  *this;
 *
 *  This operator is used to assign the passed strbuff_t object to this.
 *  If there is already data stored in 'this' it is removed (and the
 *  original buffer is released if not static).
 *  Initial the buffer is referenced by both objects. When the first object
 *  is willing to change the buffer, it is duplicated; so identical strings
 *  are stored only once.
 */

strbuff_t &strbuff_t:: operator = ( const strbuff_t &sb ) {
  if ( ok () && sb.ok () ) setbuff ( sb.sb_buffer );
  return *this;
}


/*
 *  PUBLIC  strbuff_t:: strbuff_t ( const strbuff_t &sb )
 *          ================================================
 *
 *          const strbuff_t &sb :  string buffer to use for initilization;
 *
 *  This constructor initializes a new created object using the passed 
 *  strbuff_t object 'sb'. The resulting object contains initial (until
 *  next change operation) a reference to 'sb's buffer.
 */

strbuff_t:: strbuff_t ( const strbuff_t &sb ) : buffer_t () {
  sb_buffer =  0;
  if ( sb.ok () ) setbuff ( sb.sb_buffer );
}


/*
 *  PUBLIC  strbuff_t:: strbuff_t ( const char *str )
 *          ===========================================
 *
 *          const char *str :  string to use for initilization;
 *
 *  This constructor initializes a new created object using the passed 
 *  string 'str'. The resulting object is always constructed
 *  dynamic (ie. it may grow).
 */

strbuff_t:: strbuff_t ( const char *str ) : buffer_t () {
  _strbuff_t *bp =  new _strbuff_t;
  if ( bp ) copy ( str );
}


/*
 *  PUBLIC  strbuff_t &strbuff_t:: operator += ( const strbuff_t &sb )
 *          ==========================================================
 *
 *          const strbuff_t &sb :  string buffer to append;
 *          VALUE               :  *this;
 *
 *  This operator is used to append the contents of 'sb' to 'this'. Ie.
 *  after performing '+=' 'this' is appended by sb.buffer if there is
 *  enough space left.
 */

strbuff_t &strbuff_t:: operator += ( const strbuff_t &sb ) {
  if ( ok () && sb.ok () ) 
    cat ( sb.value (), sb.length () );
  return *this;
}


/*
 *  PUBLIC  char *strbuff_t:: heap ( void )
 *          ===============================
 *
 *          VALUE      :  allocated string;
 *                        0 ==> Error detected;
 *
 *  'heap' is used to allocate a new string and to copy the complete buffer
 *  contents into it. The string is terminated by a zero byte.
 */

char *strbuff_t:: heap ( void ) {
  if ( ok () ) {
    int len =  length ();
    char *result =  (char *) malloc ( ( len + 1 ) * sizeof ( char ) );
    if ( result ) {
      mem_cpy ( result, value (), len + 1 );
      return result;
  } }
  return 0;
}


#ifdef dCfgVerify

#include  <rsn/verify.h>

void sb_print ( strbuff_t &sb, const char *name ) {
  printf ( "  %s:\n", name );
  printf ( "    value      :  \"%s\"\n", sb.value () );
  printf ( "    value(pos) :  \"%s\"\n", sb.value ( 1 ) );
  printf ( "    position   :  %d\n", sb.position () );
  printf ( "    length     :  %d\n", sb.length () );
  printf ( "    size       :  %d\n", sb.size () );
  printf ( "    refcount   :  %d\n", sb.refcount () );
  printf ( "    flags      :  " );
  if ( sb.is_fixed () ) printf ( "fixed " );
  if ( sb.is_static () ) printf ( "static " );
  if ( !( sb.is_fixed () || sb.is_static () ) ) printf ( "none" );
  printf ( "\n" );
}

#define eprint(sb) \
  if ( vrf.is_error () ) sb_print ( sb, z_string_(sb) )
  

vrf_start ( "strbuff_t: string buffer operations" )
  char test [101], test2 [101];
  strbuff_t dbuff, sbuff ( test, 101 );
  vrf_item ( sbuff.put ( "fiffi", 6 ) );
  vrf_verify ( sbuff.length () == 6 );
  vrf_verify ( sbuff.position () == 0 );
  vrf_verify ( sbuff.size () == 100 );
  vrf_verify ( !str_cmp ( sbuff.value (), "fiffi" ) );
  eprint ( sbuff );
  vrf_item ( sbuff.put ( "hu" ) );
  vrf_verify ( sbuff.length () == 6 );
  vrf_verify ( sbuff.position () == 0 );
  vrf_verify ( !str_cmp ( sbuff.value (), "huffi" ) );
  eprint ( sbuff );
  vrf_item ( sbuff.put ( "huhu not fiffi" ) );
  vrf_verify ( sbuff.length () == 14 );
  vrf_verify ( sbuff.position () == 0 );
  vrf_verify ( !str_cmp ( sbuff.value (), "huhu not fiffi" ) );
  eprint ( sbuff );
  vrf_item ( sbuff.readline ( test2, 101 ) );
  vrf_verify ( !str_cmp ( test2, "huhu not fiffi" ) );
  vrf_verify ( sbuff.position () == 14 );
  sbuff.position ( 0 );
  vrf_item ( sbuff.write ( "---- ", "test", " ----", (const char *) 0 ) );
  vrf_verify ( sbuff.length () == 14 );
  vrf_verify ( sbuff.position () == 14 );
  vrf_verify ( !str_cmp ( sbuff.value (), "---- test ----" ) );
  eprint ( sbuff );
  vrf_item ( dbuff +=  "ein test" );
  vrf_verify ( dbuff.length () == 8 );
  vrf_verify ( dbuff.position () == 0 );
  vrf_verify ( !str_cmp ( dbuff.value (), "ein test" ) );
  eprint ( dbuff );
  strbuff_t tmp;
  vrf_item ( tmp =  dbuff );
  vrf_verify ( !str_cmp ( tmp.value (), "ein test" ) );
  vrf_verify ( tmp.length () == 8 );
  vrf_verify ( tmp.position () == 0 );
  vrf_verify ( tmp.refcount () == 2 );
  vrf_verify ( sbuff.refcount () == 1 );
  eprint ( tmp );
  eprint ( sbuff );
  vrf_item ( tmp = "fiffi" );
  vrf_verify ( !str_cmp ( tmp.value (), "fiffi" ) );
  vrf_verify ( tmp.length () == 5 );
  vrf_verify ( tmp.position () == 0 );
  vrf_verify ( tmp.refcount () == 1 );
  vrf_verify ( dbuff.refcount () == 1 );
  eprint ( tmp );
  eprint ( dbuff );
vrf_end ( vrf.errors () )

#endif /* dCfgVerify */
