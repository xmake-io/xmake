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

    tb_trace_i("binaryfile: %s", binaryfile);
    tb_trace_i("outputfile: %s", outputfile);
    tb_trace_i("linewidth: %d", linewidth);
    tb_trace_i("nozeroend: %d", nozeroend);

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

        ok = tb_true;
        lua_pushboolean(lua, ok);

    } while (0);

    if (istream) tb_stream_clos(istream);
    istream = tb_null;

    if (ostream) tb_stream_clos(ostream);
    ostream = tb_null;

    return ok? 1 : 2;
}
