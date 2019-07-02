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
 * @file        file_isatty.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "file_isatty"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "file.h"
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* file:isatty()
 */
tb_int_t xm_io_file_isatty(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get file pointer
    xm_io_file* fp = xm_io_getfile(lua);

    if (xm_io_file_is_file(fp))
    {
        lua_pushboolean(lua, tb_false);
        // ok
        return 1;
    }
    tb_bool_t istty = xm_io_file_is_tty(fp);
    // return answer
    lua_pushboolean(lua, istty);

    // ok
    return 1;
}
