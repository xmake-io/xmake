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

#ifndef SEMVER_H__
# define SEMVER_H__

#include <stddef.h>

#define SV_NUM_X -1

typedef struct sv sv_t;
typedef struct sv_id sv_id_t;
typedef struct sv_comp sv_comp_t;
typedef struct sv_range sv_range_t;

enum sv_op {
  SV_OP_EQ = 0,
  SV_OP_LT,
  SV_OP_LE,
  SV_OP_GT,
  SV_OP_GE,
};

char sv_num_read(int *self, const char *str, size_t len, size_t *offset);
char sv_num_comp(const int self, const int other);

struct sv_id {
  char numeric;
  int num;
  size_t len;
  const char *raw;
  struct sv_id *next;
};

void sv_id_ctor(sv_id_t *self);
void sv_id_dtor(sv_id_t *self);
char sv_id_read(sv_id_t *self, const char *str, size_t len, size_t *offset);
int  sv_id_write(const sv_id_t self, char *buffer, size_t len);
char sv_id_comp(const sv_id_t self, const sv_id_t other);

struct sv {
  int major, minor, patch;
  sv_id_t prerelease, build;
  size_t len;
  const char *raw;
};

void sv_ctor(sv_t *self);
void sv_dtor(sv_t *self);
char sv_read(sv_t *self, const char *str, size_t len, size_t *offset);
int  sv_write(const sv_t self, char *buffer, size_t len);
char sv_comp(const sv_t self, const sv_t other);

struct sv_comp {
  struct sv_comp *next;
  enum sv_op op;
  sv_t version;
};

void sv_comp_ctor(sv_comp_t *self);
void sv_comp_dtor(sv_comp_t *self);
char sv_comp_read(sv_comp_t *self, const char *str, size_t len, size_t *offset);
int  sv_comp_write(const sv_comp_t self, char *buffer, size_t len);
char sv_match(const sv_t self, const sv_comp_t comp);

struct sv_range {
  struct sv_range *next;
  sv_comp_t comp;
};

void sv_range_ctor(sv_range_t *self);
void sv_range_dtor(sv_range_t *self);
char sv_range_read(sv_range_t *self, const char *str, size_t len, size_t *offset);
int  sv_range_write(const sv_range_t self, char *buffer, size_t len);
char sv_rmatch(const sv_t self, const sv_range_t range);

#endif /* SEMVER_H__ */
