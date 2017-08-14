/*
 * This is free and unencumbered software released into the public domain.
 *
 * Anyone is free to copy, modify, publish, use, compile, sell, or
 * distribute this software, either in source code form or as a compiled
 * binary, for any purpose, commercial or non-commercial, and by any
 * means.
 *
 * In jurisdictions that recognize copyright laws, the author or authors
 * of this software dedicate any and all copyright interest in the
 * software to the public domain. We make this dedication for the benefit
 * of the public at large and to the detriment of our heirs and
 * successors. We intend this dedication to be an overt act of
 * relinquishment in perpetuity of all present and future rights to this
 * software under copyright law.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * For more information, please refer to <http://unlicense.org>
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "semver.h"

#define STRNSIZE(s) (s), sizeof(s)-1

int test_read(const char *expected, const char *str, size_t len) {
  unsigned slen;
  char buffer[1024];
  semver_comp_t comp = {0};

  printf("test: `%.*s`", (int) len, str);
  if (semver_compn(&comp, str, len)) {
    puts(" \tcouldn't parse");
    return 1;
  }
  slen = (unsigned) semver_comp_write(comp, buffer, 1024);
  printf(" \t=> \t`%.*s`", slen, buffer);
  if (memcmp(expected, buffer, (size_t) slen > len ? slen : len) != 0) {
    printf(" != `%s`\n", expected);
    semver_comp_dtor(&comp);
    return 1;
  }
  printf(" == `%s`\n", expected);
  semver_comp_dtor(&comp);
  return 0;
}

int test_and(const char *expected, const char *base_str, size_t base_len, const char *str, size_t len) {
  unsigned slen;
  char buffer[1024];
  semver_comp_t comp = {0};

  printf("test and: `%.*s`", (int) base_len, base_str);
  if (semver_compn(&comp, base_str, base_len)) {
    puts(" \tcouldn't parse");
    return 1;
  }
  if (semver_and(&comp, str, len)) {
    puts(" \tand failed");
    return 1;
  }
  slen = (unsigned) semver_comp_write(comp, buffer, 1024);
  printf(" \t=> \t`%.*s`", slen, buffer);
  if (memcmp(expected, buffer, (size_t) slen > base_len + len + 1 ? slen : base_len + len + 1) != 0) {
    printf(" != `%s`\n", expected);
    semver_comp_dtor(&comp);
    return 1;
  }
  printf(" == `%s`\n", expected);
  semver_comp_dtor(&comp);
  return 0;
}

int main(void) {
  puts("failure:");
  if (test_read("", STRNSIZE("* ")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("*  ")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("*  |")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("* || *")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("abc")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE(">")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("<=")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("~")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("^")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("=")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE(">a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("<a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("~a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("^a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("=a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE(">1.a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("<1.a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("~1.a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("^1.a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("=1.a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.3 ")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.3 -")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.3 - ")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.3 -a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.3 - a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.3 - 1.2.a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("a.2.3")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.a.3")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.3-")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.3-alpha+")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("1.2.3+")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3", STRNSIZE("1.2.3"))) {
    return EXIT_FAILURE;
  }

  puts("\nsome prerelease and build:");
  if (test_read(">=0.0.0 1.2.3-alpha", STRNSIZE("* 1.2.3-alpha"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.0 1.2.3-alpha.2", STRNSIZE("* 1.2.3-alpha.2"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.0 1.2.3+77", STRNSIZE("* 1.2.3+77"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.0 1.2.3+77.2", STRNSIZE("* 1.2.3+77.2"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.0 1.2.3-alpha.2+77", STRNSIZE("* 1.2.3-alpha.2+77"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.0 1.2.3-alpha.2+77.2", STRNSIZE("* 1.2.3-alpha.2+77.2"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.0 1.2.3-al-pha.2+77", STRNSIZE("* 1.2.3-al-pha.2+77"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.0 1.2.3-al-pha.2+77.2", STRNSIZE("* 1.2.3-al-pha.2+77.2"))) {
    return EXIT_FAILURE;
  }

  puts("\nx-range:");
  if (test_read(">=0.0.0", STRNSIZE("*"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=1.0.0 <2.0.0", STRNSIZE("1.x"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=1.2.0 <1.3.0", STRNSIZE("1.2.x"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.0", STRNSIZE(""))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=1.0.0 <2.0.0", STRNSIZE("1"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=1.2.0 <1.3.0", STRNSIZE("1.2"))) {
    return EXIT_FAILURE;
  }

  puts("\nhyphen:");
  if (test_read(">=1.2.3 <=2.3.4", STRNSIZE("1.2.3 - 2.3.4"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=1.2.0 <=2.3.4", STRNSIZE("1.2 - 2.3.4"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=1.2.3 <2.4.0", STRNSIZE("1.2.3 - 2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=1.2.3 <3.0.0", STRNSIZE("1.2.3 - 2"))) {
    return EXIT_FAILURE;
  }

  puts("\ntidle:");
  if (test_read(">=1.2.3 <1.3.0", STRNSIZE("~1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=1.2.0 <1.3.0", STRNSIZE("~1.2"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=1.0.0 <2.0.0", STRNSIZE("~1"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.2.3 <0.3.0", STRNSIZE("~0.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.2.0 <0.3.0", STRNSIZE("~0.2"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.0 <1.0.0", STRNSIZE("~0"))) {
    return EXIT_FAILURE;
  }

  puts("\ncaret:");
  if (test_read(">=1.2.3 <2.0.0", STRNSIZE("^1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.2.3 <0.3.0", STRNSIZE("^0.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.0.3 <0.0.4", STRNSIZE("^0.0.3"))) {
    return EXIT_FAILURE;
  }

  puts("\nprimitive:");
  if (test_read(">=1.2.3 <2.0.0", STRNSIZE(">=1.2.3 <2.0"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.2.3 <0.3.0", STRNSIZE(">=0.2.3 <0.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">=0.5.0 <0.0.4", STRNSIZE(">=0.5 <0.0.4"))) {
    return EXIT_FAILURE;
  }
  if (test_read(">0.0.3", STRNSIZE(">0.0.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read("0.0.3", STRNSIZE("=0.0.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read("9.0.0", STRNSIZE("=9"))) {
    return EXIT_FAILURE;
  }

  puts("\nand:");
  if (test_and(">=0.0.0 >=0.0.3 <0.0.4", STRNSIZE("*"), STRNSIZE("^0.0.3"))) {
    return EXIT_FAILURE;
  }
  if (test_and(">=1.0.0 <2.0.0 >=0.0.3 <0.0.4", STRNSIZE("1.x"), STRNSIZE("^0.0.3"))) {
    return EXIT_FAILURE;
  }
  if (test_and(">=1.2.0 <1.3.0 >=0.0.3 <0.0.4", STRNSIZE("1.2.x"), STRNSIZE("^0.0.3"))) {
    return EXIT_FAILURE;
  }
  if (test_and(">=1.2.0 <1.3.0 >=1.2.0 <1.3.0 >=0.0.3 <0.0.4", STRNSIZE("1.2 1.2.x"), STRNSIZE("^0.0.3"))) {
    return EXIT_FAILURE;
  }
  if (test_and(">=1.0.0 <2.0.0 >=0.0.3 <0.0.4", STRNSIZE("1"), STRNSIZE("^0.0.3"))) {
    return EXIT_FAILURE;
  }
  if (test_and(">=1.2.0 <1.3.0 >=0.0.3 <0.0.4", STRNSIZE("1.2"), STRNSIZE("^0.0.3"))) {
    return EXIT_FAILURE;
  }
  if (test_and("", STRNSIZE("1.2"), STRNSIZE("")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_and("", STRNSIZE("1.2"), STRNSIZE("a")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_and("", STRNSIZE("1.2"), STRNSIZE("1.2.x abc")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget "
                             "dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascet"
                             "ur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, s"))
      == 0) {
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
