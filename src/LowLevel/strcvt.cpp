//
//  strcvt.cpp
//
//  Created by Norbert Thies on 18.03.1993.
//  Copyright © 1993 Norbert Thies. All rights reserved.
//

#include  <stdarg.h>
#include  <stdlib.h>
#include  <ctype.h>
#include  <math.h>
//#include  <ieeefp.h>

#include  "numeric.h"
#include  "strext.h"



/*
 *  The control character conversion arrays:
 */
 
static const char *_ccarray [] = {
  "NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL", "BS", "HT",
  "LF", "VT", "FF", "CR", "SO", "SI", "DLE", "DC1", "DC2", "DC3", "DC4",
  "NAK", "SYN", "ETB", "CAN", "EM", "SUB", "ESC", "FS", "GS", "RS", "US"
};

static const char _hexdigits [] =  "0123456789abcdefghijklmnopqrstuvwxyz";
static const char _Hexdigits [] =  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";


/*
 *  Some conversion macros:
 */

const int min_base =  2,
          max_base =  sizeof _hexdigits / sizeof ( char );

inline int is_baseok ( int base ) {
  return ( (base <= max_base) && (base >= min_base) )? 1 : 0;
}

inline int is_digit ( unsigned char ch ) {
  ch =  tolower ( ch );
  return isdigit ( ch ) || ( (ch >= 'a') && (ch <= 'z') );
}

inline int ord ( unsigned char ch ) {
  ch =  tolower ( ch );
  if ( isdigit ( ch ) ) return ch - '0';
  else return 10 + ( ch - 'a' );
}

inline char c2x ( int c ) { return _Hexdigits [c]; }

inline void byte2hex ( char *&d, unsigned char *&b ) {
  unsigned char n1 =  ( (unsigned char) (*b & 0xf0 ) ) >> 4,
                n2 =  *b & 0x0f;
  *(d++) =  c2x ( n1 ); 
  *(d++) =  c2x ( n2 ); 
  b++;
}

inline void hex2byte ( unsigned char *&d, const char *&h ) {
  unsigned char n1, n2;
  if ( isxdigit ( *h ) ) ( n1 = ord ( *h ) ), h++;
  if ( isxdigit ( *h ) ) ( n2 = ord ( *h ) ), h++;
  *(d++) =  ( n1 << 4 ) | n2;
}


/*
 *  The floating point conversion class:
 *  (This class is the base class for all floating point conversions)
 */

class fltcvt_t {
  private:
    const char *digits;   // the digit array to use
    double   val;         // float number to convert
    int      exp;         // exponent of 'val'
    double   mant;        // mantissa of 'val'
    char    *buff;        // buffer to write to
    int      len;         // length of 'buff'
    char     smant [101]; // mantissa string
    unsigned flags;       // flag values
    int      prec;        // conversion precision
    int      base;        // conversion base
    int      ndigits;     // number of significant digits
    void get_ndigits ( void );
    void round ( char *, unsigned );
    void cvmant ();
    char *cvdouble ( void );
  public:
    fltcvt_t ( unsigned, int );
    int convert ( char **, int *, double, int );
    inline int ok ( void ) { return (base > 1)? 1 : 0; }
};


/*
 *  SUB fltcvt_t::get_ndigits
 *  is used to evaluate the number of significant digits to print.
 */

void fltcvt_t:: get_ndigits ( void ) {
  if ( flags & cvt_adapt_c ) {
    ndigits =  prec;
    if ( ( exp < -3 ) || ( exp > prec ) )
      flags |=  cvt_exponent_c;
    else flags &=  ~cvt_exponent_c;
  }
  else if ( flags & cvt_exponent_c ) ndigits =  prec + 1;
       else if ( exp > 40 ) {
	      flags |=  cvt_exponent_c;
	      ndigits =  prec + 1;
	    }
	    else ndigits =  exp + prec;
}


/*
 *  SUB  fltcvt_t::round
 *  is used to round a given string of digits.
 */

void fltcvt_t:: round ( char *lastp, unsigned dig ) {
  char *p =  lastp -1;
  unsigned half;
  if ( base % 2 ) half =  base / 2 + 1;
  else half =  base / 2;
  if ( dig >= half ) {
    while ( dig ) {
      if ( p < smant ) {
	*(++p) =  '1';
	*(lastp++) =  '0';
	*lastp =  '\0';
	exp++;
	get_ndigits ();
	break;
      }
      else {
	dig =  ord ( *p ) + 1;
	if ( dig < base ) {
	  *p =  digits [dig];
	  dig =  0;
	}
	else *(p--) =  '0';
} } } }

    
/*
 *  SUB cvmant 
 *  is used to convert a given number of digits to ascii.
 *  assuming the passed double is a mantissa m, where
 *        0.1 <= m < base ** 0
 *  The string written to 'p' is rounded.
 */

void fltcvt_t:: cvmant ( void ) {
  char *p =  smant;
  int n =  min( ndigits, 100 );
  unsigned tmp;
  double d =  mant;
  if ( mant < 0.0 ) mant =  -mant;
  while ( n-- > 0 ) {
    d *=  (double) base;
    tmp =  (unsigned) d;
    *(p++) =  digits [tmp];
    d -=  (double) tmp;
  }
  *p =  '\0';
  d *=  (double) base;
  tmp =  (unsigned) d;
  round ( p, tmp );
}


/*
 *  SUB fltcvt_t:: cvdouble
 *  uses the above noted functions for converting a double.
 */

