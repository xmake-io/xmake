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
 * @file        std.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "io_std"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "file.h"
#include "prefix.h"
#include <stdio.h>
#ifdef TB_CONFIG_OS_WINDOWS
#    include <io.h>
#else
#    include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_size_t xm_io_std_isatty(tb_size_t type)
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

static tb_void_t xm_io_std_init(lua_State* lua, tb_size_t type)
{
    // check
    tb_assert_and_check_return(lua);

    tb_char_t const* name = tb_null;
    tb_char_t const* path = tb_null;
    tb_stdfile_ref_t fp   = tb_null;
    switch (type)
    {
    case XM_IO_FILE_TYPE_STDIN:
        name = "stdin";
        fp   = tb_stdfile_input();
        break;
    case XM_IO_FILE_TYPE_STDOUT:
        name = "stdout";
        fp   = tb_stdfile_output();
        break;
    case XM_IO_FILE_TYPE_STDERR:
        name = "stderr";
        fp   = tb_stdfile_error();
        break;
    }
#ifdef TB_CONFIG_OS_WINDOWS
    path = "CON"; // console device
#else
    switch (type)
    {
    case XM_IO_FILE_TYPE_STDIN: path = "/dev/stdin"; break;
    case XM_IO_FILE_TYPE_STDOUT: path = "/dev/stdout"; break;
    case XM_IO_FILE_TYPE_STDERR: path = "/dev/stderr"; break;
    }
#endif
    tb_assert_and_check_return(name && path && fp);

    // new file
    xm_io_file* file = xm_io_newfile(lua);
    tb_assert_and_check_return(file);
    lua_setfield(lua, -2, name);

    // init file
    file->encoding        = TB_CHARSET_TYPE_UTF8;
    file->type            = xm_io_std_isatty(type);
    file->path            = path;
    file->std_ref         = fp;
    file->stream          = tb_null;
    file->fstream         = tb_null;
    tb_char_t const* info = xm_io_file_is_tty(file) ? "" : " redirected";
    tb_snprintf(file->name, tb_arrayn(file->name), "file: (%s%s)", name, info);
}

tb_int_t xm_io_std(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // init io.stdin, io.stdout and io.stderr
    lua_getglobal(lua, "io");
    xm_io_std_init(lua, XM_IO_FILE_TYPE_STDIN);
    xm_io_std_init(lua, XM_IO_FILE_TYPE_STDOUT);
    xm_io_std_init(lua, XM_IO_FILE_TYPE_STDERR);
    lua_pop(lua, 1);
    return 0;
}
