//
//  regexpr.cpp
//
//  Created by Norbert Thies on 23.01.2022
//

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include "strext.h"

// compile regular expression
void regexpr_t::compile(void) {
  if (re) return;
  regex_t *ret = (regex_t *)malloc(sizeof(regex_t));
  if ( ret && regcomp(ret, pattern, flags) == 0 ) {
    re = ret;
    return;
  }
  if ( ret ) free(ret);
}

bool regexpr_t::ok() {
  compile();
  return re? true : false;
}

// substitute @-escape sequences
static char *decode_special(const char *s) {
  int dlen = 13 * str_len(s) + 1;
  char *tmp = (char *) alloca(dlen);
  if (tmp) {
    char *d = tmp;
    while (*s) {
      if (*s == '@') {
        s++;
        switch (*s) {
          case 'd': dlen -= str_cpy(&d, dlen, "[[:digit:]]"); break;
          case 'D': dlen -= str_cpy(&d, dlen, "[^[:digit:]]"); break;
          case 's': dlen -= str_cpy(&d, dlen, "[[:space:]]"); break;
          case 'S': dlen -= str_cpy(&d, dlen, "[^[:space:]]"); break;
          case 'a': dlen -= str_cpy(&d, dlen, "[[:alpha:]]"); break;
          case 'A': dlen -= str_cpy(&d, dlen, "[^[:alpha:]]"); break;
          case 'w': dlen -= str_cpy(&d, dlen, "[[:alnum:]_]"); break;
          case 'W': dlen -= str_cpy(&d, dlen, "[^[:alnum:]_]"); break;
          case '@': *d++ = *s; dlen--; break;
        }
      } else { *d++ = *s; dlen--; }
      s++;
    }
    *d++ = '\0';
    return str_heap(tmp);
  }
  return 0;
}

regexpr_t::regexpr_t(const char *pattern) {
  this -> pattern = decode_special(pattern);
  this -> flags = REG_EXTENDED;
}

regexpr_t::~regexpr_t() {
  if (ok()) {
    regfree(re);
    free(re);
} }

bool regexpr_t::matches(const char *str) {
  return ok() && regexec(re, str, 0, 0, 0) == 0;
}

int regexpr_t::nmatches(void) {
  return ok()? re->re_nsub + 1 : 0;
}

regmatch_t *regexpr_t::match_offsets(const char **str) {
  if (ok()) {
    int n = nmatches();
    regmatch_t *matches = (regmatch_t *)calloc(n, sizeof(regmatch_t));
    if (matches) {
      if ( regexec(re, *str, n, matches, 0) == 0 ) {
        if (matches[0].rm_eo >= 0) *str += matches[0].rm_eo;
        return matches;
      }
    }
    if (matches) free(matches);
  }
  return 0;
}

char **regexpr_t::match(const char **rstr) {
  const char *str = *rstr;
  regmatch_t *matches = match_offsets(rstr);
  if (matches) {
    int n = nmatches();
    char **ret = (char **)calloc(n+1, sizeof(char *));
    if (ret) {
      regmatch_t *m = matches;
      char **s = ret;
      for (int i=0; i<n; i++, m++, s++) {
        if (m->rm_so >= 0 && m->rm_eo >= 0) {
          *s = str_heap(str+m->rm_so, m->rm_eo - m->rm_so);
        } else *s = str_heap("");
      }
      free(matches);
      return ret;
    }
    free(matches);
  }
  return 0;
}

char **regexpr_t::match(const char *str) {
  return match(&str);
}

bool regexpr_t::subst(strbuff_t *buff, const char **rstr, const char *with,
                      int lino, int ndig) {
  const char *str = *rstr;
  regmatch_t *matches = match_offsets(rstr);
  if (matches) {
    buff->put(str, matches[0].rm_so); // not matching initial part
    const char *p = with;
    int n = nmatches();
    while (*p) {
      if (*p == '&') {
        int idx = 0;
        p++;
        if (isdigit(*p)) {
          const char *mark = p;
          while (isdigit(*p)) p++;
          idx = atoi(mark);
        }
        else if (*p == '&') { buff->put(*p++); continue; }
        if (idx < n) {
          regmatch_t *m = matches + idx;
          if (m->rm_so >= 0 && m->rm_eo >= 0) {
            buff->put(str+m->rm_so, m->rm_eo-m->rm_so);
          }
        }
      }
      else if (*p == '#' && lino >= 0) {
        char tmp[101];
        p++;
        if (ndig > 0) snprintf(tmp, 100, "%*d", ndig, lino);
        else snprintf(tmp, 100, "%d", lino);
        buff->put(tmp);
      }
      else buff->put(*p);
    }
    buff->put(str+matches[0].rm_eo); // trailing part
    free(matches);
    return true;
  }
  return false;
}

char *regexpr_t::subst(const char **rstr, const char *with,
                      int lino, int ndig) {
  strbuff_t buff;
  if (subst(&buff, rstr, with, lino, ndig)) return buff.heap();
  else return 0;
}

bool regexpr_t::gsubst(strbuff_t *buff, const char **rstr, const char *with,
                       int lino, int ndig) {
  bool ret = false;
  while (subst(buff, rstr, with, lino, ndig)) { ret = true; }
  return ret;
}

char *regexpr_t::gsubst(const char **rstr, const char *with,
                        int lino, int ndig) {
  strbuff_t buff;
  if (gsubst(&buff, rstr, with, lino, ndig)) return buff.heap();
  else return 0;
}


// C interface:
re_t *re_init(const char *pattern) { return (re_t *) new regexpr_t(pattern); }
void re_realease(re_t *re) { delete (regexpr_t *)re; }
void re_set_sensnl(re_t *re) { ((regexpr_t *)re)->set_sensnl(); }
void re_set_noresult(re_t *re) { ((regexpr_t *)re)->set_noresult(); }
bool re_matches(re_t *re, const char *str) { ((regexpr_t *)re)->matches(str); }
char **re_match(re_t *re, const char *str) { ((regexpr_t *)re)->match(str); }
char **re_rmatch(re_t *re, const char **str) { ((regexpr_t *)re)->match(str); }
char *re_subst(re_t *re, const char **rstr, const char *with)
  { return ((regexpr_t *)re)->subst(rstr, with); }
char *re_nsubst(re_t *re, const char **rstr, const char *with, int lino, int ndig)
  { return ((regexpr_t *)re)->subst(rstr, with, lino, ndig); }
char *re_gsubst(re_t *re, const char **rstr, const char *with)
  { return ((regexpr_t *)re)->gsubst(rstr, with); }
char *re_ngsubst(re_t *re, const char **rstr, const char *with, int lino, int ndig)
  { return ((regexpr_t *)re)->gsubst(rstr, with, lino, ndig); }
