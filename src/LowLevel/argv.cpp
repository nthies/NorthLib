//
//  argv.c
//
//  Created by Norbert Thies on 17.02.1987.
//  Copyright © 1987 Norbert Thies. All rights reserved.
//

#include  <stdlib.h>
#include  <ctype.h>
#include  "strext.h"
      
/**
 * av_const returns a const argv array (as simple cast)
 */
const char * const *av_const(char **argv) {
  return argv;
}

/**
 *  av_release releases an array of allocated strings.
 *  The last string in 'argv' must be a 0 pointer.
 *  Each string must have been allocated separately. 
 *  
 *  @param argv pointer to array of allocated strings
 *  @return 0: OK - array and strings released
 *  @return -1: Error detected
 */
int av_release(char **argv) {
  if ( argv ) {
    char **p =  argv;
    while ( *p ) free ( *(p++) );
    free ( argv );
    return 0;
  }
  else return -1;
}

/**
 *  av_index returns the i'th array element.
 *
 *  @param argv pointer to array of allocated strings
 *  @param i index into array
 *  @return i'th element of array
 */
char *av_index(char **argv, int i) {
  return argv[i];
}

/// av_length returns the number of strings in 'argv'.
int av_length(const char * const *argv) {
  if (!argv) return 0;
  const char * const *p =  argv;
  int val =  0;
  while ( *(p++) ) val ++;
  return val;
}

/**
 * av_size counts all characters beeing referenced by any string
 * stored in argv [0] ... argv [n-1].
 * There is no trailing zero byte counted!
 * Warning: the members of 'argv' (ie. argv[i]) are expected to be \0-
 *          terminated strings.
 */
int av_size(char **argv) {
  int val =  0;
  while ( *argv ) val +=  str_len(*(argv++));
  return val;
}

/**
 * av_heap allocates a new array of strings and initializes it.
 * 
 * av_heap is used to allocate a new argv-structured array and to
 * copy the data from 'argv' to it. If len <> 0, then each element
 * argv[i] is expected of size 'len' and as many bytes are allocated
 * for each element of the retuned array.
 */
char **av_heap(const char * const *argv, int len) {
  char **ret =  0;
  const char * const *p =  argv;
  if ( p ) {
    int n =  av_length ( argv );
    if ( (ret =  (char **) calloc ( n + 1, sizeof ( char * ) )) ) {
      char **d =  ret;
      while ( *p ) {
	int l =  len? len : ( str_len ( *p ) + 1 );
	if ( (*d =  (char *) malloc ( l )) ) mem_cpy ( *d, *p, l );
        else { av_release ( ret ); ret =  0; }
	p++; d++;
  } } } 
  return ret;
}

/**
 * av_alloc returns a new allocated char**
 *
 * It allocates space for len+1 char pointer, all pointers are initialized
 * with (char *) 0.
 *
 *  @param len size of array - 1
 *  @return new allocated char*[] containing len+1 char*
 */
char **av_alloc(int len) {
  return (char **) calloc(len+1, sizeof(char *));
}

/// av_clone returns a deep copy of 'argv'.
char **av_clone(char **argv) {
  return av_heap(argv, 0);
}

/// Increase array by n elements
static char **av_increase(char **argv, int n) {
  if (n > 0) {
    int l = av_length((char **) argv);
    int size = l + n + 1;
    char **tmp;
    if (argv) tmp = (char **)realloc(argv, size * sizeof(char*));
    else tmp = (char **)calloc(size, sizeof(char *));
    if (tmp) {
      int i;
      for (i = l; i < size; i++) { tmp[i] = 0; }
      return tmp;
    }
  }
  return 0;
}

/**
 * av_a2av converts a string into an argv structured array of strings.
 * 
 * av_a2av is used to convert a string consisting of blank- or
 * tab separated lists of words into an argv format.
 * Quoted string parts are copied including white space to 
 * the resulting array member. 'av_a2av' may be interpreted as 
 * reverse operation to 'av_av2a'.
 * The delimiter may be used to process eg. PATH structured strings.
 * Eg. "a:b:c" with delimiter ':' will be converted to following array:
 *      ( "a", "b", "c" )
 * A delimiter of 0 implies using white space as delimiter.
 */
char **av_a2av(const char *str, char delim) {
  char **ret =  0;
  int i = 1, n = 20;
  if ( str && ( ret = av_increase(0, n) ) ) {
    int blen = str_len(str) + 1;
    char *buff = (char *)malloc(blen * sizeof(char));
    char **p =  ret;
    const char *s;
    do {
      s =  str_substring(&str, buff, blen, delim);
      if ( !( *p++ =  str_heap(buff, 0) ) ) { av_release(ret); return 0; }
      if (++i > n) {
        char **tmp = av_increase(ret, n+=20);
        if (tmp) ret = tmp;
        else { av_release(ret); return 0; }
      }
    } while ( s );
    ret = (char **)realloc(ret, i * sizeof(char *));
  }
  return ret;
}
 
