/*!The Automatic Cross-platform Build Tool
 * 
 * XMake is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * XMake is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with XMake; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        getenv.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "getenv"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the separator
#ifdef TB_CONFIG_OS_WINDOWS 
#   define XM_OS_ENV_SEP                    ';'
#else
#   define XM_OS_ENV_SEP                    ':'
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_getenv(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the name  
    tb_char_t const* name = luaL_checkstring(lua, 1);
    tb_check_return_val(name, 0);

    // init values
    tb_string_t values;
    if (!tb_string_init(&values)) return 0;

    // init environment
    tb_environment_ref_t environment = tb_environment_init();
    if (environment)
    {
        // load variable
        if (tb_environment_load(environment, name))
        {
            // make values
            tb_bool_t is_first = tb_true;
            tb_for_all_if (tb_char_t const*, value, environment, value)
            {
                // append separator
                if (!is_first) tb_string_chrcat(&values, XM_OS_ENV_SEP);
                else is_first = tb_false;

                // append value
                tb_string_cstrcat(&values, value);
            }
        }

        // exit environment
        tb_environment_exit(environment);
    }

    // save result
    if (tb_string_size(&values)) lua_pushstring(lua, tb_string_cstr(&values));
    else lua_pushnil(lua);

    // exit values
    tb_string_exit(&values);

    // ok
    return 1;
}
