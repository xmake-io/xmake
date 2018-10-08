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
#include <errno.h>

#include "utils.h"
#include "comp.h"
#include "range.h"

/*!\brief Serialise the version to the STREAM. When successful: return the
 * number of bytes written and set "errno" to zero. When unsuccessful:
 * set "errno" to an error code.
 */
size_t semver_fwrite(const semver_t *self, FILE *stream) {
  char buffer[SV_MAX_LEN];
  int cs;

  if ((cs = semver_pwrite(self, buffer, SV_MAX_LEN)) == 0) {
    return 0;
  }
  errno = 0;
  return fwrite(buffer, sizeof(char), (size_t) cs, stream);
}

/*!\brief Serialise the comparator to the STREAM. When successful: return the
 * number of bytes written and set "errno" to zero. When unsuccessful:
 * set "errno" to an error code.
 */
size_t semver_comp_fwrite(const semver_comp_t *self, FILE *stream) {
  char buffer[SV_COMP_MAX_LEN];
  int cs;

  if ((cs = semver_comp_pwrite(self, buffer, SV_COMP_MAX_LEN)) == 0) {
    return 0;
  }
  errno = 0;
  return fwrite(buffer, sizeof(char), (size_t) cs, stream);
}

/*!\brief Serialise the range to the STREAM. When successful: return the
 * number of bytes written and set "errno" to zero. When unsuccessful:
 * set "errno" to an error code.
 */
size_t semver_range_fwrite(const semver_range_t *self, FILE *stream) {
  char buffer[SV_RANGE_MAX_LEN];
  int cs;

  if ((cs = semver_range_pwrite(self, buffer, SV_RANGE_MAX_LEN)) == 0) {
    return 0;
  }
  errno = 0;
  return fwrite(buffer, sizeof(char), (size_t) cs, stream);
}

const char *semver_op_string(enum semver_op op) {
  switch (op) {
    case SEMVER_OP_EQ:
      return "";
    case SEMVER_OP_LT:
      return "<";
    case SEMVER_OP_LE:
      return "<=";
    case SEMVER_OP_GT:
      return ">";
    case SEMVER_OP_GE:
      return ">=";
    default:
      return NULL;
  }
}
