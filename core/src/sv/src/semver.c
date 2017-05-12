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
#include <semver.h>
#include <stdio.h>

#ifdef _MSC_VER
# define snprintf(s, maxlen, fmt, ...) _snprintf_s(s, _TRUNCATE, maxlen, fmt, __VA_ARGS__)
#endif

void sv_dtor(sv_t *self) {
  sv_id_dtor(&self->prerelease);
  sv_id_dtor(&self->build);
}

char sv_read(sv_t *self, const char *str, size_t len, size_t *offset) {
  if (*offset < len) {
    *self = (sv_t) {0};
    self->raw = str + *offset;
    if (str[*offset] == 'v') {
      ++*offset;
    }
    if (sv_num_read(&self->major, str, len, offset) || self->major == SV_NUM_X
      || *offset >= len || str[*offset] != '.'
      || sv_num_read(&self->minor, str, len, (++*offset, offset)) || self->minor == SV_NUM_X
      || *offset >= len || str[*offset] != '.'
      || sv_num_read(&self->patch, str, len, (++*offset, offset)) || self->patch == SV_NUM_X
      || (str[*offset] == '-' && sv_id_read(&self->prerelease, str, len, (++*offset, offset)))
      || (str[*offset] == '+' && sv_id_read(&self->build, str, len, (++*offset, offset)))) {
      self->len = str + *offset - self->raw;
      return 1;
    }
    self->len = str + *offset - self->raw;
    return 0;
  }
  return 1;
}

char sv_comp(const sv_t self, const sv_t other) {
  char result;

  if ((result = sv_num_comp(self.major, other.major)) != 0) {
    return result;
  }
  if ((result = sv_num_comp(self.minor, other.minor)) != 0) {
    return result;
  }
  if ((result = sv_num_comp(self.patch, other.patch)) != 0) {
    return result;
  }
  if ((result = sv_id_comp(self.prerelease, other.prerelease)) != 0) {
    return result;
  }
  return sv_id_comp(self.build, other.build);
}

int sv_write(const sv_t self, char *buffer, size_t len) {
  char prerelease[256], build[256];

  if (self.prerelease.len && self.build.len) {
    return snprintf(buffer, len, "%d.%d.%d-%.*s+%.*s",
      self.major, self.minor, self.patch,
                    sv_id_write(self.prerelease, prerelease, 256), prerelease,
                    sv_id_write(self.build, build, 256), build
    );
  }
  if (self.prerelease.len) {
    return snprintf(buffer, len, "%d.%d.%d-%.*s",
      self.major, self.minor, self.patch,
                    sv_id_write(self.prerelease, prerelease, 256), prerelease
    );
  }
  if (self.build.len) {
    return snprintf(buffer, len, "%d.%d.%d+%.*s",
      self.major, self.minor, self.patch,
                    sv_id_write(self.build, build, 256), build
    );
  }
  return snprintf(buffer, len, "%d.%d.%d", self.major, self.minor, self.patch);
}
