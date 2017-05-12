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
#include <semver.h>
#include <stdio.h>

#ifdef _MSC_VER
# define snprintf(s, maxlen, fmt, ...) _snprintf_s(s, _TRUNCATE, maxlen, fmt, __VA_ARGS__)
#endif

static void sv_range_init(sv_range_t *self) {
#ifndef _MSC_VER
  *self = (sv_range_t) {0};
#else
  self->next = NULL;
  sv_comp_ctor(&self->comp);
#endif
}

void sv_range_dtor(sv_range_t *self) {
  if (self && self->next) {
    sv_range_dtor(self->next);
    free(self->next);
    self->next = NULL;
  }
}

char sv_range_read(sv_range_t *self, const char *str, size_t len, size_t *offset) {
  sv_range_init(self);
  if (sv_comp_read(&self->comp, str, len, offset)) {
    return 1;
  }
  while (*offset < len && str[*offset] == ' ') ++*offset;
  if (*offset < len && str[*offset] == '|'
    && *offset + 1 < len && str[*offset + 1] == '|') {
    *offset += 2;
    while (*offset < len && str[*offset] == ' ') ++*offset;
    self->next = (sv_range_t *) malloc(sizeof(sv_range_t));
    return sv_range_read(self->next, str, len, offset);
  }
  return 0;
}

char sv_rmatch(const sv_t self, const sv_range_t range) {
  return (char) (sv_match(self, range.comp) ? 1 : range.next ? sv_rmatch(self, *range.next) : 0);
}

int sv_range_write(const sv_range_t self, char *buffer, size_t len) {
  char comp[1024], next[1024];

  if (self.next) {
    return snprintf(buffer, len, "%.*s || %.*s",
      sv_comp_write(self.comp, comp, 1024), comp,
      sv_range_write(*self.next, next, 1024), next
    );
  }
  return snprintf(buffer, len, "%.*s", sv_comp_write(self.comp, comp, 1024), comp);
}
