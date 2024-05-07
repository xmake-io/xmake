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
 * @file        compress.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "compress"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_lz4_compress(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get data and size
    tb_size_t        size = 0;
    tb_byte_t const* data = tb_null;
    if (xm_lua_isinteger(lua, 1)) data = (tb_byte_t const*)(tb_size_t)(tb_long_t)lua_tointeger(lua, 1);
    if (xm_lua_isinteger(lua, 2)) size = (tb_size_t)lua_tointeger(lua, 2);
    if (!data || !size)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "invalid data(%p) and size(%d)!", data, (tb_int_t)size);
        return 2;
    }
    tb_assert_static(sizeof(lua_Integer) >= sizeof(tb_pointer_t));

    // do compress
    tb_bool_t ok = tb_false;
    tb_char_t const* error = tb_null;
    tb_byte_t* output_data = tb_null;
    tb_byte_t buffer[8192];
    do
    {
        tb_size_t output_size = LZ4F_compressFrameBound(size, tb_null);
        tb_assert_and_check_break(output_size);

        output_data = output_size <= sizeof(buffer)? buffer : (tb_byte_t*)tb_malloc(output_size);
        tb_assert_and_check_break(output_data);

        tb_size_t real_or_errs = LZ4F_compressFrame(output_data, output_size, data, size, tb_null);
        if (LZ4F_isError(real_or_errs))
        {
            error = LZ4F_getErrorName(real_or_errs);
            break;
        }

        lua_pushlstring(lua, (tb_char_t const*)output_data, real_or_errs);
        ok = tb_true;
    } while (0);

    if (output_data && output_data != buffer)
    {
        tb_free(output_data);
        output_data = tb_null;
    }

    if (!ok)
    {
        lua_pushnil(lua);
        lua_pushstring(lua, error? error : "unknown");
        return 2;
    }
    return 1;
}
