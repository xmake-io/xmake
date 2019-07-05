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
 * @file        file___len.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "file___len"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "file.h"
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* get file length, #file
 */
tb_int_t xm_io_file___len(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    xm_io_file* file = xm_io_getfile(lua);
    if (xm_io_file_is_closed(file))
        xm_io_file_return_error_closed(lua);
    else if (xm_io_file_is_file(file))
    {
        tb_assert(file->file_ref);
        lua_pushnumber(lua, (lua_Number)tb_file_size(file->file_ref));
        xm_io_file_return_success();
    }
    else xm_io_file_return_error(lua, file, "getting file size for this file is invalid");
}
