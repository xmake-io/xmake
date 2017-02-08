/*!The Make-like Build Utility based on Lua
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2015 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        argv.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "argv"
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
    tb_char_t* buffer = tb_null;
    do
    {
        // make buffer
        tb_size_t maxn = TB_PATH_MAXN;
        buffer = (tb_char_t*)tb_malloc(maxn);
        tb_assert_and_check_break(buffer);

        // copy and translate command
        tb_char_t   ch;
        tb_size_t   i = 0;
        tb_size_t   j = 0;
        for (i = 0; j <= maxn && (ch = args[i]); i++)
        {
            // not enough? grow it
            if (j == maxn)
            {
                // grow it
                maxn    += TB_PATH_MAXN;
                buffer  = (tb_char_t*)tb_ralloc(buffer, maxn);
                tb_assert_and_check_break(buffer);
            }

            // translate "\"", "\'", "\\"
            tb_char_t next = args[i + 1];
            if (ch == '\\' && (next == '\"' || next == '\'' || next == '\\')) /* skip it */ ;
            // copy it
            else buffer[j++] = ch;
        }
        tb_assert_and_check_break(j < maxn);
        buffer[j] = '\0';

        // reset index
        i = 1;

        // init table
        lua_newtable(lua);

        // parse command to the arguments
        tb_bool_t   s = 0;
        tb_char_t*  p = buffer;
        tb_char_t*  b = tb_null;
        while ((ch = *p))
        {
            // enter double quote?
            if (!s && ch == '\"') s = 2;
            // enter single quote?
            else if (!s && ch == '\'') s = 1;
            // leave quote?
            else if ((s == 2 && ch == '\"') || (s == 1 && ch == '\'')) s = 0;
            // is argument end with ' '?
            else if (!s && tb_isspace(ch))
            {
                // fill zero
                *p = '\0';

                // save this argument 
                if (b)
                {
                    // save argument
                    lua_pushstring(lua, b);
                    lua_rawseti(lua, -2, i++);

                    // clear it
                    b = tb_null;
                }
            }

            // get the argument pointer
            if ((s || !tb_isspace(ch)) && !b) b = p;

            // next 
            p++;
        }
        
        // save this argument 
        if (b)
        {
            // save argument
            lua_pushstring(lua, b);
            lua_rawseti(lua, -2, i++);

            // clear it
            b = tb_null;
        }

    } while (0);

    // exit buffer
    if (buffer) tb_free(buffer);
    buffer = tb_null;

    // ok
    return 1;
}
