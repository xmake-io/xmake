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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        compress_file.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "compress_file"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_lz4_compress_file(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the file paths
    tb_char_t const* srcpath = luaL_checkstring(lua, 1);
    tb_char_t const* dstpath = luaL_checkstring(lua, 2);
    tb_check_return_val(srcpath && dstpath, 0);

    // init lz4 stream
    xm_lz4_cstream_t* stream_lz4 = xm_lz4_cstream_init();
    tb_check_return_val(stream_lz4, 0);

    // do compress
    tb_bool_t       ok = tb_false;
    tb_stream_ref_t istream = tb_stream_init_from_file(srcpath, TB_FILE_MODE_RO);
    tb_stream_ref_t ostream = tb_stream_init_from_file(dstpath, TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
    if (istream && ostream && tb_stream_open(istream) && tb_stream_open(ostream))
    {
        tb_bool_t write_ok = tb_false;
        tb_byte_t idata[TB_STREAM_BLOCK_MAXN];
        tb_byte_t odata[TB_STREAM_BLOCK_MAXN];
        while (!tb_stream_beof(istream))
        {
            write_ok = tb_false;
            tb_long_t ireal = (tb_long_t)tb_stream_read(istream, idata, sizeof(idata));
            if (ireal > 0)
            {
                tb_long_t r = xm_lz4_cstream_write(stream_lz4, idata, ireal, tb_stream_beof(istream));
                tb_assert_and_check_break(r >= 0);
                tb_check_continue(r > 0);

                tb_long_t oreal;
                while ((oreal = xm_lz4_cstream_read(stream_lz4, odata, sizeof(odata))) > 0)
                {
                    if (!tb_stream_bwrit(ostream, odata, oreal))
                    {
                        oreal = -1;
                        break;
                    }
                }
                tb_assert_and_check_break(oreal >= 0);
            }
            else break;
            write_ok = tb_true;
        }

        if (tb_stream_beof(istream) && write_ok)
            ok = tb_true;
    }

    // exit stream
    if (istream)
    {
        tb_stream_exit(istream);
        istream = tb_null;
    }
    if (ostream)
    {
        tb_stream_exit(ostream);
        ostream = tb_null;
    }
    xm_lz4_cstream_exit(stream_lz4);

    // ok?
    lua_pushboolean(lua, ok);
    return 1;
}