char *fltcvt_t:: cvdouble ( void ) {
  char *d =  buff;
  if ( len > 1 ) {
    char *s =  smant;
    int is_point =  1;
    get_ndigits ();
    cvmant ();
    if ( val < 0.0 ) { *(d++) =  '-', len--; }
    else if ( flags & cvt_forcesign_c ) { *(d++) =  '+'; len--; }
	 else if ( flags & cvt_spacesign_c ) { *(d++) =  ' '; len--; }
    if ( flags & cvt_forcebase_c ) {
      if ( len > 1 ) { *(d++) =  '#'; len--; }
      cvt_l2a ( &d, &len, (unsigned long) base );
      if ( len > 1 ) { *(d++) =  '_'; len--; }
    }
    int n =  ndigits;
    if ( flags & cvt_exponent_c ) {
      if ( len > 1 ) { *(d++) =  *(s++); len--; }
      if ( ( --n || ( flags & cvt_alternate_c ) ) && (len > 1) )
        { *(d++) =  '.'; len--; }
      else is_point =  0;
      while ( (n-- > 0) && (len > 1) ) { *(d++) =  *(s++); len--; }
    }
    else { 
      if ( exp <= 0 ) {
	int nz =  -exp;
        if ( len > 1 ) { *(d++) =  '0'; len--; }
        if ( len > 1 ) { *(d++) =  '.'; len--; }
	while ( nz-- && (len > 1) ) { *(d++) =  '0'; len--; }
      }
      else {
	int np =  exp;
	while ( np-- && (len > 1) ) { n--; *(d++) =  *(s++); len--; }
	if ( ( ( n > 0 ) || ( flags & cvt_alternate_c ) ) && (len > 1) )
	  { *(d++) =  '.'; len--; }
	else is_point =  0;
      }
      while ( (n-- > 0) && (len > 1) ) { *(d++) =  *(s++); len--; }
    }
    if ( is_point && (flags & cvt_adapt_c) && !(flags & cvt_alternate_c) ) {
      char *p =  d - 1, *tmp;
      while ( *p == '0' ) p--;
      if ( *p != '.' ) tmp =  p + 1;
      else tmp =  p;
      len +=  d - tmp;
      d =  tmp;
    }
    if ( flags & cvt_exponent_c ) {
      int tmp =  exp - 1;
      unsigned fl =  cvt_signed_c | cvt_forcesign_c | cvt_zeroextend_c
		     | (flags & cvt_upper_c);
      if ( len > 1 ) {
	if ( base > 10 ) *(d++) =  '_';
	else *(d++) =  (flags & cvt_upper_c)? 'E' : 'e';
	len--;
      }
      cvt_l2a ( &d, &len, (unsigned long) tmp, base, 3, fl );
  } }
  *d =  '\0';
  return d;
}


/*
 *  PUBLIC  fltcvt_t:: fltcvt_t ( unsigned flags, int base )
 *          ================================================
 *
 *          unsigned flags :  conversion flags;
 *          int base       :  base of digits to use;
 *
 *  This constructor is used to instantiate a float conversion object.
 *  The passed 'flags' argument is identical to that of 'str_d2a'.
 *  The 'base; argument specifies the base of all produced digits.
 *  Remark:  1 < base <= 36
 */

fltcvt_t:: fltcvt_t ( unsigned fl, int b ) {
  if ( is_baseok ( b ) ) {
    flags =  fl;
    base =  b;
    if ( fl & cvt_upper_c ) digits =  _Hexdigits;
    else digits =  _hexdigits;
  }
  else base =  -1;
}


/*
 *  PUBLIC  int fltcvt_t:: convert ( char **buff, int &len, double val, 
 *                                   int prec )
 *          ===========================================================
 *
 *          char **buff :  where to write the result to;
 *          int &len    :  length of 'buff' (incl. \0);
 *          double val  :  the value to convert to ascii;
 *          int prec    :  the precision to use for formatting;
 *          VALUE       :  #chars written to 'buff' if >= 0,
 *                         Error detected otherwise;
 *
 *  'convert' is used to format the double given in 'val' according
 *  to the passed precision 'prec' into 'buff'. 
 *  See 'str_d2a' for more details.
 */

int fltcvt_t:: convert ( char **ptr, int *rlen, double v, int p ) {
  int ret =  -1;
  if ( rlen && len && ok () ) {
    int is_nan =  isnan ( v ),
	is_inf =  !isfinite ( v ),
	l =  *rlen;
    if ( is_inf || is_nan ) {
      if ( is_nan ) ret = str_rcpy ( ptr, l, "NaN" ); 
      else ret = str_rcpy ( ptr, l, "Inf" );
    }
    else {
      char *str;
      buff =  *ptr;
      val =  v;
      prec =  p;
      len =  l;
      mant =  flt_mantissa ( val, base, &exp );
      if ( (str =  cvdouble ()) ) {
	*ptr =  str;
	ret =  l - len;
	*rlen =  len;
  } } }
  return ret;
}
 
 
/*
 *  PROCEDURE  int cvt_d2a ( char **ref, int *len, double val, int base = 10,
 *                           int prec = 6, unsigned flags = cvt_adapt_c )
 *             ==============================================================
 *
 *             char **ref     :  where to write the formatted number to;
 *             int &len       :  length of *ref (incl. \0);
 *             double val     :  numeric value in double format;
 *             int base       :  base of digits to write;
 *             int prec       :  precision used for formatting (see below);
 *             unsigned flags :  conversion controlling flags;
 *             VALUE          :  number of chars written to *ref (excl. \0)
 *                               if > 0, Error detected otherwise;
 *             LINKAGE        :  C++;
 *
 *  'cvt_d2a' is used to convert a double number to a string.
 *  The string reference is updated, so after converting, 'ref' is
 *  positioned to the next char behind the number representation
 *  (i.e. it is positioned to the terminating zero byte).
 *  The number of chars written to *ref is subtracted from 'len'.
 *  The following flags are supported:
 *
 *         cvt_upper_c       :  use uppercase digits and exponential prefix
 *         cvt_forcesign_c   :  force a prefixing sign
 *         cvt_spacesign_c   :  space a plus sign (print minus)
 *         cvt_forcebase_c   :  force a prefixing base (#<base>_<number>)
 *         cvt_alternate_c   :  use alternate representation
 *         cvt_exponent_c    :  force exponential representation
 *         cvt_adapt_c       :  force adaption to exponential or normal
 *                              representation
 *
 *  The precision 'prec' specifys:
 *    (i)   The number of digits appearing behind the decimal point
 *          (when not cvt_adapt_c)
 *    (ii)  The maximum number of significant digits (when cvt_adapt_c)
 *
 *  When cvt_alternate_c is set, the result contains a decimal point
 *  even if no digits follow the point. Normally a decimal point appears only,
 *  when there are digits following it. In case of cvt_adapt_c trailing zeros
 *  are not removed (which are by default).
 *
 *  By default a double is formatted as ["-" | "+" | " "]ddd.ddd
 *  where 'prec' specifys the number of digits behind the decimal point.
 *  In case of cvt_exponent_c the double is formatted to:
 *  ["-" | "+" | " "]d.ddd("e" | "E")("+" | "-")dd where there is exactly one
 *  digit before the decimal point, 'prec' digits behind it and two or more
 *  digits for the exponent.
 *  In case of cvt_adapt_c the default representation form is preferred
 *  unless the exponent is < -4 or > 'prec'. Trailing zeros are removed.
 *
 *  Remarks:  if ( isnan ( val ) )
 *              then the string "NaN" is written to '*ref'.
 *  Remarks:  if ( !finite ( val ) )
 *              then the string "Inf" is written to '*ref'.
 */
 
