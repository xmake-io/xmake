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

#include "semver.h"

#define STRNSIZE(s) (s), sizeof(s)-1

int test_matchn(bool expected, const char *semver_str, size_t semver_len, const char *comp_str, size_t comp_len) {
  bool result;
  semver_t semver = {0};

  printf("test: `%.*s` ^ `%.*s`", (int) semver_len, semver_str, (int) comp_len, comp_str);
  if (semvern(&semver, semver_str, semver_len)) {
    puts(" \tcouldn't parse semver");
    return 1;
  }
  result = semver_comp_matchn(&semver, comp_str, comp_len);
  printf(" \t=> %d\t", result);
  if (result != expected) {
    printf(" != `%d`\n", expected);
    semver_dtor(&semver);
    return 1;
  }
  printf(" == `%d`\n", expected);
  semver_dtor(&semver);
  return 0;
}

int test_rmatchn(bool expected, const char *semver_str, size_t semver_len, const char *range_str, size_t range_len) {
  bool result;
  semver_t semver = {0};

  printf("test: `%.*s` ^ `%.*s`", (int) semver_len, semver_str, (int) range_len, range_str);
  if (semvern(&semver, semver_str, semver_len)) {
    puts(" \tcouldn't parse semver");
    return 1;
  }
  result = semver_range_matchn(&semver, range_str, range_len);
  printf(" \t=> %d\t", result);
  if (result != expected) {
    printf(" != `%d`\n", expected);
    semver_dtor(&semver);
    return 1;
  }
  printf(" == `%d`\n", expected);
  semver_dtor(&semver);
  return 0;
}

int main(void) {
  if (test_matchn(true, STRNSIZE("v1.2.3"), STRNSIZE("1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("v1.2.3"), STRNSIZE("1.2.x"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("v1.2.3"), STRNSIZE("1.x.x"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("v1.2.3"), STRNSIZE("1.x"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("v1.2.3"), STRNSIZE("1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("v1.2.3"), STRNSIZE("*"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("v1.2.3"), STRNSIZE(">1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("v1.2.3"), STRNSIZE(">2"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("v1.2.3"), STRNSIZE(">=2"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("v1.2.3"), STRNSIZE("<1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("v1.2.3"), STRNSIZE("<=1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("v1.2.3"), STRNSIZE(">=1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("v1.2.3"), STRNSIZE(">1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("v1.2.3"), STRNSIZE("<1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("v1.2.3"), STRNSIZE("<=1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("v1.2.3"), STRNSIZE("2.x"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("<0.0.1-99"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("<=0.0.1-99"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("<=0.0.1-98"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("=0.0.1-98"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-98"), STRNSIZE(">=0.0.1-98"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-98"), STRNSIZE(">=0.0.1-97"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-98"), STRNSIZE(">0.0.1-97"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha"), STRNSIZE("0.0.1-alpha"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("<0.0.1-99"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("<0.0.1-alpha.99"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("<=0.0.1-alpha.99"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("<=0.0.1-alpha.98"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("=0.0.1-alpha.98"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE(">=0.0.1-alpha.98"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE(">=0.0.1-alpha.97"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE(">0.0.1-alpha.97"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("<0.0.1-alpha.99.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("<=0.0.1-alpha.99.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("<=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("0.0.1-alpha.98"), STRNSIZE(">=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE(">=0.0.1-alpha.97.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE(">0.0.1-alpha.97.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("<0.0.1-alpha.99.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("<=0.0.1-alpha.99.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("<=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(false, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE(">=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE(">=0.0.1-alpha.97.1"))) {
    return EXIT_FAILURE;
  }
  if (test_matchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE(">0.0.1-alpha.97.1"))) {
    return EXIT_FAILURE;
  }

  if (test_rmatchn(true, STRNSIZE("v1.2.3"), STRNSIZE("9.x || 1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("v1.2.3"), STRNSIZE("9.x || 1.2.x"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("v1.2.3"), STRNSIZE("9.x || 1.x.x"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("v1.2.3"), STRNSIZE("9.x || 1.x"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("v1.2.3"), STRNSIZE("9.x || 1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("v1.2.3"), STRNSIZE("9.x || *"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("v1.2.3"), STRNSIZE("9.x || >1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("v1.2.3"), STRNSIZE("9.x || >2"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("v1.2.3"), STRNSIZE("9.x || >=2"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("v1.2.3"), STRNSIZE("9.x || <1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("v1.2.3"), STRNSIZE("9.x || <=1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("v1.2.3"), STRNSIZE("9.x || >=1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("v1.2.3"), STRNSIZE("9.x || >1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("v1.2.3"), STRNSIZE("9.x || <1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("v1.2.3"), STRNSIZE("9.x || <=1.2.3"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("v1.2.3"), STRNSIZE("9.x || 2.x"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("9.x || <0.0.1-99"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("9.x || <=0.0.1-99"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("9.x || <=0.0.1-98"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("9.x || =0.0.1-98"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("9.x || >=0.0.1-98"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("9.x || >=0.0.1-97"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("9.x || >0.0.1-97"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha"), STRNSIZE("9.x || 0.0.1-alpha"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-98"), STRNSIZE("9.x || <0.0.1-99"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || <0.0.1-alpha.99"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || <=0.0.1-alpha.99"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || <=0.0.1-alpha.98"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || =0.0.1-alpha.98"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || >=0.0.1-alpha.98"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || >=0.0.1-alpha.97"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || >0.0.1-alpha.97"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || <0.0.1-alpha.99.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || <=0.0.1-alpha.99.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || <=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || =0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || >=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || >=0.0.1-alpha.97.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98"), STRNSIZE("9.x || >0.0.1-alpha.97.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("9.x || <0.0.1-alpha.99.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("9.x || <=0.0.1-alpha.99.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("9.x || <=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(false, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("9.x || =0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("9.x || >=0.0.1-alpha.98.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("9.x || >=0.0.1-alpha.97.1"))) {
    return EXIT_FAILURE;
  }
  if (test_rmatchn(true, STRNSIZE("0.0.1-alpha.98.1.3"), STRNSIZE("9.x || >0.0.1-alpha.97.1"))) {
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
