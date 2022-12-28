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
 * @file        args.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "os.args"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t tb_os_args_append(tb_string_ref_t result, tb_char_t const* cstr, tb_size_t size, tb_bool_t escape, tb_bool_t nowrap)
{
    // check
    tb_assert_and_check_return(size < TB_PATH_MAXN);

    // need wrap quote?
    tb_char_t ch;
    tb_char_t const* p = cstr;
    tb_bool_t wrap_quote = tb_false;
    if (!nowrap)
    {
        while ((ch = *p))
        {
            if (ch == ' ') wrap_quote = tb_true;
            p++;
        }
    }

    // wrap begin quote
    if (wrap_quote) tb_string_chrcat(result, '\"');

    // escape characters
    p = cstr;
    while ((ch = *p))
    {
        // escape '"' or '\\'
        if (ch == '\"' || ((escape || wrap_quote) && ch == '\\'))
            tb_string_chrcat(result, '\\');
        tb_string_chrcat(result, ch);
        p++;
    }

    // wrap end quote
    if (wrap_quote) tb_string_chrcat(result, '\"');
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
// os.args({"xx", "yy"}, {escape = true})
tb_int_t xm_os_args(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // escape '\\' characters in global?
    tb_bool_t escape = tb_false;
    if (lua_istable(lua, 2))
    {
        // is escape?
        lua_pushstring(lua, "escape");
        lua_gettable(lua, 2);
        escape = lua_toboolean(lua, -1);
        lua_pop(lua, 1);
    }

    // disable to wrap quote characters in global?
    tb_bool_t nowrap = tb_false;
    if (lua_istable(lua, 2))
    {
        // is nowrap?
        lua_pushstring(lua, "nowrap");
        lua_gettable(lua, 2);
        nowrap = lua_toboolean(lua, -1);
        lua_pop(lua, 1);
    }

    // init result
    tb_string_t result;
    tb_string_init(&result);

    // make string from arguments list
    if (lua_istable(lua, 1))
    {
        tb_size_t i = 0;
        tb_size_t n = (tb_size_t)lua_objlen(lua, 1);
        for (i = 1; i <= n; i++)
        {
            // add space
            if (i != 1) tb_string_chrcat(&result, ' ');

            // add argument
            lua_pushnumber(lua, (tb_int_t)i);
            lua_rawget(lua, 1);
            if (lua_istable(lua, -1)) // is path instance?
            {
                lua_pushstring(lua, "_STR");
                lua_gettable(lua, -2);
                size_t size = 0;
                tb_char_t const* cstr = luaL_checklstring(lua, -1, &size);
                if (cstr && size)
                    tb_os_args_append(&result, cstr, size, escape, nowrap);
                lua_pop(lua, 1);
            }
            else
            {
                size_t size = 0;
                tb_char_t const* cstr = luaL_checklstring(lua, -1, &size);
                if (cstr && size)
                    tb_os_args_append(&result, cstr, size, escape, nowrap);
            }
            lua_pop(lua, 1);
        }
    }
    else
    {
        size_t size = 0;
        tb_char_t const* cstr = luaL_checklstring(lua, 1, &size);
        if (cstr && size)
            tb_os_args_append(&result, cstr, size, escape, nowrap);
    }

    // return result
    tb_size_t size = tb_string_size(&result);
    if (size) lua_pushlstring(lua, tb_string_cstr(&result), size);
    else lua_pushliteral(lua, "");
    tb_string_exit(&result);
    return 1;
}
