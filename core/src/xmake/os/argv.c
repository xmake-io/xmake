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
 * @file        argv.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "os.argv"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_argv(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the argument string
    tb_char_t const* args = luaL_checkstring(lua, 1);
    tb_check_return_val(args, 0);

    // done
    tb_string_t arg;
    do
    {
        // init table
        lua_newtable(lua);

        // init arg
        if (!tb_string_init(&arg)) break;

        // parse command to the arguments
        tb_int_t            i = 1;
        tb_int_t            skip = 0;
        tb_int_t            escape = 0;
        tb_char_t           quote = 0;
        tb_char_t           ch = 0;
        tb_char_t const*    p = args;
        while ((ch = *p))
        {
            // no escape now?
            if (!escape)
            {
                // enter quote?
                if (!quote && (ch == '\"' || ch == '\'')) { quote = ch; skip = 1; }
                // leave quote?
                else if (ch == quote) { quote = 0; skip = 1; }
                // escape charactor? only escape \\, \"
                else if (ch == '\\' && (p[1] == '\\' || p[1] == '\"')) { escape = 1; skip = 1; }
                // is argument end with ' '?
                else if (!quote && tb_isspace(ch))
                {
                    // save this argument
                    tb_string_ltrim(&arg);
                    if (tb_string_size(&arg))
                    {
                        // save argument
                        lua_pushstring(lua, tb_string_cstr(&arg));
                        lua_rawseti(lua, -2, i++);
                    }

                    // clear argument
                    tb_string_clear(&arg);
                }
            }

            // save this charactor to argument
            if (!skip) tb_string_chrcat(&arg, ch);

            // step and cancel escape
            if (escape == 1) escape++;
            else if (escape == 2) escape = 0;

            // clear skip
            skip = 0;

            // next
            p++;
        }

        // save this argument
        tb_string_ltrim(&arg);
        if (tb_string_size(&arg))
        {
            // save argument
            lua_pushstring(lua, tb_string_cstr(&arg));
            lua_rawseti(lua, -2, i++);
        }

    } while (0);

    // exit arg
    tb_string_exit(&arg);

    // ok
    return 1;
}
