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
 * @file        setenv.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "setenv"
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
tb_int_t xm_os_setenv(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the name and value 
    size_t              value_size = 0;
    tb_char_t const*    name = luaL_checkstring(lua, 1);
    tb_char_t const*    value = luaL_checklstring(lua, 2, &value_size);
    tb_check_return_val(name, 0);

    // find the first separator position
    tb_char_t const* p = value? tb_strchr(value, XM_OS_ENV_SEP) : tb_null;
    if (p)
    {
        // init filter
        tb_hash_set_ref_t filter = tb_hash_set_init(8, tb_element_str(tb_true));

        // init environment 
        tb_char_t               data[TB_PATH_MAXN];
        tb_environment_ref_t    environment = tb_environment_init();
        if (environment)
        {
            // make environment
            tb_char_t const* b = value;
            tb_char_t const* e = b + value_size;
            do
            {
                // not empty?
                if (b < p)
                {
                    // the size
                    tb_size_t size = tb_min(p - b, sizeof(data) - 1);

                    // copy it
                    tb_strncpy(data, b, size);
                    data[size] = '\0';

                    // have been not inserted?
                    if (!filter || !tb_hash_set_get(filter, data)) 
                    {
                        // append the environment 
                        tb_environment_insert(environment, data, tb_false);

                        // save it to the filter
                        tb_hash_set_insert(filter, data);
                    }
                }

                // end?
                tb_check_break(p + 1 < e);

                // find the next separator position
                b = p + 1;
                p = tb_strchr(b, XM_OS_ENV_SEP);
                if (!p) p = e;

            } while (1);

            // done os.setenv(name, value) 
            lua_pushboolean(lua, tb_environment_save(environment, name));

            // exit environment
            tb_environment_exit(environment);
        }

        // exit filter
        if (filter) tb_hash_set_exit(filter);
        filter = tb_null;
    }
    // only one?
    else
    {
        // done os.setenv(name, value) 
        lua_pushboolean(lua, tb_environment_set_one(name, value));
    }

    // ok
    return 1;
}
