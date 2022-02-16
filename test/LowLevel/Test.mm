//
//  TestLowlevel.m
//  Test
//
//  Created by Norbert Thies on 02.01.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "NorthLib/strext.h"
#include "NorthLib/fileop.h"

@interface TestLowlevel : XCTestCase

@end

@implementation TestLowlevel

- (void) setUp {
}

- (void) tearDown {
}

- (void) testString {
  char buff1[1001], buff2[1001];
  mem_set(buff1, 'A', 1000);
  XCTAssert(buff1[999] == 'A');
  buff1[1000] = 0;
  mem_cpy(buff2, buff1, 1001);
  XCTAssert(mem_cmp(buff1, buff2, 1001) == 0);
  mem_set(buff2, 'B', 1000);
  XCTAssert(buff2[0] == 'B');
  mem_swap(buff1, buff2, 1001);
  XCTAssert(buff1[500] == 'B');
  XCTAssert(buff2[500] == 'A');
  mem_set(buff1, 'C', 500);
  mem_move(buff1, buff1+400, 500);
  XCTAssert(buff1[0] == 'C');
  XCTAssert(buff1[99] == 'C');
  XCTAssert(buff1[100] == 'B');
  void *ptr = mem_heap(buff1, 1001);
  XCTAssert(mem_cmp(ptr, buff1, 1001) == 0);
  mem_release(&ptr);
  XCTAssert(ptr == 0);
  XCTAssert(str_len(buff1) == 1000);
  str_cpy(buff1, 1001, "abc");
  XCTAssert(str_len(buff1) == 3);
  XCTAssert(str_cmp(buff1, "abc") == 0);
  str_cpy(buff1, 3, "abcd");
  XCTAssert(str_len(buff1) == 2);
  XCTAssert(str_cmp(buff1, "ab") == 0);
  str_mcpy(buff1, 1001, "ab", "cd", "ef", NIL);
  XCTAssert(str_cmp(buff1, "abcdef") == 0);
  str_ncpy(buff1, 1001, "abcd", 2);
  XCTAssert(str_cmp(buff1, "ab") == 0);
  char *s = buff1;
  str_rqcpy(&s, 1001, "a \"simple\" test with a \\ backslash");
  XCTAssert(str_cmp(buff1, 
    "\"a \\\"simple\\\" test with a \\\\ backslash\"" ) == 0);
  XCTAssert(s == buff1 + str_len(buff1));
  str_chcpy(buff1, 1001, '=', 5);
  XCTAssert(str_cmp(buff1, "=====") == 0);
  str_mcat(buff1, 1001, "a", "b", NIL);
  XCTAssert(str_cmp(buff1, "=====ab") == 0);
  s = str_heap(buff1, 0);
  XCTAssert(str_cmp(s, "=====ab") == 0);
  str_release(&s);
  XCTAssert(s == NIL);
  s = str_heap(buff1, 5);
  XCTAssert(str_cmp(s, "=====") == 0);
  str_release(&s);
  s = str_slice(buff1, 5, -1);
  XCTAssert(str_cmp(s, "ab") == 0);
  str_release(&s);
  s = str_slice(buff1, 5, 5);
  XCTAssert(str_cmp(s, "a") == 0);
  str_release(&s);
  const char *cs = str_chr(buff1, 'a');
  XCTAssert(cs == buff1+5);
  cs = str_rchr(buff1, '=');
  XCTAssert(cs == buff1 + 4);
  cs = str_pbrk(buff1, "ab");
  XCTAssert(cs == buff1+5);
  cs = str_pbrk(buff1, "Ab");
  XCTAssert(cs == buff1+6);
  XCTAssert(str_ccmp("abc=13", "abc=22", '=') == 0);
  XCTAssert(str_ncasecmp("abcdef", "ABCxyz", 3) == 0);
  XCTAssert(str_is_gpattern("ab[c-d]*xy") != 0);
  XCTAssert(str_gmatch("abcfooxy", "ab[c-d]*xy") == 1);
  XCTAssert(str_gmatch("abefooxy", "ab[c-d]*xy") == 0);
  XCTAssert(str_gmatch("abdxy", "ab[c-d]*xy") == 1);
  XCTAssert(str_match("X=abc", "abc", '=') == NIL);
  cs = "X=abc";
  XCTAssert(str_match(cs, "abc", 0) == cs+2);
  str_cpy(buff1, 1001, cs);
  const void *cp = mem_match(buff1, 1001, "abc");
  XCTAssert(cp == buff1+2);
  str_cpy(buff2, 1001, "a b \"c d\" e");
  cs = buff2;
  const char *cs2 = str_substring(&cs, buff1, 1001, 0);
  XCTAssert(cs2 == buff1);
  XCTAssert(str_cmp(cs2, "a") == 0);
  XCTAssert(cs == buff2 + 2);
  cs2 = str_substring(&cs, buff1, 1001, 0);
  XCTAssert(str_cmp(cs2, "b") == 0);
  XCTAssert(cs == buff2 + 4);
  cs2 = str_substring(&cs, buff1, 1001, 0);
  XCTAssert(str_cmp(cs2, "c d") == 0);
  XCTAssert(cs == buff2 + 10);
  cs2 = str_substring(&cs, buff1, 1001, 0);
  XCTAssert(str_cmp(buff1, "e") == 0);
  XCTAssert(cs2 == NIL);
  XCTAssert(cs == buff2 + 11);
  s = str_trim(" bla\n ");
  XCTAssert(str_cmp(s, "bla") == 0);
  str_release(&s);
  str_cpy(buff1, 1001, "abc");
  XCTAssert(str_cmp(str_2upper(buff1), "ABC") == 0);
  XCTAssert(str_cmp(str_2lower(buff1), "abc") == 0);
  XCTAssert(str_cmp(str_reverse(buff1), "cba") == 0);
  s = str_quote("a \"b c\" d\n");
  XCTAssert(str_cmp(s, "\"a \\\"b c\\\" d\\n\"") == 0);
  char *s2 = str_dequote(s);
  XCTAssert(str_cmp(s2, "a \"b c\" d\n") == 0);
  str_release(&s);
  str_release(&s2);
  str_i2roman(buff1, 1001, 1024, 0);
  XCTAssert(str_cmp(buff1, "mxxiv") == 0);
  XCTAssert(str_roman2i(buff1) == 1024);
}

