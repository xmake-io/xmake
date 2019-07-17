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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      OpportunityLiu
 * @file        trim.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                 "trim"
#define TB_TRACE_MODULE_DEBUG                (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * privates
 */

static tb_char_t const* xm_string_ltrim(tb_char_t const* strstart, tb_char_t const* strend, tb_char_t const* trimchars,
                                        size_t ntrimchars)
{
    // check
    tb_assert_and_check_return_val(strstart && strend && trimchars, tb_null);

    // done
    tb_char_t const* p = strstart;
    while (p < strend && tb_strnchr(trimchars, ntrimchars, *p))
        p++;

    return p;
}

static tb_char_t const* xm_string_rtrim(tb_char_t const* strstart, tb_char_t const* strend, tb_char_t const* trimchars,
                                        size_t ntrimchars)
{
    // check
    tb_assert_and_check_return_val(strstart && strend && trimchars, tb_null);

    // done
    tb_char_t const* p = strend - 1;
    while (p >= strstart && tb_strnchr(trimchars, ntrimchars, *p))
        p--;

    return p + 1;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* trim string
 *
 * @param str            the string
 * @param trimchars      the chars to trim
 * @param trimtype       0 to trim left and right, -1 to trim left, 1 to trim right
 *
 * @code
 *      local result = string.trim(str, "\r\n \v\t", 0)
 *      local result = string.trim(str, "(", -1)
 * @endcode
 */
tb_int_t xm_string_trim(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    size_t           lstr, ltrim;
    tb_char_t const* sstr      = luaL_checklstring(lua, 1, &lstr);
    tb_char_t const* estr      = sstr + lstr;
    tb_char_t const* trimchars = luaL_optlstring(lua, 2, "\r\n\t \f\v", &ltrim);
    tb_int64_t const trimtype  = (tb_int64_t)luaL_optinteger(lua, 3, 0);

    tb_char_t const* const rsstr = sstr;
    tb_char_t const* const restr = estr;

    tb_assert_and_check_goto(sstr && trimchars, failed);
    // empty string or empty tmim chars
    tb_check_goto(ltrim != 0 && lstr != 0, failed);

    // trim chars
    if (trimtype <= 0) sstr = xm_string_ltrim(sstr, estr, trimchars, ltrim);
    if (trimtype >= 0) estr = xm_string_rtrim(sstr, estr, trimchars, ltrim);

    // no trimed chars
    tb_check_goto(sstr != rsstr || estr != restr, failed);

    // ok
    lua_pushlstring(lua, sstr, estr - sstr);
    return 1;

failed:
    // return orignal value
    lua_settop(lua, 1);
    return 1;
}
