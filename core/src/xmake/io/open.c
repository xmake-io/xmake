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
#define TB_TRACE_MODULE_NAME "open"
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
 * io.open(path, mode)
 */
tb_int_t xm_io_open(lua_State* lua)
{
    tb_char_t const* path    = luaL_checkstring(lua, 1);
    tb_char_t const* mode    = luaL_optstring(lua, 2, "r");
    tb_size_t        tb_mode = TB_FILE_MODE_RW;
    switch (mode[0])
    {
    case 'w': tb_mode |= TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC; break;
    case 'a': tb_mode |= TB_FILE_MODE_APPEND | TB_FILE_MODE_CREAT; break;
    default: break;
    }
    tb_bool_t update             = !!tb_strchr(mode, '+');
    tb_char_t full[TB_PATH_MAXN] = {0};
    path                         = tb_path_absolute(path, full, TB_PATH_MAXN);
    tb_file_ref_t file           = tb_file_init(path, tb_mode);
    tb_size_t     pathlen        = tb_strlen(path);
    tb_char_t*    savedfull      = tb_malloc_cstr(pathlen + 1);
    tb_strcpy(savedfull, path);

    if (file)
    {
        tb_bool_t is_binary = mode[1] == 'b' || (update && mode[2] == 'b');
        tb_bool_t is_utf8   = tb_strstr(mode, "utf8") || tb_strstr(mode, "utf-8");
        tb_bool_t is_u16le  = tb_strstr(mode, "utf16le") || tb_strstr(mode, "utf-16le");
        tb_bool_t is_u16be  = tb_strstr(mode, "utf16be") || tb_strstr(mode, "utf-16be");
        tb_bool_t is_u16    = tb_strstr(mode, "utf16") || tb_strstr(mode, "utf-16");

        tb_size_t enc = XM_IO_FILE_ENCODING_UNKNOWN;
        if (is_binary)
            enc = XM_IO_FILE_ENCODING_BINARY;
        else if (is_utf8)
            enc = TB_CHARSET_TYPE_UTF8;
        else if (is_u16le)
            enc = TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_LE;
        else if (is_u16be)
            enc = TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_BE;
        else if (is_u16)
            enc = TB_CHARSET_TYPE_UTF16 | TB_CHARSET_TYPE_NE;

        xm_io_file* xm_file = xm_io_newfile(lua);
        xm_file->file_ref   = file;
        xm_file->mode       = tb_mode;
        xm_file->type       = XM_IO_FILE_TYPE_FILE;
        xm_file->encoding   = enc;
        xm_file->path       = savedfull;
        tb_strcpy(xm_file->name, "file: ");
        if (pathlen < tb_arrayn(xm_file->name) - tb_arrayn("file: "))
        {
            tb_strcat(xm_file->name, full);
        }
        else
        {
            tb_strcat(xm_file->name, "...");
            tb_strcat(xm_file->name,
                      full + (pathlen - tb_arrayn(xm_file->name) + tb_arrayn("file: ") + tb_arrayn("...")));
        }
        return 1;
    }
    else
    {
        tb_free(savedfull);
        lua_pushnil(lua);
        lua_pushliteral(lua, "failed to open file.");
        return 2;
    }
}