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
 * @file        object.c
 * @ingroup     object
 *
 */
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "object"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "object.h"
#include "impl/impl.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_object_init(tb_object_ref_t object, tb_size_t flag, tb_size_t type)
{
    // check
    tb_assert_and_check_return_val(object, tb_false);

    // init
    tb_memset(object, 0, sizeof(tb_object_t));
    object->flag = (tb_uint8_t)flag;
    object->type = (tb_uint16_t)type;
    object->refn = 1;

    // ok
    return tb_true;
}
tb_void_t tb_object_exit(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return(object);

    // readonly?
    tb_check_return(!(object->flag & TB_OBJECT_FLAG_READONLY));

    // check refn
    tb_assert_and_check_return(object->refn);

    // refn--
    object->refn--;

    // exit it?
    if (!object->refn && object->exit) object->exit(object);
}
tb_void_t tb_object_clear(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return(object);

    // readonly?
    tb_check_return(!(object->flag & TB_OBJECT_FLAG_READONLY));

    // clear
    if (object->clear) object->clear(object);
}
tb_void_t tb_object_setp(tb_object_ref_t object, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return(object);

    // set it
    object->priv = priv;
}
tb_cpointer_t tb_object_getp(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object, tb_null);

    // get it
    return object->priv;
}
tb_object_ref_t tb_object_copy(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && object->copy, tb_null);

    // copy
    return object->copy(object);
}
tb_size_t tb_object_type(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object, TB_OBJECT_TYPE_NONE);

    // the object type
    return object->type;
}
tb_object_ref_t tb_object_data(tb_object_ref_t object, tb_size_t format)
{   
    // check
    tb_assert_and_check_return_val(object, tb_null);

    // done
    tb_object_ref_t  odata = tb_null;
    tb_size_t           maxn = TB_STREAM_BLOCK_MAXN;
    tb_byte_t*          data = tb_null;
    do
    {
        // make data
        data = data? (tb_byte_t*)tb_ralloc(data, maxn) : tb_malloc_bytes(maxn);
        tb_assert_and_check_break(data);

        // writ object to data
        tb_long_t size = tb_object_writ_to_data(object, data, maxn, format);
    
        // ok? make the data object
        if (size >= 0) odata = tb_oc_data_init_from_data(data, size);
        // failed? grow it
        else maxn <<= 1;

    } while (!odata);

    // exit data
    if (data) tb_free(data);
    data = tb_null;

    // ok?
    return odata;
}
tb_object_ref_t tb_object_seek(tb_object_ref_t object, tb_char_t const* path, tb_bool_t bmacro)
{
    // check
    tb_assert_and_check_return_val(object, tb_null);

    // null?
    tb_check_return_val(path, object);

    // done
    tb_object_ref_t  root = object;
    tb_char_t const*    p = path;
    tb_char_t const*    e = path + tb_strlen(path);
    while (p < e && object)
    {
        // done seek
        switch (*p)
        {
        case '.':
            {
                // check
                tb_assert_and_check_return_val(tb_object_type(object) == TB_OBJECT_TYPE_DICTIONARY, tb_null);

                // skip
                p++;

                // read the key name
                tb_char_t   key[4096] = {0};
                tb_char_t*  kb = key;
                tb_char_t*  ke = key + 4095;
                for (; p < e && kb < ke && *p && (*p != '.' && *p != '[' && *p != ']'); p++, kb++) 
                {
                    if (*p == '\\') p++;
                    *kb = *p;
                }

                // trace
                tb_trace_d("key: %s", key);
            
                // the value
                object = tb_oc_dictionary_value(object, key);
            }
            break;
        case '[':
            {
                // check
                tb_assert_and_check_return_val(tb_object_type(object) == TB_OBJECT_TYPE_ARRAY, tb_null);

                // skip
                p++;

                // read the item index
                tb_char_t   index[32] = {0};
                tb_char_t*  ib = index;
                tb_char_t*  ie = index + 31;
                for (; p < e && ib < ie && *p && tb_isdigit10(*p); p++, ib++) *ib = *p;

                // trace
                tb_trace_d("index: %s", index);

                // check
                tb_size_t i = tb_atoi(index);
                tb_assert_and_check_return_val(i < tb_oc_array_size(object), tb_null);

                // the value
                object = tb_oc_array_item(object, i);
            }
            break;
        case ']':
        default:
            p++;
            break;
        }

        // is macro? done it if be enabled
        if (    object
            &&  bmacro
            &&  tb_object_type(object) == TB_OBJECT_TYPE_STRING
            &&  tb_oc_string_size(object)
            &&  tb_oc_string_cstr(object)[0] == '$')
        {
            // the next path
            path = tb_oc_string_cstr(object) + 1;

            // continue to seek it
            object = tb_object_seek(root, path, bmacro);
        }
    }

    // ok?
    return object;
}
tb_object_ref_t tb_object_dump(tb_object_ref_t object, tb_size_t format)
{
    // check
    tb_assert_and_check_return_val(object, tb_null);

    // data
    tb_object_ref_t odata = tb_object_data(object, format);
    if (odata)
    {
        // the data and size 
        tb_byte_t const*    data = (tb_byte_t const*)tb_oc_data_getp(odata);
        tb_size_t           size = tb_oc_data_size(odata);
        if (data && size)
        {
            // done
            tb_char_t const*    p = (tb_char_t const*)data;
            tb_char_t const*    e = (tb_char_t const*)data + size;
            tb_char_t           b[4096 + 1];
            if (p && p < e)
            {
                while (p < e && *p && tb_isspace(*p)) p++;
                while (p < e && *p)
                {
                    tb_char_t*          q = b;
                    tb_char_t const*    d = b + 4096;
                    for (; p < e && q < d && *p; p++, q++) *q = *p;
                    *q = '\0';
                    tb_printf("%s", b);
                }
                tb_printf("\n");
            }
        }

        // exit data
        tb_object_exit(odata);
    }

    // the object
    return object;
}
tb_size_t tb_object_refn(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object, 0);

    // get it
    return object->refn;
}
tb_void_t tb_object_retain(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return(object);

    // readonly?
    tb_check_return(!(object->flag & TB_OBJECT_FLAG_READONLY));

    // refn++
    object->refn++;
}
tb_object_ref_t tb_object_read(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // done reader
    return tb_oc_reader_done(stream);
}
tb_object_ref_t tb_object_read_from_url(tb_char_t const* url)
{
    // check
    tb_assert_and_check_return_val(url, tb_null);

    // init
    tb_object_ref_t object = tb_null;

    // make stream
    tb_stream_ref_t stream = tb_stream_init_from_url(url);
    tb_assert_and_check_return_val(stream, tb_null);

    // read object
    if (tb_stream_open(stream)) object = tb_object_read(stream);

    // exit stream
    tb_stream_exit(stream);

    // ok?
    return object;
}
tb_object_ref_t tb_object_read_from_data(tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(data && size, tb_null);

    // init
    tb_object_ref_t object = tb_null;

    // make stream
    tb_stream_ref_t stream = tb_stream_init_from_data(data, size);
    tb_assert_and_check_return_val(stream, tb_null);

    // read object
    if (tb_stream_open(stream)) object = tb_object_read(stream);

    // exit stream
    tb_stream_exit(stream);

    // ok?
    return object;
}
tb_long_t tb_object_writ(tb_object_ref_t object, tb_stream_ref_t stream, tb_size_t format)
{
    // check
    tb_assert_and_check_return_val(object && stream, -1);

    // for xml
#ifndef TB_CONFIG_MODULE_HAVE_XML
    tb_assertf(format != TB_OBJECT_FORMAT_XML || format != TB_OBJECT_FORMAT_XPLIST, "please enable xml module first!");
#endif

    // writ it
    return tb_oc_writer_done(object, stream, format);
}
tb_long_t tb_object_writ_to_url(tb_object_ref_t object, tb_char_t const* url, tb_size_t format)
{
    // check
    tb_assert_and_check_return_val(object && url, -1);

    // make stream
    tb_long_t           writ = -1;
    tb_stream_ref_t     stream = tb_stream_init_from_url(url);
    if (stream)
    {
        // ctrl stream
        if (tb_stream_type(stream) == TB_STREAM_TYPE_FILE)
            tb_stream_ctrl(stream, TB_STREAM_CTRL_FILE_SET_MODE, TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);

        // open and writ stream
        if (tb_stream_open(stream)) writ = tb_object_writ(object, stream, format);

        // exit stream
        tb_stream_exit(stream);
    }

    // ok?
    return writ;
}
tb_long_t tb_object_writ_to_data(tb_object_ref_t object, tb_byte_t* data, tb_size_t size, tb_size_t format)
{
    // check
    tb_assert_and_check_return_val(object && data && size, -1);

    // make stream
    tb_long_t           writ = -1;
    tb_stream_ref_t     stream = tb_stream_init_from_data(data, size);
    if (stream)
    {
        // open and writ stream
        if (tb_stream_open(stream)) writ = tb_object_writ(object, stream, format);

        // exit stream
        tb_stream_exit(stream);
    }

    // ok?
    return writ;
}

