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
 * @file        file_seek.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "file_seek"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "file.h"
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/*
 * file:seek([whence [, offset]])
 */
tb_int_t xm_io_file_seek(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    xm_io_file*      file   = xm_io_getfile(lua);
    tb_char_t const* whence = luaL_optstring(lua, 2, "cur");
    tb_hong_t        offset = (tb_hong_t)luaL_optnumber(lua, 3, 0);

    tb_assert_and_check_return_val(file && whence, 0);

    if (xm_io_file_is_file(file))
    {
        if (xm_io_file_is_closed_file(file)) xm_io_file_error_closed(lua);
        tb_size_t mode = TB_FILE_SEEK_CUR;
        switch (*whence)
        {
        case 's': // "set"
            mode = TB_FILE_SEEK_BEG;
            break;
        case 'e': // "end"
            mode = TB_FILE_SEEK_END;
            break;
        }
        offset = tb_file_seek(file->file_ref, offset, mode);
        lua_pushnumber(lua, (lua_Number)offset);
        xm_io_file_success();
    }
    else
    {
        xm_io_file_error(lua, file, "seek is not supported on this file");
    }
}