int cvt_d2a ( char **ref, int *len, double val, int base, int prec,
              unsigned flags ) {
  fltcvt_t fc ( flags, base );
  return fc.convert ( ref, len, val, prec );
}


/*
 *  PROCEDURE  int cvt_l2a ( char **dest, int *len, unsigned long val,
 *                           int base = 10, int cmin = -1, unsigned flags = 0 )
 *             ================================================================
 *
 *             char **dest       :  where to write to;
 *             int &len          :  length of string buffer;
 *             unsigned long val :  value to convert;
 *             int base          :  conversion base;
 *             int cmin          :  minimal number of chars to write;
 *             unsigned flags    :  conversion flags (see below);
 *             VALUE             :  number of chars written to *dest (excl. \0)
 *                                  if > 0, Error detected else;
 *             LINKAGE           :  C++;
 *
 *  'cvt_l2a' is used as general integer to ascii conversion function.
 *  After formatting the integral value, *dest is positioned to the
 *  trailing zero byte and the number of chars written to *dest is
 *  subtracted from 'len'. 'base' specifies the conversion base to
 *  apply to 'val'. Supported bases range from 2 (binary representation) to
 *  36. The digits used are:
 *    "0123456789abcdefghijklmnopqrstuvwxyz"
 *  'cmin' specifies the minimal number of characters to write to '*dest',
 *  ie. there are no less characters than 'cmin' written, but more if
 *  the number representation is longer than 'cmin'. The following flags
 *  may be used to control the conversion algorithm in detail:
 *
 *    cvt_signed_c      :  do a signed conversion
 *    cvt_forcesign_c   :  force the output of a sign character (+|-)
 *    cvt_spacesign_c   :  space a positive value
 *    cvt_alternate_c   :  use alternate representation (ie. 0xff, 012, ...)
 *    cvt_upper_c       :  use uppercase digits
 *    cvt_forcebase_c   :  force a base representation of #<base>_<number>
 *    cvt_zeroextend_c  :  use zeros for filling
 *    cvt_rightextend_c :  fill from right side
 */

int cvt_l2a ( char **dest, int *rlen, unsigned long val, int base, int cmin, 
              unsigned flags ) {
  int ret =  -1;
  if ( dest && *dest && is_baseok ( base ) && rlen ) {
    int dlen =  *rlen;
    char buffer [100], tmp [20];
    const char *sign = "", *salt = "", *s;
    char *p = buffer, *d = *dest;
    const char *digits =  (flags & cvt_upper_c)? _Hexdigits : _hexdigits;
    long sval =  val;
    int len =  dlen, npad = 0, plen;
    if ( ( flags & ( cvt_forcesign_c | cvt_spacesign_c ) ) ||
         ( ( flags & cvt_signed_c ) && ( sval < 0L ) ) ) {
      if ( ( flags & cvt_signed_c ) && ( sval < 0L ) )
        { sign =  "-"; val =  -sval; }
      else {
        if ( flags & cvt_forcesign_c ) sign =  "+";
	else sign =  " ";
    } }
    do {
      *p++ =  digits [ val % base ];
      val /= base;
    }
    while ( val );
    if ( flags & cvt_alternate_c ) {
      switch ( base ) {
	case  2 :  salt =  (flags & cvt_upper_c)? "0B" : "0b"; break;
	case  8 :  if ( *(p - 1) != '0' ) salt = "0"; break;
	case 16 :  salt =  (flags & cvt_upper_c)? "0X" : "0x"; break;
	default :  flags |=  cvt_forcebase_c; break;
    } }
    if ( flags & cvt_forcebase_c ) {
      char *t =  tmp; int l = 19;
      salt =  tmp;
      *t++ =  '#';
      cvt_l2a ( &t, &l, (unsigned long) base );
      *t++ =  '_';
      *t =  '\0';
    }
    if ( flags & cvt_zeroextend_c ) flags &= ~cvt_rightextend_c;
    plen =  str_len ( salt ) + str_len ( sign );
    if ( cmin > 0 ) npad =  (int)(cmin - (p - buffer) - plen);
    if ( (npad > 0) && !(flags & cvt_rightextend_c) ) {
      int n =  npad;
      if ( flags & cvt_zeroextend_c ) {
	for ( s = sign; *s && (len > 1); len-- ) *d++ = *s++;
	for ( s = salt; *s && (len > 1); len-- ) *d++ = *s++;
	for ( ; (n > 0) && (len > 1); n--, len-- ) *d++ = '0';
      }
      else {
	for ( ; (n > 0) && (len > 1); n--, len-- ) *d++ = ' ';
	for ( s = sign; *s && (len > 1); len-- ) *d++ = *s++;
	for ( s = salt; *s && (len > 1); len-- ) *d++ = *s++;
    } }
    else {
      for ( s = sign; *s && (len > 1); len-- ) *d++ = *s++;
      for ( s = salt; *s && (len > 1); len-- ) *d++ = *s++;
    }
    for ( ; (p > buffer) && (len > 1); len-- ) *d++ = *--p;
    if ( (flags & cvt_rightextend_c) && (npad > 0) ) {
      int n =  npad;
      for ( ; (n > 0) && (len > 1); n--, len-- ) *d++ = ' ';
    }
    *d =  '\0';
    *dest =  d;
    ret =  dlen - len;
    *rlen =  len;
  }
  return ret;
}


