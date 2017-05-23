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
  semver_t semver = {0};

  printf("test: `%.*s`", (int) len, str);
  if (semvern(&semver, str, len)) {
    puts(" \tcouldn't parse");
    return 1;
  }
  slen = (unsigned) semver_write(semver, buffer, 1024);
  printf(" \t=> \t`%.*s`", slen, buffer);
  if (memcmp(expected, buffer, (size_t) slen > len ? slen : len) != 0) {
    printf(" != `%s`\n", expected);
    semver_dtor(&semver);
    return 1;
  }
  printf(" == `%s`\n", expected);
  semver_dtor(&semver);
  return 0;
}

int test_try_read(const char *expected, const char *str, size_t len) {
  unsigned slen;
  char buffer[1024];
  semver_t semver = {0};

  printf("test: `%.*s`", (int) len, str);
  if (semver_tryn(&semver, str, len)) {
    puts(" \tcouldn't parse");
    return 1;
  }
  slen = (unsigned) semver_write(semver, buffer, 1024);
  printf(" \t=> \t`%.*s`", slen, buffer);
  if (memcmp(expected, buffer, (size_t) slen > len ? slen : len) != 0) {
    printf(" != `%s`\n", expected);
    semver_dtor(&semver);
    return 1;
  }
  printf(" == `%s`\n", expected);
  semver_dtor(&semver);
  return 0;
}

int main(void) {
  puts("normal:");
  if (test_read("0.2.3", STRNSIZE("0.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3", STRNSIZE("1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3-alpha", STRNSIZE("v1.2.3-alpha"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3-alpha.2", STRNSIZE("1.2.3-alpha.2"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3+77", STRNSIZE("v1.2.3+77"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3+0", STRNSIZE("v1.2.3+0"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3+77.2", STRNSIZE("1.2.3+77.2"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3-alpha.2+77", STRNSIZE("v1.2.3-alpha.2+77"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3-alpha.2+77.2", STRNSIZE("1.2.3-alpha.2+77.2"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3-al-pha.2+77", STRNSIZE("v1.2.3-al-pha.2+77"))) {
    return EXIT_FAILURE;
  }
  if (test_read("1.2.3-al-pha.2+77.2", STRNSIZE("1.2.3-al-pha.2+77.2"))) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("vv1.2.3")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("v1.2")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("v1.2.x")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("v1.2.3-")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("v1.2.3+")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("v1.2.3+01")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("v0.01.3")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_read("", STRNSIZE("Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget "
                             "dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascet"
                             "ur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, s"))
      == 0) {
    return EXIT_FAILURE;
  }

  puts("try:");
  if (test_try_read("0.2.3", STRNSIZE("0.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3", STRNSIZE("1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3-alpha", STRNSIZE("v1.2.3-alpha"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3-alpha.2", STRNSIZE("1.2.3-alpha.2"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3+77", STRNSIZE("v1.2.3+77"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3+0", STRNSIZE("v1.2.3+0"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3+77.2", STRNSIZE("1.2.3+77.2"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3-alpha.2+77", STRNSIZE("v1.2.3-alpha.2+77"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3-alpha.2+77.2", STRNSIZE("1.2.3-alpha.2+77.2"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3-al-pha.2+77", STRNSIZE("v1.2.3-al-pha.2+77"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3-al-pha.2+77.2", STRNSIZE("1.2.3-al-pha.2+77.2"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("", STRNSIZE("")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_try_read("", STRNSIZE("vv1.2.3")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_try_read("", STRNSIZE("v1.2")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_try_read("", STRNSIZE("v1.2.x")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_try_read("", STRNSIZE("v1.2.3-")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_try_read("", STRNSIZE("v1.2.3+")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_try_read("", STRNSIZE("v1.2.3+01")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_try_read("", STRNSIZE("v0.01.3")) == 0) {
    return EXIT_FAILURE;
  }
  if (test_try_read("", STRNSIZE("Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget "
                               "dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascet"
                               "ur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, s"))
      == 0) {
    return EXIT_FAILURE;
  }
  if (test_try_read("0.2.0", STRNSIZE("0.2"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.0.0", STRNSIZE("v1"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.0-alpha", STRNSIZE("v1.2alpha"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3-alpha.2", STRNSIZE("1.2.3alpha.2"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.0.0+77", STRNSIZE("v1+77"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.0+0", STRNSIZE("v1.2+0"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.0.0+77.2", STRNSIZE("v1+77.2"))) {
    return EXIT_FAILURE;
  }
  if (test_try_read("1.2.3-alpha.2+77", STRNSIZE("v1.2.3alpha.2+77"))) {
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
