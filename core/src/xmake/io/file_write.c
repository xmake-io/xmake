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

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_io_file_write_file_directly(xm_io_file_t* file, tb_char_t const* data, tb_size_t size)
{
    // check
    tb_assert(file && data && xm_io_file_is_file(file) && file->file_ref);

    // write data to file
    tb_stream_bwrit(file->file_ref, (tb_byte_t const*)data, size);
}
static tb_void_t xm_io_file_write_file_transcrlf(xm_io_file_t* file, tb_char_t const* data, tb_size_t size)
{
    // check
    tb_assert(file && data && xm_io_file_is_file(file) && file->file_ref);

#ifdef TB_CONFIG_OS_WINDOWS

    // write cached data first
    tb_byte_t const* odata = tb_buffer_data(&file->wcache);
    tb_size_t        osize = tb_buffer_size(&file->wcache);
    if (odata && osize)
    {
        if (!tb_stream_bwrit(file->file_ref, odata, osize)) return ;
        tb_buffer_clear(&file->wcache);
    }

    // write data by lines
    tb_char_t const* p = (tb_char_t const*)data;
    tb_char_t const* e = p + size;
    tb_char_t const* lf = tb_null;
    while (p < e)
    {
        lf = tb_strnchr(p, e - p, '\n');
        if (lf)
        {
            if (lf > p && lf[-1] == '\r')
            {
                if (!tb_stream_bwrit(file->file_ref, (tb_byte_t const*)p, lf + 1 - p)) break;
            }
            else
            {
                if (lf > p && !tb_stream_bwrit(file->file_ref, (tb_byte_t const*)p, lf - p)) break;
                if (!tb_stream_bwrit(file->file_ref, (tb_byte_t const*)"\r\n", 2)) break;
            }

            // next line
            p = lf + 1;
        }
        else
        {
            // cache the left data
            tb_buffer_memncat(&file->wcache, (tb_byte_t const*)p, e - p);
            p = e;
            break;
        }
    }
#else
    return xm_io_file_write_file_directly(file, data, size);
#endif
}
static tb_void_t xm_io_file_write_std(xm_io_file_t* file, tb_char_t const* data, tb_size_t size)
{
    // check
    tb_assert(file && data && xm_io_file_is_std(file));

    // check type
    tb_size_t type = (file->type & ~XM_IO_FILE_FLAG_TTY);
    tb_check_return(type != XM_IO_FILE_TYPE_STDIN);

    // write data to stdout/stderr
    tb_stdfile_writ(file->std_ref, (tb_byte_t const*)data, size);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// io.file_write(file, ...)
tb_int_t xm_io_file_write(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is user data?
    if (!lua_isuserdata(lua, 1))
        xm_io_return_error(lua, "write(invalid file)!");

    // get file
    xm_io_file_t* file = (xm_io_file_t*)lua_touserdata(lua, 1);
    tb_check_return_val(file, 0);

    // write file data
    tb_int_t narg = lua_gettop(lua);
    if (narg > 1)
    {
        tb_bool_t is_binary = file->encoding == XM_IO_FILE_ENCODING_BINARY;
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
            else if (is_binary)
                xm_io_file_write_file_directly(file, data, (tb_size_t)datasize);
            else
                xm_io_file_write_file_transcrlf(file, data, (tb_size_t)datasize);
        }
    }
    lua_settop(lua, 1);
    lua_pushboolean(lua, tb_true);
    return 1;
}
