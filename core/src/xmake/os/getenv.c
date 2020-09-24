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
#if defined(TB_CONFIG_OS_WINDOWS) && !defined(TB_COMPILER_LIKE_UNIX)
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