/**
 * av_av2a converts an array of strings into a string.
 * 
 * 'av_av2a' is used to write an argv list to a string buffer; if a string
 * av[i] contains white space or a " or a \
 * then av [i] will be quoted and each \ and " will be preceeded by
 * a backslash (\).
 * If delim <> 0, then each string will be separated by a delimiter character
 * 'delim' from its follower.
 * 
 * - returns: 'characters written to 'buff'.
 */
int av_av2a(char *buff, int blen, char **av, char delim) {
  if ( buff && av ) {
    int l =  blen;
    if ( !delim ) delim =  ' ';
    while ( *av && ( l > 2 ) ) {
      if ( ( !**av && ( delim == ' ' ) ) || str_pbrk ( *av, "\\\" \t\n\r\f" ) )
        l -=  str_rqcpy ( &buff, l - 1, *av );
      else l -=  str_rcpy ( &buff, l - 1, *av );
      if ( *++av ) { *buff++ =  delim; l--; }
    }
    *buff =  '\0';
    return blen - l;
  }
  else return 0;
}

/**
 * av_vinsert inserts a list of strings into an argv-structured string array.
 * 
 * av_vinsert is used to insert a list of strings (terminated by
 * (const char *) 0) into the argv array 'av'. 'pos' defines, in front
 * of which position the list of strings is to insert. pos = 0 identifies
 * the first position. If pos > av_length(av) or pos < 0, then
 * the string list is appended to 'av'.
 * 
 * - returns: the reallocated string array
 */
char **av_vinsert(char **av, int pos, va_list vp) {
  char **ret =  0;
  if ( av && vp ) {
    va_list v;
    int i, n =  0;
    va_copy ( v, vp );
    while ( va_arg ( v, const char * ) ) n++;
    if ( n ) {
      int l =  av_length(av);
      if ( (ret =  (char **) malloc ( (n+l+1) * sizeof ( char * ) )) ) {
	const char *s;
	char **p =  ret, **a =  av;
	if ( ( pos < 0 ) || ( pos > l ) ) pos =  l;
	for ( i = 0; i < pos; i++ ) *p++ =  *a++;
	while ( (s =  va_arg ( vp, const char * )) ) 
	  *p++ =  str_heap ( s, 0 );
	while ( *a ) *p++ =  *a++;
	free ( av );
	*p =  0;
    } }
    else return av;
  }
  return ret;
}

/*
 *  av_minsert is used to insert a list of strings (terminated by
 *  (const char *) 0) into 'av'. For more information refer to 'av_vinsert'.
 */
char **av_minsert(char **av, int pos, ...) {
  char **ret;
  va_list vp;
  va_start ( vp, pos );
  ret =  av_vinsert ( av, pos, vp );
  va_end ( vp );
  return ret;
}

/// av_insert inserts a string into an argv-array.
char **av_insert(char **av, int pos, const char *s) {
  return av_minsert ( av, pos, s, (const char *) 0 );
}

/// av_vappend appends a list of strings to 'av'.
char **av_vappend(char **av, va_list vp) {
  return av_vinsert (av, -1, vp);
}

/// av_mappend appends multiple strings to 'av'.
char **av_mappend(char **av, ...) {
  char **ret;
  va_list vp;
  va_start ( vp, av );
  ret =  av_vinsert ( av, -1, vp );
  va_end ( vp );
  return ret;
}

/// av_append appends a string to 'av'.
char **av_append(char **av, const char *s) {
  return av_minsert(av, -1, s, (const char *) 0);
}

/// av_avinsert inserts one argv-array into another.
char **av_avinsert(char **av, int pos, char **arg) {
  char **ret =  0;
  if ( av && arg ) {
    int i, n =  av_length ( arg );
    if ( n ) {
      int l =  av_length(av);
      if ( (ret =  (char **) malloc ( (n+l+1) * sizeof ( char * ) )) ) {
	char **p =  ret, **a =  av;
        char **s =  arg;
	if ( ( pos < 0 ) || ( pos > l ) ) pos =  l;
	for ( i = 0; i < pos; i++ ) *p++ =  *a++;
	while ( *s ) *p++ =  str_heap ( *s++, 0 );
	while ( *a ) *p++ =  *a++;
	free ( av );
	*p =  0;
    } }
    else return av;
  }
  return ret;
}

/**
 * av_delete deletes a number of strings from an argv-array.
 * 
 * av_delete is used to delete a number of strings from 'av'.
 * Ie. the strings av[from] ... av[to] are deleted. If to < 0 or
 * to >= av_length ( av ), then 'to' is set to av_length(av) - 1.
 * The first array index is always 0.
 * Warning: 'av' is not reallocated (so be aware of wasted space)!
 * 
 * - returns: av
 */
char **av_delete(char **av, int from, int to) {
  if ( av ) {
    int i, l =  av_length(av);
    if ( ( from >= 0 ) && ( from < l ) ) {
      char **d =  av + from, **s =  av + from;
      if ( to >= l ) to =  l - 1;
      for ( i = from; i <= to; i++ ) free ( s++ );
      while ( (*s++ = *d++) );
  } }
  return av;
}