/*
 *  PROCEDURE  int cvt_a2l ( unsigned long *lnref, const char **rstr, 
 *                           int base = 0, int maxdig = 0 )
 *             ======================================================
 *
 *             long  &lnref      :  ref. to value for storing result,
 *             const char *rstr  :  ref. to string containing number;
 *             int base          :  base to use for conversion;
 *             int maxdig        :  max. number of digits to convert;
 *             VALUE             :  >0  ==>  #chars converted,
 *                                  -1 ==> Error detected;
 *             LINKAGE           :  C++;
 *
 *  'cvt_a2l' converts a string representing a long number either in 
 *  decimal (default case), hexadecimal (leading '0x'), octal
 *  (leading 0 or 0o/0O), binary (leading 0b) notation or of the
 *  general form #<base>_<number>, where <base> is a decimal base
 *  (eg #17_123efg).
 *  The given string is positioned to the next char not belonging
 *  to the number.
 *  The result is stored in 'lnref' and the return value is 0, when
 *  no error is occured.
 *  The number to convert is interpreted as signed value.
 *  If base <> 0, then no adaptive number scanning is performed 
 *  (ie. leading 0 or 0x are not interpreted).
 */

int cvt_a2l ( unsigned long *lnref, const char **rstr, int fbase, 
              int maxdig ) {
  int ret =  -1;
  if ( lnref && rstr && *rstr ) {
    unsigned long n =  0;
    const char *str =  *rstr;
    unsigned base =  fbase? fbase : 10, 
	     val =  0;
    int negative =  0;
    const char *first =  str, *tmp;
    if ( !maxdig ) maxdig =  100;
    for (;;) {  // handle prefixes
      switch ( *str ) {
	case '\0':   return -1;
	case ' ' :
	case '\t':
	case '+' :   str ++;                                   
		     continue;
	case '-' :   negative =  ! negative;                 
		     str ++;                                   
		     continue;
	case '#' :   if ( fbase ) break;
		     str ++;
		     unsigned long lbase;
		     if ( cvt_a2l ( &lbase, &str, 10 ) ) return -1;
		     if ( *str != '_' ) return -1;
		     str++;
		     base =  (unsigned) lbase;
		     if ( !is_baseok ( base ) ) return -1;
		     break;
	case '0' :   if ( fbase ) break;
		     str ++;
		     switch ( tolower ( *str ) ) {
		       case 'x' :   base =  16;
				    str ++;
				    break;
		       case 'b' :   base =  2;
				    str ++;
				    break;
		       case 'o' :   str++;
		       default  :   base =  8;
				    break;
		     }  
	default  :   break;
      }
      break;
    }
    tmp =  str;
    while ( ( maxdig-- > 0 ) && *str && 
	    is_digit ( *str ) && ( ( val = ord ( *str ) ) < base ) ) {
      n =  n * base + val;
      str++;
    }
    if ( ( tmp == str ) && ( base != 8 ) ) return -1;
    ret =  (int) ( str - *rstr );
    *lnref =  (negative)? -n : n;
    *rstr =  str;
  }
  return ret;
}


/*
 *  PROCEDURE  int str_rbin2a ( char **dest, int dlen, const void *mem, 
 *                              int len )
 *             ========================================================
 * 
 *             char **dest     :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const void *mem :  ptr to memory area;
 *             int len         :  nb. of bytes to convert;
 *             VALUE           :  #chars copied to *dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_rbin2a' is used to convert 'len' bytes from 'mem' to a string 
 *  representation at 'dest'. Each non printable character is converted 
 *  to its ascii representation with following substitutions:
 *  (let cc be the control character to convert).
 *      0 <= cc < 0x20   cc  -->   "[" <type> "]"
 *                       where type is a string representing the
 *                       specific control character, e.g. \003
 *                       is converted to "[ETX]".
 *    0x20 <= cc < 0x7f  cc  -->   "cc"
 *                       the character cc remains unchanged.
 *    0x7f               cc  -->  "[DEL]"
 *    0x7f <= cc <= 0xff cc  -->   "[" <hex> "]"
 *                       where hex is the hexadecimal representation,
 *                       e.g. 0xa5 is converted to "[a5]"
 */

int str_rbin2a ( char **dest, int dlen, const void *mem, int len ) {
  unsigned char *s =  (unsigned char *) mem;
  char *d =  *dest;
  int ret;
  while ( ( dlen > 1 ) && ( len-- > 0 ) ) {
    if ( ( *s < 0x20 ) || ( *s >= 0x7f ) ) {
      if ( *s < 0x20 ) 
        dlen -= str_rmcpy ( &d, dlen, "[", _ccarray [*s], "]", 
	                    (const char *) 0 );
      else {
	if ( *s == 0x7f ) dlen -= str_rcpy ( &d, dlen, "[DEL]" );
	else if ( dlen > 4 ) {
	  unsigned h = *s >> 4, l = *s & 0xf;
	  *d++ =  '['; *d++ = _hexdigits [h]; *d++ = _hexdigits [l]; *d++ = ']';
	  dlen -=  4;
	}
	else break;
      }
      s++;
    }
    else { *d++ = (char) *s++; dlen--; }
  }
  *d =  '\0';
  ret =  (int)(d - *dest);
  *dest =  d;
  return ret;
}


/*
 *  PROCEDURE  int str_bin2a ( char *dest, int dlen, const void *mem, 
 *                             int len )
 *             ========================================================
 * 
 *             char *dest      :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const void *mem :  ptr to memory area;
 *             int len         :  nb. of bytes to convert;
 *             VALUE           :  #chars copied to dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_bin2a' is used to convert 'len' bytes from 'mem' to a string 
 *  representation at 'dest'. Each non printable character is converted 
 *  to its ascii representation with following substitutions:
 *  (let cc be the control character to convert).
 *      0 <= cc < 0x20   cc  -->   "[" <type> "]"
 *                       where type is a string representing the
 *                       specific control character, e.g. \003
 *                       is converted to "[ETX]".
 *    0x20 <= cc < 0x7f  cc  -->   "cc"
 *                       the character cc remains unchanged.
 *    0x7f <= cc <= 0xff cc  -->   "[" <hex> "]"
 *                       where hex is the hexadecimal representation,
 *                       e.g. 0xa5 is converted to "[a5]"
 */

