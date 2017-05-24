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

#include <stdio.h>
#include <stdlib.h>

#include "semvers.h"

#define ISPOW2(n) (((n) & -(n)) == (n))

uint32_t semvers_pgrowth(semvers_t *self, const int32_t nmin) {
  if (nmin > 0) {
    uint32_t unmin = (uint32_t) nmin;

    if (self->capacity) {
      if (self->capacity < unmin) {
        if (ISPOW2(nmin)) {
          self->capacity = unmin;
        } else {
          do self->capacity *= 2; while (self->capacity < unmin);
        }
        self->data = (semver_t *) realloc((char *) self->data, sizeof(semver_t) * self->capacity);
      }
    } else {
      if (unmin == SEMVERS_MIN_CAP || (unmin > SEMVERS_MIN_CAP && ISPOW2(nmin))) {
        self->capacity = unmin;
      } else {
        self->capacity = SEMVERS_MIN_CAP;
        while (self->capacity < unmin) self->capacity *= 2;
      }
      self->data = (semver_t *) sv_malloc(sizeof(semver_t) * self->capacity);
    }
    return unmin;
  }
  return 0;
}

semver_t semvers_perase(semvers_t *self, uint32_t i) {
  semver_t x = self->data[i];

  memmove(self->data + i, self->data + i + 1, --self->length * sizeof(semver_t));
  return x;
}

static int semvers_qsort_fn(const void *a, const void *b) {
  return semver_pcmp((semver_t *) a, (semver_t *) b);
}

void semvers_psort(semvers_t *self) {
  qsort((char *) self->data, self->length, sizeof(semver_t), semvers_qsort_fn);
}

static int semvers_rqsort_fn(const void *a, const void *b) {
  return semver_pcmp((semver_t *) b, (semver_t *) a);
}

void semvers_prsort(semvers_t *self) {
  qsort((char *) self->data, self->length, sizeof(semver_t), semvers_rqsort_fn);
}

void semvers_pdtor(semvers_t *self) {
  if (self->data) {
    uint32_t i;

    for (i = 0; i < self->length; ++i) {
      semver_dtor(self->data + i);
    }
    sv_free(self->data);
    self->data = NULL;
  }
  self->length = self->capacity = 0;
}

void semvers_pclear(semvers_t *self) {
  if (self->data) {
    uint32_t i;

    for (i = 0; i < self->length; ++i) {
      semver_dtor(self->data + i);
    }
    memset((char *) self->data, 0, self->length * sizeof(semver_t));
  }
  self->length = 0;
}
