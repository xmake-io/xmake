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
 * @file        file_close___gc.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "file_close___gc"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "file.h"
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

static tb_int_t xm_io_file_close_impl(lua_State* lua, tb_bool_t allow_closed_file)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    xm_io_file* file = xm_io_getfile(lua);
    if (xm_io_file_is_closed(file))
    {
        if (allow_closed_file)
        {
            lua_pushboolean(lua, tb_true);
            xm_io_file_success();
        }else
            xm_io_file_error_closed(lua);
    }
    if (xm_io_file_is_file(file))
    {
        if (!tb_file_exit(file->file_ref)) xm_io_file_error(lua, "failed to close file");
        file->file_ref = tb_null;
        if (file->path)
        {
            tb_free(file->path);
            file->path = tb_null;
        }
        tb_strlcpy(file->name, "file: (closed file)", tb_arrayn(file->name));
        lua_pushboolean(lua, tb_true);
        xm_io_file_success();
    }
    else
    {
        // should we support close std files?

        // if (fclose(file->std_ref)) xm_io_file_error(lua, "failed to close file");
        // file->std_ref = tb_null;
        // file->path    = tb_null;
        // tb_strcpy(file->name, "file: (closed file)");
        lua_pushboolean(lua, tb_true);
        xm_io_file_success();
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*
 * file:close()
 */
tb_int_t xm_io_file_close(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    return xm_io_file_close_impl(lua, tb_false);
}

/*
 * file:close()
 */
tb_int_t xm_io_file___gc(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    return xm_io_file_close_impl(lua, tb_true);
}