int str_bin2a ( char *dest, int dlen, const void *mem, int len ) {
  return str_rbin2a ( &dest, dlen, mem, len );
}


/*
 *  PROCEDURE  int str_vcc2a ( char **dest, int dlen, va_list vp )
 *             ===================================================
 * 
 *             char **dest     :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             va_list vp      :  list of strings to copy (and convert);
 *             VALUE           :  #chars copied to *dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_vcc2a' is used to copy a number of strings 'str' to *dest while
 *  converting each control character to an ascii representation.
 *  Each non printable character is converted 
 *  to its ascii representation with following substitutions:
 *  (let cc be the control character to convert).
 *      0 <= cc < 0x20   cc  -->   "[" <type> "]"
 *                       where type is a string representing the
 *                       specific control character, e.g. \003
 *                       is converted to "[ETX]".
 *    0x20 <= cc < 0x7f  cc  -->   "cc"
 *                       the character cc remains unchanged.
 *    0x7f <= cc <= 0xff cc  -->   "[" <hex> "]"
 *                       where hex is the hexadecimal representation,
 *                       e.g. 0xa5 is converted to "[a5]"
 */

int str_vcc2a ( char **dest, int dlen, va_list vp ) {
  if ( vp ) {
    const char *str;
    int dl =  dlen;
    while ( (str = va_arg ( vp, const char * )) )
      dl -= str_rbin2a ( dest, dl, str, str_len ( str ) );
    return dlen - dl;
  }
  else return 0;
}


/*
 *  PROCEDURE  int str_rmcc2a ( char **dest, int dlen, const char *str, ... )
 *             ==============================================================
 * 
 *             char **dest     :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const char *str :  string(s) to copy (and convert);
 *             VALUE           :  #chars copied to *dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_rmcc2a' is used to copy a number of strings 'str' to *dest while
 *  converting each control character to an ascii representation.
 *  Each non printable character is converted 
 *  to its ascii representation with following substitutions:
 *  (let cc be the control character to convert).
 *      0 <= cc < 0x20   cc  -->   "[" <type> "]"
 *                       where type is a string representing the
 *                       specific control character, e.g. \003
 *                       is converted to "[ETX]".
 *    0x20 <= cc < 0x7f  cc  -->   "cc"
 *                       the character cc remains unchanged.
 *    0x7f <= cc <= 0xff cc  -->   "[" <hex> "]"
 *                       where hex is the hexadecimal representation,
 *                       e.g. 0xa5 is converted to "[a5]"
 */

int str_rmcc2a ( char **dest, int dlen, ... ) {
  int ret;
  va_list vp;
  va_start ( vp, dlen );
  ret =  str_vcc2a ( dest, dlen, vp );
  va_end ( vp );
  return ret;
}


/*
 *  PROCEDURE  int str_mcc2a ( char *dest, int dlen, const char *str, ... )
 *             ============================================================
 * 
 *             char *dest      :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const char *str :  string(s) to copy (and convert);
 *             VALUE           :  #chars copied to dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_mcc2a' is used to copy a number of strings 'str' to *dest while
 *  converting each control character to an ascii representation.
 *  Each non printable character is converted 
 *  to its ascii representation with following substitutions:
 *  (let cc be the control character to convert).
 *      0 <= cc < 0x20   cc  -->   "[" <type> "]"
 *                       where type is a string representing the
 *                       specific control character, e.g. \003
 *                       is converted to "[ETX]".
 *    0x20 <= cc < 0x7f  cc  -->   "cc"
 *                       the character cc remains unchanged.
 *    0x7f <= cc <= 0xff cc  -->   "[" <hex> "]"
 *                       where hex is the hexadecimal representation,
 *                       e.g. 0xa5 is converted to "[a5]"
 */

int str_mcc2a ( char *dest, int dlen, ... ) {
  int ret;
  va_list vp;
  va_start ( vp, dlen );
  ret =  str_vcc2a ( &dest, dlen, vp );
  va_end ( vp );
  return ret;
}


/*
 *  PROCEDURE  int str_rcc2a ( char **dest, int dlen, const char *str )
 *             ========================================================
 * 
 *             char **dest     :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const char *str :  string to copy (and convert);
 *             VALUE           :  #chars copied to *dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_rcc2a' is used to copy a string 'str' to *dest while
 *  converting each control character to an ascii representation.
 *  Each non printable character is converted 
 *  to its ascii representation with following substitutions:
 *  (let cc be the control character to convert).
 *      0 <= cc < 0x20   cc  -->   "[" <type> "]"
 *                       where type is a string representing the
 *                       specific control character, e.g. \003
 *                       is converted to "[ETX]".
 *    0x20 <= cc < 0x7f  cc  -->   "cc"
 *                       the character cc remains unchanged.
 *    0x7f <= cc <= 0xff cc  -->   "[" <hex> "]"
 *                       where hex is the hexadecimal representation,
 *                       e.g. 0xa5 is converted to "[a5]"
 */

int str_rcc2a ( char **dest, int dlen, const char *str ) {
  return str_rmcc2a ( dest, dlen, str, (const char *) 0 );
}


/*
 *  PROCEDURE  int str_cc2a ( char *dest, int dlen, const char *str )
 *             ======================================================
 * 
 *             char *dest      :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const char *str :  string to copy (and convert);
 *             VALUE           :  #chars copied to dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_cc2a' is used to copy a string 'str' to dest while
 *  converting each control character to an ascii representation.
 *  Each non printable character is converted 
 *  to its ascii representation with following substitutions:
 *  (let cc be the control character to convert).
 *      0 <= cc < 0x20   cc  -->   "[" <type> "]"
 *                       where type is a string representing the
 *                       specific control character, e.g. \003
 *                       is converted to "[ETX]".
 *    0x20 <= cc < 0x7f  cc  -->   "cc"
 *                       the character cc remains unchanged.
 *    0x7f <= cc <= 0xff cc  -->   "[" <hex> "]"
 *                       where hex is the hexadecimal representation,
 *                       e.g. 0xa5 is converted to "[a5]"
 */

int str_cc2a ( char *dest, int dlen, const char *str ) {
  return str_mcc2a ( dest, dlen, str, (const char *) 0 );
}


