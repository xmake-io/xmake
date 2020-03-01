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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        split.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "string_split"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_string_split_str(lua_State* lua, tb_char_t const* cstr, tb_size_t nstr, tb_char_t const* cdls, tb_size_t ndls, tb_bool_t strict, tb_int_t limit)
{
    tb_int_t num = 0;
    tb_char_t const* end = cstr + nstr;
    tb_char_t const* pos = tb_strstr(cstr, cdls); // faster than tb_strnstr()
    while (pos && pos < end)
    {
        if (pos > cstr || strict)
        {
            if (limit > 0 && num + 1 >= limit)
                break;

            lua_pushlstring(lua, cstr, pos - cstr);
            lua_rawseti(lua, -2, ++num);
        }

        cstr = pos + ndls;
        pos = tb_strstr(cstr, cdls);
    }
    if (cstr < end)
    {
        lua_pushlstring(lua, cstr, end - cstr);
        lua_rawseti(lua, -2, ++num);
    }
    else if (strict && (limit < 0 || num < limit) && cstr == end)
    {
        lua_pushliteral(lua, "");
        lua_rawseti(lua, -2, ++num);
    }
}
static tb_void_t xm_string_split_chr(lua_State* lua, tb_char_t const* cstr, tb_size_t nstr, tb_char_t ch, tb_bool_t strict, tb_int_t limit)
{
    tb_int_t num = 0;
    tb_char_t const* end = cstr + nstr;
    tb_char_t const* pos = tb_strchr(cstr, ch); // faster than tb_strnchr()
    while (pos && pos < end)
    {
        if (pos > cstr || strict)
        {
            if (limit > 0 && num + 1 >= limit)
                break;

            lua_pushlstring(lua, cstr, pos - cstr);
            lua_rawseti(lua, -2, ++num);
        }

        cstr = pos + 1;
        pos = tb_strchr(cstr, ch);
    }
    if (cstr < end)
    {
        lua_pushlstring(lua, cstr, end - cstr);
        lua_rawseti(lua, -2, ++num);
    }
    else if (strict && (limit < 0 || num < limit) && cstr == end)
    {
        lua_pushliteral(lua, "");
        lua_rawseti(lua, -2, ++num);
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* split string (only support plain text)
 *
 * @param str             the string
 * @param delimiter       the delimiter
 * @param strict          is strict?
 * @param limit           the limit count
 */
tb_int_t xm_string_split(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get string
    size_t           nstr = 0;
    tb_char_t const* cstr = luaL_checklstring(lua, 1, &nstr);

    // get delimiter
    size_t           ndls = 0;
    tb_char_t const* cdls = luaL_checklstring(lua, 2, &ndls);

    // is strict?
    tb_bool_t const  strict = (tb_bool_t)lua_toboolean(lua, 3);

    // get limit count
    tb_int_t const   limit  = (tb_int_t)luaL_optinteger(lua, 4, -1);

    // split it
    lua_newtable(lua);
    if (ndls == 1) xm_string_split_chr(lua, cstr, (tb_size_t)nstr, cdls[0], strict, limit);
    else xm_string_split_str(lua, cstr, (tb_size_t)nstr, cdls, ndls, strict, limit);
    return 1;
}
