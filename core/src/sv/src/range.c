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

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "range.h"
#include "comp.h"

void semver_range_ctor(semver_range_t *self) {
#ifndef _MSC_VER
  *self = (semver_range_t) {0};
#else
  self->next = NULL;
  semver_comp_ctor(&self->comp);
#endif
}

void semver_range_dtor(semver_range_t *self) {
  if (self && self->next) {
    semver_range_dtor(self->next);
    sv_free(self->next);
    self->next = NULL;
  }
}

char semver_rangen(semver_range_t *self, const char *str, size_t len) {
  size_t offset = 0;

  if (len > SV_RANGE_MAX_LEN) {
    return 1;
  }
  if (semver_range_read(self, str, len, &offset) || offset < len) {
    semver_range_dtor(self);
    return 1;
  }
  return 0;
}

char semver_range_read(semver_range_t *self, const char *str, size_t len, size_t *offset) {
  semver_range_ctor(self);
  if (semver_comp_read(&self->comp, str, len, offset)) {
    return 1;
  }
  while (*offset < len && str[*offset] == ' ') ++*offset;
  if (*offset < len && str[*offset] == '|'
    && *offset + 1 < len && str[*offset + 1] == '|') {
    *offset += 2;
    while (*offset < len && str[*offset] == ' ') ++*offset;
    self->next = (semver_range_t *) sv_malloc(sizeof(semver_range_t));
    if (self->next == NULL) {
      return 1;
    }
    return semver_range_read(self->next, str, len, offset);
  }
  return 0;
}

char semver_or(semver_range_t *left, const char *str, size_t len) {
  semver_range_t *range, *tail;

  if (len > 0) {
    range = (semver_range_t *) sv_malloc(sizeof(semver_range_t));
    if (NULL == range) {
      return 1;
    }
    if (semver_rangen(range, str, len)) {
      sv_free(range);
      return 1;
    }
    if (NULL == left->next) {
      left->next = range;
    } else {
      tail = left->next;
      while (tail->next) tail = tail->next;
      tail->next = range;
    }
    return 0;
  }
  return 1;
}

bool semver_range_pmatch(const semver_t *self, const semver_range_t *range) {
  return semver_comp_pmatch(self, &range->comp) ? true : range->next ? semver_range_pmatch(self, range->next) : false;
}

bool semver_range_matchn(const semver_t *self, const char *range_str, size_t range_len) {
  semver_range_t range;
  bool result;

  if (semver_rangen(&range, range_str, range_len)) {
    return false;
  }
  result = semver_range_pmatch(self, &range);
  semver_range_dtor(&range);
  return result;
}

int semver_range_pwrite(const semver_range_t *self, char *buffer, size_t len) {
  char comp[SV_RANGE_MAX_LEN];

  if (self->next) {
    char next[SV_RANGE_MAX_LEN];
    return snprintf(buffer, len, "%.*s || %.*s",
      semver_comp_write(self->comp, comp, SV_RANGE_MAX_LEN), comp,
      semver_range_pwrite(self->next, next, SV_RANGE_MAX_LEN), next
    );
  }
  return snprintf(buffer, len, "%.*s", semver_comp_write(self->comp, comp, SV_RANGE_MAX_LEN), comp);
}
