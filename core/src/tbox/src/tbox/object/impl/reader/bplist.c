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
 * @file        bplist.c
 * @ingroup     object
 *
 */
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "oc_reader_bplist"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "bplist.h"
#include "reader.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the array grow
#ifdef __tb_small__
#   define TB_OC_BPLIST_READER_ARRAY_GROW           (64)
#else
#   define TB_OC_BPLIST_READER_ARRAY_GROW           (256)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the bplist type enum
typedef enum __tb_oc_bplist_type_e
{
    TB_OC_BPLIST_TYPE_NONE      = 0x00
,   TB_OC_BPLIST_TYPE_FALSE     = 0x08
,   TB_OC_BPLIST_TYPE_TRUE      = 0x09
,   TB_OC_BPLIST_TYPE_UINT      = 0x10
,   TB_OC_BPLIST_TYPE_REAL      = 0x20
,   TB_OC_BPLIST_TYPE_DATE      = 0x30
,   TB_OC_BPLIST_TYPE_DATA      = 0x40
,   TB_OC_BPLIST_TYPE_STRING    = 0x50
,   TB_OC_BPLIST_TYPE_UNICODE   = 0x60
,   TB_OC_BPLIST_TYPE_UID       = 0x80
,   TB_OC_BPLIST_TYPE_ARRAY     = 0xA0
,   TB_OC_BPLIST_TYPE_SET       = 0xC0
,   TB_OC_BPLIST_TYPE_DICT      = 0xD0
,   TB_OC_BPLIST_TYPE_MASK      = 0xF0

}tb_oc_bplist_type_e;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_time_t tb_oc_bplist_reader_time_apple2host(tb_time_t time)
{
    tb_tm_t tm = {0};
    if (tb_localtime(time, &tm))
    {
        if (tm.year < 2000) tm.year += 31;
        time = tb_mktime(&tm);
    }
    return time;
}
static __tb_inline__ tb_size_t tb_oc_bplist_bits_get(tb_byte_t const* p, tb_size_t n)
{
    tb_size_t v = 0;
    switch (n) 
    {
    case 1: v = tb_bits_get_u8((p)); break; 
    case 2: v = tb_bits_get_u16_be((p)); break; 
    case 4: v = tb_bits_get_u32_be((p)); break; 
    case 8: v = tb_bits_get_u64_be((p)); break; 
    default: break; 
    }
    return v; 
}
static tb_object_ref_t tb_oc_bplist_reader_func_object(tb_oc_bplist_reader_t* reader, tb_size_t item_size)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // read the object type 
    tb_uint8_t type = 0;
    tb_bool_t ok = tb_stream_bread_u8(reader->stream, &type);
    tb_assert_and_check_return_val(ok, tb_null);

    // read the object type and size
    tb_uint8_t size = type & 0x0f; type &= 0xf0;
    tb_trace_d("type: %x, size: %x", type, size);

    // the func
    tb_oc_bplist_reader_func_t func = tb_oc_bplist_reader_func(type);
    tb_assert_and_check_return_val(func, tb_null);

    // read
    return func(reader, type, size, item_size);
}
static tb_long_t tb_oc_bplist_reader_func_size(tb_oc_bplist_reader_t* reader, tb_size_t item_size)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, -1);

    // read size
    tb_object_ref_t object = tb_oc_bplist_reader_func_object(reader, item_size);
    tb_assert_and_check_return_val(object, -1);

    tb_long_t size = -1;
    if (tb_object_type(object) == TB_OBJECT_TYPE_NUMBER)
        size = tb_oc_number_uint32(object);

    // exit
    tb_object_exit(object);

    // size
    return size;
}
static tb_object_ref_t tb_oc_bplist_reader_func_data(tb_oc_bplist_reader_t* reader, tb_size_t type, tb_size_t size, tb_size_t item_size)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // init 
    tb_byte_t*          data = tb_null;
    tb_object_ref_t     object = tb_null;

    // size is too large?
    if (size == 0x0f)
    {
        // read size
        tb_long_t val = tb_oc_bplist_reader_func_size(reader, item_size);
        tb_assert_and_check_return_val(val >= 0, tb_null);
        size = (tb_size_t)val;
    }

    // no empty?
    if (size)
    {
        // make data
        data = tb_malloc_bytes(size);
        tb_assert_and_check_return_val(data, tb_null);

        // read data
        if (tb_stream_bread(reader->stream, data, size))
            object = tb_oc_data_init_from_data(data, size);
    }
    else object = tb_oc_data_init_from_data(tb_null, 0);

    // exit
    if (data) tb_free(data);

    // ok?
    return object;
}
static tb_object_ref_t tb_oc_bplist_reader_func_array(tb_oc_bplist_reader_t* reader, tb_size_t type, tb_size_t size, tb_size_t item_size)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // init 
    tb_object_ref_t object = tb_null;

    // size is too large?
    if (size == 0x0f)
    {
        // read size
        tb_long_t val = tb_oc_bplist_reader_func_size(reader, item_size);
        tb_assert_and_check_return_val(val >= 0, tb_null);
        size = (tb_size_t)val;
    }

    // init array
    object = tb_oc_array_init(size? size : 16, tb_false);
    tb_assert_and_check_return_val(object, tb_null);

    // init items data
    if (size)
    {
        tb_byte_t* data = tb_malloc_bytes(sizeof(tb_uint32_t) + (size * item_size));
        if (data)
        {
            if (tb_stream_bread(reader->stream, data + sizeof(tb_uint32_t), size * item_size))
            {
                tb_bits_set_u32_ne(data, (tb_uint32_t)size);

                // FIXME: not using the user private data
                tb_object_setp(object, data);
            }
            else tb_free(data);
        }
    }

    // ok?
    return object;
}
static tb_object_ref_t tb_oc_bplist_reader_func_string(tb_oc_bplist_reader_t* reader, tb_size_t type, tb_size_t size, tb_size_t item_size)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // init 
    tb_char_t*      utf8 = tb_null;
    tb_char_t*      utf16 = tb_null;
    tb_object_ref_t    object = tb_null;

    // read
    switch (type)
    {
    case TB_OC_BPLIST_TYPE_STRING:
        {
            // size is too large?
            if (size == 0x0f)
            {
                // read size
                tb_long_t val = tb_oc_bplist_reader_func_size(reader, item_size);
                tb_assert_and_check_return_val(val >= 0, tb_null);
                size = (tb_size_t)val;
            }

            // read string
            if (size)
            {
                // init utf8
                utf8 = tb_malloc_cstr(size + 1);
                tb_assert_and_check_break(utf8);

                // read utf8
                if (!tb_stream_bread(reader->stream, (tb_byte_t*)utf8, size)) break;
                utf8[size] = '\0';
            }

            // init object
            object = tb_oc_string_init_from_cstr(utf8);
        }
        break;
    case TB_OC_BPLIST_TYPE_UNICODE:
        {
#ifdef TB_CONFIG_MODULE_HAVE_CHARSET
            // size is too large?
            if (size == 0x0f)
            {
                // read size
                tb_long_t val = tb_oc_bplist_reader_func_size(reader, item_size);
                tb_assert_and_check_return_val(val >= 0, tb_null);
                size = (tb_size_t)val;
            }

            // read string
            if (size)
            {
                // init utf8 & utf16 data
                utf8 = tb_malloc_cstr((size + 1) << 2);
                utf16 = tb_malloc_cstr(size << 1);
                tb_assert_and_check_break(utf8 && utf16);

                // read utf16
                if (!tb_stream_bread(reader->stream, (tb_byte_t*)utf16, size << 1)) break;
                
                // utf16 to utf8
                tb_long_t osize = tb_charset_conv_data(TB_CHARSET_TYPE_UTF16, TB_CHARSET_TYPE_UTF8, (tb_byte_t*)utf16, size << 1, (tb_byte_t*)utf8, (size + 1) << 2);
                tb_assert_and_check_break(osize > 0 && osize < (tb_long_t)((size + 1) << 2));
                utf8[osize] = '\0';

                // init object
                object = tb_oc_string_init_from_cstr(utf8);
            }
#else
            // trace
            tb_trace1_e("unicode type is not supported, please enable charset module config if you want to use it!");
#endif
        }
        break;
    default:
        break;
    }

    // exit
    if (utf8) tb_free(utf8);
    if (utf16) tb_free(utf16);

    // ok?
    return object;
}
static tb_object_ref_t tb_oc_bplist_reader_func_number(tb_oc_bplist_reader_t* reader, tb_size_t type, tb_size_t size, tb_size_t item_size)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // adjust size
    size = (tb_size_t)1 << size;

    // done
    tb_value_t          value;
    tb_object_ref_t  object = tb_null;
    switch (size)
    {
    case 1:
        {
            // read and init object
            if (tb_stream_bread_u8(reader->stream, &value.u8))
                object = tb_oc_number_init_from_uint8(value.u8);
        }
        break;
    case 2:
        {
            // read and init object
            if (tb_stream_bread_u16_be(reader->stream, &value.u16))
                object = tb_oc_number_init_from_uint16(value.u16);
        }
        break;
    case 4:
        {
            switch (type)
            {
            case TB_OC_BPLIST_TYPE_UID:
            case TB_OC_BPLIST_TYPE_UINT:
                {
                    // read and init object
                    if (tb_stream_bread_u32_be(reader->stream, &value.u32))
                        object = tb_oc_number_init_from_uint32(value.u32);
                }
                break;
            case TB_OC_BPLIST_TYPE_REAL:
                {
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
                    // read and init object
                    if (tb_stream_bread_float_be(reader->stream, &value.f))
                        object = tb_oc_number_init_from_float(value.f);
#else
                    tb_trace_e("real type is not supported! please enable float config.");
#endif
                }
                break;
            default:
                tb_assert(0);
                break;
            }
        }
        break;
    case 8:
        {
            switch (type)
            {
            case TB_OC_BPLIST_TYPE_UID:
            case TB_OC_BPLIST_TYPE_UINT:
                {
                    // read and init object
                    if (tb_stream_bread_u64_be(reader->stream, &value.u64))
                        object = tb_oc_number_init_from_uint64(value.u64);
                }
                break;
            case TB_OC_BPLIST_TYPE_REAL:
                {
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
                    // read and init object
                    if (tb_stream_bread_double_bbe(reader->stream, &value.d))
                        object = tb_oc_number_init_from_double(value.d);
#else
                    tb_trace_e("real type is not supported! please enable float config.");
#endif
                }
                break;
            default:
                tb_assert(0);
                break;
            }
        }
        break;
    default:
        tb_assert(0);
        break;
    }

    // ok?
    return object;
}
static tb_object_ref_t tb_oc_bplist_reader_func_uid(tb_oc_bplist_reader_t* reader, tb_size_t type, tb_size_t size, tb_size_t item_size)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // done
    tb_bool_t       ok = tb_false;
    tb_object_ref_t uid = tb_null;
    tb_object_ref_t value = tb_null;
    do
    {
        // read uid value
        value = tb_oc_bplist_reader_func_number(reader, TB_OC_BPLIST_TYPE_UINT, size, item_size);
        tb_assert_and_check_break(value);

        // init uid object
        uid = tb_oc_dictionary_init(8, tb_false);
        tb_assert_and_check_break(uid);

        // save this uid value
        tb_oc_dictionary_insert(uid, "CF$UID", value);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit value
        if (value) tb_object_exit(value);
        value = tb_null;
    }

    // ok?
    return uid;
}
static tb_object_ref_t tb_oc_bplist_reader_func_date(tb_oc_bplist_reader_t* reader, tb_size_t type, tb_size_t size, tb_size_t item_size)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // the date data
    tb_object_ref_t data = tb_oc_bplist_reader_func_number(reader, TB_OC_BPLIST_TYPE_REAL, size, item_size);
    tb_assert_and_check_return_val(data, tb_null);

    // init date
    tb_object_ref_t date = tb_oc_date_init_from_time(tb_oc_bplist_reader_time_apple2host((tb_time_t)tb_oc_number_uint64(data)));

    // exit data
    tb_object_exit(data);

    // ok?
    return date;
}
static tb_object_ref_t tb_oc_bplist_reader_func_boolean(tb_oc_bplist_reader_t* reader, tb_size_t type, tb_size_t size, tb_size_t item_size)
{
    // init 
    tb_object_ref_t object = tb_null;

    // read 
    switch (size)
    {
    case TB_OC_BPLIST_TYPE_TRUE:
        object = tb_oc_boolean_init(tb_true);
        break;
    case TB_OC_BPLIST_TYPE_FALSE:
        object = tb_oc_boolean_init(tb_false);
        break;
    default:
        tb_assert(0);
        break;
    }
    return object;
}
static tb_object_ref_t tb_oc_bplist_reader_func_dictionary(tb_oc_bplist_reader_t* reader, tb_size_t type, tb_size_t size, tb_size_t item_size)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // init 
    tb_object_ref_t object = tb_null;

    // size is too large?
    if (size == 0x0f)
    {
        // read size
        tb_long_t val = tb_oc_bplist_reader_func_size(reader, item_size);
        tb_assert_and_check_return_val(val >= 0, tb_null);
        size = (tb_size_t)val;
    }

    // init dictionary
    object = tb_oc_dictionary_init(TB_OC_DICTIONARY_SIZE_MICRO, tb_false);
    tb_assert_and_check_return_val(object, tb_null);

    // init items data
    if (size)
    {
        item_size <<= 1;
        tb_byte_t* data = tb_malloc_bytes(sizeof(tb_uint32_t) + (size * item_size));
        if (data)
        {
            if (tb_stream_bread(reader->stream, data + sizeof(tb_uint32_t), size * item_size))
            {
                tb_bits_set_u32_ne(data, (tb_uint32_t)size);
                tb_object_setp(object, data);
            }
            else tb_free(data);
        }
    }

    // ok?
    return object;
}
static tb_object_ref_t tb_oc_bplist_reader_done(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // init root
    tb_object_ref_t root = tb_null;

    // init reader
    tb_oc_bplist_reader_t reader = {0};
    reader.stream = stream;

    // init size
    tb_hize_t size = tb_stream_size(stream);
    tb_assert_and_check_return_val(size, tb_null);

    // init data
    tb_byte_t data[32] = {0};
    
    // read magic & version
    if (!tb_stream_bread(stream, data, 8)) return tb_null;

    // check magic & version
    if (tb_strncmp((tb_char_t const*)data, "bplist00", 8)) return tb_null;

    // seek to tail
    if (!tb_stream_seek(stream, size - 26)) return tb_null;
    
    // read offset size
    tb_uint8_t offset_size = 0;
    if (!tb_stream_bread_u8(stream, &offset_size)) return tb_null;

    // read item size for array and dictionary
    tb_uint8_t item_size = 0;
    if (!tb_stream_bread_u8(stream, &item_size)) return tb_null;
    
    // read object count
    tb_uint64_t object_count = 0;
    if (!tb_stream_bread_u64_be(stream, &object_count)) return tb_null;
    
    // read root object
    tb_uint64_t root_object = 0;
    if (!tb_stream_bread_u64_be(stream, &root_object)) return tb_null;

    // read offset table index
    tb_uint64_t offset_table_index = 0;
    if (!tb_stream_bread_u64_be(stream, &offset_table_index)) return tb_null;

    // trace
    tb_trace_d("offset_size: %u",           offset_size);
    tb_trace_d("item_size: %u",             item_size);
    tb_trace_d("object_count: %llu",        object_count);
    tb_trace_d("root_object: %llu",         root_object);
    tb_trace_d("offset_table_index: %llu",  offset_table_index);
    
    // check
    tb_assert_and_check_return_val(item_size && offset_size && object_count, tb_null);

    // init object hash
    tb_object_ref_t* object_hash = (tb_object_ref_t*)tb_malloc0(sizeof(tb_object_ref_t) * (tb_size_t)object_count);
    tb_assert_and_check_return_val(object_hash, tb_null);

    // done
    tb_bool_t failed = tb_false;
    do
    {
        // walk
        tb_size_t i = 0;
        for (i = 0; i < object_count; i++)
        {
            // seek to the offset entry
            if (!tb_stream_seek(stream, offset_table_index + i * offset_size)) 
            {
                failed = tb_true;
                break;
            }

            // read the object offset
            tb_value_t  value;
            tb_hize_t   offset = 0;
            switch (offset_size)
            {
            case 1:
                if (tb_stream_bread_u8(stream, &value.u8)) offset = value.u8;
                break;
            case 2:
                if (tb_stream_bread_u16_be(stream, &value.u16)) offset = value.u16;
                break;
            case 4:
                if (tb_stream_bread_u32_be(stream, &value.u32)) offset = value.u32;
                break;
            case 8:
                if (tb_stream_bread_u64_be(stream, &value.u64)) offset = value.u64;
                break;
            default:
                return tb_null;
                break;
            }
            tb_check_break(!failed);

            // seek to the object offset 
            if (!tb_stream_seek(stream, offset)) 
            {
                failed = tb_true;
                break;
            }

            // read object
            object_hash[i] = tb_oc_bplist_reader_func_object(&reader, item_size);
        }

        // failed?
        tb_check_break(!failed);

        // build array and dictionary items
        for (i = 0; i < object_count; i++)
        {
            tb_object_ref_t object = object_hash[i];
            if (object)
            {
                switch (tb_object_type(object))
                {
                case TB_OBJECT_TYPE_ARRAY:
                    {
                        // the priv data
                        tb_byte_t* priv = (tb_byte_t*)tb_object_getp(object);
                        if (priv)
                        {
                            // count
                            tb_size_t count = (tb_size_t)tb_bits_get_u32_ne(priv);
                            if (count)
                            {
                                // goto item data
                                tb_byte_t const* p = priv + sizeof(tb_uint32_t);
                                // walk items
                                tb_size_t j = 0;
                                for (j = 0; j < count; j++)
                                {
                                    // the item index
                                    tb_size_t item = tb_oc_bplist_bits_get(p + j * item_size, item_size);
                                    tb_assert(item < object_count && object_hash[item]);

                                    // append item
                                    if (item < object_count && object_hash[item])
                                    {
                                        tb_object_retain(object_hash[item]);
                                        tb_oc_array_append(object, object_hash[item]);
                                    }
                                }
                            }

                            // exit priv
                            tb_free(priv);
                            tb_object_setp(object, tb_null);
                        }
                    }
                    break;
                case TB_OBJECT_TYPE_DICTIONARY:
                    { 
                        // the priv data
                        tb_byte_t* priv = (tb_byte_t*)tb_object_getp(object);
                        if (priv)
                        {
                            // count
                            tb_size_t count = (tb_size_t)tb_bits_get_u32_ne(priv);
                            if (count)
                            {
                                // goto item data
                                tb_byte_t const* p = priv + sizeof(tb_uint32_t);

                                // walk items
                                tb_size_t j = 0;
                                for (j = 0; j < count; j++)
                                {
                                    // the key and val
                                    tb_size_t key = tb_oc_bplist_bits_get(p + j * item_size, item_size);
                                    tb_size_t val = tb_oc_bplist_bits_get(p + (count + j) * item_size, item_size);
                                    tb_assert(key < object_count && object_hash[key]);
                                    tb_assert(val < object_count && object_hash[val]);

                                    // append the key & val
                                    if (key < object_count && val < object_count && object_hash[key] && object_hash[val])
                                    {
                                        // key must be string now.
                                        tb_assert(tb_object_type(object_hash[key]) == TB_OBJECT_TYPE_STRING);
                                        if (tb_object_type(object_hash[key]) == TB_OBJECT_TYPE_STRING)
                                        {
                                            // set key => val
                                            tb_char_t const* skey = tb_oc_string_cstr(object_hash[key]);
                                            if (skey) 
                                            {
                                                tb_object_retain(object_hash[val]);
                                                tb_oc_dictionary_insert(object, skey, object_hash[val]);
                                            }
                                            tb_assert(skey);
                                        }
                                    }
                                }
                            }

                            // exit priv
                            tb_free(priv);
                            tb_object_setp(object, tb_null);
                        }
                    }
                    break;
                default:
                    break;
                }
            }
        }   

    } while (0);

    // exit object hash
    if (object_hash)
    {
        // root
        if (root_object < object_count) root = object_hash[root_object];

        // refn--
        tb_size_t i;
        for (i = 0; i < object_count; i++)
        {
            if (object_hash[i] && i != root_object)
                tb_object_exit(object_hash[i]);
        }

        // exit object hash
        tb_free(object_hash);
        object_hash = tb_null;
    }

    // ok?
    return root;
}
static tb_size_t tb_oc_bplist_reader_probe(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // need it
    tb_byte_t* p = tb_null;
    if (!tb_stream_need(stream, &p, 6)) return 0;
    tb_assert_and_check_return_val(p, 0);

    // ok?
    return !tb_strnicmp((tb_char_t const*)p, "bplist", 6)? 80 : 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_oc_reader_t* tb_oc_bplist_reader()
{
    // the reader
    static tb_oc_reader_t s_reader = {0};

    // init reader
    s_reader.read   = tb_oc_bplist_reader_done;
    s_reader.probe  = tb_oc_bplist_reader_probe;

    // init hooker
    s_reader.hooker = tb_hash_map_init(TB_HASH_MAP_BUCKET_SIZE_MICRO, tb_element_uint32(), tb_element_ptr(tb_null, tb_null));
    tb_assert_and_check_return_val(s_reader.hooker, tb_null);

    // hook reader 
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_DATE,      tb_oc_bplist_reader_func_date);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_DATA,      tb_oc_bplist_reader_func_data);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_UID,       tb_oc_bplist_reader_func_uid);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_ARRAY,     tb_oc_bplist_reader_func_array);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_STRING,    tb_oc_bplist_reader_func_string);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_UNICODE,   tb_oc_bplist_reader_func_string);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_UINT,      tb_oc_bplist_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_REAL,      tb_oc_bplist_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_NONE,      tb_oc_bplist_reader_func_boolean);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_SET,       tb_oc_bplist_reader_func_dictionary);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)TB_OC_BPLIST_TYPE_DICT,      tb_oc_bplist_reader_func_dictionary);

    // ok
    return &s_reader;
}
tb_bool_t tb_oc_bplist_reader_hook(tb_size_t type, tb_oc_bplist_reader_func_t func)
{
    // check
    tb_assert_and_check_return_val(func, tb_false);

    // the reader
    tb_oc_reader_t* reader = tb_oc_reader_get(TB_OBJECT_FORMAT_BPLIST);
    tb_assert_and_check_return_val(reader && reader->hooker, tb_false);

    // hook it
    tb_hash_map_insert(reader->hooker, (tb_pointer_t)type, func);

    // ok
    return tb_true;
}
tb_oc_bplist_reader_func_t tb_oc_bplist_reader_func(tb_size_t type)
{
    // the reader
    tb_oc_reader_t* reader = tb_oc_reader_get(TB_OBJECT_FORMAT_BPLIST);
    tb_assert_and_check_return_val(reader && reader->hooker, tb_null);

    // the func
    return (tb_oc_bplist_reader_func_t)tb_hash_map_get(reader->hooker, (tb_pointer_t)type);
}

