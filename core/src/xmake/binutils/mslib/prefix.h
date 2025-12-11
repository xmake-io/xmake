/*!A cross-platform build utility based on Lua
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        prefix.h
 *
 */
#ifndef XM_BINUTILS_MSLIB_PREFIX_H
#define XM_BINUTILS_MSLIB_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// MSVC lib header
#include "tbox/prefix/packed.h"
typedef struct __xm_mslib_header_t {
    tb_char_t   name[16];
    tb_char_t   date[12];
    tb_char_t   uid[6];
    tb_char_t   gid[6];
    tb_char_t   mode[8];
    tb_char_t   size[10];
    tb_char_t   fmag[2];
} __tb_packed__ xm_mslib_header_t;
#include "tbox/prefix/packed.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

static __tb_inline__ tb_int64_t xm_binutils_mslib_parse_decimal(tb_char_t const *p, tb_size_t n) {
    tb_assert_and_check_return_val(p && n > 0, -1);
    tb_int64_t v = 0;
    tb_char_t const* e = p + n;
    while (p < e && *p == ' ') {
        p++;
    }
    while (p < e && *p >= '0' && *p <= '9') {
        v = v * 10 + (*p - '0');
        p++;
    }
    return v;
}

static __tb_inline__ tb_bool_t xm_binutils_mslib_check_magic(tb_stream_ref_t istream) {
    tb_char_t magic[8];
    if (!tb_stream_bread(istream, (tb_byte_t*)magic, 8)) {
        return tb_false;
    }
    return tb_strncmp(magic, "!<arch>\n", 8) == 0;
}

#endif
