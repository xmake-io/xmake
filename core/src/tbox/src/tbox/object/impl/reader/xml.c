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
 * @file        xml.c
 * @ingroup     object
 *
 */
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "oc_reader_xml"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "xml.h"
#include "reader.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the array grow
#ifdef __tb_small__
#   define TB_OC_XML_READER_ARRAY_GROW          (64)
#else
#   define TB_OC_XML_READER_ARRAY_GROW          (256)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_object_ref_t tb_oc_xml_reader_func_null(tb_oc_xml_reader_t* reader, tb_size_t event)
{
    // check
    tb_assert_and_check_return_val(reader && reader->reader && event, tb_null);

    // ok
    return (tb_object_ref_t)tb_oc_null_init();
}
static tb_object_ref_t tb_oc_xml_reader_func_date(tb_oc_xml_reader_t* reader, tb_size_t event)
{
    // check
    tb_assert_and_check_return_val(reader && reader->reader && event, tb_null);

    // empty?
    if (event == TB_XML_READER_EVENT_ELEMENT_EMPTY) 
        return tb_oc_date_init_from_time(0);

    // walk
    tb_object_ref_t date = tb_null;
    tb_bool_t       leave = tb_false;
    while (!leave && (event = tb_xml_reader_next(reader->reader)))
    {
        switch (event)
        {
        case TB_XML_READER_EVENT_ELEMENT_END: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader->reader);
                tb_assert_and_check_break_state(name, leave, tb_true);
                
                // is end?
                if (!tb_stricmp(name, "date"))
                {
                    // empty?
                    if (!date) date = tb_oc_date_init_from_time(0);

                    // leave it
                    leave = tb_true;
                }
            }
            break;
        case TB_XML_READER_EVENT_TEXT: 
            {
                // text
                tb_char_t const* text = tb_xml_reader_text(reader->reader);
                tb_assert_and_check_break_state(text, leave, tb_true);
                tb_trace_d("date: %s", text);

                // done date: %04ld-%02ld-%02ld %02ld:%02ld:%02ld
                tb_tm_t tm = {0};
                tb_char_t const* p = text;
                tb_char_t const* e = text + tb_strlen(text);

                // init year
                while (p < e && *p && !tb_isdigit(*p)) p++;
                tb_assert_and_check_break_state(p < e, leave, tb_true);
                tm.year = tb_atoi(p);

                // init month
                while (p < e && *p && tb_isdigit(*p)) p++;
                while (p < e && *p && !tb_isdigit(*p)) p++;
                tb_assert_and_check_break_state(p < e, leave, tb_true);
                tm.month = tb_atoi(p);
                
                // init day
                while (p < e && *p && tb_isdigit(*p)) p++;
                while (p < e && *p && !tb_isdigit(*p)) p++;
                tb_assert_and_check_break_state(p < e, leave, tb_true);
                tm.mday = tb_atoi(p);
                
                // init hour
                while (p < e && *p && tb_isdigit(*p)) p++;
                while (p < e && *p && !tb_isdigit(*p)) p++;
                tb_assert_and_check_break_state(p < e, leave, tb_true);
                tm.hour = tb_atoi(p);
                        
                // init minute
                while (p < e && *p && tb_isdigit(*p)) p++;
                while (p < e && *p && !tb_isdigit(*p)) p++;
                tb_assert_and_check_break_state(p < e, leave, tb_true);
                tm.minute = tb_atoi(p);
                
                // init second
                while (p < e && *p && tb_isdigit(*p)) p++;
                while (p < e && *p && !tb_isdigit(*p)) p++;
                tb_assert_and_check_break_state(p < e, leave, tb_true);
                tm.second = tb_atoi(p);
            
                // time
                tb_time_t time = tb_mktime(&tm);
                tb_assert_and_check_break_state(time >= 0, leave, tb_true);

                // date
                date = tb_oc_date_init_from_time(time);
            }
            break;
        default:
            break;
        }
    }

    // ok?
    return date;
}
static tb_object_ref_t tb_oc_xml_reader_func_data(tb_oc_xml_reader_t* reader, tb_size_t event)
{
    // check
    tb_assert_and_check_return_val(reader && reader->reader && event, tb_null);

    // empty?
    if (event == TB_XML_READER_EVENT_ELEMENT_EMPTY) 
        return tb_oc_data_init_from_data(tb_null, 0);

    // walk
    tb_object_ref_t data    = tb_null;
    tb_char_t*      base64  = tb_null;
    tb_bool_t       leave   = tb_false;
    while (!leave && (event = tb_xml_reader_next(reader->reader)))
    {
        switch (event)
        {
        case TB_XML_READER_EVENT_ELEMENT_END: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader->reader);
                tb_assert_and_check_break_state(name, leave, tb_true);
                
                // is end?
                if (!tb_stricmp(name, "data"))
                {
                    // empty?
                    if (!data) data = tb_oc_data_init_from_data(tb_null, 0);
                    
                    // leave it
                    leave = tb_true;
                }
            }
            break;
        case TB_XML_READER_EVENT_TEXT: 
            {
                // text
                tb_char_t const* text = tb_xml_reader_text(reader->reader);
                tb_assert_and_check_break_state(text, leave, tb_true);
                tb_trace_d("data: %s", text);

                // base64
                base64 = tb_strdup(text);
                tb_char_t* p = base64;
                tb_char_t* q = p;
                for (; *p; p++) if (!tb_isspace(*p)) *q++ = *p;
                *q = '\0';

                // decode base64 data
                tb_char_t const*    ib = base64;
                tb_size_t           in = tb_strlen(base64); 
                if (in)
                {
                    tb_size_t           on = in;
                    tb_byte_t*          ob = tb_malloc0_bytes(on);
                    tb_assert_and_check_break_state(ob && on, leave, tb_true);
                    on = tb_base64_decode(ib, in, ob, on);
                    tb_trace_d("base64: %u => %u", in, on);

                    // init data
                    data = tb_oc_data_init_from_data(ob, on); tb_free(ob);
                }
                else data = tb_oc_data_init_from_data(tb_null, 0);
                tb_assert_and_check_break_state(data, leave, tb_true);
            }
            break;
        default:
            break;
        }
    }

    // exit base64
    if (base64) tb_free(base64);
    base64 = tb_null;

    // ok?
    return data;
}
static tb_object_ref_t tb_oc_xml_reader_func_array(tb_oc_xml_reader_t* reader, tb_size_t event)
{
    // check
    tb_assert_and_check_return_val(reader && reader->reader && event, tb_null);

    // empty?
    if (event == TB_XML_READER_EVENT_ELEMENT_EMPTY) 
        return tb_oc_array_init(TB_OC_XML_READER_ARRAY_GROW, tb_false);

    // init array
    tb_object_ref_t array = tb_oc_array_init(TB_OC_XML_READER_ARRAY_GROW, tb_false);
    tb_assert_and_check_return_val(array, tb_null);

    // done
    tb_long_t ok = 0;
    while (!ok && (event = tb_xml_reader_next(reader->reader)))
    {
        switch (event)
        {
        case TB_XML_READER_EVENT_ELEMENT_BEG: 
        case TB_XML_READER_EVENT_ELEMENT_EMPTY: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader->reader);
                tb_assert_and_check_break_state(name, ok, -1);
                tb_trace_d("item: %s", name);

                // func
                tb_oc_xml_reader_func_t func = tb_oc_xml_reader_func(name);
                tb_assert_and_check_break_state(func, ok, -1);

                // read
                tb_object_ref_t object = func(reader, event);

                // append object
                if (object) tb_oc_array_append(array, object);
            }
            break;
        case TB_XML_READER_EVENT_ELEMENT_END: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader->reader);
                tb_assert_and_check_break_state(name, ok, -1);
                
                // is end?
                if (!tb_stricmp(name, "array")) ok = 1;
            }
            break;
        default:
            break;
        }
    }

    // failed?
    if (ok < 0)
    {
        // exit it
        if (array) tb_object_exit(array);
        array = tb_null;
    }

    // ok?
    return array;
}
static tb_object_ref_t tb_oc_xml_reader_func_string(tb_oc_xml_reader_t* reader, tb_size_t event)
{
    // check
    tb_assert_and_check_return_val(reader && reader->reader && event, tb_null);

    // empty?
    if (event == TB_XML_READER_EVENT_ELEMENT_EMPTY) 
        return tb_oc_string_init_from_cstr(tb_null);

    // done
    tb_bool_t       leave = tb_false;
    tb_object_ref_t string = tb_null;
    while (!leave && (event = tb_xml_reader_next(reader->reader)))
    {
        switch (event)
        {
        case TB_XML_READER_EVENT_ELEMENT_END: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader->reader);
                tb_assert_and_check_break_state(name, leave, tb_true);
                
                // is end?
                if (!tb_stricmp(name, "string"))
                {
                    // empty?
                    if (!string) string = tb_oc_string_init_from_cstr(tb_null);
                    
                    // leave it
                    leave = tb_true;
                }
            }
            break;
        case TB_XML_READER_EVENT_TEXT: 
            {
                // text
                tb_char_t const* text = tb_xml_reader_text(reader->reader);
                tb_assert_and_check_break_state(text, leave, tb_true);
                tb_trace_d("string: %s", text);
                
                // string
                string = tb_oc_string_init_from_cstr(text);
                tb_assert_and_check_break_state(string, leave, tb_true);
            }
            break;
        default:
            break;
        }
    }

    // ok?
    return string;
}
static tb_object_ref_t tb_oc_xml_reader_func_number(tb_oc_xml_reader_t* reader, tb_size_t event)
{
    // check
    tb_assert_and_check_return_val(reader && reader->reader && event, tb_null);

    // empty?
    if (event == TB_XML_READER_EVENT_ELEMENT_EMPTY) 
        return tb_oc_number_init_from_uint32(0);

    // done
    tb_bool_t       leave = tb_false;
    tb_object_ref_t number = tb_null;
    while (!leave && (event = tb_xml_reader_next(reader->reader)))
    {
        switch (event)
        {
        case TB_XML_READER_EVENT_ELEMENT_END: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader->reader);
                tb_assert_and_check_break_state(name, leave, tb_true);
                
                // is end?
                if (!tb_stricmp(name, "number")) leave = tb_true;
            }
            break;
        case TB_XML_READER_EVENT_TEXT: 
            {
                // text
                tb_char_t const* text = tb_xml_reader_text(reader->reader);
                tb_assert_and_check_break_state(text, leave, tb_true);
                tb_trace_d("number: %s", text);

                // has sign? is float?
                tb_size_t s = 0;
                tb_size_t f = 0;
                tb_char_t const* p = text;
                for (; *p; p++)
                {
                    if (!s && *p == '-') s = 1;
                    if (!f && *p == '.') f = 1;
                    if (s && f) break;
                }
                
                // number
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
                if (f) number = tb_oc_number_init_from_double(tb_atof(text));
#else
                if (f) tb_trace_noimpl();
#endif
                else number = s? tb_oc_number_init_from_sint64(tb_stoi64(text)) : tb_oc_number_init_from_uint64(tb_stou64(text));
                tb_assert_and_check_break_state(number, leave, tb_true);
            }
            break;
        default:
            break;
        }
    }

    // ok?
    return number;
}
static tb_object_ref_t tb_oc_xml_reader_func_boolean(tb_oc_xml_reader_t* reader, tb_size_t event)
{
    // check
    tb_assert_and_check_return_val(reader && reader->reader && event, tb_null);

    // name
    tb_char_t const* name = tb_xml_reader_element(reader->reader);
    tb_assert_and_check_return_val(name, tb_null);
    tb_trace_d("boolean: %s", name);

    // the boolean value
    tb_bool_t val = tb_false;
    if (!tb_stricmp(name, "true")) val = tb_true;
    else if (!tb_stricmp(name, "false")) val = tb_false;
    else return tb_null;

    // ok?
    return (tb_object_ref_t)tb_oc_boolean_init(val);
}
static tb_object_ref_t tb_oc_xml_reader_func_dictionary(tb_oc_xml_reader_t* reader, tb_size_t event)
{
    // check
    tb_assert_and_check_return_val(reader && reader->reader && event, tb_null);

    // empty?
    if (event == TB_XML_READER_EVENT_ELEMENT_EMPTY) 
        return tb_oc_dictionary_init(TB_OC_DICTIONARY_SIZE_MICRO, tb_false);

    // init key name
    tb_static_string_t  kname;
    tb_char_t       kdata[8192];
    if (!tb_static_string_init(&kname, kdata, 8192)) return tb_null;

    // init dictionary
    tb_object_ref_t dictionary = tb_oc_dictionary_init(0, tb_false);
    tb_assert_and_check_return_val(dictionary, tb_null);

    // walk
    tb_long_t   ok = 0;
    tb_bool_t   key = tb_false;
    while (!ok && (event = tb_xml_reader_next(reader->reader)))
    {
        switch (event)
        {
        case TB_XML_READER_EVENT_ELEMENT_BEG: 
        case TB_XML_READER_EVENT_ELEMENT_EMPTY: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader->reader);
                tb_assert_and_check_break_state(name, ok, -1);
                tb_trace_d("%s", name);

                // is key
                if (!tb_stricmp(name, "key")) key = tb_true;
                else if (!key)
                {
                    // func
                    tb_oc_xml_reader_func_t func = tb_oc_xml_reader_func(name);
                    tb_assert_and_check_break_state(func, ok, -1);

                    // read
                    tb_object_ref_t object = func(reader, event);
                    tb_trace_d("%s => %p", tb_static_string_cstr(&kname), object);
                    tb_assert_and_check_break_state(object, ok, -1);

                    // set key & value
                    if (tb_static_string_size(&kname) && dictionary) 
                        tb_oc_dictionary_insert(dictionary, tb_static_string_cstr(&kname), object);

                    // clear key name
                    tb_static_string_clear(&kname);
                }
            }
            break;
        case TB_XML_READER_EVENT_ELEMENT_END: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader->reader);
                tb_assert_and_check_break_state(name, ok, -1);
                
                // is end?
                if (!tb_stricmp(name, "dict")) ok = 1;
                else if (!tb_stricmp(name, "key")) key = tb_false;
            }
            break;
        case TB_XML_READER_EVENT_TEXT: 
            {
                if (key)
                {
                    // text
                    tb_char_t const* text = tb_xml_reader_text(reader->reader);
                    tb_assert_and_check_break_state(text, ok, -1);

                    // writ key name
                    tb_static_string_cstrcpy(&kname, text);
                }
            }
            break;
        default:
            break;
        }
    }

    // failed?
    if (ok < 0) 
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
static tb_object_ref_t tb_oc_xml_reader_done(tb_stream_ref_t stream)
{
    // init reader 
    tb_oc_xml_reader_t reader = {0};
    reader.reader = tb_xml_reader_init();
    tb_assert_and_check_return_val(reader.reader, tb_null);

    // open reader
    tb_object_ref_t object = tb_null;
    if (tb_xml_reader_open(reader.reader, stream, tb_false))
    {
        // done
        tb_bool_t       leave = tb_false;
        tb_size_t       event = TB_XML_READER_EVENT_NONE;
        while (!leave && !object && (event = tb_xml_reader_next(reader.reader)))
        {
            switch (event)
            {
            case TB_XML_READER_EVENT_ELEMENT_EMPTY: 
            case TB_XML_READER_EVENT_ELEMENT_BEG: 
                {
                    // name
                    tb_char_t const* name = tb_xml_reader_element(reader.reader);
                    tb_assert_and_check_break_state(name, leave, tb_true);

                    // func
                    tb_oc_xml_reader_func_t func = tb_oc_xml_reader_func(name);
                    tb_assert_and_check_break_state(func, leave, tb_true);

                    // read
                    object = func(&reader, event);
                }
                break;
            default:
                break;
            }
        }
    }

    // exit reader
    tb_xml_reader_exit(reader.reader);

    // ok?
    return object;
}
static tb_size_t tb_oc_xml_reader_probe(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, 0);

    // need it
    tb_byte_t* p = tb_null;
    if (!tb_stream_need(stream, &p, 5)) return 0;
    tb_assert_and_check_return_val(p, 0);

    // ok?
    return !tb_strnicmp((tb_char_t const*)p, "<?xml", 5)? 50 : 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_oc_reader_t* tb_oc_xml_reader()
{
    // the reader
    static tb_oc_reader_t s_reader = {0};

    // init reader
    s_reader.read   = tb_oc_xml_reader_done;
    s_reader.probe  = tb_oc_xml_reader_probe;

    // init hooker
    s_reader.hooker = tb_hash_map_init(TB_HASH_MAP_BUCKET_SIZE_MICRO, tb_element_str(tb_false), tb_element_ptr(tb_null, tb_null));
    tb_assert_and_check_return_val(s_reader.hooker, tb_null);

    // hook reader 
    tb_hash_map_insert(s_reader.hooker, "null", tb_oc_xml_reader_func_null);
    tb_hash_map_insert(s_reader.hooker, "date", tb_oc_xml_reader_func_date);
    tb_hash_map_insert(s_reader.hooker, "data", tb_oc_xml_reader_func_data);
    tb_hash_map_insert(s_reader.hooker, "array", tb_oc_xml_reader_func_array);
    tb_hash_map_insert(s_reader.hooker, "string", tb_oc_xml_reader_func_string);
    tb_hash_map_insert(s_reader.hooker, "number", tb_oc_xml_reader_func_number);
    tb_hash_map_insert(s_reader.hooker, "true", tb_oc_xml_reader_func_boolean);
    tb_hash_map_insert(s_reader.hooker, "false", tb_oc_xml_reader_func_boolean);
    tb_hash_map_insert(s_reader.hooker, "dict", tb_oc_xml_reader_func_dictionary);

    // ok
    return &s_reader;
}
tb_bool_t tb_oc_xml_reader_hook(tb_char_t const* type, tb_oc_xml_reader_func_t func)
{
    // check
    tb_assert_and_check_return_val(type && func, tb_false);

    // the reader
    tb_oc_reader_t* reader = tb_oc_reader_get(TB_OBJECT_FORMAT_XML);
    tb_assert_and_check_return_val(reader && reader->hooker, tb_false);

    // hook it
    tb_hash_map_insert(reader->hooker, type, func);

    // ok
    return tb_true;
}
tb_oc_xml_reader_func_t tb_oc_xml_reader_func(tb_char_t const* type)
{
    // check
    tb_assert_and_check_return_val(type, tb_null);

    // the reader
    tb_oc_reader_t* reader = tb_oc_reader_get(TB_OBJECT_FORMAT_XML);
    tb_assert_and_check_return_val(reader && reader->hooker, tb_null);

    // the func
    return (tb_oc_xml_reader_func_t)tb_hash_map_get(reader->hooker, type);
}

