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
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        bin.c
 * @ingroup     object
 *
 */
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "oc_writer_bin"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "bin.h"
#include "writer.h"
#include "../../../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_oc_bin_writer_func_null(tb_oc_bin_writer_t* writer, tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && writer && writer->stream, tb_false);

    // writ type & null
    return tb_oc_writer_bin_type_size(writer->stream, object->type, 0);
}
static tb_bool_t tb_oc_bin_writer_func_date(tb_oc_bin_writer_t* writer, tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && writer && writer->stream, tb_false);

    // writ type & time
    return tb_oc_writer_bin_type_size(writer->stream, object->type, (tb_uint64_t)tb_oc_date_time(object));
}
static tb_bool_t tb_oc_bin_writer_func_data(tb_oc_bin_writer_t* writer, tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && writer && writer->stream, tb_false);

    // the data & size
    tb_byte_t const*    data = (tb_byte_t const*)tb_oc_data_getp(object);
    tb_size_t           size = tb_oc_data_size(object);

    // writ type & size
    if (!tb_oc_writer_bin_type_size(writer->stream, object->type, size)) return tb_false;

    // empty?
    tb_check_return_val(size, tb_true);

    // check 
    tb_assert_and_check_return_val(data, tb_false);

    // make the encoder data
    if (!writer->data)
    {
        writer->maxn = tb_max(size, 8192);
        writer->data = tb_malloc0_bytes(writer->maxn);
    }
    else if (writer->maxn < size)
    {
        writer->maxn = size;
        writer->data = (tb_byte_t*)tb_ralloc(writer->data, writer->maxn);
    }
    tb_assert_and_check_return_val(writer->data && size <= writer->maxn, tb_false);

    // copy data to encoder
    tb_memcpy(writer->data, data, size);

    // encode data
    tb_byte_t const*    pb = data;
    tb_byte_t const*    pe = data + size;
    tb_byte_t*          qb = writer->data;
    tb_byte_t*          qe = writer->data + writer->maxn;
    tb_byte_t           xb = (tb_byte_t)(((size >> 8) & 0xff) | (size & 0xff));
    for (; pb < pe && qb < qe; pb++, qb++, xb++) *qb = *pb ^ xb;

    // writ it
    return tb_stream_bwrit(writer->stream, writer->data, size);
}
static tb_bool_t tb_oc_bin_writer_func_array(tb_oc_bin_writer_t* writer, tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && writer && writer->stream && writer->ohash, tb_false);

    // writ type & size
    if (!tb_oc_writer_bin_type_size(writer->stream, object->type, tb_oc_array_size(object))) return tb_false;

    // walk
    tb_for_all (tb_object_ref_t, item, tb_oc_array_itor(object))
    {
        if (item)
        {
            // exists?
            tb_size_t index = (tb_size_t)tb_hash_map_get(writer->ohash, item);
            if (index)
            {
                // writ index
                if (!tb_oc_writer_bin_type_size(writer->stream, 0, (tb_uint64_t)(index - 1))) return tb_false;
            }
            else
            {
                // the func
                tb_oc_bin_writer_func_t func = tb_oc_bin_writer_func(item->type);
                tb_assert_and_check_continue(func);

                // writ it
                if (!func(writer, item)) return tb_false;

                // save index
                tb_hash_map_insert(writer->ohash, item, (tb_cpointer_t)(++writer->index));
            }
        }
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_oc_bin_writer_func_string(tb_oc_bin_writer_t* writer, tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && writer && writer->stream, tb_false);

    // the data & size
    tb_char_t const*    data = tb_oc_string_cstr(object);
    tb_size_t           size = tb_oc_string_size(object);

    // writ type & size
    if (!tb_oc_writer_bin_type_size(writer->stream, object->type, size)) return tb_false;

    // empty?
    tb_check_return_val(size, tb_true);

    // check
    tb_assert_and_check_return_val(data, tb_false);

    // make the encoder data
    if (!writer->data)
    {
        writer->maxn = tb_max(size, 8192);
        writer->data = tb_malloc0_bytes(writer->maxn);
    }
    else if (writer->maxn < size)
    {
        writer->maxn = size;
        writer->data = (tb_byte_t*)tb_ralloc(writer->data, writer->maxn);
    }
    tb_assert_and_check_return_val(writer->data && size <= writer->maxn, tb_false);

    // copy data to encoder
    tb_memcpy(writer->data, data, size);

    // encode data
    tb_byte_t const*    pb = (tb_byte_t const*)data;
    tb_byte_t const*    pe = (tb_byte_t const*)data + size;
    tb_byte_t*          qb = writer->data;
    tb_byte_t*          qe = writer->data + writer->maxn;
    tb_byte_t           xb = (tb_byte_t)(((size >> 8) & 0xff) | (size & 0xff));
    for (; pb < pe && qb < qe && *pb; pb++, qb++, xb++) *qb = *pb ^ xb;

    // writ it
    return tb_stream_bwrit(writer->stream, writer->data, size);
}
static tb_bool_t tb_oc_bin_writer_func_number(tb_oc_bin_writer_t* writer, tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && writer && writer->stream, tb_false);

    // writ type
    if (!tb_oc_writer_bin_type_size(writer->stream, object->type, (tb_uint64_t)tb_oc_number_type(object))) return tb_false;

    // writ number
    switch (tb_oc_number_type(object))
    {
    case TB_OC_NUMBER_TYPE_UINT64:
        if (!tb_stream_bwrit_u64_be(writer->stream, tb_oc_number_uint64(object))) return tb_false;
        break;
    case TB_OC_NUMBER_TYPE_SINT64:
        if (!tb_stream_bwrit_s64_be(writer->stream, tb_oc_number_sint64(object))) return tb_false;
        break;
    case TB_OC_NUMBER_TYPE_UINT32:
        if (!tb_stream_bwrit_u32_be(writer->stream, tb_oc_number_uint32(object))) return tb_false;
        break;
    case TB_OC_NUMBER_TYPE_SINT32:
        if (!tb_stream_bwrit_s32_be(writer->stream, tb_oc_number_sint32(object))) return tb_false;
        break;
    case TB_OC_NUMBER_TYPE_UINT16:
        if (!tb_stream_bwrit_u16_be(writer->stream, tb_oc_number_uint16(object))) return tb_false;
        break;
    case TB_OC_NUMBER_TYPE_SINT16:
        if (!tb_stream_bwrit_s16_be(writer->stream, tb_oc_number_sint16(object))) return tb_false;
        break;
    case TB_OC_NUMBER_TYPE_UINT8:
        if (!tb_stream_bwrit_u8(writer->stream, tb_oc_number_uint8(object))) return tb_false;
        break;
    case TB_OC_NUMBER_TYPE_SINT8:
        if (!tb_stream_bwrit_s8(writer->stream, tb_oc_number_sint8(object))) return tb_false;
        break;
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
    case TB_OC_NUMBER_TYPE_FLOAT:
        {
            tb_byte_t data[4];
            tb_bits_set_float_be(data, tb_oc_number_float(object));
            if (!tb_stream_bwrit(writer->stream, data, 4)) return tb_false;
        }
        break;
    case TB_OC_NUMBER_TYPE_DOUBLE:
        {
            tb_byte_t data[8];
            tb_bits_set_double_bbe(data, tb_oc_number_double(object));
            if (!tb_stream_bwrit(writer->stream, data, 8)) return tb_false;
        }
        break;
#endif
    default:
        tb_assert_and_check_return_val(0, tb_false);
        break;
    }

    // ok
    return tb_true;
}
static tb_bool_t tb_oc_bin_writer_func_boolean(tb_oc_bin_writer_t* writer, tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && writer && writer->stream, tb_false);

    // writ type & bool
    return tb_oc_writer_bin_type_size(writer->stream, object->type, tb_oc_boolean_bool(object));
}
static tb_bool_t tb_oc_bin_writer_func_dictionary(tb_oc_bin_writer_t* writer, tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && writer && writer->stream && writer->ohash, tb_false);

    // writ type & size
    if (!tb_oc_writer_bin_type_size(writer->stream, object->type, tb_oc_dictionary_size(object))) return tb_false;

    // walk
    tb_for_all (tb_oc_dictionary_item_t*, item, tb_oc_dictionary_itor(object))
    {
        if (item)
        {
            tb_char_t const*    key = item->key;
            tb_object_ref_t        val = item->val;
            if (key && val)
            {
                // writ key
                {
                    // exists?
                    tb_size_t index = (tb_size_t)tb_hash_map_get(writer->shash, key);
                    if (index)
                    {
                        // writ index
                        if (!tb_oc_writer_bin_type_size(writer->stream, 0, (tb_uint64_t)(index - 1))) return tb_false;
                    }
                    else
                    {
                        // the func
                        tb_oc_bin_writer_func_t func = tb_oc_bin_writer_func(TB_OBJECT_TYPE_STRING);
                        tb_assert_and_check_return_val(func, tb_false);

                        // make the key object
                        tb_object_ref_t okey = tb_oc_string_init_from_cstr(key);
                        tb_assert_and_check_return_val(okey, tb_false);

                        // writ it
                        if (!func(writer, okey)) return tb_false;

                        // exit it
                        tb_object_exit(okey);

                        // save index
                        tb_hash_map_insert(writer->shash, key, (tb_cpointer_t)(++writer->index));
                    }
                }

                // writ val
                {
                    // exists?
                    tb_size_t index = (tb_size_t)tb_hash_map_get(writer->ohash, val);
                    if (index)
                    {
                        // writ index
                        if (!tb_oc_writer_bin_type_size(writer->stream, 0, (tb_uint64_t)(index - 1))) return tb_false;
                    }
                    else
                    {
                        // the func
                        tb_oc_bin_writer_func_t func = tb_oc_bin_writer_func(val->type);
                        tb_assert_and_check_return_val(func, tb_false);

                        // writ it
                        if (!func(writer, val)) return tb_false;

                        // save index
                        tb_hash_map_insert(writer->ohash, val, (tb_cpointer_t)(++writer->index));
                    }
                }
            }
        }
    }

    // ok
    return tb_true;
}
static tb_long_t tb_oc_bin_writer_done(tb_stream_ref_t stream, tb_object_ref_t object, tb_bool_t deflate)
{
    // check
    tb_assert_and_check_return_val(object && stream, -1);

    // the func
    tb_oc_bin_writer_func_t func = tb_oc_bin_writer_func(object->type);
    tb_assert_and_check_return_val(func, -1);

    // the begin offset
    tb_hize_t bof = tb_stream_offset(stream);

    // writ bin header
    if (!tb_stream_bwrit(stream, (tb_byte_t const*)"tbo00", 5)) return -1;

    // done
    tb_oc_bin_writer_t writer = {0};
    do
    {
        // init writer
        writer.stream           = stream;
        writer.ohash            = tb_hash_map_init(TB_HASH_MAP_BUCKET_SIZE_MICRO, tb_element_ptr(tb_null, tb_null), tb_element_uint32());
        writer.shash            = tb_hash_map_init(TB_HASH_MAP_BUCKET_SIZE_MICRO, tb_element_str(tb_true), tb_element_uint32());
        tb_assert_and_check_break(writer.shash && writer.ohash);

        // writ
        if (!func(&writer, object)) break;

        // sync
        if (!tb_stream_sync(stream, tb_true)) break;

    } while (0);

    // exit the hash
    if (writer.ohash) tb_hash_map_exit(writer.ohash);
    if (writer.shash) tb_hash_map_exit(writer.shash);

    // exit the data
    if (writer.data) tb_free(writer.data);

    // the end offset
    tb_hize_t eof = tb_stream_offset(stream);

    // ok?
    return eof >= bof? (tb_long_t)(eof - bof) : -1;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_oc_writer_t* tb_oc_bin_writer()
{
    // the writer
    static tb_oc_writer_t s_writer = {0};
  
    // init writer
    s_writer.writ = tb_oc_bin_writer_done;
 
    // init hooker
    s_writer.hooker = tb_hash_map_init(TB_HASH_MAP_BUCKET_SIZE_MICRO, tb_element_uint32(), tb_element_ptr(tb_null, tb_null));
    tb_assert_and_check_return_val(s_writer.hooker, tb_null);

    // hook writer 
    tb_hash_map_insert(s_writer.hooker, (tb_pointer_t)TB_OBJECT_TYPE_NULL, tb_oc_bin_writer_func_null);
    tb_hash_map_insert(s_writer.hooker, (tb_pointer_t)TB_OBJECT_TYPE_DATE, tb_oc_bin_writer_func_date);
    tb_hash_map_insert(s_writer.hooker, (tb_pointer_t)TB_OBJECT_TYPE_DATA, tb_oc_bin_writer_func_data);
    tb_hash_map_insert(s_writer.hooker, (tb_pointer_t)TB_OBJECT_TYPE_ARRAY, tb_oc_bin_writer_func_array);
    tb_hash_map_insert(s_writer.hooker, (tb_pointer_t)TB_OBJECT_TYPE_STRING, tb_oc_bin_writer_func_string);
    tb_hash_map_insert(s_writer.hooker, (tb_pointer_t)TB_OBJECT_TYPE_NUMBER, tb_oc_bin_writer_func_number);
    tb_hash_map_insert(s_writer.hooker, (tb_pointer_t)TB_OBJECT_TYPE_BOOLEAN, tb_oc_bin_writer_func_boolean);
    tb_hash_map_insert(s_writer.hooker, (tb_pointer_t)TB_OBJECT_TYPE_DICTIONARY, tb_oc_bin_writer_func_dictionary);

    // ok
    return &s_writer;
}
tb_bool_t tb_oc_bin_writer_hook(tb_size_t type, tb_oc_bin_writer_func_t func)
{
    // check
    tb_assert_and_check_return_val(func, tb_false);
 
    // the writer
    tb_oc_writer_t* writer = tb_oc_writer_get(TB_OBJECT_FORMAT_BIN);
    tb_assert_and_check_return_val(writer && writer->hooker, tb_false);

    // hook it
    tb_hash_map_insert(writer->hooker, (tb_pointer_t)type, func);

    // ok
    return tb_true;
}
tb_oc_bin_writer_func_t tb_oc_bin_writer_func(tb_size_t type)
{
    // the writer
    tb_oc_writer_t* writer = tb_oc_writer_get(TB_OBJECT_FORMAT_BIN);
    tb_assert_and_check_return_val(writer && writer->hooker, tb_null);

    // the func
    return (tb_oc_bin_writer_func_t)tb_hash_map_get(writer->hooker, (tb_pointer_t)type);
}

