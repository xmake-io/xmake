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
 * @file        bin2c.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "bin2c"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static __tb_inline__ tb_size_t xm_utils_bin2c_hex2str(tb_char_t str[5], tb_byte_t value)
{
    static tb_char_t const* digits_table = "0123456789ABCDEF";
    str[0] = ' ';
    str[1] = '0';
    str[2] = 'x';
    str[3] = digits_table[(value >> 4) & 15];
    str[4] = digits_table[value & 15];
    return 5;
}

static tb_bool_t xm_utils_bin2c_dump(tb_stream_ref_t istream, tb_stream_ref_t ostream, tb_int_t linewidth, tb_bool_t nozeroend)
{
    tb_bool_t first = tb_true;
    tb_hong_t i = 0;
    tb_hong_t left = 0;
    tb_char_t line[4096];
    tb_byte_t data[512];
    tb_size_t linesize = 0;
    tb_size_t need = 0;
    tb_assert_and_check_return_val(linewidth < sizeof(data), tb_false);
    while (!tb_stream_beof(istream))
    {
        linesize = 0;
        left = tb_stream_left(istream);
        need = (tb_size_t)tb_min(left, linewidth);
        if (need)
        {
            if (!tb_stream_bread(istream, data, need))
                break;

            if (!nozeroend && tb_stream_beof(istream))
            {
                tb_assert_and_check_break(need + 1 < sizeof(data));
                data[need++] = '\0';
            }

            tb_assert_and_check_break(linesize + 6 * need < sizeof(line));

            i = 0;
            if (first)
            {
                first = tb_false;
                line[linesize++] = ' ';
            }
            else line[linesize++] = ',';
            linesize += xm_utils_bin2c_hex2str(line + linesize, data[i]);

            for (i = 1; i < need; i++)
            {
                line[linesize++] = ',';
                linesize += xm_utils_bin2c_hex2str(line + linesize, data[i]);
            }
            tb_assert_and_check_break(i == need && linesize && linesize < sizeof(line));

            if (tb_stream_bwrit_line(ostream, line, linesize) < 0)
                break;
        }
    }

    return tb_stream_beof(istream);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* generate c/c++ code from the binary file
 *
 * local ok, errors = utils.bin2c(binaryfile, outputfile, linewidth, nozeroend)
 */
tb_int_t xm_utils_bin2c(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the binaryfile
    tb_char_t const* binaryfile = luaL_checkstring(lua, 1);
    tb_check_return_val(binaryfile, 0);

    // get the outputfile
    tb_char_t const* outputfile = luaL_checkstring(lua, 2);
    tb_check_return_val(outputfile, 0);

    // get line width
    tb_int_t linewidth = (tb_int_t)lua_tointeger(lua, 3);

    // no zero end?
    tb_bool_t nozeroend = (tb_bool_t)lua_toboolean(lua, 4);

    // do dump
    tb_bool_t ok = tb_false;
    tb_stream_ref_t istream = tb_stream_init_from_file(binaryfile, TB_FILE_MODE_RO);
    tb_stream_ref_t ostream = tb_stream_init_from_file(outputfile, TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
    do
    {
        if (!tb_stream_open(istream))
        {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2c: open %s failed", binaryfile);
            break;
        }

        if (!tb_stream_open(ostream))
        {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2c: open %s failed", outputfile);
            break;
        }

        if (!xm_utils_bin2c_dump(istream, ostream, linewidth, nozeroend))
        {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2c: dump data failed");
            break;
        }

        ok = tb_true;
        lua_pushboolean(lua, ok);

    } while (0);

    if (istream) tb_stream_clos(istream);
    istream = tb_null;

    if (ostream) tb_stream_clos(ostream);
    ostream = tb_null;

    return ok? 1 : 2;
}
