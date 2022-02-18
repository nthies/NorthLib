//
//  strext.h
//
//  Created by Norbert Thies on 18.03.1993.
//  Copyright © 1993 Norbert Thies. All rights reserved.
//

#ifndef  strext_h
#define  strext_h

#include <stdarg.h>
#include <regex.h>
#include "sysdef.h"

// constants used by various conversion functions:
#define  cvt_signed_c             1
#define  cvt_upper_c              2
#define  cvt_forcesign_c          4
#define  cvt_spacesign_c          8
#define  cvt_forcebase_c         16
#define  cvt_alternate_c         32 
#define  cvt_zeroextend_c        64
#define  cvt_exponent_c         128
#define  cvt_adapt_c            256
#define  cvt_allocated_c        512
#define  cvt_long_c            1024
#define  cvt_short_c           2048
#define  cvt_rightextend_c     4096


#ifdef __cplusplus

// A virtual buffer class:
class buffer_t {
  public:
    // pure virtual methods:
    buffer_t ( void ) {};
    virtual ~buffer_t ( void ) {};
    virtual int ok ( void ) const = 0;
    virtual int position ( int pos = -1 ) = 0;
    virtual int raw_write ( const void *ptr, int len ) = 0;
    virtual int raw_write ( char ch, int n = -1 ) = 0;
    virtual int raw_read ( void *ptr, int len ) = 0;
    virtual int getch ( void ) = 0;
    virtual int ungetch ( char ch ) = 0;
    virtual int flush ( void ) = 0;
    // predefined methods:
    virtual int write ( const void *ptr, int len )
      { return raw_write ( ptr, len ); }
    virtual int write ( char ch, int n = -1 )
      { return raw_write ( ch, n ); }
    virtual int write ( const char *str, int len = -1 );
    virtual int write ( const char *str, va_list vp );
    virtual int write ( const char *s1, const char *s2, ... );
    virtual int read ( void *ptr, int len )
      { return raw_read ( ptr, len ); }
    virtual int read ( char **ptr, int &len );
    virtual int read ( char *ptr, int len ) 
      { return read ( &ptr, len ); }
    virtual int readline ( char **ptr, int &len );
    virtual int readline ( char *ptr, int len )
      { return readline ( &ptr, len ); }
};

#define strb_size_c	40

// dynamic string buffer class
class strbuff_t : public buffer_t {
  private:
    void *sb_buffer;
    void *chkwrite ( void );
    void destruct ( void );
    void setbuff ( void *buff );
    void setbuff ( const strbuff_t &sb ) { setbuff ( sb.sb_buffer ); }
  public:
    int ok ( void ) const { return sb_buffer? 1 : 0; }
    int position ( int pos = -1 );
    int put ( const char *str, int len = -1 );
    int put ( char ch, int n = 1 );
    int raw_write ( const void *ptr, int len );
    int raw_write ( char ch, int n = -1 );
    int raw_read ( void *ptr, int len );
    int getch ( void );
    int ungetch ( char ch );
    int flush ( void ) { return 0; }
    void truncate ( void );
    int length ( void ) const;
    int refcount ( void ) const;
    int size ( int newsize = -1 );
    int is_fixed ( void ) const;
    int is_static ( void ) const;
    void fix ( int dofix = 1 );
    const char *value ( int atpos = 0 ) const;
    strbuff_t ( int len =  strb_size_c );
    strbuff_t ( char *buff, int len );
    strbuff_t ( const strbuff_t &sb );
    strbuff_t ( const char *str );
    ~strbuff_t () { destruct (); }
    int copy ( const char *str, int len = -1 );
    int copy ( char ch ) { return copy ( &ch, 1 ); }
    int cat ( const char *str, int len = -1 );
    int cat ( char ch ) { return cat ( &ch, 1 ); }
    strbuff_t &operator = ( const strbuff_t &sb );
    strbuff_t &operator = ( const char *str ) { copy ( str ); return *this; }
    strbuff_t &operator = ( char ch ) { copy ( ch ); return *this; }
    strbuff_t &operator += ( const strbuff_t &sb );
    strbuff_t &operator += ( const char *str ) { cat ( str ); return *this; }
    strbuff_t &operator += ( char ch ) { cat ( ch ); return *this; }
    operator const char * () { return value (); }
    operator char () { return *value ( 1 ); }
    char *heap ( void );
};

