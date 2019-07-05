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
 * @file        open.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "open"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "file.h"
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/*
 * io.open(path, modestr)
 */
tb_int_t xm_io_open(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get file path and mode
    tb_char_t const* path    = luaL_checkstring(lua, 1);
    tb_char_t const* modestr = luaL_optstring(lua, 2, "r");
    tb_assert_and_check_return_val(path && modestr, 0);

    // get file mode value
    tb_size_t mode = TB_FILE_MODE_RW;
    switch (modestr[0])
    {
    case 'w': mode |= TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC; break;
    case 'a': mode |= TB_FILE_MODE_APPEND | TB_FILE_MODE_CREAT; break;
    default: break;
    }

    // open file
    tb_file_ref_t file = tb_file_init(path, mode);
    if (!file)
    {
        lua_pushnil(lua);
        lua_pushliteral(lua, "failed to open file.");
        return 2;
    }

    // get file encoding
    tb_bool_t update = !!tb_strchr(modestr, '+');
    tb_size_t encoding = XM_IO_FILE_ENCODING_UNKNOWN;
    if (modestr[1] == 'b' || (update && modestr[2] == 'b'))
        encoding = XM_IO_FILE_ENCODING_BINARY;
    else if (tb_strstr(modestr, "utf8") || tb_strstr(modestr, "utf-8"))
        encoding = TB_CHARSET_TYPE_UTF8;
    else if (tb_strstr(modestr, "utf16le") || tb_strstr(modestr, "utf-16le"))
        encoding = TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_LE;
    else if (tb_strstr(modestr, "utf16be") || tb_strstr(modestr, "utf-16be"))
        encoding = TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_BE;
    else if (tb_strstr(modestr, "utf16") || tb_strstr(modestr, "utf-16"))
        encoding = TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_NE;

    // get absolute file path
    tb_char_t full[TB_PATH_MAXN] = {0};
    path = tb_path_absolute(path, full, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, 0);

    // new file
    xm_io_file* xm_file = xm_io_newfile(lua);
    xm_file->file_ref   = file;
    xm_file->mode       = mode;
    xm_file->type       = XM_IO_FILE_TYPE_FILE;
    xm_file->encoding   = encoding;

    // save file path
    tb_size_t pathlen = tb_strlen(path);
    xm_file->path = tb_malloc_cstr(pathlen + 1);
    if (xm_file->path)
        tb_strncpy(xm_file->path, path, pathlen);

    // save file name
    tb_size_t name_maxn = tb_arrayn(xm_file->name);
    tb_strlcpy(xm_file->name, "file: ", name_maxn);
    if (pathlen < name_maxn - tb_arrayn("file: "))
        tb_strlcat(xm_file->name, full, name_maxn);
    else
    {
        tb_strlcat(xm_file->name, "...", name_maxn);
        tb_strlcat(xm_file->name, full + (pathlen - name_maxn + tb_arrayn("file: ") + tb_arrayn("...")), name_maxn);
    }
    return 1;
}
