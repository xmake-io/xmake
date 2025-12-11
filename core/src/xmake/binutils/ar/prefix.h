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
#ifndef XM_BINUTILS_AR_PREFIX_H
#define XM_BINUTILS_AR_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../coff/prefix.h"
#include "../elf/prefix.h"
#include "../macho/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * forward declarations
 */
extern tb_bool_t xm_binutils_coff_read_symbols(tb_stream_ref_t istream, lua_State *lua);
extern tb_bool_t xm_binutils_elf_read_symbols(tb_stream_ref_t istream, lua_State *lua);
extern tb_bool_t xm_binutils_macho_read_symbols(tb_stream_ref_t istream, lua_State *lua);
extern tb_int_t xm_binutils_detect_format(tb_stream_ref_t istream);

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
#include "tbox/prefix/packed.h"
typedef struct __xm_ar_header_t {
    tb_char_t name[16];   // file name (null-padded)
    tb_char_t date[12];   // modification time (decimal)
    tb_char_t uid[6];     // user ID (decimal)
    tb_char_t gid[6];     // group ID (decimal)
    tb_char_t mode[8];    // file mode (octal)
    tb_char_t size[10];   // file size (decimal)
    tb_char_t fmag[2];    // magic: "`\n"
} __tb_packed__ xm_ar_header_t;
#include "tbox/prefix/packed.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline implementation
 */

/* parse decimal number from string
 *
 * @param str the string
 * @param len the length
 * @return    the parsed number, or -1 on error
 */
static __tb_inline__ tb_int64_t xm_binutils_ar_parse_decimal(tb_char_t const *str, tb_size_t len) {
    tb_assert_and_check_return_val(str && len > 0, -1);
    
    tb_int64_t result = 0;
    for (tb_size_t i = 0; i < len; i++) {
        if (str[i] == ' ' || str[i] == '\0') {
            break;
        }
        if (str[i] < '0' || str[i] > '9') {
            return -1;
        }
        result = result * 10 + (str[i] - '0');
    }
    return result;
}

/* check AR magic (!<arch>\n)
 *
 * @param istream    the input stream
 * @return           tb_true on success, tb_false on failure
 */
static __tb_inline__ tb_bool_t xm_binutils_ar_check_magic(tb_stream_ref_t istream) {
    tb_uint8_t magic[8];
    if (!tb_stream_seek(istream, 0)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, magic, 8)) {
        return tb_false;
    }
    if (magic[0] != '!' || magic[1] != '<' || magic[2] != 'a' || magic[3] != 'r' ||
        magic[4] != 'c' || magic[5] != 'h' || (magic[6] != '>' && magic[6] != '\n') ||
        (magic[7] != '\n' && magic[7] != '\r')) {
        return tb_false;
    }
    return tb_true;
}

#endif