// some additional strbuff_t operators:
inline strbuff_t operator + ( const strbuff_t &a, const strbuff_t &b )
  { strbuff_t c =  a; return c += b; }
inline strbuff_t operator + ( const strbuff_t &a, const char *b )
  { strbuff_t c =  a; return c += b; }
inline strbuff_t operator + ( const strbuff_t &a, char b )
  { strbuff_t c =  a; return c += b; }
inline strbuff_t operator + ( const char *a, const strbuff_t &b )
  { return b + a; }
inline strbuff_t operator + ( char a, const strbuff_t &b )
  { return b + a; }

// conversion functions:
int cvt_l2a ( char **dest, int *len, unsigned long val, int base = 10,
              int cmin = -1, unsigned flags = 0 );
int cvt_a2l ( unsigned long *lnref, const char **rstr, int base = 0, 
              int maxdig = 0 );
int cvt_d2a ( char **ref, int *len, double val, int base = 10, int prec = 6,
              unsigned flags = cvt_adapt_c );

/**
 * A simple pattern matching class based on libc's regex funtions
 *
 * This interface uses the POSIX extended Syntax, e.g. grouping with
 * parantheses like (<group>) instead of \(group\).
 * In addition to [:<class>:] character classes the following shorthands
 * are provided:
 *   @d : digit
 *   @D : no digits
 *   @s : spaces
 *   @S : no spaces
 *   @a : alpha
 *   @A : no alpha
 *   @w : word
 *   @W : no word
 *   @@ : a single '@' character
 * Warning: Unicode alternate character representations may not be supported
 *          by POSIX regex functions.
 *
 * The substitute functions allow references to matching (sub-)expressions:
 *   &    : substitues complete matching string
 *   &<n> : substitutes the n'th sub-expression (aka group),
 *          e.g. '&1' refers to the first group, '&0' to the complete matching
 *          string
 *   &&   : substitutes a single '&'
 */
class regexpr_t {
private:
  char    *pattern;  /// pattern given to constructor
  regex_t *re;       /// libc's compiled pattern
  unsigned flags;    /// flags passed to regcomp
  int      last_err; /// last error encountered
  static const char *locale; /// locale used for LC_CTYPE and LC_COLLATE
  static const char *locale_check(void);
  void compile(void);
  void clear();
public:
  /// return true if pattern is a valid regular expression
  bool ok(void);
  /// return nil (if no error) or allocated error description
  char *last_error(void);
  /// perform sensitive newline mode
  void set_sensnl(int);
  int get_sensnl(void) const { return this->flags & REG_NEWLINE; }
  /// don't provide match results
  void set_noresult(int);
  int get_noresult(void) const { return this->flags & REG_NOSUB; }
  /// ignore case while matching
  void set_icase(int);
  int get_icase(void) const { return this->flags & REG_ICASE; }
  /// initialize with pattern
  regexpr_t(const char *pattern);
  /// free all allocated memory
  ~regexpr_t();
  /// Set new pattern
  void set_pattern(const char *pattern);
  /// Return current pattern
  const char *get_pattern(void) const { return this->pattern; }
  /// test whether 'str' is matched
  bool matches(const char *str);
  /// return regmatch_t array of match offsets
  regmatch_t *match_offsets(const char **str);
  /// return match result as argv array (index 0 is complete matched string)
  char **match(const char *str);
  /// return match result and update string pointer
  char **match(const char **str);
  /// return nb. of strings in result of 'match'
  int nmatches(void);
  /// substitute matched pattern with string and write result to string buffer
  /// returns true when successfully substituted
  bool subst(strbuff_t &buff, const char **rstr, const char *with,
             int lino = -1, int ndig = -1);
  /// substitute matched part with string
  char *subst(const char **rstr, const char *with,
              int lino = -1, int ndig = -1);
  /// substitute all matches with string and write result to string buffer
  /// returns true when at least one pattern was successfully substituted
  bool gsubst(strbuff_t &buff, const char **rstr, const char *with,
              int lino = -1, int ndig = -1);
  /// substitute all matched parts with string
  char *gsubst(const char **rstr, const char *with,
               int lino = -1, int ndig = -1);
  /// Returns true if 'spec' is a valid substitution pattern
  static bool is_valid_subst(const char *spec);
  /// substitue string by sed-like /pattern/substitution/g specification
  static char *subst(const char *str, const char *spec, int lino = -1,
                     int ndig = -1);
};

