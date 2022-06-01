/*
 * Functions and classes operating on floating point numbers:
 */

#include  <stdlib.h>
#include  <limits>
#include  <float.h>
#include  <math.h>
#include  "sysdef.h"
#include  "string.h"
#include  "numeric.h"

#ifdef DBL_MAX
# define MaxDouble DBL_MAX
#else
# ifdef MAXDOUBLE
#   define MaxDouble MAXDOUBLE
# endif
#endif

#ifdef DBL_MIN
# define MinDouble DBL_MIN
#else
# ifdef MINDOUBLE
#   define MinDouble MINDOUBLE
# endif
#endif

// The exponent table:

struct flt_exentry_s {
  double dval;
  int    ival;
};

class flt_exptable_t {
  public:
    int            base;
    int            nentries;
    flt_exentry_s *tbl;
    int make ( int base );
    int ok ( void ) const { return tbl? 1 : 0; }
    flt_exptable_t ( int base = 10 );
    ~flt_exptable_t ( void );
    static flt_exptable_t *tbl_10;
};

static flt_exptable_t *tbl_10 = 0;

/*
 * 'make' is used to create an exponent table in implicitly passed
 *  object according to the base 'base'.
 */

int flt_exptable_t:: make ( int b ) {
  if ( ( base != b ) || !tbl ) {
    double dmax =  sqrt(MaxDouble), 
	   dmin =  sqrt(MinDouble),
	   d =  (double) b;
    int n = 1, exp =  1;
    flt_exentry_s *tmptbl =  (flt_exentry_s *) 
      calloc ( 40, sizeof ( flt_exentry_s ) );
    flt_exentry_s *p = tmptbl, *dest = p;
    if ( p ) {
      base =  b;
      if ( tbl ) free ( tbl );
      p -> dval =  1.0;
      p++ -> ival =  0;
      while ( ( d < dmax ) && ( 1/d > dmin ) && ( n <= 40 ) ) {
	n++;
	p -> dval =  d;
	p++ -> ival =  exp;
	d *=  d;
	exp +=  exp;
      }
      while ( --p > dest ) {
	flt_exentry_s tmp =  *dest;
	*(dest++) = *p;
	*p =  tmp;
      }
      nentries =  n;
      tbl =  (flt_exentry_s *) realloc ( tmptbl, n * sizeof ( flt_exentry_s ) );
      return 0;
    }
    else return -1;
  }
  else return 0;
}


/*
 *  This constructor is used to create an exponent table to given
 *  base 'base'.
 */

flt_exptable_t:: flt_exptable_t ( int b ) {
  base =  nentries =  0;
  tbl =  0;
  make ( b );
}


/* 
 *  This destructor is used to release an optional allocated exponent
 *  table.
 */

flt_exptable_t:: ~flt_exptable_t ( void ) {
  if ( tbl ) free ( tbl );
}

/*
 *  'flt_exponent' is used to evaluate the exponent of a floating point number
 *  'd' according to base 'base'.
 *
 *  A floating point number is represented as:
 *      mantissa * ( base ** exponent )
 *  where 0.1 <= mantissa < 1
 *  The exponent is returned and if given, the value ( base ** exponent )
 *  is written to *dret.
 *
 * @param d    double value whose exponent is requested;
 * @param base base of exponent;
 * @param dret where base ** exp is stored;
 * @return exponent of 'd';
 *
 */
int flt_exponent ( double d, int base, double *dret ) {
  if ( base <= 1 ) return 0;
  else if ( !d ) {
    if ( dret ) *dret =  1;
    return 0;
  }
  else {
    int exp =  0;
    flt_exptable_t tbl =  base;
    if ( tbl.ok () ) {
      double ret =  1.0;
      flt_exentry_s *p =  tbl.tbl;
      if ( d < 0.0 ) d =  -d;
      if ( d >= 1.0 ) {
	exp =  1; ret =  base;
	do {
	  while ( d >= p -> dval )
	    { d /= p -> dval; ret *= p -> dval; exp += p -> ival; }
	  p ++;
	}
	while ( p -> ival );
      }
      else if ( d < ( 1.0 / (double) base ) )
	do {
	  while ( d < ( 1 / p -> dval ) )
	    { d *= p -> dval; ret /= p -> dval; exp -= p -> ival; }
	  p++;
	}
	while ( p -> ival );
      if ( dret ) *dret =  ret;
    }
    return exp;
} }


/*
 *  'flt_mantissa' is used to evaluate the mantissa of a floating point number
 *  'd' according to base 'base'.
 *
 *  A floating point number is represented as:
 *      mantissa * ( base ** exponent )
 *  where 0.1 <= mantissa < 1
 *  The mantissa is returned and if given, the exponent is written to *pexp.
 *
 *  @param d     double value whose mantissa is requested;
 *  @param base  base of exponent;
 *  @param pexp  where the exponent is stored;
 *  @return      mantissa of 'd';
 */
  
double flt_mantissa ( double d, int base, int *pexp ) {
  double ex;
  int exp =  flt_exponent ( d, base, &ex );
  if ( pexp ) *pexp =  exp;
  return d /=  ex;
}


#ifdef dCfgVerify

#include  <north/verify.h>

inline double dist ( double d1, double d2 ) {
  double ret =  d1 - d2;
  return (ret < 0.0)? -ret : ret;
}

vrf_start ( "float: flt_functions" )
  double d; int i;
  vrf_item ( i = flt_exponent ( 1.234 ) );
  vrf_verify ( i == 1 );
  vrf_item ( d = flt_mantissa ( 1.234, 10, &i ) );
  vrf_verify ( dist ( d, 0.1234 ) < 0.0001 );
  vrf_verify ( i == 1 );
  vrf.eprint ( "  d = %g, i = %d\n", d, i );
  vrf_item ( d = flt_mantissa ( 0.456e10, 10, &i ) );
  vrf_verify ( dist ( d, 0.456 ) < 0.001 );
  vrf_verify ( i == 10 );
  vrf.eprint ( "  d = %g, i = %d\n", d, i );
  vrf_item ( d = flt_mantissa ( 0.0456e10, 10, &i ) );
  vrf_verify ( dist ( d, 0.456 ) < 0.001 );
  vrf_verify ( i == 9 );
  vrf.eprint ( "  d = %g, i = %d\n", d, i );
  vrf_item ( d = flt_mantissa ( 0.456e-10, 10, &i ) );
  vrf_verify ( dist ( d, 0.456 ) < 0.001 );
  vrf_verify ( i == -10 );
  vrf.eprint ( "  d = %g, i = %d\n", d, i );
  vrf_item ( d = flt_mantissa ( 0.0456e-10, 10, &i ) );
  vrf_verify ( dist ( d, 0.456 ) < 0.001 );
  vrf_verify ( i == -11 );
  vrf.eprint ( "  d = %g, i = %d\n", d, i );
  vrf_item ( d = flt_mantissa ( 4.56e-10, 10, &i ) );
  vrf_verify ( dist ( d, 0.456 ) < 0.001 );
  vrf_verify ( i == -9 );
  vrf.eprint ( "  d = %g, i = %d\n", d, i );
  vrf_item ( d = flt_mantissa ( 1.234e10, 16, &i ) );
  vrf_verify ( dist ( d, 0.179571 ) < 0.001 );
  vrf_verify ( i == 9 );
  vrf.eprint ( "  d = %g, i = %d\n", d, i );
vrf_end ( vrf.errors () )

#endif /* dCfgVerify */
