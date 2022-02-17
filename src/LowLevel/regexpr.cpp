//
//  regexpr.cpp
//
//  Created by Norbert Thies on 23.01.2022
//

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <locale.h>
#include "strext.h"

/// Check for system locale, fall back to de_DE.UTF-8
const char *regexpr_t::locale_check() {
  char *ret = setlocale(LC_CTYPE, "");
  if (!ret || !str_cmp(ret, "C") || !str_cmp(ret, "POSIX"))
    ret = setlocale(LC_CTYPE, "de_DE.UTF-8");
  setlocale(LC_COLLATE, ret);
  return ret;
}
const char *regexpr_t::locale = locale_check();

// compile regular expression
void regexpr_t::compile(void) {
  if (re) return;
  regex_t *ret = (regex_t *)malloc(sizeof(regex_t));
  if ( ret && (last_err = regcomp(ret, pattern, flags)) == 0 ) {
    re = ret;
    return;
  }
  if ( ret ) free(ret);
}

char *regexpr_t::last_error() {
  compile();
  if (last_err) {
    char buff[2001];
    regerror(last_err, re, buff, 2000);
    return str_heap(buff);
  }
  else return 0;
}

bool regexpr_t::ok() {
  compile();
  return re? true : false;
}

// substitute @\-escape sequences
static char *decode_special(const char *s) {
  int dlen = 13 * str_len(s) + 1;
  char *tmp = (char *) alloca(dlen);
  if (tmp) {
    char *d = tmp;
    while (*s) {
      if (*s == '@' || *s == '\\') {
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
          case 'n': *d++ = '\n'; dlen--; break;
          case 'r': *d++ = '\r'; dlen--; break;
          case 't': *d++ = '\t'; dlen--; break;
          default:  *d++ = *s; dlen--; break;
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
  this -> re = 0;
}

void regexpr_t::set_pattern(const char *pattern) {
  clear();
  if (this->pattern) str_release(&(this->pattern));
  this->pattern = decode_special(pattern);
}

void regexpr_t::set_sensnl(int val) {
  clear();
  if (val) flags |= REG_NEWLINE;
  else flags &= ~REG_NEWLINE;
}

void regexpr_t::set_noresult(int val) {
  clear();
  if (val) flags |= REG_NOSUB;
  else flags &= ~REG_NOSUB;
}

void regexpr_t::set_icase(int val) {
  clear();
  if (val) flags |= REG_ICASE;
  else flags &= ~REG_ICASE;
}

void regexpr_t::clear() {
  if (re) {
    regfree(re);
    free(re);
    re = 0;
  }
}

regexpr_t::~regexpr_t() {
  clear();
  if (pattern) str_release(&pattern);
}

bool regexpr_t::matches(const char *str) {
  return ok() && (last_err = regexec(re, str, 0, 0, 0)) == 0;
}

int regexpr_t::nmatches(void) {
  return ok()? int(re->re_nsub) + 1 : 0;
}

regmatch_t *regexpr_t::match_offsets(const char **str) {
  if (ok()) {
    int n = nmatches();
    regmatch_t *matches = (regmatch_t *)calloc(n, sizeof(regmatch_t));
    if (matches) {
      if ( (last_err = regexec(re, *str, n, matches, 0)) == 0 ) {
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
          int len = (int)(m->rm_eo - m->rm_so);
          *s = str_heap(str+m->rm_so, len);
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

bool regexpr_t::subst(strbuff_t &buff, const char **rstr, const char *with,
                      int lino, int ndig) {
  const char *str = *rstr;
  regmatch_t *matches = match_offsets(rstr);
  if (matches && matches[0].rm_so < matches[0].rm_eo) {
    buff.write(str, (int)(matches[0].rm_so)); // not matching initial part
    const char *p = with;
    int n = nmatches();
    while (*p) {
      if (*p == '&' || *p == '\\') {
        char ch = *p;
        int idx = 0;
        p++;
        if (isdigit(*p)) {
          const char *mark = p;
          while (isdigit(*p)) p++;
          idx = atoi(mark);
        }
        else if (ch == '\\') {
          switch(*p) {
            case 'n': buff.cat('\n'); break;
            case 'r': buff.cat('\r'); break;
            case 't': buff.cat('\t'); break;
            default:  buff.cat('\\'); buff.cat(*p); break;
          }
          p++; continue;
        }
        if (idx < n) {
          regmatch_t *m = matches + idx;
          if (m->rm_so >= 0 && m->rm_eo >= 0) {
            int len = (int)(m->rm_eo - m->rm_so);
            buff.cat(str+m->rm_so, len);
          }
        }
      }
      else if (*p == '#' && lino >= 0) {
        char tmp[101];
        p++;
        if (ndig > 0) snprintf(tmp, 100, "%0*d", ndig, lino);
        else snprintf(tmp, 100, "%d", lino);
        buff.cat(tmp);
      }
      else buff.cat(*p++);
    }
    auto pos = buff.length();
    buff.cat(str+matches[0].rm_eo); // trailing part
    buff.position(pos);
    free(matches);
    return true;
  }
  return false;
}

char *regexpr_t::subst(const char **rstr, const char *with,
                      int lino, int ndig) {
  strbuff_t buff;
  if (subst(buff, rstr, with, lino, ndig)) return buff.heap();
  else return 0;
}

bool regexpr_t::gsubst(strbuff_t &buff, const char **rstr, const char *with,
                       int lino, int ndig) {
  bool ret = false;
  while (subst(buff, rstr, with, lino, ndig)) { ret = true; }
  return ret;
}

char *regexpr_t::gsubst(const char **rstr, const char *with,
                        int lino, int ndig) {
  strbuff_t buff;
  if (gsubst(buff, rstr, with, lino, ndig)) return buff.heap();
  else return 0;
}

// Interprete substitution pattern a la sed /pattern/substitution/g
// returns true if successfully decoded
static bool is_subst_pattern(strbuff_t &pattern, strbuff_t &subst, bool &is_global,
                             const char *s) {
  if (s && *s) {
    char delim = *s++;
    bool in_pattern = true;
    while (*s) {
      if (*s == '\\' && *(s+1) == delim) {
        if (in_pattern) pattern += *++s;
        else subst += *++s;
      }
      else if (*s == delim) {
        if (in_pattern) in_pattern = false;
        else {
          if (*++s == 'g') is_global = true;
          else is_global = false;
          return true;
        }
      }
      else {
        if (in_pattern) pattern += *s;
        else subst += *s;
      }
      s++;
    }
  }
  return false;
}

bool regexpr_t::is_valid_subst(const char *spec) {
  strbuff_t pattern;
  strbuff_t subst;
  bool is_global;
  if (is_subst_pattern(pattern, subst, is_global, spec)) {
    auto re = regexpr_t(pattern.value());
    if (re.ok()) return true;
  }
  return false;
}

char *regexpr_t::subst(const char *str, const char *spec, int lino, int ndig) {
  strbuff_t pattern;
  strbuff_t subst;
  bool is_global;
  if (is_subst_pattern(pattern, subst, is_global, spec)) {
    auto re = regexpr_t(pattern.value());
    if (!re.ok()) return 0;
    if (is_global) return re.gsubst(&str, subst.value(), lino, ndig);
    else return re.subst(&str, subst.value(), lino, ndig);
  }
  return 0;
}

// C interface:
re_t re_init(const char *pattern) { return (re_t) new regexpr_t(pattern); }
char *re_last_error(re_t re) { return ((regexpr_t *)re)->last_error(); }
void re_release(re_t re) { delete (regexpr_t *)re; }
void re_set_sensnl(re_t re, int val) { ((regexpr_t *)re)->set_sensnl(val); }
void re_set_icase(re_t re, int val) { ((regexpr_t *)re)->set_icase(val); }
void re_set_noresult(re_t re, int val) { ((regexpr_t *)re)->set_noresult(val); }
void re_set_pattern(re_t re, const char *pattern)
  { ((regexpr_t *)re)->set_pattern(pattern); }
int re_get_sensnl(re_t re) { return ((regexpr_t *)re)->get_sensnl(); }
int re_get_icase(re_t re) { return ((regexpr_t *)re)->get_icase(); }
int re_get_noresult(re_t re) { return ((regexpr_t *)re)->get_noresult(); }
const char *re_get_pattern(re_t re) { return ((regexpr_t *)re)->get_pattern(); }
int re_matches(re_t re, const char *str)
  { return ((regexpr_t *)re)->matches(str); }
char **re_match(re_t re, const char *str)
  { return ((regexpr_t *)re)->match(str); }
char **re_rmatch(re_t re, const char **str)
  { return ((regexpr_t *)re)->match(str); }
char *re_subst(re_t re, const char **rstr, const char *with)
  { return ((regexpr_t *)re)->subst(rstr, with); }
char *re_nsubst(re_t re, const char **rstr, const char *with, int lino, int ndig)
  { return ((regexpr_t *)re)->subst(rstr, with, lino, ndig); }
char *re_gsubst(re_t re, const char **rstr, const char *with)
  { return ((regexpr_t *)re)->gsubst(rstr, with); }
char *re_ngsubst(re_t re, const char **rstr, const char *with, int lino, int ndig)
  { return ((regexpr_t *)re)->gsubst(rstr, with, lino, ndig); }
char *re_strsubst(const char *str, const char *spec)
  { return regexpr_t::subst(str, spec); }
char *re_nstrsubst(const char *str, const char *spec, int lino, int ndig)
  { return regexpr_t::subst(str, spec, lino, ndig); }
int re_is_valid_subst(const char *spec) 
  { return regexpr_t::is_valid_subst(spec); }
