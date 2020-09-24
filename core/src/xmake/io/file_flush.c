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
 * @author      OpportunityLiu, ruki
 * @file        file_flush.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "file_flush"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_io_std_flush_impl(xm_io_file_t* file)
{
    tb_assert_and_check_return_val(xm_io_file_is_std(file), tb_false);
    return (file->std_ref != tb_stdfile_input())? tb_stdfile_flush(file->std_ref) : tb_false;
}

static tb_bool_t xm_io_file_flush_impl(xm_io_file_t* file)
{
    // check
    tb_assert_and_check_return_val(xm_io_file_is_file(file), tb_false);

#ifdef TB_CONFIG_OS_WINDOWS
    // write cached data first
    tb_byte_t const* odata = tb_buffer_data(&file->wcache);
    tb_size_t        osize = tb_buffer_size(&file->wcache);
    if (odata && osize)
    {
        if (!tb_stream_bwrit(file->file_ref, odata, osize)) return tb_false;
        tb_buffer_clear(&file->wcache);
    }
#endif
    return tb_stream_sync(file->file_ref, tb_false);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// io.file_flush(file)
tb_int_t xm_io_file_flush(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is user data?
    if (!lua_isuserdata(lua, 1))
        xm_io_return_error(lua, "flush(invalid file)!");

    // get file
    xm_io_file_t* file = (xm_io_file_t*)lua_touserdata(lua, 1);
    tb_check_return_val(file, 0);

    // flush file
    tb_bool_t ok = xm_io_file_is_file(file)? xm_io_file_flush_impl(file) : xm_io_std_flush_impl(file);
    if (ok)
    {
        lua_pushboolean(lua, tb_true);
        return 1;
    }
    else xm_io_return_error(lua, "failed to flush file");
}