#endif /* __cplusplus */

BeginCLinkage

// Typedefs used by str_mexpand
typedef const char *str_matchfunc_t ( void *, const char * );
typedef int str_updatefunc_t ( void *, const char *, const char * );

// An opaque type for regexpr_t
typedef void *re_t;

// Exports of strext.cpp
extern const char *str_empty_c;
void *mem_cpy ( void *p1, const void *p2, size_t len );
void *mem_swap ( void *p1, void *p2, size_t len );
void *mem_set ( void *ptr, int c, size_t len );
int mem_cmp ( const void *p1, const void *p2, size_t len );
void *mem_move ( void *p1, const void *p2, size_t len );
void *mem_heap ( const void *, size_t );
void *mem_resize(void *ptr, size_t len);
void *mem_0byte(void **ptr, size_t *len);
void mem_release(void **);
int str_len (  const char *s );
int str_vcpy ( char **rdst, int n, va_list vp );
int str_mcpy ( char *dst, int n, ... );
int str_rmcpy ( char **rdst, int n, ... );
int str_cpy ( char *dst, int n, const char *src );
int str_rncpy ( char **dst, int len, const char *src, int n );
int str_ncpy ( char *dst, int len, const char *src, int n );
int str_rcpy ( char **rdst, int n, const char *src );
int str_rqcpy ( char **dest, int blen, const char *src );
int str_rchcpy ( char **dest, int blen, char ch, int n );
int str_chcpy ( char *dest, int blen, char ch, int n );
int str_vcat ( char **rdst, int n, va_list vp );
int str_mcat ( char *dst, int n, ... );
int str_rmcat ( char **rdst, int n, ... );
int str_cat ( char *dst, int n, const char *src );
int str_ncat ( char *dst, int len, const char *src, int n );
int str_rcat ( char **rdst, int n, const char *src );
char *str_heap ( const char *str, int len );
void str_release ( char **str );
char *str_slice ( const char *str, int from, int to );
const char *str_chr (  const char *s, char c );
const char *str_rchr (  const char *s, char c );
const char *str_pbrk (  const char *s1,  const char *s2 );
int str_ccmp (  const char *s1,  const char *s2, char delim );
int str_cmp (  const char *s1,  const char *s2 );
int str_ncmp (  const char *s1,  const char *s2, int n );
int str_casecmp (  const char *s1,  const char *s2 );
int str_ncasecmp (  const char *s1,  const char *s2, int n );
int str_is_gpattern ( const char *str );
int str_gmatch ( const char *str, const char *pattern );
const void *mem_match ( const void *str, int len, const char *match );
const char *str_match ( const char *str, const char *match, char delim );
const char *str_casematch ( const char *str, const char *match, char delim );
const char *str_substring ( const char **rs, char *buff, int len, char delim );
char *str_trim(const char *str);
char *str_2upper ( char *str );
char *str_2lower ( char *str );
char *str_reverse ( char *str );
int str_rquote ( char **, int, const char * );
char *str_quote ( const char * );
int str_rdequote ( char **, int, const char * );
char *str_dequote ( const char * );
const char *str_error ( int errcode );
char *str_get ( char *str, int len );
int str_skip_white ( const char **p, int skip_eol );
int str_i2roman ( char *buff, int len, int val, int islarge );
int str_rroman2i ( const char **rstr );
int str_roman2i ( const char *str );
char *str_mexpand(const char *, str_matchfunc_t *, str_updatefunc_t *, void *);
char *str_tm2iso(struct tm *t, int usec);
const char *uts_sysname();
const char *uts_nodename();
const char *uts_release();
const char *uts_version();
const char *uts_machine();

