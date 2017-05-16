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

static void semver_xrevert(semver_t *semver) {
  if (semver->major == SEMVER_NUM_X) {
    semver->major = semver->minor = semver->patch = 0;
  } else if (semver->minor == SEMVER_NUM_X) {
    semver->minor = semver->patch = 0;
  } else if (semver->patch == SEMVER_NUM_X) {
    semver->patch = 0;
  }
}

static semver_comp_t *semver_xconvert(semver_comp_t *self) {
  if (self->version.major == SEMVER_NUM_X) {
    self->op = SEMVER_OP_GE;
    semver_xrevert(&self->version);
    return self;
  }
  if (self->version.minor == SEMVER_NUM_X) {
    semver_xrevert(&self->version);
    self->op = SEMVER_OP_GE;
    self->next = (semver_comp_t *) malloc(sizeof(semver_comp_t));
    semver_comp_ctor(self->next);
    self->next->op = SEMVER_OP_LT;
    self->next->version = self->version;
    ++self->next->version.major;
    return self->next;
  }
  if (self->version.patch == SEMVER_NUM_X) {
    semver_xrevert(&self->version);
    self->op = SEMVER_OP_GE;
    self->next = (semver_comp_t *) malloc(sizeof(semver_comp_t));
    semver_comp_ctor(self->next);
    self->next->op = SEMVER_OP_LT;
    self->next->version = self->version;
    ++self->next->version.minor;
    return self->next;
  }
  self->op = SEMVER_OP_EQ;
  return self;
}

static char parse_partial(semver_t *self, const char *str, size_t len, size_t *offset) {
  semver_ctor(self);
  self->major = self->minor = self->patch = SEMVER_NUM_X;
  if (*offset < len) {
    self->raw = str + *offset;
    if (semver_num_read(&self->major, str, len, offset)) {
      return 0;
    }
    if (*offset >= len || str[*offset] != '.') {
      return 0;
    }
    ++*offset;
    if (semver_num_read(&self->minor, str, len, offset)) {
      return 1;
    }
    if (*offset >= len || str[*offset] != '.') {
      return 0;
    }
    ++*offset;
    if (semver_num_read(&self->patch, str, len, offset)) {
      return 1;
    }
    if ((str[*offset] == '-' && semver_id_read(&self->prerelease, str, len, (++*offset, offset)))
      || (str[*offset] == '+' && semver_id_read(&self->build, str, len, (++*offset, offset)))) {
      return 1;
    }
    self->len = str + *offset - self->raw;
    return 0;
  }
  return 0;
}

static char parse_hiphen(semver_comp_t *self, const char *str, size_t len, size_t *offset) {
  semver_t partial;

  if (parse_partial(&partial, str, len, offset)) {
    return 1;
  }
  self->op = SEMVER_OP_GE;
  semver_xrevert(&self->version);
  self->next = (semver_comp_t *) malloc(sizeof(semver_comp_t));
  semver_comp_ctor(self->next);
  self->next->op = SEMVER_OP_LT;
  if (partial.minor == SEMVER_NUM_X) {
    self->next->version.major = partial.major + 1;
  } else if (partial.patch == SEMVER_NUM_X) {
    self->next->version.major = partial.major;
    self->next->version.minor = partial.minor + 1;
  } else {
    self->next->op = SEMVER_OP_LE;
    self->next->version = partial;
  }

  return 0;
}

static char parse_tidle(semver_comp_t *self, const char *str, size_t len, size_t *offset) {
  semver_t partial;

  if (parse_partial(&self->version, str, len, offset)) {
    return 1;
  }
  semver_xrevert(&self->version);
  self->op = SEMVER_OP_GE;
  partial = self->version;
  if (partial.major != 0) {
    ++partial.major;
    partial.minor = partial.patch = 0;
  } else if (partial.minor != 0) {
    ++partial.minor;
    partial.patch = 0;
  } else {
    ++partial.patch;
  }
  self->next = (semver_comp_t *) malloc(sizeof(semver_comp_t));
  semver_comp_ctor(self->next);
  self->next->op = SEMVER_OP_LT;
  self->next->version = partial;
  return 0;
}

static char parse_caret(semver_comp_t *self, const char *str, size_t len, size_t *offset) {
  semver_t partial;

  if (parse_partial(&self->version, str, len, offset)) {
    return 1;
  }
  semver_xrevert(&self->version);
  self->op = SEMVER_OP_GE;
  partial = self->version;
  if (partial.minor || partial.patch) {
    ++partial.minor;
    partial.patch = 0;
  } else {
    ++partial.major;
    partial.minor = partial.patch = 0;
  }
  self->next = (semver_comp_t *) malloc(sizeof(semver_comp_t));
  semver_comp_ctor(self->next);
  self->next->op = SEMVER_OP_LT;
  self->next->version = partial;
  return 0;
}

