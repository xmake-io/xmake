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
 * @file        file.h
 *
 */
#ifndef XM_IO_FILE_H
#define XM_IO_FILE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
typedef enum __xm_io_file_type_e
{
    XM_IO_FILE_TYPE_FILE   = 0, //!< disk file

    XM_IO_FILE_TYPE_STDIN  = 1,
    XM_IO_FILE_TYPE_STDOUT = 2,
    XM_IO_FILE_TYPE_STDERR = 3,

    XM_IO_FILE_FLAG_TTY    = 0x10, //!< mark tty std stream
} xm_io_file_type_e;

// use negetive numbers for this enum, its a extension for tb_charset_type_e
// before adding new values, make sure they have not conflicts with values in tb_charset_type_e
typedef enum __xm_io_file_encoding_e
{
    XM_IO_FILE_ENCODING_BINARY  = -1,
    XM_IO_FILE_ENCODING_UNKNOWN = -2,
#ifdef TB_CONFIG_OS_WINDOWS
    XM_IO_FILE_ENCODING_ANSI    = -3,
#endif
} xm_io_file_encoding_e;

typedef struct __xm_io_file
{
    union 
    {
        tb_file_ref_t file_ref; // valid if type == XM_IO_FILE_TYPE_FILE
        FILE*         std_ref;  // valid otherwise
    };

    tb_size_t        mode;      // tb_file_mode_t
    tb_size_t        type;      // xm_io_file_type_e
    tb_size_t        encoding;  // value of xm_io_file_encoding_e or tb_charset_type_e
    tb_char_t        name[64];
    tb_char_t const* path;
} xm_io_file;

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define xm_io_file_is_file(fileref)          (fileref->type == XM_IO_FILE_TYPE_FILE)
#define xm_io_file_is_std(fileref)           (fileref->type != XM_IO_FILE_TYPE_FILE)

#define xm_io_file_is_closed_file(fileref)   (fileref->type == XM_IO_FILE_TYPE_FILE && !(fileref->file_ref))
#define xm_io_file_is_closed_std(fileref)    (fileref->type != XM_IO_FILE_TYPE_FILE && !(fileref->file_ref))

#define xm_io_file_is_tty(fileref)           (!!(fileref->type & XM_IO_FILE_FLAG_TTY))
#define xm_io_file_is_closed(fileref)        (xm_io_file_is_closed_file(fileref) || xm_io_file_is_closed_std(fileref))

#define xm_io_file_udata "XM_IO_FILE*"

#define xm_io_file_success()                                                                                           \
    do                                                                                                                 \
    {                                                                                                                  \
        return 1;                                                                                                      \
    } while (0)

#define xm_io_file_error(lua, file, reason)                                                                            \
    do                                                                                                                 \
    {                                                                                                                  \
        lua_pushnil(lua);                                                                                              \
        lua_pushfstring(lua, "error: %s (%s)", reason, file->name);                                                    \
        return 2;                                                                                                      \
    } while (0)

#define xm_io_file_error_closed(lua)                                                                                   \
    do                                                                                                                 \
    {                                                                                                                  \
        lua_pushnil(lua);                                                                                              \
        lua_pushliteral(lua, "error: file has been closed");                                                           \
        return 2;                                                                                                      \
    } while (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
static inline xm_io_file* xm_io_newfile(lua_State* lua)
{
    tb_assert_and_check_return_val(lua, tb_null);

    xm_io_file* file = (xm_io_file*)lua_newuserdata(lua, sizeof(xm_io_file));
    tb_assert(file);
    luaL_getmetatable(lua, xm_io_file_udata);
    lua_setmetatable(lua, -2);
    tb_memset(file, 0, sizeof(xm_io_file));
    return file;
}

static inline xm_io_file* xm_io_getfile(lua_State* lua)
{
    tb_assert_and_check_return_val(lua, tb_null);

    xm_io_file* file = (xm_io_file*)luaL_checkudata(lua, 1, xm_io_file_udata);
    tb_assert(file);
    return file;
}

#endif
