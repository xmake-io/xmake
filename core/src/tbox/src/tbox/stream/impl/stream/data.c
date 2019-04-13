/*!The Treasure Box Library
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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        data.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the data stream type
typedef struct __tb_stream_data_t
{
    // the data
    tb_byte_t*              data;

    // the head
    tb_byte_t*              head;

    // the size
    tb_size_t               size;

    // the data is referenced?
    tb_bool_t               bref;

}tb_stream_data_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_stream_data_t* tb_stream_data_cast(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && tb_stream_type(stream) == TB_STREAM_TYPE_DATA, tb_null);

    // ok?
    return (tb_stream_data_t*)stream;
}
static tb_bool_t tb_stream_data_open(tb_stream_ref_t stream)
{
    // check
    tb_stream_data_t* stream_data = tb_stream_data_cast(stream);
    tb_assert_and_check_return_val(stream_data && stream_data->data && stream_data->size, tb_false);

    // init head
    stream_data->head = stream_data->data;

    // ok
    return tb_true;
}
static tb_bool_t tb_stream_data_clos(tb_stream_ref_t stream)
{
    // check
    tb_stream_data_t* stream_data = tb_stream_data_cast(stream);
    tb_assert_and_check_return_val(stream_data, tb_false);
    
    // clear head
    stream_data->head = tb_null;

    // ok
    return tb_true;
}
static tb_void_t tb_stream_data_exit(tb_stream_ref_t stream)
{
    // check
    tb_stream_data_t* stream_data = tb_stream_data_cast(stream);
    tb_assert_and_check_return(stream_data);
    
    // clear head
    stream_data->head = tb_null;

    // exit data
    if (stream_data->data && !stream_data->bref) tb_free(stream_data->data);
    stream_data->data = tb_null;
    stream_data->size = 0;
}
static tb_long_t tb_stream_data_read(tb_stream_ref_t stream, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_stream_data_t* stream_data = tb_stream_data_cast(stream);
    tb_assert_and_check_return_val(stream_data && stream_data->data && stream_data->head, -1);

    // check
    tb_check_return_val(data, -1);
    tb_check_return_val(size, 0);

    // the left
    tb_size_t left = stream_data->data + stream_data->size - stream_data->head;

    // the need
    if (size > left) size = left;

    // read data
    if (size) tb_memcpy(data, stream_data->head, size);

    // save head
    stream_data->head += size;

    // ok?
    return (tb_long_t)(size);
}
static tb_long_t tb_stream_data_writ(tb_stream_ref_t stream, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_stream_data_t* stream_data = tb_stream_data_cast(stream);
    tb_assert_and_check_return_val(stream_data && stream_data->data && stream_data->head, -1);

    // check
    tb_check_return_val(data, -1);
    tb_check_return_val(size, 0);

    // the left
    tb_size_t left = stream_data->data + stream_data->size - stream_data->head;

    // the need
    if (size > left) size = left;

    // writ data
    if (size) tb_memcpy(stream_data->head, data, size);

    // save head
    stream_data->head += size;

    // ok?
    return left? (tb_long_t)(size) : -1; // force end if full
}
static tb_bool_t tb_stream_data_seek(tb_stream_ref_t stream, tb_hize_t offset)
{
    // check
    tb_stream_data_t* stream_data = tb_stream_data_cast(stream);
    tb_assert_and_check_return_val(stream_data && offset <= stream_data->size, tb_false);

    // seek 
    stream_data->head = stream_data->data + offset;

    // ok
    return tb_true;
}
static tb_long_t tb_stream_data_wait(tb_stream_ref_t stream, tb_size_t wait, tb_long_t timeout)
{
    // check
    tb_stream_data_t* stream_data = tb_stream_data_cast(stream);
    tb_assert_and_check_return_val(stream_data && stream_data->head <= stream_data->data + stream_data->size, -1);

    // wait 
    tb_long_t events = 0;
    if (!tb_stream_beof((tb_stream_ref_t)stream))
    {
        if (wait & TB_STREAM_WAIT_READ) events |= TB_STREAM_WAIT_READ;
        if (wait & TB_STREAM_WAIT_WRIT) events |= TB_STREAM_WAIT_WRIT;
    }

    // ok?
    return events;
}
static tb_bool_t tb_stream_data_ctrl(tb_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{
    // check
    tb_stream_data_t* stream_data = tb_stream_data_cast(stream);
    tb_assert_and_check_return_val(stream_data, tb_false);

    // ctrl
    switch (ctrl)
    {
    case TB_STREAM_CTRL_GET_SIZE:
        {
            // the psize
            tb_hong_t* psize = (tb_hong_t*)tb_va_arg(args, tb_hong_t*);
            tb_assert_and_check_return_val(psize, tb_false);

            // get size
            *psize = stream_data->size;
            return tb_true;
        }   
    case TB_STREAM_CTRL_DATA_SET_DATA:
        {
            // exit data first if exists
            if (stream_data->data && !stream_data->bref) tb_free(stream_data->data);

            // save data
            stream_data->data = (tb_byte_t*)tb_va_arg(args, tb_byte_t*);
            stream_data->size = (tb_size_t)tb_va_arg(args, tb_size_t);
            stream_data->head = tb_null;
            stream_data->bref = tb_true;

            // check
            tb_assert_and_check_return_val(stream_data->data && stream_data->size, tb_false);
            return tb_true;
        }
    case TB_STREAM_CTRL_SET_URL:
        {
            // check
            tb_assert_and_check_return_val(tb_stream_is_closed((tb_stream_ref_t)stream), tb_false);

            // set url
            tb_char_t const* url = (tb_char_t const*)tb_va_arg(args, tb_char_t const*);
            tb_assert_and_check_return_val(url, tb_false); 
            
            // the url size
            tb_size_t url_size = tb_strlen(url);
            tb_assert_and_check_return_val(url_size > 7, tb_false);

            // the base64 data and size
            tb_char_t const*    base64_data = url + 7;
            tb_size_t           base64_size = url_size - 7;

            // make data
            tb_size_t   maxn = base64_size;
            tb_byte_t*  data = tb_malloc_bytes(maxn); 
            tb_assert_and_check_return_val(data, tb_false);

            // decode base64 data
            tb_size_t   size = tb_base64_decode(base64_data, base64_size, data, maxn);
            tb_assert_and_check_return_val(size, tb_false);

            // exit data first if exists
            if (stream_data->data && !stream_data->bref) tb_free(stream_data->data);

            // save data
            stream_data->data = data;
            stream_data->size = size;
            stream_data->bref = tb_false;
            stream_data->head = tb_null;

            // ok
            return tb_true;
        }
        break;
    default:
        break;
    }
    return tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interface implementation
 */
tb_stream_ref_t tb_stream_init_data()
{
    return tb_stream_init(  TB_STREAM_TYPE_DATA
                        ,   sizeof(tb_stream_data_t)
                        ,   0
                        ,   tb_stream_data_open
                        ,   tb_stream_data_clos
                        ,   tb_stream_data_exit
                        ,   tb_stream_data_ctrl
                        ,   tb_stream_data_wait
                        ,   tb_stream_data_read
                        ,   tb_stream_data_writ
                        ,   tb_stream_data_seek
                        ,   tb_null
                        ,   tb_null);
}
tb_stream_ref_t tb_stream_init_from_data(tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(data && size, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     stream = tb_null;
    do
    {
        // init stream
        stream = tb_stream_init_data();
        tb_assert_and_check_break(stream);

        // set data and size
        if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_DATA_SET_DATA, data, size)) break;

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
