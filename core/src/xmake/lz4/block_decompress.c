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
 * @file        block_decompress.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "block_decompress"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_lz4_block_decompress(lua_State* lua)
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

    // get real size
    tb_int_t real = (tb_int_t)lua_tointeger(lua, 3);
    if (real <= 0)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "invalid output size(%d)!", real);
        return 2;
    }

    // do decompress
    tb_bool_t ok = tb_false;
    tb_byte_t* output_data = tb_null;
    tb_byte_t buffer[8192];
    do
    {
        output_data = real <= sizeof(buffer)? buffer : (tb_byte_t*)tb_malloc(real);
        tb_assert_and_check_break(output_data);

        tb_int_t r = LZ4_decompress_safe((tb_char_t const*)data, (tb_char_t*)output_data, (tb_int_t)size, real);
        tb_assert_and_check_break(r > 0);

        lua_pushlstring(lua, (tb_char_t const*)output_data, r);
        ok = tb_true;
    } while (0);

    if (output_data && output_data != buffer)
    {
        tb_free(output_data);
        output_data = tb_null;
    }

    if (!ok) lua_pushnil(lua);
    return 1;
}