/*
 *  PROCEDURE  int str_rcntl2a ( char **dest, int dlen, const void *mem, 
 *                               int len )
 *             =========================================================
 * 
 *             char **dest     :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const void *mem :  ptr to memory area;
 *             int len         :  nb. of bytes to convert;
 *             VALUE           :  #chars copied to *dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_rcntl2a' is used to convert 'len' bytes from 'mem' to a string 
 *  representation at 'dest'. Each non printable character is converted 
 *  to its ascii representation with following substitutions:
 *  (let cc be the control character to convert).
 *      0 < cc < 0x20   cc  -->   "^"<char>
 *                      where char is evaluated from cc.
 *                      <char> ( 1 ) = 'A' and 
 *                      <char> ( n ) = <char> ( n - 1 ) + 1
 *                      where 2 < n < 0x20
 *      cc = 0          cc  -->  "^@"
 *      cc = 0x7f       cc  -->  "^?"
 *      0x20 <= cc < 0x7f  cc  -->  cc
 *      cc > 0x7f          cc  -->  \<code>
 *                         where code is the three digit octal code
 */

int str_rcntl2a ( char **dest, int dlen, const void *mem, int len ) {
  unsigned char *s =  (unsigned char *) mem;
  char *d =  *dest;
  int ret;
  while ( ( dlen > 1 ) && ( len-- > 0 ) ) {
    if ( ( *s < 0x20 ) || ( *s >= 0x7f ) ) {
      if ( *s < 0x20 ) {
        if ( !*s ) dlen -=  str_rcpy ( &d, dlen, "^@" );
	else {
	  dlen -=  str_rchcpy ( &d, dlen, '^', 1 );
	  dlen -=  str_rchcpy ( &d, dlen, 'A' + *s - 1, 1 );
      } }
      else {
	if ( *s == 0x7f ) dlen -=  str_rcpy ( &d, dlen, "^?" );
	else if ( dlen > 4 ) {
	  unsigned h = *s >> 6, 
	           m = (unsigned) ( *s & 0x38 ) >> 3, 
	           l = *s & 0x07;
	  *d++ =  '\\'; 
	  *d++ =  _hexdigits [h];
	  *d++ =  _hexdigits [m];
	  *d++ =  _hexdigits [l];
	  dlen -=  4;
	}
	else break;
      }
      s++;
    }
    else { *d++ = (char) *s++; dlen--; }
  }
  *d =  '\0';
  ret =  (int)(d - *dest);
  *dest =  d;
  return ret;
}


/*
 *  PROCEDURE  int str_cntl2a ( char *dest, int dlen, const void *mem, 
 *                              int len )
 *             =========================================================
 * 
 *             char *dest      :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const void *mem :  ptr to memory area;
 *             int len         :  nb. of bytes to convert;
 *             VALUE           :  #chars copied to dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_cntl2a' is used to convert 'len' bytes from 'mem' to a string 
 *  representation at 'dest'. Each non printable character is converted 
 *  to its ascii representation with following substitutions:
 *  (let cc be the control character to convert).
 *      0 < cc < 0x20   cc  -->   "^"<char>
 *                      where char is evaluated from cc.
 *                      <char> ( 1 ) = 'A' and 
 *                      <char> ( n ) = <char> ( n - 1 ) + 1
 *                      where 2 < n < 0x20
 *      cc = 0          cc  -->  "^@"
 *      cc = 0x7f       cc  -->  "^?"
 *      0x20 <= cc < 0x7f  cc  -->  cc
 *      cc > 0x7f          cc  -->  \<code>
 *                         where code is the three digit octal code
 */

int str_cntl2a ( char *dest, int dlen, const void *mem, int len ) {
  return str_rcntl2a ( &dest, dlen, mem, len );
}


/*
 *  PROCEDURE  int str_rbin2hex ( char **dest, int dlen, const void *mem, 
 *                                int len )
 *             ==========================================================
 * 
 *             char **dest     :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const void *mem :  ptr to memory area;
 *             int len         :  nb. of bytes to convert;
 *             VALUE           :  #chars copied to *dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_rbin2hex' is used to convert 'len' bytes from 'mem' to a string 
 *  representation at 'dest'. Each byte is converted two two characters
 *  (ie. the hexadecimal representation uppercase).
 */

int str_rbin2hex ( char **dest, int dlen, const void *mem, int len ) {
  int ret =  0;
  if ( dest && *dest && mem ) {
    unsigned char *s =  (unsigned char *) mem;
    char *d =  *dest;
    while ( ( dlen > 2 ) && ( len-- > 0 ) ) {
      byte2hex ( d, s );
      dlen -= 2;
    }
    *d =  '\0';
    ret =  (int)(d - *dest);
    *dest =  d;
  }
  return ret;
}


/*
 *  PROCEDURE  int str_bin2hex ( char *dest, int dlen, const void *mem, 
 *                               int len )
 *             ========================================================
 * 
 *             char *dest      :  where to write string to;
 *             int dlen        :  length of 'dest' (incl. \0);
 *             const void *mem :  ptr to memory area;
 *             int len         :  nb. of bytes to convert;
 *             VALUE           :  #chars copied to dest (without \0);
 *             LINKAGE         :  C;
 *
 *  'str_bin2hex' is used to convert 'len' bytes from 'mem' to a string 
 *  representation at 'dest'. Each byte is converted two two characters
 *  (ie. the hexadecimal representation uppercase).
 */

int str_bin2hex ( char *dest, int dlen, const void *mem, int len ) {
  return str_rbin2hex ( &dest, dlen, mem, len );
}


/*
 *  PROCEDURE  int str_vhex2bin ( void **dest, int dlen, va_list vp )
 *             ======================================================
 * 
 *             void **dest     :  where to write bytes to;
 *             int dlen        :  length of 'dest' (max. #bytes to write);
 *             va_list vp      :  list of strings of hex digits;
 *             VALUE           :  #bytes copied to *dest;
 *             LINKAGE         :  C;
 *
 *  'str_vhex2bin' is used to convert max. 'dlen' bytes from hex strings
 *  stored in the list of strings refered by vp.
 *  The hex digits to convert may be upper or lower case.
 */

