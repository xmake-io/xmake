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
 * @file        file_write.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "file_write"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "file.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_io_file_write_file(xm_io_file* file, tb_char_t const* data, tb_size_t size)
{
    // check
    tb_assert(file && data && xm_io_file_is_file(file) && !xm_io_file_is_closed(file));

    // write data to file
    tb_stream_bwrit(file->file_ref, (tb_byte_t const*)data, size);
}
static tb_void_t xm_io_file_write_std(xm_io_file* file, tb_char_t const* data, tb_size_t size)
{
    // check
    tb_assert(file && data && xm_io_file_is_std(file) && !xm_io_file_is_closed(file));

    // check type
    tb_size_t type = (file->type & ~XM_IO_FILE_FLAG_TTY);
    tb_check_return(type != XM_IO_FILE_TYPE_STDIN);

    // write data to stdout/stderr
    tb_stdfile_writ(file->std_ref, (tb_byte_t const*)data, size);
}

/*
 * file:write(...)
 */
tb_int_t xm_io_file_write(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get file 
    xm_io_file* file = xm_io_getfile(lua);
    tb_int_t    narg = lua_gettop(lua);

    // this file has been closed? 
    if (xm_io_file_is_closed(file))
        xm_io_file_return_error_closed(lua);

    if (narg > 1)
    {
        for (tb_int_t i = 2; i <= narg; i++)
        {
            // get data
            size_t datasize = 0;
            tb_char_t const* data = luaL_checklstring(lua, i, &datasize);
            tb_check_continue(datasize);
            tb_assert_and_check_break(data);

            // write data to std or file
            if (xm_io_file_is_std(file))
                xm_io_file_write_std(file, data, (tb_size_t)datasize);
            else
                xm_io_file_write_file(file, data, (tb_size_t)datasize);
        }
    }

    lua_settop(lua, 1);
    xm_io_file_return_success();
}
