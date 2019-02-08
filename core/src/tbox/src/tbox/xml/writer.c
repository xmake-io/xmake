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
 * @file        writer.c
 * @ingroup     xml
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "xml"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "writer.h"
#include "../charset/charset.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifdef __tb_small__
#   define TB_XML_WRITER_ELEMENTS_GROW      (32)
#else
#   define TB_XML_WRITER_ELEMENTS_GROW      (64)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the xml writer impl type
typedef struct __tb_xml_writer_impl_t
{
    // stream
    tb_stream_ref_t         stream;

    // is format?
    tb_bool_t               bformat;

    // is owner of the stream?
    tb_bool_t               bowner;
    
    // the elements stack
    tb_stack_ref_t          elements;

    // the attributes hash
    tb_hash_map_ref_t       attributes;

}tb_xml_writer_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_xml_writer_ref_t tb_xml_writer_init()
{
    // done
    tb_bool_t               ok = tb_false;
    tb_xml_writer_impl_t*   writer = tb_null;
    do
    {
        // make writer
        writer = tb_malloc0_type(tb_xml_writer_impl_t);
        tb_assert_and_check_break(writer);

        // init elements
        writer->elements    = tb_stack_init(TB_XML_WRITER_ELEMENTS_GROW, tb_element_str(tb_false));
        tb_assert_and_check_break(writer->elements);

        // init attributes
        writer->attributes  = tb_hash_map_init(TB_HASH_MAP_BUCKET_SIZE_MICRO, tb_element_str(tb_false), tb_element_str(tb_false));
        tb_assert_and_check_break(writer->attributes);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (writer) tb_xml_writer_exit((tb_xml_writer_ref_t)writer);
        writer = tb_null;
    }

    // ok?
    return (tb_xml_writer_ref_t)writer;
}
tb_void_t tb_xml_writer_exit(tb_xml_writer_ref_t writer)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl);

    // clos it first
    tb_xml_writer_clos(writer);

    // exit attributes
    if (impl->attributes) tb_hash_map_exit(impl->attributes);
    impl->attributes = tb_null;

    // exit elements
    if (impl->elements) tb_stack_exit(impl->elements);
    impl->elements = tb_null;

    // free it
    tb_free(impl);
}
tb_bool_t tb_xml_writer_open(tb_xml_writer_ref_t writer, tb_bool_t bformat, tb_stream_ref_t stream, tb_bool_t bowner)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return_val(impl && stream, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // check
        tb_assert_and_check_break(!impl->stream);

        // init format
        impl->bformat = bformat;

        // init owner
        impl->bowner = bowner;

        // init stream
        impl->stream = stream;

        // ctrl stream
        if (tb_stream_type(stream) == TB_STREAM_TYPE_FILE) 
        {
            // ctrl mode
            if (!tb_stream_ctrl(stream, TB_STREAM_CTRL_FILE_SET_MODE, TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC)) break;
        }

        // open the reader stream if be not opened
        if (!tb_stream_is_opened(impl->stream) && !tb_stream_open(impl->stream)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed? close it
    if (!ok) tb_xml_writer_clos(writer);

    // ok?
    return ok;
}
tb_void_t tb_xml_writer_clos(tb_xml_writer_ref_t writer)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl);

    // clos stream
    if (impl->stream) tb_stream_clos(impl->stream);
    
    // exit stream
    if (impl->stream && impl->bowner) tb_stream_exit(impl->stream);
    impl->stream = tb_null;

    // clear owner
    impl->bowner = tb_false;

    // clear format 
    impl->bformat = tb_false;

    // clear attributes
    if (impl->attributes) tb_hash_map_clear(impl->attributes);

    // clear elements
    if (impl->elements) tb_stack_clear(impl->elements);
}
tb_void_t tb_xml_writer_save(tb_xml_writer_ref_t writer, tb_xml_node_ref_t node)
{
    // check
    tb_assert_and_check_return(writer && node);

    // done
    switch (node->type)
    {
    case TB_XML_NODE_TYPE_DOCUMENT:
        {
            // document
            tb_xml_document_t* document = (tb_xml_document_t*)node;
            tb_xml_writer_document(writer, tb_string_cstr(&document->version), tb_string_cstr(&document->charset));

            // childs
            tb_xml_node_ref_t next = node->chead;
            while (next)
            {
                // save
                tb_xml_writer_save(writer, next);

                // next
                next = next->next;
            }
        }
        break;
    case TB_XML_NODE_TYPE_DOCUMENT_TYPE:
        {
            // document type
            tb_xml_document_type_t* doctype = (tb_xml_document_type_t*)node;
            tb_xml_writer_document_type(writer, tb_string_cstr(&doctype->type));
        }
        break;
    case TB_XML_NODE_TYPE_ELEMENT:
        {
            // attributes
            tb_xml_node_ref_t attr = node->ahead;
            while (attr)
            {
                // save
                tb_xml_writer_attributes_cstr(writer, tb_string_cstr(&attr->name), tb_string_cstr(&attr->data));

                // next
                attr = attr->next;
            }

            // childs
            tb_xml_node_ref_t next = node->chead;
            if (next)
            {
                // enter
                tb_xml_writer_element_enter(writer, tb_string_cstr(&node->name));

                // init
                while (next)
                {
                    // save
                    tb_xml_writer_save(writer, next);

                    // next
                    next = next->next;
                }

                // leave
                tb_xml_writer_element_leave(writer);
            }
            else tb_xml_writer_element_empty(writer, tb_string_cstr(&node->name));
        }
        break;
    case TB_XML_NODE_TYPE_COMMENT:
        tb_xml_writer_comment(writer, tb_string_cstr(&node->data));
        break;
    case TB_XML_NODE_TYPE_CDATA:
        tb_xml_writer_cdata(writer, tb_string_cstr(&node->data));
        break;
    case TB_XML_NODE_TYPE_TEXT:
        tb_xml_writer_text(writer, tb_string_cstr(&node->data));
        break;
    default:
        break;
    }
}
tb_void_t tb_xml_writer_document(tb_xml_writer_ref_t writer, tb_char_t const* version, tb_char_t const* charset)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->stream);

    tb_stream_printf(impl->stream, "<?xml version=\"%s\" encoding=\"%s\"?>", version? version : "2.0", charset? charset : "utf-8");
    if (impl->bformat) tb_stream_printf(impl->stream, "\n");
}
tb_void_t tb_xml_writer_document_type(tb_xml_writer_ref_t writer, tb_char_t const* type)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->stream);

    tb_stream_printf(impl->stream, "<!DOCTYPE %s>", type? type : "");
    if (impl->bformat) tb_stream_printf(impl->stream, "\n");
}
tb_void_t tb_xml_writer_cdata(tb_xml_writer_ref_t writer, tb_char_t const* data)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->stream && data);

    // writ tabs
    if (impl->bformat)
    {
        tb_size_t t = tb_stack_size(impl->elements);
        while (t--) tb_stream_printf(impl->stream, "\t");
    }

    tb_stream_printf(impl->stream, "<![CDATA[%s]]>", data);
    if (impl->bformat) tb_stream_printf(impl->stream, "\n");
}
tb_void_t tb_xml_writer_text(tb_xml_writer_ref_t writer, tb_char_t const* text)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->stream && text);

    // writ tabs
    if (impl->bformat)
    {
        tb_size_t t = tb_stack_size(impl->elements);
        while (t--) tb_stream_printf(impl->stream, "\t");
    }

    tb_stream_printf(impl->stream, "%s", text);
    if (impl->bformat) tb_stream_printf(impl->stream, "\n");
}
tb_void_t tb_xml_writer_comment(tb_xml_writer_ref_t writer, tb_char_t const* comment)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->stream && comment);

    // writ tabs
    if (impl->bformat)
    {
        tb_size_t t = tb_stack_size(impl->elements);
        while (t--) tb_stream_printf(impl->stream, "\t");
    }

    tb_stream_printf(impl->stream, "<!--%s-->", comment);
    if (impl->bformat) tb_stream_printf(impl->stream, "\n");
}
tb_void_t tb_xml_writer_element_empty(tb_xml_writer_ref_t writer, tb_char_t const* name)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->stream && impl->attributes && name);

    // writ tabs
    if (impl->bformat)
    {
        tb_size_t t = tb_stack_size(impl->elements);
        while (t--) tb_stream_printf(impl->stream, "\t");
    }

    // writ name
    tb_stream_printf(impl->stream, "<%s", name);

    // writ attributes
    if (tb_hash_map_size(impl->attributes))
    {
        tb_for_all (tb_hash_map_item_ref_t, item, impl->attributes)
        {
            if (item && item->name && item->data)
                tb_stream_printf(impl->stream, " %s=\"%s\"", item->name, item->data);
        }
        tb_hash_map_clear(impl->attributes);
    }

    // writ end
    tb_stream_printf(impl->stream, "/>");
    if (impl->bformat) tb_stream_printf(impl->stream, "\n");
}
tb_void_t tb_xml_writer_element_enter(tb_xml_writer_ref_t writer, tb_char_t const* name)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->stream && impl->elements && impl->attributes && name);

    // writ tabs
    if (impl->bformat)
    {
        tb_size_t t = tb_stack_size(impl->elements);
        while (t--) tb_stream_printf(impl->stream, "\t");
    }

    // writ name
    tb_stream_printf(impl->stream, "<%s", name);

    // writ attributes
    if (tb_hash_map_size(impl->attributes))
    {
        tb_for_all (tb_hash_map_item_ref_t, item, impl->attributes)
        {
            if (item && item->name && item->data)
                tb_stream_printf(impl->stream, " %s=\"%s\"", item->name, item->data);
        }
        tb_hash_map_clear(impl->attributes);
    }

    // writ end
    tb_stream_printf(impl->stream, ">");
    if (impl->bformat) tb_stream_printf(impl->stream, "\n");

    // put name
    tb_stack_put(impl->elements, name);
}
tb_void_t tb_xml_writer_element_leave(tb_xml_writer_ref_t writer)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->stream && impl->elements && impl->attributes);

    // writ tabs
    if (impl->bformat)
    {
        tb_size_t t = tb_stack_size(impl->elements);
        if (t) t--;
        while (t--) tb_stream_printf(impl->stream, "\t");
    }

    // writ name
    tb_char_t const* name = (tb_char_t const*)tb_stack_top(impl->elements);
    tb_assert_and_check_return(name);

    tb_stream_printf(impl->stream, "</%s>", name);
    if (impl->bformat) tb_stream_printf(impl->stream, "\n");

    // pop name
    tb_stack_pop(impl->elements);
}
tb_void_t tb_xml_writer_attributes_long(tb_xml_writer_ref_t writer, tb_char_t const* name, tb_long_t value)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->attributes && name);

    tb_char_t data[64] = {0};
    tb_snprintf(data, 64, "%ld", value);
    tb_hash_map_insert(impl->attributes, name, data);
}
tb_void_t tb_xml_writer_attributes_bool(tb_xml_writer_ref_t writer, tb_char_t const* name, tb_bool_t value)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->attributes && name);

    tb_char_t data[64] = {0};
    tb_snprintf(data, 64, "%s", value? "true" : "false");
    tb_hash_map_insert(impl->attributes, name, data);
}
tb_void_t tb_xml_writer_attributes_cstr(tb_xml_writer_ref_t writer, tb_char_t const* name, tb_char_t const* value)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->attributes && name && value);

    tb_hash_map_insert(impl->attributes, name, value);
}
tb_void_t tb_xml_writer_attributes_format(tb_xml_writer_ref_t writer, tb_char_t const* name, tb_char_t const* format, ...)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->attributes && name && format);

    tb_size_t size = 0;
    tb_char_t data[8192] = {0};
    tb_vsnprintf_format(data, 8192, format, &size);
    tb_hash_map_insert(impl->attributes, name, data);
}
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
tb_void_t tb_xml_writer_attributes_float(tb_xml_writer_ref_t writer, tb_char_t const* name, tb_float_t value)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->attributes && name);

    tb_char_t data[64] = {0};
    tb_snprintf(data, 64, "%f", value);
    tb_hash_map_insert(impl->attributes, name, data);
}
tb_void_t tb_xml_writer_attributes_double(tb_xml_writer_ref_t writer, tb_char_t const* name, tb_double_t value)
{
    // check
    tb_xml_writer_impl_t* impl = (tb_xml_writer_impl_t*)writer;
    tb_assert_and_check_return(impl && impl->attributes && name);

    tb_char_t data[64] = {0};
    tb_snprintf(data, 64, "%lf", value);
    tb_hash_map_insert(impl->attributes, name, data);
}
#endif

