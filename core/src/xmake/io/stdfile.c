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
 * @author      OpportunityLiu, ruki
 * @file        stdfile.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "stdfile"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_OS_WINDOWS
#    include <io.h>
#else
#    include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macors
 */

// the singleton type of stdfile
#define XM_IO_STDFILE_STDIN      (TB_SINGLETON_TYPE_USER + 1)
#define XM_IO_STDFILE_STDOUT     (TB_SINGLETON_TYPE_USER + 2)
#define XM_IO_STDFILE_STDERR     (TB_SINGLETON_TYPE_USER + 3)

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_size_t xm_io_stdfile_isatty(tb_size_t type)
{
    tb_bool_t answer = tb_false;
#ifdef TB_CONFIG_OS_WINDOWS
    DWORD  mode;
    HANDLE console_handle;
    switch (type)
    {
    case XM_IO_FILE_TYPE_STDIN: console_handle = GetStdHandle(STD_INPUT_HANDLE); break;
    case XM_IO_FILE_TYPE_STDOUT: console_handle = GetStdHandle(STD_OUTPUT_HANDLE); break;
    case XM_IO_FILE_TYPE_STDERR: console_handle = GetStdHandle(STD_ERROR_HANDLE); break;
    }
    answer = GetConsoleMode(console_handle, &mode);
#else
    switch (type)
    {
    case XM_IO_FILE_TYPE_STDIN: answer = isatty(fileno(stdin)); break;
    case XM_IO_FILE_TYPE_STDOUT: answer = isatty(fileno(stdout)); break;
    case XM_IO_FILE_TYPE_STDERR: answer = isatty(fileno(stderr)); break;
    }
#endif

    if (answer) type |= XM_IO_FILE_FLAG_TTY;
    return type;
}
static tb_handle_t xm_io_stdfile_instance_init(tb_cpointer_t* ppriv)
{
    // get stdfile type
    tb_size_t* ptype = (tb_size_t*)ppriv;
    tb_assert_and_check_return_val(ptype, tb_null);

    // init stdfile
    tb_stdfile_ref_t fp = tb_null;
    tb_size_t type = *ptype;
    switch (type)
    {
    case XM_IO_FILE_TYPE_STDIN:
        fp = tb_stdfile_input();
        break;
    case XM_IO_FILE_TYPE_STDOUT:
        fp = tb_stdfile_output();
        break;
    case XM_IO_FILE_TYPE_STDERR:
        fp = tb_stdfile_error();
        break;
    }

    // make file
    xm_io_file_t* file = tb_malloc0_type(xm_io_file_t);
    tb_assert_and_check_return_val(file, 0);

    // init file
    file->std_ref    = fp;
    file->stream     = tb_null;
    file->fstream    = tb_null;
    file->type       = xm_io_stdfile_isatty(type);
    file->encoding   = TB_CHARSET_TYPE_UTF8;

    // init the read/write line cache buffer
    tb_buffer_init(&file->rcache); 
    tb_buffer_init(&file->wcache); 

    // ok
    return (tb_handle_t)file;
}
static tb_void_t xm_io_stdfile_instance_exit(tb_handle_t stdfile, tb_cpointer_t priv)
{
    xm_io_file_t* file = (xm_io_file_t*)stdfile;
    if (file)
    {
        tb_buffer_exit(&file->rcache);
        tb_buffer_exit(&file->wcache);
        tb_free(file);
    }
}
static xm_io_file_t* xm_io_stdfile_input()
{
    return (xm_io_file_t*)tb_singleton_instance(XM_IO_STDFILE_STDIN, xm_io_stdfile_instance_init, xm_io_stdfile_instance_exit, tb_null, tb_u2p(XM_IO_FILE_TYPE_STDIN));
}
static xm_io_file_t* xm_io_stdfile_output()
{
    return (xm_io_file_t*)tb_singleton_instance(XM_IO_STDFILE_STDOUT, xm_io_stdfile_instance_init, xm_io_stdfile_instance_exit, tb_null, tb_u2p(XM_IO_FILE_TYPE_STDOUT));
}
static xm_io_file_t* xm_io_stdfile_error()
{
    return (xm_io_file_t*)tb_singleton_instance(XM_IO_STDFILE_STDERR, xm_io_stdfile_instance_init, xm_io_stdfile_instance_exit, tb_null, tb_u2p(XM_IO_FILE_TYPE_STDERR));
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// io.stdfile(stdin: 1, stdout: 2, stderr: 3)
tb_int_t xm_io_stdfile(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get std type
    tb_long_t type = lua_tointeger(lua, 1);

    // get stdfile
    xm_io_file_t* file = tb_null;
    switch (type)
    {
    case XM_IO_FILE_TYPE_STDIN:
        file = xm_io_stdfile_input();
        break;
    case XM_IO_FILE_TYPE_STDOUT:
        file = xm_io_stdfile_output();
        break;
    case XM_IO_FILE_TYPE_STDERR:
        file = xm_io_stdfile_error();
        break;
    }
    if (file)
    {
        lua_pushlightuserdata(lua, (tb_pointer_t)file);
        return 1;
    }
    else xm_io_file_return_error(lua, "invalid stdfile type!");
}

