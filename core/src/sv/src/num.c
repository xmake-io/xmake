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
#include <ctype.h>
#include <semver.h>

#ifdef _MSC_VER
# define snprintf(s, maxlen, fmt, ...) _snprintf_s(s, _TRUNCATE, maxlen, fmt, __VA_ARGS__)
#endif

char semver_num_read(int *self, const char *str, size_t len, size_t *offset) {
  char *endptr;

  *self = 0;
  if (*offset >= len) {
    return 1;
  }
  switch (str[*offset]) {
    case 'x':
    case 'X':
    case '*':
      *self = SEMVER_NUM_X;
      ++*offset;
      break;
    default:
      if (isdigit(str[*offset])) {
        *self = (int) strtol(str + *offset, &endptr, 0);
        *offset += endptr - str - *offset;
      } else {
        return 1;
      }
      break;
  }
  return 0;
}

char semver_num_comp(const int self, const int other) {
  if (self == SEMVER_NUM_X || other == SEMVER_NUM_X) {
    return 0;
  }
  if (self > other) {
    return 1;
  }
  if (self < other) {
    return -1;
  }
  return 0;
}
