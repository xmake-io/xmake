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
#ifndef XM_BINUTILS_PREFIX_H
#define XM_BINUTILS_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline implementation
 */

/* copy data from input stream to output stream
 *
 * @param istream    the input stream
 * @param ostream    the output stream
 * @param size       the size to copy
 *
 * @return           tb_true on success, tb_false on failure
 */
static __tb_inline__ tb_bool_t xm_binutils_stream_copy(tb_stream_ref_t istream, tb_stream_ref_t ostream, tb_hize_t size) {
    tb_assert_and_check_return_val(istream && ostream && size > 0, tb_false);

    tb_byte_t data[TB_STREAM_BLOCK_MAXN];
    tb_hize_t writ = 0;
    do {
        tb_size_t need = (tb_size_t)tb_min(size - writ, (tb_hize_t)TB_STREAM_BLOCK_MAXN);
        tb_check_break(need);

        tb_long_t real = tb_stream_read(istream, data, need);
        if (real > 0) {
            if (!tb_stream_bwrit(ostream, data, (tb_size_t)real)) {
                return tb_false;
            }
            writ += real;
        } else if (!real) {
            tb_long_t wait = tb_stream_wait(istream, TB_STREAM_WAIT_READ, tb_stream_timeout(istream));
            tb_check_break(wait > 0 && (wait & TB_STREAM_WAIT_READ));
        } else {
            return tb_false;
        }

        tb_check_break(writ < size);
    } while (1);

    return tb_true;
}

#endif

