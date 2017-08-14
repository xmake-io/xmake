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

#ifndef SV_H__
# define SV_H__

#include <stddef.h>
#include <stdio.h>
#include <string.h>

#ifndef SV_COMPILE
# define SV_COMPILE (0)
#endif

#ifndef SV_BUILD_DYNAMIC_LINK
# define SV_BUILD_DYNAMIC_LINK (0)
#endif

#if SV_BUILD_DYNAMIC_LINK && defined(_MSC_VER)
# define SV_EXPORT_LINK __declspec(dllexport)
# define SV_IMPORT_LINK __declspec(dllimport)
#else
# define SV_EXPORT_LINK
# define SV_IMPORT_LINK
#endif
#if SV_COMPILE
# ifdef __cplusplus
#   define SV_API extern "C" SV_EXPORT_LINK
# else
#   define SV_API extern SV_EXPORT_LINK
# endif
#else
# ifdef __cplusplus
#   define SV_API extern "C" SV_IMPORT_LINK
# else
#   define SV_API extern SV_IMPORT_LINK
# endif
#endif

#ifndef __cplusplus
# if defined(_MSC_VER) && _MSC_VER < 1900
#   define bool	unsigned char
#   define true	1
#   define false	0
#   define __bool_true_false_are_defined	1
# else
#   include <stdbool.h>
# endif
#endif

#if defined(_MSC_VER)
typedef __int8 int8_t;
typedef __int16 int16_t;
typedef __int32 int32_t;
typedef __int64 int64_t;
typedef unsigned __int8 uint8_t;
typedef unsigned __int16 uint16_t;
typedef unsigned __int32 uint32_t;
typedef unsigned __int64 uint64_t;
#ifdef _WIN64
typedef __int64 intptr_t;
typedef unsigned __int64 uintptr_t;
#else
typedef __int32 intptr_t;
typedef unsigned __int32 uintptr_t;
#endif
#else
#   include <stdint.h>
#endif

#ifndef sv_malloc
# define sv_malloc malloc
#endif

#ifndef sv_free
# define sv_free free
#endif

#define SEMVER_NUM_X (-1)

#define semver(self, str) semvern(self, str, strlen(str))
#define semver_write(self, buffer, len) semver_pwrite(&(self), buffer, len)
#define semver_cmp(self, other) semver_pcmp(&(self), &(other))
#define semver_comp(self, str) semver_compn(self, str, strlen(str))
#define semver_comp_write(self, buffer, len) semver_comp_pwrite(&(self), buffer, len)
#define semver_comp_match(self, comp) semver_comp_pmatch(&(self), &(comp))
#define semver_match(self, comp_str) semver_comp_matchn(&(self), comp_str, strlen(comp_str))
#define semver_range(self, str) semver_rangen(self, str, strlen(str))
#define semver_range_write(self, buffer, len) semver_range_pwrite(&(self), buffer, len)
#define semver_range_match(self, range) semver_range_pmatch(&(self), &(range))
#define semver_rmatch(self, range_str) semver_range_matchn(&(self), range_str, strlen(range_str))

typedef struct semver semver_t;
typedef struct semver_id semver_id_t;
typedef struct semver_comp semver_comp_t;
typedef struct semver_range semver_range_t;
typedef struct semvers semvers_t;

enum semver_op {
  SEMVER_OP_EQ = 0,
  SEMVER_OP_LT,
  SEMVER_OP_LE,
  SEMVER_OP_GT,
  SEMVER_OP_GE,
};

struct semver_id {
  bool numeric;
  int num;
  size_t len;
  const char *raw;
  struct semver_id *next;
};

struct semver {
  int major, minor, patch;
  semver_id_t prerelease, build;
  size_t len;
  const char *raw;
};

SV_API char semvern(semver_t *self, const char *str, size_t len);
SV_API char semver_tryn(semver_t *self, const char *str, size_t len);
SV_API void semver_dtor(semver_t *self);
SV_API int  semver_pwrite(const semver_t *self, char *buffer, size_t len);
SV_API size_t semver_fwrite (const semver_t *self, FILE * stream);
SV_API char semver_pcmp(const semver_t *self, const semver_t *other);
SV_API bool semver_comp_pmatch(const semver_t *self, const semver_comp_t *comp);
SV_API bool semver_comp_matchn(const semver_t *self, const char *comp_str, size_t comp_len);
SV_API bool semver_range_pmatch(const semver_t *self, const semver_range_t *range);
SV_API bool semver_range_matchn(const semver_t *self, const char *range_str, size_t range_len);

struct semver_comp {
  struct semver_comp *next;
  enum semver_op op;
  semver_t version;
};

SV_API char semver_compn(semver_comp_t *self, const char *str, size_t len);
SV_API void semver_comp_dtor(semver_comp_t *self);
SV_API int  semver_comp_pwrite(const semver_comp_t *self, char *buffer, size_t len);
SV_API size_t semver_comp_fwrite (const semver_comp_t *self, FILE *stream);
SV_API char semver_and(semver_comp_t *left, const char *str, size_t len);

struct semver_range {
  struct semver_range *next;
  semver_comp_t comp;
};

SV_API char semver_rangen(semver_range_t *self, const char *str, size_t len);
SV_API void semver_range_dtor(semver_range_t *self);
SV_API int  semver_range_pwrite(const semver_range_t *self, char *buffer, size_t len);
SV_API size_t semver_range_fwrite (const semver_range_t *rangep, FILE *stream);
SV_API char semver_or(semver_range_t *left, const char *str, size_t len);

struct semvers {
  uint32_t length, capacity;
  semver_t *data;
};

SV_API uint32_t semvers_pgrowth(semvers_t *self, int32_t nmin);
SV_API semver_t semvers_perase(semvers_t *self, uint32_t i);
SV_API void semvers_psort(semvers_t *self);
SV_API void semvers_prsort(semvers_t *self);
SV_API void semvers_pdtor(semvers_t *self);
SV_API void semvers_pclear(semvers_t *self);

#define semvers_dtor(s) \
  semvers_pdtor(&(s))

#define semvers_clear(s) \
  semvers_pclear(&(s))

#define semvers_growth(s, n) \
  semvers_pgrowth(&(s),n)

#define semvers_grow(s, n) \
  semvers_pgrowth(&(s),(s).length+(n))

#define semvers_resize(s, n) \
  ((s).length=semvers_growth(s, n))

#define semvers_erase(s, i) \
  semvers_perase(&(s), i)

#define semvers_push(s, x) \
  (semvers_grow(s,1),(s).data[(s).length++]=(x))

#define semvers_pop(s) \
  (s).data[--(s).length]

#define semvers_unshift(s, x) \
  (semvers_grow(s,1),memmove((s).data+1,(s).data,(s).length++*sizeof(semver_t)),(s).data[0]=(x))

#define semvers_shift(s) \
  semvers_erase(s, 0)

#define semvers_sort(s) \
  semvers_psort(&(s))

#define semvers_rsort(s) \
  semvers_prsort(&(s))

#endif /* SV_H__ */
