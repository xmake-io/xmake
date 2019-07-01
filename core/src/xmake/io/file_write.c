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
#define TB_TRACE_MODULE_NAME "file_write"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_OS_WINDOWS
#    include "../winos/ansi.h"
#    include <io.h>
#else
#    include <unistd.h>
#endif
#include "file.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

static tb_void_t direct_write(xm_io_file* file, tb_char_t const* data, tb_size_t size)
{
    tb_file_writ(file->file_ref, (tb_byte_t const*)data, size);
}
static tb_void_t transcode_write(xm_io_file* file, tb_char_t const* data, tb_size_t size)
{
    tb_buffer_t buf;
    tb_buffer_init(&buf);
    tb_byte_t* buf_ptr  = tb_buffer_resize(&buf, (size + 1) * 2);
    tb_long_t  buf_size = tb_charset_conv_cstr(TB_CHARSET_TYPE_UTF8, file->encoding, data, buf_ptr, size * 2);
    if (buf_size > 0) tb_file_writ(file->file_ref, buf_ptr, (tb_size_t)buf_size);
    tb_buffer_exit(&buf);
    return;
}

static tb_void_t std_write(xm_io_file* file, tb_char_t const* data, tb_size_t size)
{
    tb_size_t type = (file->type & ~XM_IO_FILE_FLAG_TTY);
    tb_check_return(type != XM_IO_FILE_TYPE_STDIN);

#ifdef TB_CONFIG_OS_WINDOWS
    HANDLE handle = INVALID_HANDLE_VALUE;
    switch (type)
    {
    case XM_IO_FILE_TYPE_STDOUT: handle = GetStdHandle(STD_OUTPUT_HANDLE); break;
    case XM_IO_FILE_TYPE_STDERR: handle = GetStdHandle(STD_ERROR_HANDLE); break;
    }
    tb_check_return(handle != INVALID_HANDLE_VALUE);

    // write string to stdout
    tb_size_t writ = 0;

    // write to the stdout
    DWORD       real = 0;
    tb_buffer_t wbuf;
    tb_buffer_init(&wbuf);
    if (xm_io_file_is_tty(file))
    {
        // write to console
        tb_wchar_t* wdata = (tb_wchar_t*)tb_buffer_resize(&wbuf, (size + 1) * 2);
        tb_size_t   wsize = tb_mbstowcs(wdata, data, size);
        while (writ < wsize)
        {
            if (!WriteConsoleW(handle, wdata + writ, (DWORD)(wsize - writ), &real, tb_null)) break;
            // update writted size
            writ += (tb_size_t)real;
        }
    }
    else
    {
        // write to redirected file
        tb_char_t* wdata = (tb_char_t*)tb_buffer_resize(&wbuf, (size + 1) * 4);
        tb_size_t  wsize = xm_utf8tombs(wdata, data, size * 4, GetConsoleOutputCP());
        while (writ < wsize)
        {
            if (!WriteFile(handle, wdata + writ, (DWORD)(wsize - writ), &real, tb_null)) break;
            // update writted size
            writ += (tb_size_t)real;
        }
    }
    tb_buffer_exit(&wbuf);
#else
    fwrite(data, sizeof(tb_char_t), size, file->std_ref);
#endif
}

/*
 * file:write(...)
 */
tb_int_t xm_io_file_write(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    xm_io_file* file = (xm_io_file*)luaL_checkudata(lua, 1, xm_io_file_udata);
    tb_int_t    narg = lua_gettop(lua);

    // set to utf-8 if not specified
    if (file->encoding == XM_IO_FILE_ENCODING_UNKNOWN) file->encoding = TB_CHARSET_TYPE_UTF8;
    tb_bool_t direct = file->encoding == TB_CHARSET_TYPE_UTF8 || file->encoding == XM_IO_FILE_ENCODING_BINARY;
    if (xm_io_file_is_closed_file(file)) xm_io_file_error_closed(lua);

    for (tb_int_t i = 2; i <= narg; i++)
    {
        size_t           datasize;
        tb_char_t const* data = luaL_checklstring(lua, i, &datasize);

        if (!xm_io_file_is_file(file))
            std_write(file, data, (tb_size_t)datasize);
        else if (direct)
            direct_write(file, data, (tb_size_t)datasize);
        else
            transcode_write(file, data, (tb_size_t)datasize);
    }

    lua_settop(lua, 1);
    xm_io_file_success();
}
