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
#include <stdio.h>

#include "version.h"
#include "num.h"
#include "id.h"

void semver_ctor(semver_t *self) {
#ifndef _MSC_VER
  *self = (semver_t) {0};
#else
  self->len = 0;
  self->raw = NULL;
  self->major = 0;
  self->minor = 0;
  self->patch = 0;
  semver_id_ctor(&self->prerelease);
  semver_id_ctor(&self->build);
#endif
}

void semver_dtor(semver_t *self) {
  semver_id_dtor(&self->prerelease);
  semver_id_dtor(&self->build);
}

char semvern(semver_t *self, const char *str, size_t len) {
  size_t offset = 0;

  if (len > SV_MAX_LEN) {
    return 1;
  }
  if (semver_read(self, str, len, &offset) || offset < len) {
    semver_dtor(self);
    return 1;
  }
  return 0;
}

char semver_tryn(semver_t *self, const char *str, size_t len) {
  size_t offset = 0;

  if (len > SV_MAX_LEN) {
    return 1;
  }
  if (semver_try_read(self, str, len, &offset) || offset < len) {
    semver_dtor(self);
    return 1;
  }
  return 0;
}

char semver_read(semver_t *self, const char *str, size_t len, size_t *offset) {
  if (*offset < len) {
    semver_ctor(self);
    self->raw = str + *offset;
    if (str[*offset] == 'v') {
      ++*offset;
    }
    if (semver_num_read(&self->major, str, len, offset) || self->major == SEMVER_NUM_X
      || *offset >= len || str[*offset] != '.'
      || semver_num_read(&self->minor, str, len, (++*offset, offset)) || self->minor == SEMVER_NUM_X
      || *offset >= len || str[*offset] != '.'
      || semver_num_read(&self->patch, str, len, (++*offset, offset)) || self->patch == SEMVER_NUM_X
      || (str[*offset] == '-' && semver_id_read(&self->prerelease, str, len, (++*offset, offset)))
      || (str[*offset] == '+' && semver_id_read(&self->build, str, len, (++*offset, offset)))) {
      self->len = str + *offset - self->raw;
      return 1;
    }
    self->len = str + *offset - self->raw;
    return 0;
  }
  return 1;
}

char semver_try_read(semver_t *self, const char *str, size_t len, size_t *offset) {
  if (*offset < len) {
    semver_ctor(self);
    self->raw = str + *offset;
    if (str[*offset] == 'v') {
      ++*offset;
    }
    if (semver_num_read(&self->major, str, len, offset) || self->major == SEMVER_NUM_X) {
      fail:
      self->len = str + *offset - self->raw;
      return 1;
    }
    if (*offset < len && str[*offset] == '.'
        && (semver_num_read(&self->minor, str, len, (++*offset, offset)) || self->minor == SEMVER_NUM_X)) {
      goto fail;
    }
    if (*offset < len && str[*offset] == '.'
        && (semver_num_read(&self->patch, str, len, (++*offset, offset)) || self->patch == SEMVER_NUM_X)) {
      goto fail;
    }
    if (*offset < len && str[*offset] == '-') {
      ++*offset;
    }
    semver_id_read(&self->prerelease, str, len, offset);
    if (*offset < len && str[*offset] == '+') {
      ++*offset;
    }
    semver_id_read(&self->build, str, len, offset);
    self->len = str + *offset - self->raw;
    return 0;
  }
  return 1;
}

char semver_pcmp(const semver_t *self, const semver_t *other) {
  char result;

  if ((result = semver_num_cmp(self->major, other->major)) != 0) {
    return result;
  }
  if ((result = semver_num_cmp(self->minor, other->minor)) != 0) {
    return result;
  }
  if ((result = semver_num_cmp(self->patch, other->patch)) != 0) {
    return result;
  }
  return semver_id_comp(self->prerelease, other->prerelease);
}

int semver_pwrite(const semver_t *self, char *buffer, size_t len) {
  char prerelease[SV_MAX_LEN], build[SV_MAX_LEN];

  if (self->prerelease.len && self->build.len) {
    return snprintf(buffer, len, "%d.%d.%d-%.*s+%.*s",
      self->major, self->minor, self->patch,
      semver_id_write(self->prerelease, prerelease, SV_MAX_LEN), prerelease,
      semver_id_write(self->build, build, SV_MAX_LEN), build
    );
  }
  if (self->prerelease.len) {
    return snprintf(buffer, len, "%d.%d.%d-%.*s",
      self->major, self->minor, self->patch,
      semver_id_write(self->prerelease, prerelease, SV_MAX_LEN), prerelease
    );
  }
  if (self->build.len) {
    return snprintf(buffer, len, "%d.%d.%d+%.*s",
      self->major, self->minor, self->patch,
      semver_id_write(self->build, build, SV_MAX_LEN), build
    );
  }
  return snprintf(buffer, len, "%d.%d.%d", self->major, self->minor, self->patch);
}
