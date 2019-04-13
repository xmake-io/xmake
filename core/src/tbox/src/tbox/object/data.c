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
 * @ingroup     object
 *
 */
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "oc_data"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "object.h"
#include "../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the data type
typedef struct __tb_oc_data_t
{
    // the object base
    tb_object_t     base;

    // the data buffer
    tb_buffer_t     buffer;

}tb_oc_data_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_oc_data_t* tb_oc_data_cast(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && object->type == TB_OBJECT_TYPE_DATA, tb_null);

    // cast
    return (tb_oc_data_t*)object;
}
static tb_object_ref_t tb_oc_data_copy(tb_object_ref_t object)
{
    return tb_oc_data_init_from_data(tb_oc_data_getp(object), tb_oc_data_size(object));
}
static tb_void_t tb_oc_data_exit(tb_object_ref_t object)
{
    tb_oc_data_t* data = tb_oc_data_cast(object);
    if (data) 
    {
        tb_buffer_exit(&data->buffer);
        tb_free(data);
    }
}
static tb_void_t tb_oc_data_clear(tb_object_ref_t object)
{
    tb_oc_data_t* data = tb_oc_data_cast(object);
    if (data) tb_buffer_clear(&data->buffer);
}
static tb_oc_data_t* tb_oc_data_init_base()
{
    // done
    tb_bool_t       ok = tb_false;
    tb_oc_data_t*   data = tb_null;
    do
    {
        // make data
        data = tb_malloc0_type(tb_oc_data_t);
        tb_assert_and_check_break(data);

        // init data
        if (!tb_object_init((tb_object_ref_t)data, TB_OBJECT_FLAG_NONE, TB_OBJECT_TYPE_DATA)) break;

        // init base
        data->base.copy     = tb_oc_data_copy;
        data->base.exit     = tb_oc_data_exit;
        data->base.clear    = tb_oc_data_clear;
        
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (data) tb_object_exit((tb_object_ref_t)data);
        data = tb_null;
    }

    // ok?
    return data;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_object_ref_t tb_oc_data_init_from_url(tb_char_t const* url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // init stream
    tb_stream_ref_t stream = tb_stream_init_from_url(url);
    tb_assert_and_check_return_val(stream, tb_null);

    // make stream
    tb_object_ref_t object = tb_null;
    if (tb_stream_open(stream))
    {
        // read all data
        tb_size_t   size = 0;
        tb_byte_t*  data = (tb_byte_t*)tb_stream_bread_all(stream, tb_false, &size);
        if (data)
        {
            // make object
            object = tb_oc_data_init_from_data(data, size);

            // exit data
            tb_free(data);
        }

        // exit stream
        tb_stream_exit(stream);
    }

    // ok?
    return object;
}
tb_object_ref_t tb_oc_data_init_from_data(tb_pointer_t addr, tb_size_t size)
{
    // make
    tb_oc_data_t* data = tb_oc_data_init_base();
    tb_assert_and_check_return_val(data, tb_null);

    // init buffer
    if (!tb_buffer_init(&data->buffer))
    {
        tb_oc_data_exit((tb_object_ref_t)data);
        return tb_null;
    }

    // copy data
    if (addr && size) tb_buffer_memncpy(&data->buffer, (tb_byte_t const*)addr, size);

    // ok
    return (tb_object_ref_t)data;
}
tb_object_ref_t tb_oc_data_init_from_buffer(tb_buffer_ref_t pbuf)
{   
    // make
    tb_oc_data_t* data = tb_oc_data_init_base();
    tb_assert_and_check_return_val(data, tb_null);

    // init buffer
    if (!tb_buffer_init(&data->buffer))
    {
        tb_oc_data_exit((tb_object_ref_t)data);
        return tb_null;
    }

    // copy data
    if (pbuf) tb_buffer_memcpy(&data->buffer, pbuf);

    // ok
    return (tb_object_ref_t)data;
}
tb_pointer_t tb_oc_data_getp(tb_object_ref_t object)
{
    // check
    tb_oc_data_t* data = tb_oc_data_cast(object);
    tb_assert_and_check_return_val(data, tb_null);

    // data
    return tb_buffer_data(&data->buffer);
}
tb_bool_t tb_oc_data_setp(tb_object_ref_t object, tb_pointer_t addr, tb_size_t size)
{
    // check
    tb_oc_data_t* data = tb_oc_data_cast(object);
    tb_assert_and_check_return_val(data && addr, tb_false);

    // data
    tb_buffer_memncpy(&data->buffer, (tb_byte_t const*)addr, size);

    // ok
    return tb_true;
}
tb_size_t tb_oc_data_size(tb_object_ref_t object)
{
    // check
    tb_oc_data_t* data = tb_oc_data_cast(object);
    tb_assert_and_check_return_val(data, 0);

    // data
    return tb_buffer_size(&data->buffer);
}
tb_buffer_ref_t tb_oc_data_buffer(tb_object_ref_t object)
{
    // check
    tb_oc_data_t* data = tb_oc_data_cast(object);
    tb_assert_and_check_return_val(data, tb_null);

    // buffer
    return &data->buffer;
}
tb_bool_t tb_oc_data_writ_to_url(tb_object_ref_t object, tb_char_t const* url)
{
    // check
    tb_oc_data_t* data = tb_oc_data_cast(object);
    tb_assert_and_check_return_val(data && tb_oc_data_getp((tb_object_ref_t)data) && url, tb_false);

    // make stream
    tb_stream_ref_t stream = tb_stream_init_from_url(url);
    tb_assert_and_check_return_val(stream, tb_false);

    // ctrl
    if (tb_stream_type(stream) == TB_STREAM_TYPE_FILE)
        tb_stream_ctrl(stream, TB_STREAM_CTRL_FILE_SET_MODE, TB_FILE_MODE_WO | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
    
    // open stream
    tb_bool_t ok = tb_false;
    if (tb_stream_open(stream))
    {
        // writ stream
        if (tb_stream_bwrit(stream, (tb_byte_t const*)tb_oc_data_getp((tb_object_ref_t)data), tb_oc_data_size((tb_object_ref_t)data))) ok = tb_true;
    }

    // exit stream
    tb_stream_exit(stream);

    // ok?
    return ok;
}
