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
 * @author      ruki
 * @file        prefix.h
 *
 */
#ifndef XM_IO_PREFIX_H
#define XM_IO_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define xm_io_file_is_file(file)          ((file)->type == XM_IO_FILE_TYPE_FILE)
#define xm_io_file_is_std(file)           ((file)->type != XM_IO_FILE_TYPE_FILE)
#define xm_io_file_is_tty(file)           (!!((file)->type & XM_IO_FILE_FLAG_TTY))

// return io error
#define xm_io_return_error(lua, error)       \
    do                                            \
    {                                             \
        lua_pushnil(lua);                         \
        lua_pushliteral(lua, error);              \
        return 2;                                 \
    } while (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
typedef enum __xm_io_file_type_e
{
    XM_IO_FILE_TYPE_FILE   = 0      //!< disk file

,   XM_IO_FILE_TYPE_STDIN  = 1
,   XM_IO_FILE_TYPE_STDOUT = 2
,   XM_IO_FILE_TYPE_STDERR = 3

,   XM_IO_FILE_FLAG_TTY    = 0x10   //!< mark tty std stream

} xm_io_file_type_e;

/* use negetive numbers for this enum, its a extension for tb_charset_type_e
 * before adding new values, make sure they have not conflicts with values in tb_charset_type_e
 */
typedef enum __xm_io_file_encoding_e
{
    XM_IO_FILE_ENCODING_UNKNOWN = -1
,   XM_IO_FILE_ENCODING_BINARY  = -2

} xm_io_file_encoding_e;

// the file type
typedef struct __xm_io_file_t
{
    union
    {
        /* the normal file for XM_IO_FILE_TYPE_FILE
         *
         * direct:    file_ref -> stream -> file
         * transcode: file_ref -> fstream -> stream -> file
         */
        tb_stream_ref_t     file_ref;

        // the standard io file
        tb_stdfile_ref_t    std_ref;
    };

    tb_stream_ref_t  stream;    // the file stream for XM_IO_FILE_TYPE_FILE
    tb_stream_ref_t  fstream;   // the file charset stream filter
    tb_size_t        mode;      // tb_file_mode_t
    tb_size_t        type;      // xm_io_file_type_e
    tb_size_t        encoding;  // value of xm_io_file_encoding_e or tb_charset_type_e
    tb_buffer_t      rcache;    // the read line cache buffer
    tb_buffer_t      wcache;    // the write line cache buffer

} xm_io_file_t;

#endif


