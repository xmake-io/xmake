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
 * @author      OpportunityLiu
 * @file        trim.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "string_trim"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_string_trim_space(tb_char_t const** psstr, tb_char_t const** pestr, tb_int_t mode)
{
    // check
    tb_assert(psstr && pestr && *psstr && *pestr);

    tb_char_t const* p = *psstr;
    tb_char_t const* e = *pestr;

    // trim left?
    if (mode <= 0)
        while (p < e && tb_isspace(*p))
            p++;

    // trim right
    if (mode >= 0)
    {
        e--;
        while (e >= p && tb_isspace(*e))
            e--;
        e++;
    }

    // save trimed string
    *psstr = p;
    *pestr = e;
}

static tb_char_t const* xm_string_ltrim(tb_char_t const* sstr, tb_char_t const* estr, tb_char_t const* ctrim, size_t ntrim)
{
    // check
    tb_assert(sstr && estr && ctrim);

    // done
    tb_char_t const* p = sstr;
    while (p < estr && tb_strnchr(ctrim, ntrim, *p))
        p++;

    return p;
}

static tb_char_t const* xm_string_rtrim(tb_char_t const* sstr, tb_char_t const* estr, tb_char_t const* ctrim, size_t ntrim)
{
    // check
    tb_assert(sstr && estr && ctrim);

    // done
    tb_char_t const* p = estr - 1;
    while (p >= sstr && tb_strnchr(ctrim, ntrim, *p))
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
    tb_char_t const* trimchars = luaL_optlstring(lua, 2, "", &ltrim);
    tb_int_t const   trimtype  = (tb_int_t)luaL_optinteger(lua, 3, 0);
    do
    {
        tb_assert_and_check_break(sstr && trimchars);
        tb_check_break(lstr != 0);

        tb_char_t const* const rsstr = sstr;
        tb_char_t const* const restr = estr;
        if (ltrim == 0)
            xm_string_trim_space(&sstr, &estr, trimtype);
        else
        {
            // trim chars
            if (trimtype <= 0) sstr = xm_string_ltrim(sstr, estr, trimchars, ltrim);
            if (trimtype >= 0) estr = xm_string_rtrim(sstr, estr, trimchars, ltrim);
        }

        // no trimed chars
        tb_check_break(sstr != rsstr || estr != restr);

        // ok
        lua_pushlstring(lua, sstr, estr - sstr);
        return 1;

    } while (0);

    // return orignal value
    lua_settop(lua, 1);
    return 1;
}
