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
#   include <io.h>
#   include "iscygpty.c"
#else
#    include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
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
#if defined(TB_CONFIG_OS_WINDOWS)
    DWORD  mode;
    HANDLE console_handle;
    switch (type)
    {
    case XM_IO_FILE_TYPE_STDIN: console_handle = GetStdHandle(STD_INPUT_HANDLE); break;
    case XM_IO_FILE_TYPE_STDOUT: console_handle = GetStdHandle(STD_OUTPUT_HANDLE); break;
    case XM_IO_FILE_TYPE_STDERR: console_handle = GetStdHandle(STD_ERROR_HANDLE); break;
    }
    answer = GetConsoleMode(console_handle, &mode);
    if (!answer)
        answer = is_cygpty(console_handle);
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
static xm_io_file_t* xm_io_stdfile_new(lua_State* lua, tb_size_t type)
{
    // init stdfile
    tb_stdfile_ref_t fp = tb_null;
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

    // new file
    xm_io_file_t* file = (xm_io_file_t*)lua_newuserdata(lua, sizeof(xm_io_file_t));
    tb_assert_and_check_return_val(file, tb_null);

    // init file
    file->std_ref    = fp;
    file->stream     = tb_null;
    file->fstream    = tb_null;
    file->type       = xm_io_stdfile_isatty(type);
    file->encoding   = TB_CHARSET_TYPE_UTF8;

    // init the read/write line cache buffer
    tb_buffer_init(&file->rcache);
    tb_buffer_init(&file->wcache);
    return file;
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

    /* push a new stdfile
     *
     * @note we need to ensure that it is a singleton in the external lua script, and will only be created once, e.g. io.stdin, io.stdout, io.stderr
     */
    xm_io_file_t* file = xm_io_stdfile_new(lua, type);
    if (file) return 1;
    else xm_io_return_error(lua, "invalid stdfile type!");
}