/* Exports of strcvt.cpp: */
int str_rbin2a ( char **dest, int dlen, const void *mem, int len );
int str_bin2a ( char *dest, int dlen, const void *mem, int len );
int str_rcntl2a ( char **dest, int dlen, const void *mem, int len );
int str_cntl2a ( char *dest, int dlen, const void *mem, int len );
int str_vcc2a ( char **dest, int dlen, va_list vp );
int str_rmcc2a ( char **dest, int dlen, ... );
int str_mcc2a ( char *dest, int dlen, ... );
int str_rcc2a ( char **dest, int dlen, const char *str );
int str_cc2a ( char *dest, int dlen, const char *str );
int str_rbin2hex ( char **dest, int dlen, const void *mem, int len );
int str_bin2hex ( char *dest, int dlen, const void *mem, int len );
int str_vhex2bin ( void **dest, int dlen, va_list vp );
int str_rmhex2bin ( void **dest, int dlen, ... );
int str_mhex2bin ( void *dest, int dlen, ... );
int str_rhex2bin ( void **dest, int dlen, const char *str );
int str_hex2bin ( void *dest, int dlen, const char *str );
int str_rl2a ( char **dest, int len, long unsigned int val, int base );
int str_l2a ( char *dest, int len, long unsigned int val, int base );
int str_rdec2a ( char **dest, int len, long unsigned int val, int ndig );
int str_dec2a ( char *dest, int len, long unsigned int val, int ndig );
int str_ra2l ( long unsigned int *rval, const char **str, int base );
int str_a2l ( long unsigned int *rval, const char *str, int base );
int str_bin2fhex ( char *dest, int dlen, const void *src, int len, long unsigned int addr );

/* Exports of argv.cpp: */
int av_release ( char **ptr );
const char * const *av_const(char **argv);
char *av_index(char **argv, int i);
int av_length (const char * const * );
int av_size ( char **argv );
char **av_heap ( const char * const *argv, int len );
char **av_alloc(int len);
char **av_clone ( char **argv );
char **av_a2av ( const char *str, char delim );
int av_av2a ( char *buff, int blen, char **av, char delim );
char **av_vinsert ( char **av, int pos, va_list vp );
char **av_minsert ( char **av, int pos, ... );
char **av_insert ( char **av, int pos, const char *s );
char **av_vappend ( char **av, va_list vp );
char **av_mappend ( char **av, ... );
char **av_append ( char **av, const char *s );
char **av_avinsert ( char **av, int pos, char **arg );
char **av_delete ( char **av, int from, int to );

/* Exports of regexpr.cpp */
re_t re_init(const char *str);
char *re_last_error(re_t re);
void re_release(re_t);
void re_set_sensnl(re_t re, int val);
void re_set_noresult(re_t re, int val);
void re_set_icase(re_t re, int val);
void re_set_pattern(re_t re, const char *pattern);
int re_get_sensnl(re_t re);
int re_get_icase(re_t re);
int re_get_noresult(re_t re);
const char *re_get_pattern(re_t re);
int re_matches(re_t re, const char *str);
char **re_match(re_t re, const char *str);
char **re_rmatch(re_t re, const char **str);
char *re_subst(re_t re, const char **rstr, const char *with);
char *re_nsubst(re_t re, const char **rstr, const char *with, int lino, int ndig);
char *re_gsubst(re_t re, const char **rstr, const char *with);
char *re_ngsubst(re_t re, const char **rstr, const char *with, int lino, int ndig);
char *re_strsubst(const char *str, const char *spec);
char *re_nstrsubst(const char *str, const char *spec, int lino, int ndig);
int re_is_valid_subst(const char *spec);

EndCLinkage

#ifdef __cplusplus

inline char *str_heap(const char *str) { return str_heap(str, 0); }
inline int str_cpy ( char **rdst, int n, const char *src )
  { return str_rcpy( rdst, n, src); }
inline char **av_heap(const char *const *argv) { return av_heap(argv, 0); }
inline const char *str_error() { return str_error(-1); }

#endif /* __cpluplus */

#endif  /* strext_h */