int str_vhex2bin ( void **dest, int dlen, va_list vp ) {
  int ret =  0;
  if ( dest && *dest && vp ) {
    unsigned char *d =  *( (unsigned char **) dest );
    const char *s;
    while ( (s =  va_arg ( vp, const char * )) )
      while ( *s && isxdigit ( *s ) && (dlen >0) ) {
	hex2byte ( d, s );
	dlen--;
      }
    ret =  (int)(d - *( (unsigned char **) dest ));
    *( (unsigned char **) dest ) =  d;
  }
  return ret;
}


/*
 *  PROCEDURE  int str_rmhex2bin ( void **dest, int dlen, const char *str, ... )
 *             =================================================================
 * 
 *             void **dest     :  where to write bytes to;
 *             int dlen        :  length of 'dest' (max. #bytes to write);
 *             const char *str :  string(s) of hex digits;
 *             VALUE           :  #bytes copied to *dest;
 *             LINKAGE         :  C;
 *
 *  'str_rhex2bin' is used to convert max. 'len' bytes from a hex string
 *  stored in 'str' to *dest.
 *  The hex digits to convert may be upper or lower case.
 */

int str_rmhex2bin ( void **dest, int dlen, ... ) {
  int ret;
  va_list vp;
  va_start ( vp, dlen );
  ret =  str_vhex2bin ( dest, dlen, vp );
  va_end ( vp );
  return ret;
}


/*
 *  PROCEDURE  int str_mhex2bin ( void *dest, int dlen, const char *str, ... )
 *             ===============================================================
 * 
 *             void *dest      :  where to write bytes to;
 *             int dlen        :  length of 'dest' (max. #bytes to write);
 *             const char *str :  string(s) of hex digits;
 *             VALUE           :  #bytes copied to dest;
 *             LINKAGE         :  C;
 *
 *  'str_mhex2bin' is used to convert max. 'len' bytes from a hex string
 *  stored in 'str' to *dest.
 *  The hex digits to convert may be upper or lower case.
 */

int str_mhex2bin ( void *dest, int dlen, ... ) {
  int ret;
  va_list vp;
  va_start ( vp, dlen );
  ret =  str_vhex2bin ( &dest, dlen, vp );
  va_end ( vp );
  return ret;
}


/*
 *  PROCEDURE  int str_rhex2bin ( void **dest, int dlen, const char *str )
 *             ===========================================================
 * 
 *             void **dest     :  where to write bytes to;
 *             int dlen        :  length of 'dest' (max. #bytes to write);
 *             const char *str :  string of hex digits;
 *             VALUE           :  #bytes copied to *dest;
 *             LINKAGE         :  C;
 *
 *  'str_rhex2bin' is used to convert max. 'len' bytes from a hex string
 *  stored in 'str' to *dest.
 *  The hex digits to convert may be upper or lower case.
 */

int str_rhex2bin ( void **dest, int dlen, const char *str ) {
  return str_rmhex2bin ( dest, dlen, str, (const char *) 0 );
}


/*
 *  PROCEDURE  int str_hex2bin ( void *dest, int dlen, const char *str )
 *             =========================================================
 * 
 *             void *dest      :  where to write bytes to;
 *             int dlen        :  length of 'dest' (max. #bytes to write);
 *             const char *str :  string of hex digits;
 *             VALUE           :  #bytes copied to dest;
 *             LINKAGE         :  C;
 *
 *  'str_hex2bin' is used to convert max. 'len' bytes from a hex string
 *  stored in 'str' to dest.
 *  The hex digits to convert may be upper or lower case.
 */

int str_hex2bin ( void *dest, int dlen, const char *str ) {
  return str_mhex2bin ( dest, dlen, str, (const char *) 0 );
}


/*
 *  PROCEDURE  int str_rl2a ( char **dest, int len, unsigned long val,
 *                            int base )
 *             =======================================================
 *
 *             char **dest       :  where to store the string;
 *             int len           :  lenget of *dest;
 *             unsigned long val :  value to convert;
 *             int base          :  base to use for representation;
 *             VALUE             :  number of chars written to *dest (excl. \0);
 *             LINKAGE           :  C;
 *
 *  'str_rl2a' is used to convert an unsigned long number to its
 *  ascii representation.
 */

int str_rl2a ( char **dest, int len, unsigned long val, int base ) {
  return cvt_l2a ( dest, &len, val, base );
}


/*
 *  PROCEDURE  int str_l2a ( char *dest, int len, unsigned long val,
 *                           int base )
 *             ======================================================
 *
 *             char *dest        :  where to store the string;
 *             int len           :  lenget of *dest;
 *             unsigned long val :  value to convert;
 *             int base          :  base to use for representation;
 *             VALUE             :  number of chars written to *dest (excl. \0);
 *             LINKAGE           :  C;
 *
 *  'str_l2a' is used to convert an unsigned long number to its
 *  ascii representation.
 */

int str_l2a ( char *dest, int len, unsigned long val, int base ) {
  return str_rl2a ( &dest, len, val, base );
}


/*
 *  PROCEDURE  int str_rdec2a ( char **dest, int len, unsigned long val,
 *                              int ndig )
 *             =========================================================
 *
 *             char **dest       :  where to store the string;
 *             int len           :  lenget of *dest;
 *             unsigned long val :  value to convert;
 *             int ndig          :  number of digits to write;
 *             VALUE             :  number of chars written to *dest (excl. \0);
 *             LINKAGE           :  C;
 *
 *  'str_rdec2a' is used to convert an unsigned long decimal number to its
 *  ascii representation. If there are less than 'ndig' digits to write
 *  leading '0' are used to write exactly 'ndig' digits.
 */

int str_rdec2a ( char **dest, int len, unsigned long val, int ndig ) {
  return cvt_l2a ( dest, &len, val, 10, ndig, cvt_zeroextend_c );
}


/*
 *  PROCEDURE  int str_dec2a ( char *dest, int len, unsigned long val,
 *                             int ndig )
 *             ========================================================
 *
 *             char *dest        :  where to store the string;
 *             int len           :  length of dest;
 *             unsigned long val :  value to convert;
 *             int ndig          :  base to use for representation;
 *             VALUE             :  number of chars written to *dest (excl. \0);
 *             LINKAGE           :  C;
 *
 *  'str_dec2a' is used to convert an unsigned long decimal number to its
 *  ascii representation (see str_rdec2a).
 */

