/*
 *  Functions and classes operating on numeric data:
 */

#ifndef  _numeric_h
#define  _numeric_h

#ifdef  __cplusplus

/* Exports of float.cc */
int flt_exponent ( double d, int base = 10, double *dret = 0 );
double flt_mantissa ( double d, int base = 10, int *pexp = 0 );

#endif  /* __cplusplus */

#endif  /* _numeric_h */
