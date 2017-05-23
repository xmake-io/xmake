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

#ifndef SV_ID_H__
# define SV_ID_H__

#include "version.h"

void semver_id_ctor(semver_id_t *self);
void semver_id_dtor(semver_id_t *self);
char semver_id_read(semver_id_t *self, const char *str, size_t len, size_t *offset);
int  semver_id_pwrite(const semver_id_t *self, char *buffer, size_t len);
char semver_id_pcmp(const semver_id_t *self, const semver_id_t *other);

#define semver_id_write(self, buffer, len) semver_id_pwrite(&(self), buffer, len)
#define semver_id_comp(self, other) semver_id_pcmp(&(self), &(other))

#endif /* SV_ID_H__ */