int str_dec2a ( char *dest, int len, unsigned long val, int ndig ) {
  return str_rdec2a ( &dest, len, val, ndig );
}


/*
 *  PROCEDURE  int str_ra2l ( unsigned long *rval, const char **rstr,
 *                            int base )
 *             ======================================================
 *
 *             unsigned long *rval :  where to store evaluated number;
 *             const char **rstr   :  ref to string to convert;
 *             int base            :  base to use for convertion;
 *             VALUE               :  #chars converted;
 *             LINKAGE             :  C;
 *
 *  'str_ra2l' is used to convert a string representing an unsigned long
 *  value to binary format.
 *  Leading white space is skipped.
 */

int str_ra2l ( unsigned long *rval, const char **str, int base ) {
  return cvt_a2l ( rval, str, base );
}


/*
 *  PROCEDURE  int str_a2l ( unsigned long *rval, const char *str,
 *                           int base )
 *             ===================================================
 *
 *             unsigned long *rval :  where to store evaluated number;
 *             const char *str     :  ref to string to convert;
 *             int base            :  base to use for convertion;
 *             VALUE               :  #chars converted;
 *             LINKAGE             :  C;
 *
 *  'str_a2l' is used to convert a string representing an unsigned long
 *  value to binary format.
 */

int str_a2l ( unsigned long *rval, const char *str, int base ) {
  return str_ra2l ( rval, &str, base );
}


/*
 *  PROCEDURE  int str_bin2fhex ( char *dest, int dlen, const void *src,
 *                                int len, unsigned long addr )
 *             =========================================================
 *
 *             char *dest         :  where to write to;
 *             int dlen           :  length of dest (incl. \0);
 *             const void *src    :  binary data to read;
 *             int len            :  number of bytes to format;
 *             unsigned long addr :  start address to use;
 *             VALUE              :  #chars written to dest;
 *             LINKAGE            :  C;
 *
 *  'str_bin2fhex' is used to format a binary area of data into a string buffer.
 *  The fomatted result is organized in rows of the following format:
 *    address hexstring * asciistring
 *  where the 'address' is initialized with 'addr', 'hexstring' is a string
 *  of hex digits representing the data and 'asciistring' is a sequence of
 *  chars representing the printable chars of data.
 */

int str_bin2fhex ( char *dest, int dlen, const void *src, int len,
                   unsigned long addr ) {
  int ret =  0;
  if ( dest && src ) {
    unsigned char *s =  (unsigned char *) src;
    char *d =  dest;
    char tmp [20];
    int olen =  dlen, i;
    while ( ( len > 0 ) && ( dlen > 80 ) ) {
      i =  8 - str_l2a ( tmp, 20, addr, 10 );
      while ( i-- > 0 ) *d++ = '0';
      str_rcpy ( &d, 9, tmp );
      *d++ =  ' '; *d++ =  ' ';
      for ( i = 0; ( i < 16 ) && ( len > 0 ); i++, len-- ) {
	*d++ =  ' '; 
	byte2hex ( d, s );
      }
      len += i; s -= i;
      while ( i++ < 16 ) { *d++ =  ' '; *d++ =  ' '; *d++ = ' '; }
      *d++ =  ' '; *d++ =  ' '; *d++ = ' ';
      *d++ = '*';
      for ( i = 0; ( i < 16 ) && ( len > 0 ); i++, s++, len-- ) {
	if ( isprint ( *s ) ) *d++ =  *s;
	else *d++ =  '.';
      }
      while ( i++ <= 16 ) *d++ =  '*';
      *d++ =  '\n';
      dlen -=  80;
      addr +=  16;
    }
    ret =  olen - dlen;
    *d =  '\0';
  }
  return ret;
}


#ifdef dCfgVerify

#include  <north/verify.h>

vrf_start ( "strcvt: string conversion functions" )
  char buff [1024], buff2 [1024];
  char *ptr =  buff;
  int len =  1024;
  unsigned long l;
  int ret;
  const char *t1 =  "\001huhu\002\n";
  vrf_item ( str_bin2a ( buff, 1024, t1, 8 ) );
  vrf_verify ( !str_cmp ( buff, "[SOH]huhu[STX][LF][NUL]" ) );
  vrf.eprint ( "    buff = \"%s\"\n", buff );
  vrf_item ( str_bin2hex ( buff, 1024, t1, 8 ) );
  vrf_verify ( !str_cmp ( buff, "0168756875020A00" ) );
  vrf.eprint ( "    buff = \"%s\"\n", buff );
  vrf_item ( str_hex2bin ( buff2, 1024, buff ) );
  vrf_verify ( !str_cmp ( buff2, t1 ) );
  vrf_item ( str_l2a ( buff, 1024, 1024L, 10 ) );
  vrf_verify ( !str_cmp ( buff, "1024" ) );
  vrf_item ( str_dec2a ( buff, 1024, 1024L, 6 ) );
  vrf_verify ( !str_cmp ( buff, "001024" ) );
  vrf_item ( ret = str_a2l ( &l, buff, 10 ) );
  vrf_verify ( ( ret == 6 ) && ( l == 1024L ) );
  vrf_item ( ret = cvt_d2a ( &ptr, &len, 1.234e10, 10, 4 ) );
  vrf_verify ( ( ret == 9 ) && ( len == 1015 ) &&
               !str_cmp ( buff, "1.234e+10" ) );
  vrf.eprint ( "    buff = \"%s\", ret = %d, len = %d\n", buff, ret, len );
  ptr =  buff; len =  1024;
  vrf_item ( ret = cvt_d2a ( &ptr, &len, 1.234e10, 16, 4 ) );
  vrf_verify ( ( ret == 9 ) && ( len == 1015 ) &&
               !str_cmp ( buff, "2.df8_+08" ) );
  vrf.eprint ( "    buff = \"%s\", ret = %d, len = %d\n", buff, ret, len );
vrf_end ( vrf.errors () )

#endif /* dCfgVerify */
