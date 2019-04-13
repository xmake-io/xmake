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
 * @file        json.c
 * @ingroup     object
 *
 */
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "oc_reader_json"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "json.h"
#include "reader.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the array grow
#ifdef __tb_small__
#   define TB_OC_JSON_READER_ARRAY_GROW             (64)
#else
#   define TB_OC_JSON_READER_ARRAY_GROW             (256)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_object_ref_t tb_oc_json_reader_func_null(tb_oc_json_reader_t* reader, tb_char_t type)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // init data
    tb_static_string_t  data;
    tb_char_t           buff[256];
    if (!tb_static_string_init(&data, buff, 256)) return tb_null;

    // done 
    tb_object_ref_t null = tb_null;
    do
    {
        // append character
        tb_static_string_chrcat(&data, type);

        // walk
        tb_bool_t failed = tb_false;
        while (!failed && tb_stream_left(reader->stream)) 
        {
            // need one character
            tb_byte_t* p = tb_null;
            if (!tb_stream_need(reader->stream, &p, 1) && p) 
            {
                failed = tb_true;
                break;
            }

            // the character
            tb_char_t ch = *p;

            // append character
            if (tb_isalpha(ch)) tb_static_string_chrcat(&data, ch);
            else break;

            // skip it
            tb_stream_skip(reader->stream, 1);
        }

        // failed?
        tb_check_break(!failed);

        // check
        tb_assert_and_check_break(tb_static_string_size(&data));

        // trace
        tb_trace_d("null: %s", tb_static_string_cstr(&data));

        // null?
        if (!tb_stricmp(tb_static_string_cstr(&data), "null")) null = tb_oc_null_init();

    } while (0);

    // exit data
    tb_static_string_exit(&data);

    // ok?
    return null;
}
static tb_object_ref_t tb_oc_json_reader_func_array(tb_oc_json_reader_t* reader, tb_char_t type)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream && type == '[', tb_null);

    // init array
    tb_object_ref_t array = tb_oc_array_init(TB_OC_JSON_READER_ARRAY_GROW, tb_false);
    tb_assert_and_check_return_val(array, tb_null);

    // done
    tb_char_t ch;
    tb_bool_t ok = tb_true;
    while (ok && tb_stream_left(reader->stream)) 
    {
        // read one character
        if (!tb_stream_bread_s8(reader->stream, (tb_sint8_t*)&ch)) break;

        // end?
        if (ch == ']') break;
        // no space? skip ','
        else if (!tb_isspace(ch) && ch != ',')
        {
            // the func
            tb_oc_json_reader_func_t func = tb_oc_json_reader_func(ch);
            tb_assert_and_check_break_state(func, ok, tb_false);

            // read item
            tb_object_ref_t item = func(reader, ch);
            tb_assert_and_check_break_state(item, ok, tb_false);

            // append item
            tb_oc_array_append(array, item);
        }
    }

    // failed?
    if (!ok)
    {
        // exit it
        if (array) tb_object_exit(array);
        array = tb_null;
    }

    // ok?
    return array;
}
static tb_object_ref_t tb_oc_json_reader_func_string(tb_oc_json_reader_t* reader, tb_char_t type)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream && (type == '\"' || type == '\''), tb_null);

    // init data
    tb_string_t data;
    if (!tb_string_init(&data)) return tb_null;

    // walk
    tb_char_t ch;
    while (tb_stream_left(reader->stream)) 
    {
        // read one character
        if (!tb_stream_bread_s8(reader->stream, (tb_sint8_t*)&ch)) break;

        // end?
        if (ch == '\"' || ch == '\'') break;
        // the escaped character?
        else if (ch == '\\')
        {
            // read one character
            if (!tb_stream_bread_s8(reader->stream, (tb_sint8_t*)&ch)) break;

            // unicode?
            if (ch == 'u')
            {
#ifdef TB_CONFIG_MODULE_HAVE_CHARSET
                // the unicode string
                tb_char_t unicode_str[5];
                if (!tb_stream_bread(reader->stream, (tb_byte_t*)unicode_str, 4)) break;
                unicode_str[4] = '\0';

                // the unicode value
                tb_uint16_t unicode_val = tb_s16toi32(unicode_str);

                // the utf8 stream
                tb_char_t           utf8_data[16] = {0};
                tb_static_stream_t  utf8_stream;
                tb_static_stream_init(&utf8_stream, (tb_byte_t*)utf8_data, sizeof(utf8_data));

                // the unicode stream
                tb_static_stream_t  unicode_stream = {0};
                tb_static_stream_init(&unicode_stream, (tb_byte_t*)&unicode_val, 2);

                // unicode to utf8
                tb_long_t utf8_size = tb_charset_conv_bst(TB_CHARSET_TYPE_UCS2 | TB_CHARSET_TYPE_NE, TB_CHARSET_TYPE_UTF8, &unicode_stream, &utf8_stream);
                if (utf8_size > 0) tb_string_cstrncat(&data, utf8_data, utf8_size);
#else
                // trace
                tb_trace1_e("unicode type is not supported, please enable charset module config if you want to use it!");

                // only append it
                tb_string_chrcat(&data, ch);
#endif
            }
            // append escaped character
            else tb_string_chrcat(&data, ch);
        }
        // append character
        else tb_string_chrcat(&data, ch);
    }

    // init string
    tb_object_ref_t string = tb_oc_string_init_from_cstr(tb_string_cstr(&data));

    // trace
    tb_trace_d("string: %s", tb_string_cstr(&data));

    // exit data
    tb_string_exit(&data);

    // ok?
    return string;
}
static tb_object_ref_t tb_oc_json_reader_func_number(tb_oc_json_reader_t* reader, tb_char_t type)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // init data
    tb_static_string_t  data;
    tb_char_t           buff[256];
    if (!tb_static_string_init(&data, buff, 256)) return tb_null;

    // done
    tb_object_ref_t number = tb_null;
    do
    {
        // append character
        tb_static_string_chrcat(&data, type);

        // walk
        tb_bool_t bs = (type == '-')? tb_true : tb_false;
        tb_bool_t bf = (type == '.')? tb_true : tb_false;
        tb_bool_t failed = tb_false;
        while (!failed && tb_stream_left(reader->stream)) 
        {
            // need one character
            tb_byte_t* p = tb_null;
            if (!tb_stream_need(reader->stream, &p, 1) && p) 
            {
                failed = tb_true;
                break;
            }

            // the character
            tb_char_t ch = *p;

            // is float?
            if (!bf && ch == '.') bf = tb_true;
            else if (bf && ch == '.') 
            {
                failed = tb_true;
                break;
            }

            // append character
            if (tb_isdigit10(ch) || ch == '.' || ch == 'e' || ch == 'E' || ch == '-' || ch == '+') 
                tb_static_string_chrcat(&data, ch);
            else break;

            // skip it
            tb_stream_skip(reader->stream, 1);
        }

        // failed?
        tb_check_break(!failed);

        // check
        tb_assert_and_check_break(tb_static_string_size(&data));

        // trace
        tb_trace_d("number: %s", tb_static_string_cstr(&data));

        // init number 
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
        if (bf) number = tb_oc_number_init_from_float(tb_stof(tb_static_string_cstr(&data)));
#else
        if (bf) tb_trace_noimpl();
#endif
        else if (bs) 
        {
            tb_sint64_t value = tb_stoi64(tb_static_string_cstr(&data));
            tb_size_t   bytes = tb_object_need_bytes(-value);
            switch (bytes)
            {
            case 1: number = tb_oc_number_init_from_sint8((tb_sint8_t)value); break;
            case 2: number = tb_oc_number_init_from_sint16((tb_sint16_t)value); break;
            case 4: number = tb_oc_number_init_from_sint32((tb_sint32_t)value); break;
            case 8: number = tb_oc_number_init_from_sint64((tb_sint64_t)value); break;
            default: break;
            }
            
        }
        else 
        {
            tb_uint64_t value = tb_stou64(tb_static_string_cstr(&data));
            tb_size_t   bytes = tb_object_need_bytes(value);
            switch (bytes)
            {
            case 1: number = tb_oc_number_init_from_uint8((tb_uint8_t)value); break;
            case 2: number = tb_oc_number_init_from_uint16((tb_uint16_t)value); break;
            case 4: number = tb_oc_number_init_from_uint32((tb_uint32_t)value); break;
            case 8: number = tb_oc_number_init_from_uint64((tb_uint64_t)value); break;
            default: break;
            }
        }

    } while (0);

    // exit data
    tb_static_string_exit(&data);

    // ok?
    return number;
}
static tb_object_ref_t tb_oc_json_reader_func_boolean(tb_oc_json_reader_t* reader, tb_char_t type)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream, tb_null);

    // init data
    tb_static_string_t  data;
    tb_char_t           buff[256];
    if (!tb_static_string_init(&data, buff, 256)) return tb_null;

    // done 
    tb_object_ref_t boolean = tb_null;
    do
    {
        // append character
        tb_static_string_chrcat(&data, type);

        // walk
        tb_bool_t failed = tb_false;
        while (!failed && tb_stream_left(reader->stream)) 
        {
            // need one character
            tb_byte_t* p = tb_null;
            if (!tb_stream_need(reader->stream, &p, 1) && p)
            {
                failed = tb_true;
                break;
            }

            // the character
            tb_char_t ch = *p;

            // append character
            if (tb_isalpha(ch)) tb_static_string_chrcat(&data, ch);
            else break;

            // skip it
            tb_stream_skip(reader->stream, 1);
        }

        // failed?
        tb_check_break(!failed);

        // check
        tb_assert_and_check_break(tb_static_string_size(&data));

        // trace
        tb_trace_d("boolean: %s", tb_static_string_cstr(&data));

        // true?
        if (!tb_stricmp(tb_static_string_cstr(&data), "true")) boolean = tb_oc_boolean_init(tb_true);
        // false?
        else if (!tb_stricmp(tb_static_string_cstr(&data), "false")) boolean = tb_oc_boolean_init(tb_false);

    } while (0);

    // exit data
    tb_static_string_exit(&data);

    // ok?
    return boolean;
}
static tb_object_ref_t tb_oc_json_reader_func_dictionary(tb_oc_json_reader_t* reader, tb_char_t type)
{
    // check
    tb_assert_and_check_return_val(reader && reader->stream && type == '{', tb_null);

    // init key name
    tb_static_string_t  kname;
    tb_char_t           kdata[8192];
    if (!tb_static_string_init(&kname, kdata, 8192)) return tb_null;

    // init dictionary
    tb_object_ref_t dictionary = tb_oc_dictionary_init(0, tb_false);
    tb_assert_and_check_return_val(dictionary, tb_null);

    // walk
    tb_char_t ch;
    tb_bool_t ok = tb_true;
    tb_bool_t bkey = tb_false;
    tb_size_t bstr = 0;
    while (ok && tb_stream_left(reader->stream)) 
    {
        // read one character
        if (!tb_stream_bread_s8(reader->stream, (tb_sint8_t*)&ch)) break;

        // end?
        if (ch == '}') break;
        // no space? skip ','
        else if (!tb_isspace(ch) && ch != ',')
        {
            // no key?
            if (!bkey)
            {
                // is str?
                if (ch == '\"' || ch == '\'') bstr = !bstr;
                // is key end?
                else if (!bstr && ch == ':') bkey = tb_true;
                // append key
                else if (bstr) tb_static_string_chrcat(&kname, ch);
            }
            // key ok? read val
            else
            {
                // trace
                tb_trace_d("key: %s", tb_static_string_cstr(&kname));

                // the func
                tb_oc_json_reader_func_t func = tb_oc_json_reader_func(ch);
                tb_assert_and_check_break_state(func, ok, tb_false);

                // read val
                tb_object_ref_t val = func(reader, ch);
                tb_assert_and_check_break_state(val, ok, tb_false);

                // set key => val
                tb_oc_dictionary_insert(dictionary, tb_static_string_cstr(&kname), val);

                // reset key
                bstr = 0;
                bkey = tb_false;
                tb_static_string_clear(&kname);
            }
        }
    }

    // failed?
    if (!ok)
    {
        // exit it
        if (dictionary) tb_object_exit(dictionary);
        dictionary = tb_null;
    }

    // exit key name
    tb_static_string_exit(&kname);

    // ok?
    return dictionary;
}
static tb_object_ref_t tb_oc_json_reader_done(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // init reader
    tb_oc_json_reader_t reader = {0};
    reader.stream = stream;

    // skip spaces
    tb_char_t type = '\0';
    while (tb_stream_left(stream)) 
    {
        if (!tb_stream_bread_s8(stream, (tb_sint8_t*)&type)) break;
        if (!tb_isspace(type)) break;
    }

    // empty?
    tb_check_return_val(tb_stream_left(stream), tb_null);

    // the func
    tb_oc_json_reader_func_t func = tb_oc_json_reader_func(type);
    tb_assert_and_check_return_val(func, tb_null);

    // read it
    return func(&reader, type);
}
static tb_size_t tb_oc_json_reader_probe(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // need it
    tb_byte_t*  p = tb_null;
    if (!tb_stream_need(stream, &p, 5)) return 0;
    tb_assert_and_check_return_val(p, 0);

    // probe it
    tb_size_t   s = 10;
    tb_byte_t*  e = p + 5;
    for (; p < e && *p; p++)
    {
        if (*p == '{' || *p == '[') 
        {
            s = 50;
            break;
        }
        else if (!tb_isgraph(*p)) 
        {
            s = 0;
            break;
        }
    }

    // ok?
    return s;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_oc_reader_t* tb_oc_json_reader()
{
    // the reader
    static tb_oc_reader_t s_reader = {0};

    // init reader
    s_reader.read   = tb_oc_json_reader_done;
    s_reader.probe  = tb_oc_json_reader_probe;

    // init hooker
    s_reader.hooker = tb_hash_map_init(TB_HASH_MAP_BUCKET_SIZE_MICRO, tb_element_uint8(), tb_element_ptr(tb_null, tb_null));
    tb_assert_and_check_return_val(s_reader.hooker, tb_null);

    // hook reader 
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'n', tb_oc_json_reader_func_null);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'N', tb_oc_json_reader_func_null);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'[', tb_oc_json_reader_func_array);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'\'', tb_oc_json_reader_func_string);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'\"', tb_oc_json_reader_func_string);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'0', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'1', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'2', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'3', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'4', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'5', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'6', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'7', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'8', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'9', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'.', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'-', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'+', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'e', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'E', tb_oc_json_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'t', tb_oc_json_reader_func_boolean);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'T', tb_oc_json_reader_func_boolean);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'f', tb_oc_json_reader_func_boolean);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'F', tb_oc_json_reader_func_boolean);
    tb_hash_map_insert(s_reader.hooker, (tb_pointer_t)'{', tb_oc_json_reader_func_dictionary);

    // ok
    return &s_reader;
}
tb_bool_t tb_oc_json_reader_hook(tb_char_t type, tb_oc_json_reader_func_t func)
{
    // check
    tb_assert_and_check_return_val(type && func, tb_false);

    // the reader
    tb_oc_reader_t* reader = tb_oc_reader_get(TB_OBJECT_FORMAT_JSON);
    tb_assert_and_check_return_val(reader && reader->hooker, tb_false);

    // hook it
    tb_hash_map_insert(reader->hooker, (tb_pointer_t)(tb_size_t)type, func);

    // ok
    return tb_true;
}
tb_oc_json_reader_func_t tb_oc_json_reader_func(tb_char_t type)
{
    // check
    tb_assert_and_check_return_val(type, tb_null);

    // the reader
    tb_oc_reader_t* reader = tb_oc_reader_get(TB_OBJECT_FORMAT_JSON);
    tb_assert_and_check_return_val(reader && reader->hooker, tb_null);
 
    // the func
    return (tb_oc_json_reader_func_t)tb_hash_map_get(reader->hooker, (tb_pointer_t)(tb_size_t)type);
}