- (void) testArgv {
  const char *str = "a:b:c";
  char **av = av_a2av(str, ':');
  XCTAssert(av != 0);
  XCTAssert(av_length(av) == 3);
  XCTAssert(str_cmp(av[0], "a") == 0);
  XCTAssert(str_cmp(av[1], "b") == 0);
  XCTAssert(str_cmp(av[2], "c") == 0);
  XCTAssert(av[3] == 0);
  XCTAssert(av_size(av) == 3);
  av_release(av);
  str = "a \"b c\" d";
  av = av_a2av(str, 0);
  XCTAssert(av_length(av) == 3);
  XCTAssert(str_cmp(av[0], "a") == 0);
  XCTAssert(str_cmp(av[1], "b c") == 0);
  XCTAssert(str_cmp(av[2], "d") == 0);
  XCTAssert(av[3] == 0);
  XCTAssert(av_size(av) == 5);
  char buff[1001];
  int ret = av_av2a(buff, 1001, av, 0);
  XCTAssert(ret == str_len(str));
  XCTAssert(str_cmp(buff, str) == 0);
  av = av_minsert(av, 1, "x", "y", (const char *) 0);
  XCTAssert(av_length(av) == 5);
  XCTAssert(str_cmp(av[1], "x") == 0);
  XCTAssert(str_cmp(av[2], "y") == 0);
  av = av_mappend(av, "A", "B", (const char *) 0);
  XCTAssert(av_length(av) == 7);
  XCTAssert(str_cmp(av[5], "A") == 0);
  XCTAssert(str_cmp(av[6], "B") == 0);
  av_release(av);
}

- (void) testFile {
  char *dir = fn_abs(".");
  XCTAssert(dir != 0);
  printf("cwd: %s\n", dir);
  char *home = getenv("HOME");
  XCTAssert(home != 0);
  printf("home: %s\n", home);
  str_release(&dir);
  char buff[1000];
  snprintf(buff, 1000, "%s/../..", home);
  dir = fn_abs(buff);
  XCTAssert(dir != 0);
  printf("%s\n", dir);
  stat_t st;
  XCTAssert(stat_read(&st, home) == 0);
  XCTAssert(stat_isdir(&st));
  XCTAssert(stat_istype(&st, "d") != 0);
  snprintf(buff, 1000, "%s/test.foo", home);
  char *tmp = fn_basename(buff);
  XCTAssert(str_cmp(tmp, "test.foo") == 0);
  str_release(&tmp);
  tmp = fn_dirname(buff);
  XCTAssert(str_cmp(tmp, home) == 0);
  str_release(&tmp);
  tmp = fn_progname(buff);
  XCTAssert(str_cmp(tmp, "test") == 0);
  str_release(&tmp);
}

@end