void semver_comp_ctor(semver_comp_t *self) {
#ifndef _MSC_VER
  *self = (semver_comp_t) {0};
#else
  self->next = NULL;
  self->op = SEMVER_OP_EQ;
  semver_ctor(&self->version);
#endif
}

void semver_comp_dtor(semver_comp_t *self) {
  if (self && self->next) {
    semver_comp_dtor(self->next);
    free(self->next);
    self->next = NULL;
  }
}

char semver_comp_read(semver_comp_t *self, const char *str, size_t len, size_t *offset) {
  semver_comp_ctor(self);
  while (*offset < len) {
    switch (str[*offset]) {
      case '^':
        ++*offset;
        if (parse_tidle(self, str, len, offset)) {
          return 1;
        }
        self = self->next;
        goto next;
      case '~':
        ++*offset;
        if (parse_caret(self, str, len, offset)) {
          return 1;
        }
        self = self->next;
        goto next;
      case '>':
        ++*offset;
        if (*offset < len && str[*offset] == '=') {
          ++*offset;
          self->op = SEMVER_OP_GE;
        } else {
          self->op = SEMVER_OP_GT;
        }
        if (parse_partial(&self->version, str, len, offset)) {
          return 1;
        }
        semver_xrevert(&self->version);
        goto next;
      case '<':
        ++*offset;
        if (*offset < len && str[*offset] == '=') {
          ++*offset;
          self->op = SEMVER_OP_LE;
        } else {
          self->op = SEMVER_OP_LT;
        }
        if (parse_partial(&self->version, str, len, offset)) {
          return 1;
        }
        semver_xrevert(&self->version);
        goto next;
      case '=':
        ++*offset;
        self->op = SEMVER_OP_EQ;
        if (parse_partial(&self->version, str, len, offset)) {
          return 1;
        }
        semver_xrevert(&self->version);
        goto next;
      default:
        goto range;
    }
  }
  range:
  if (parse_partial(&self->version, str, len, offset)) {
    return 1;
  }
  if (*offset < len && str[*offset] == ' '
    && *offset + 1 < len && str[*offset + 1] == '-'
    && *offset + 2 < len && str[*offset + 2] == ' ') {
    *offset += 3;
    if (parse_hiphen(self, str, len, offset)) {
      return 1;
    }
    self = self->next;
  } else {
    self = semver_xconvert(self);
  }
  next:
  if (*offset < len && str[*offset] == ' '
    && *offset < len + 1 && str[*offset + 1] != ' ' && str[*offset + 1] != '|') {
    ++*offset;
    if (*offset < len) {
      self->next = (semver_comp_t *) malloc(sizeof(semver_comp_t));
      return semver_comp_read(self->next, str, len, offset);
    }
    return 1;
  }
  return 0;
}

char semver_match(const semver_t self, const semver_comp_t comp) {
  switch (semver_comp(self, comp.version)) {
    case -1:
      if (comp.op != SEMVER_OP_LT && comp.op != SEMVER_OP_LE) {
        return 0;
      }
      break;
    case 0:
      if (comp.op != SEMVER_OP_EQ && comp.op != SEMVER_OP_LE && comp.op != SEMVER_OP_GE) {
        return 0;
      }
      break;
    case 1:
      if (comp.op != SEMVER_OP_GT && comp.op != SEMVER_OP_GE) {
        return 0;
      }
      break;
    default:
      return 0;
  }
  if (comp.next) {
    return semver_match(self, *comp.next);
  }
  return 1;
}

int semver_comp_write(const semver_comp_t self, char *buffer, size_t len) {
  char *op = "";
  char semver[256], next[1024];

  switch (self.op) {
    case SEMVER_OP_EQ:
      break;
    case SEMVER_OP_LT:
      op = "<";
      break;
    case SEMVER_OP_LE:
      op = "<=";
      break;
    case SEMVER_OP_GT:
      op = ">";
      break;
    case SEMVER_OP_GE:
      op = ">=";
      break;
  }
  semver_write(self.version, semver, 256);
  if (self.next) {
    return snprintf(buffer, len, "%s%s %.*s", op, semver, semver_comp_write(*self.next, next, 1024), next);
  }
  return snprintf(buffer, len, "%s%s", op, semver);
}
