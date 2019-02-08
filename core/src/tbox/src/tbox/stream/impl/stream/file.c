/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        file.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the file cache maxn
#define TB_STREAM_FILE_CACHE_MAXN             TB_FILE_DIRECT_CSIZE

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the file stream type
typedef struct __tb_stream_file_t
{
    // the file handle
    tb_file_ref_t       file;

    // the last read size
    tb_long_t           read;

    // the file mode
    tb_size_t           mode;

    // is stream file?
    tb_bool_t           bstream;

}tb_stream_file_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_stream_file_t* tb_stream_file_cast(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && tb_stream_type(stream) == TB_STREAM_TYPE_FILE, tb_null);

    // ok?
    return (tb_stream_file_t*)stream;
}
static tb_bool_t tb_stream_file_open(tb_stream_ref_t stream)
{
    // check
    tb_stream_file_t* stream_file = tb_stream_file_cast(stream);
    tb_assert_and_check_return_val(stream_file && !stream_file->file, tb_false);

    // opened?
    tb_check_return_val(!stream_file->file, tb_true);

    // url
    tb_char_t const* url = tb_url_cstr(tb_stream_url(stream));
    tb_assert_and_check_return_val(url, tb_false);

    // open file
    stream_file->file = tb_file_init(url, stream_file->mode);
    
    // open file failed?
    if (!stream_file->file)
    {
        // save state
        tb_stream_state_set(stream, tb_syserror_state());
        return tb_false;
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_stream_file_clos(tb_stream_ref_t stream)
{
    // check
    tb_stream_file_t* stream_file = tb_stream_file_cast(stream);
    tb_assert_and_check_return_val(stream_file, tb_false);

    // exit file
    if (stream_file->file && !tb_file_exit(stream_file->file)) return tb_false;
    stream_file->file = tb_null;

    // ok
    return tb_true;
}
static tb_long_t tb_stream_file_read(tb_stream_ref_t stream, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_stream_file_t* stream_file = tb_stream_file_cast(stream);
    tb_assert_and_check_return_val(stream_file && stream_file->file, -1);

    // check
    tb_check_return_val(data, -1);
    tb_check_return_val(size, 0);

    // read 
    stream_file->read = tb_file_read(stream_file->file, data, size);

    // ok?
    return stream_file->read;
}
static tb_long_t tb_stream_file_writ(tb_stream_ref_t stream, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_stream_file_t* stream_file = tb_stream_file_cast(stream);
    tb_assert_and_check_return_val(stream_file && stream_file->file && data, -1);

    // check
    tb_check_return_val(size, 0);

    // not support for stream file
    tb_assert_and_check_return_val(!stream_file->bstream, -1);

    // writ
    return tb_file_writ(stream_file->file, data, size);
}
static tb_bool_t tb_stream_file_sync(tb_stream_ref_t stream, tb_bool_t bclosing)
{
    // check
    tb_stream_file_t* stream_file = tb_stream_file_cast(stream);
    tb_assert_and_check_return_val(stream_file && stream_file->file, tb_false);

    // not support for stream file
    tb_assert_and_check_return_val(!stream_file->bstream, -1);

    // sync
    return tb_file_sync(stream_file->file);
}
static tb_bool_t tb_stream_file_seek(tb_stream_ref_t stream, tb_hize_t offset)
{
    // check
    tb_stream_file_t* stream_file = tb_stream_file_cast(stream);
    tb_assert_and_check_return_val(stream_file && stream_file->file, tb_false);

    // is stream file?
    tb_check_return_val(!stream_file->bstream, tb_false);

    // seek
    return (tb_file_seek(stream_file->file, offset, TB_FILE_SEEK_BEG) == offset)? tb_true : tb_false;
}
static tb_long_t tb_stream_file_wait(tb_stream_ref_t stream, tb_size_t wait, tb_long_t timeout)
{
    // check
    tb_stream_file_t* stream_file = tb_stream_file_cast(stream);
    tb_assert_and_check_return_val(stream_file && stream_file->file, -1);

    // wait 
    tb_long_t events = 0;
    if (!tb_stream_beof(stream))
    {
        if (wait & TB_STREAM_WAIT_READ) events |= TB_STREAM_WAIT_READ;
        if (wait & TB_STREAM_WAIT_WRIT) events |= TB_STREAM_WAIT_WRIT;
    }

    // end?
    if (stream_file->bstream && events > 0 && !stream_file->read) events = -1;

    // ok?
    return events;
}
static tb_bool_t tb_stream_file_ctrl(tb_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{
    // check
    tb_stream_file_t*  stream_file = tb_stream_file_cast(stream);
    tb_assert_and_check_return_val(stream_file, tb_false);

    // ctrl
    switch (ctrl)
    {
    case TB_STREAM_CTRL_GET_SIZE:
        {
            // the psize
            tb_hong_t* psize = (tb_hong_t*)tb_va_arg(args, tb_hong_t*);
            tb_assert_and_check_return_val(psize, tb_false);

            // get size
            if (!stream_file->bstream) *psize = stream_file->file? tb_file_size(stream_file->file) : 0;
            else *psize = -1;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FILE_SET_MODE:
        {
            // get mode
            stream_file->mode = (tb_size_t)tb_va_arg(args, tb_size_t);

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FILE_GET_MODE:
        {
            // the pmode
            tb_size_t* pmode = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_return_val(pmode, tb_false);

            // get mode
            *pmode = stream_file->mode;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FILE_IS_STREAM:
        {
            // is stream
            stream_file->bstream = (tb_bool_t)tb_va_arg(args, tb_bool_t);

            // ok
            return tb_true;
        }
    default:
        break;
    }
    return tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_stream_ref_t tb_stream_init_file()
{
    // init stream
    tb_stream_ref_t stream = tb_stream_init(    TB_STREAM_TYPE_FILE
                                            ,   sizeof(tb_stream_file_t)
                                            ,   TB_STREAM_FILE_CACHE_MAXN
                                            ,   tb_stream_file_open
                                            ,   tb_stream_file_clos
                                            ,   tb_null
                                            ,   tb_stream_file_ctrl
                                            ,   tb_stream_file_wait
                                            ,   tb_stream_file_read
                                            ,   tb_stream_file_writ
                                            ,   tb_stream_file_seek
                                            ,   tb_stream_file_sync
                                            ,   tb_null);
    tb_assert_and_check_return_val(stream, tb_null);

    // init the file stream 
    tb_stream_file_t* stream_file = tb_stream_file_cast(stream);
    if (stream_file)
    {
        // init it
        stream_file->mode      = TB_FILE_MODE_RO;
        stream_file->bstream   = tb_false;
        stream_file->read      = 0;
    }

    // ok?
    return (tb_stream_ref_t)stream;
}
tb_stream_ref_t tb_stream_init_from_file(tb_char_t const* path, tb_size_t mode)
{
    // check
    tb_assert_and_check_return_val(path, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     stream = tb_null;
    do
    {
        // init stream
        stream = tb_stream_init_file();
        tb_assert_and_check_break(stream);

        // set path
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_SET_URL, path)) break;
        
        // set mode
        if (mode) if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_FILE_SET_MODE, mode)) break;
    
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (stream) tb_stream_exit(stream);
        stream = tb_null;
    }

    // ok
    return stream;
}
