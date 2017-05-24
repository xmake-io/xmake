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
#include <assert.h>

#include "semver.h"

#define STRNSIZE(s) (s), sizeof(s)-1

int main(void) {
  semver_t v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10;
  semvers_t semvers = {0};

  semver_tryn(&v0, STRNSIZE("2.0.0"));
  semver_tryn(&v1, STRNSIZE("2.0.1"));
  semver_tryn(&v2, STRNSIZE("2.0.2"));
  semver_tryn(&v3, STRNSIZE("v2.0.0"));
  semver_tryn(&v4, STRNSIZE("v2.0.1"));
  semver_tryn(&v5, STRNSIZE("v2.0.2"));
  semver_tryn(&v6, STRNSIZE("v2.0.3"));
  semver_tryn(&v7, STRNSIZE("v2.1.0-beta1"));
  semver_tryn(&v8, STRNSIZE("v2.1.0-beta2"));
  semver_tryn(&v9, STRNSIZE("v2.0"));
  semver_tryn(&v10, STRNSIZE("v2.1"));

  if (semver_rmatch(v0, ">2.0.1")) semvers_push(semvers, v0);
  if (semver_rmatch(v1, ">2.0.1")) semvers_unshift(semvers, v1);
  if (semver_rmatch(v2, ">2.0.1")) semvers_push(semvers, v2);
  if (semver_rmatch(v3, ">2.0.1")) semvers_unshift(semvers, v3);
  if (semver_rmatch(v4, ">2.0.1")) semvers_push(semvers, v4);
  if (semver_rmatch(v5, ">2.0.1")) semvers_unshift(semvers, v5);
  if (semver_rmatch(v6, ">2.0.1")) semvers_push(semvers, v6);
  if (semver_rmatch(v7, ">2.0.1")) semvers_unshift(semvers, v7);
  if (semver_rmatch(v8, ">2.0.1")) semvers_push(semvers, v8);
  if (semver_rmatch(v9, ">2.0.1")) semvers_unshift(semvers, v9);
  if (semver_rmatch(v10, ">2.0.1")) semvers_push(semvers, v10);
  if (semver_rmatch(v0, ">2.0.1")) semvers_push(semvers, v0);
  if (semver_rmatch(v1, ">2.0.1")) semvers_unshift(semvers, v1);
  if (semver_rmatch(v2, ">2.0.1")) semvers_push(semvers, v2);
  if (semver_rmatch(v3, ">2.0.1")) semvers_unshift(semvers, v3);
  if (semver_rmatch(v4, ">2.0.1")) semvers_push(semvers, v4);
  if (semver_rmatch(v5, ">2.0.1")) semvers_unshift(semvers, v5);
  if (semver_rmatch(v6, ">2.0.1")) semvers_push(semvers, v6);
  if (semver_rmatch(v7, ">2.0.1")) semvers_unshift(semvers, v7);
  if (semver_rmatch(v8, ">2.0.1")) semvers_push(semvers, v8);
  if (semver_rmatch(v9, ">2.0.1")) semvers_unshift(semvers, v9);
  if (semver_rmatch(v10, ">2.0.1")) semvers_push(semvers, v10);
  if (semver_rmatch(v0, ">2.0.1")) semvers_push(semvers, v0);
  if (semver_rmatch(v1, ">2.0.1")) semvers_unshift(semvers, v1);
  if (semver_rmatch(v2, ">2.0.1")) semvers_push(semvers, v2);
  if (semver_rmatch(v3, ">2.0.1")) semvers_unshift(semvers, v3);
  if (semver_rmatch(v4, ">2.0.1")) semvers_push(semvers, v4);
  if (semver_rmatch(v5, ">2.0.1")) semvers_unshift(semvers, v5);
  if (semver_rmatch(v6, ">2.0.1")) semvers_push(semvers, v6);
  if (semver_rmatch(v7, ">2.0.1")) semvers_unshift(semvers, v7);
  if (semver_rmatch(v8, ">2.0.1")) semvers_push(semvers, v8);
  if (semver_rmatch(v9, ">2.0.1")) semvers_unshift(semvers, v9);
  if (semver_rmatch(v10, ">2.0.1")) semvers_push(semvers, v10);

  if (semvers.length != 18) {
    return EXIT_FAILURE;
  }
  if (semvers.capacity != 32) {
    return EXIT_FAILURE;
  }

  semvers_sort(semvers);

  for (unsigned i = 0; i < semvers.length; ++i) {
    semver_fwrite(semvers.data + i, stdout);
    putc('\n', stdout);
  }

  v0 = semvers_pop(semvers);
  v1 = semvers_shift(semvers);

  assert(memcmp("v2.1", v0.raw, v0.len) == 0);
  assert(memcmp("v2.0.2", v1.raw, v1.len) == 0 || memcmp("2.0.2", v1.raw, v1.len) == 0);

  semvers_rsort(semvers);
  putc('\n', stdout);
  for (unsigned i = 0; i < semvers.length; ++i) {
    semver_fwrite(semvers.data + i, stdout);
    putc('\n', stdout);
  }

  semvers_dtor(semvers);

  return EXIT_SUCCESS;
}
