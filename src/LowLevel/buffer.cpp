/*
 *  buffer.cpp
 *
 */

#include  "strext.h"

// buffer_t methods:

int buffer_t:: write ( const char *str, int len ) {
  if ( str ) {
    if ( len < 0 ) len =  str_len ( str );
    return write ( (void *) str, len );
  }
  return -1;
}

int buffer_t:: write ( const char *str, va_list vp ) {
  int total =  0;
  while ( str ) {
    int ret =  write ( str );
    if ( ret < 0 ) return ret;
    str =  va_arg ( vp, const char * );
    total +=  ret;
  }
  return total;
}
    
int buffer_t:: write ( const char *s1, const char *s2, ... ) {
  int ret =  write ( s1 );
  if ( ret >= 0 ) {
    va_list vp;
    va_start ( vp, s2 );
    int ret2 =  write ( s2, vp );
    va_end ( vp );
    if ( ret2 >= 0 ) return ret + ret2;
    else return ret2;
  }
  else return ret;
}

int buffer_t:: read ( char **ptr, int &len ) {
  int ret =  read ( (void *) *ptr, len - 1 );
  if ( ret >= 0 ) {
    (*ptr) +=  ret;
    (*ptr) [ret] =  '\0';
    len +=  ret;
  }
  return ret;
}

int buffer_t:: readline ( char **ptr, int &len ) {
  if ( ptr && *ptr ) {
    char *p =  *ptr;
    int l =  1;
    while ( l < len ) {
      int ch =  getch ();
      if ( (ch != -1) && (ch != '\n') ) { *p++ = (char) ch; l++; }
      else break;
    }
    *p =  '\0';
    *ptr =  p;
    len -=  --l;
    return l;
  }
  return -1;
}
