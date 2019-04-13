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
 * @file        reader.c
 * @ingroup     xml
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                    "xml"
#define TB_TRACE_MODULE_DEBUG                   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "reader.h"
#include "../charset/charset.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifdef __tb_small__
#   define TB_XML_READER_ATTRIBUTES_MAXN        (64)
#else
#   define TB_XML_READER_ATTRIBUTES_MAXN        (128)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the xml reader impl type
typedef struct __tb_xml_reader_impl_t
{
    // the event
    tb_size_t               event;

    // the level
    tb_size_t               level;

    // is bowner of the input stream?
    tb_bool_t               bowner;
    
    // the input stream
    tb_stream_ref_t         istream;

    // the filter stream
    tb_stream_ref_t         fstream;

    // the reader stream
    tb_stream_ref_t         rstream;

    // the version
    tb_string_t             version;

    // the charset
    tb_string_t             charset;

    // the element
    tb_string_t             element;

    // the element name
    tb_string_t             element_name;

    // the text
    tb_string_t             text;

    // the attribute name
    tb_string_t             attribute_name;

    // the attribute data
    tb_string_t             attribute_data;

    // the attributes
    tb_xml_attribute_t      attributes[TB_XML_READER_ATTRIBUTES_MAXN];

}tb_xml_reader_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * parser implementation
 */
static tb_char_t const* tb_xml_reader_element_parse(tb_xml_reader_impl_t* reader)
{
    // clear element
    tb_string_clear(&reader->element);

    // parse element
    tb_char_t ch = '\0';
    tb_size_t in = 0;
    while (tb_stream_bread_s8(reader->rstream, (tb_sint8_t*)&ch))
    {
        // append element
        if (!in && ch == '<') in = 1;
        else if (in)
        {
            if (ch != '>') tb_string_chrcat(&reader->element, ch);
            else return tb_string_cstr(&reader->element);
        }
    }

    // failed
    tb_assertf(0, "invalid element: %s from %s", tb_string_cstr(&reader->element), tb_url_cstr(tb_stream_url(reader->istream)));
    return tb_null;
}
static tb_char_t const* tb_xml_reader_text_parse(tb_xml_reader_impl_t* reader)
{
    // clear text
    tb_string_clear(&reader->text);

    // parse text
    tb_char_t* pc = tb_null;
    while (tb_stream_need(reader->rstream, (tb_byte_t**)&pc, 1) && pc)
    {
        // is end? </ ..>
        if (pc[0] == '<') return tb_string_cstr(&reader->text);
        else
        {
            tb_string_chrcat(&reader->text, *pc);
            if (!tb_stream_skip(reader->rstream, 1)) return tb_null;
        }
    }
    return tb_null;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_xml_reader_ref_t tb_xml_reader_init()
{
    // init reader
    tb_xml_reader_impl_t* reader = tb_malloc0_type(tb_xml_reader_impl_t);
    tb_assert_and_check_return_val(reader, tb_null);

    // init string
    tb_string_init(&reader->text);
    tb_string_init(&reader->version);
    tb_string_init(&reader->charset);
    tb_string_init(&reader->element);
    tb_string_init(&reader->element_name);
    tb_string_init(&reader->attribute_name);
    tb_string_init(&reader->attribute_data);
    tb_string_cstrcpy(&reader->version, "2.0");
    tb_string_cstrcpy(&reader->charset, "utf-8");

    // init attributes
    tb_size_t i = 0;
    for (i = 0; i < TB_XML_READER_ATTRIBUTES_MAXN; i++)
    {
        tb_xml_node_ref_t node = (tb_xml_node_ref_t)(reader->attributes + i);
        tb_string_init(&node->name);
        tb_string_init(&node->data);
    }

    // ok
    return (tb_xml_reader_ref_t)reader;
}
tb_void_t tb_xml_reader_exit(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return(impl);

    // clos it first
    tb_xml_reader_clos(reader);

    // exit the filter stream
    if (impl->fstream) tb_stream_exit(impl->fstream);

    // exit text
    tb_string_exit(&impl->text);

    // exit version
    tb_string_exit(&impl->version);

    // exit charset
    tb_string_exit(&impl->charset);

    // exit element
    tb_string_exit(&impl->element);

    // exit element name
    tb_string_exit(&impl->element_name);

    // exit attribute name
    tb_string_exit(&impl->attribute_name);

    // exit attribute data
    tb_string_exit(&impl->attribute_data);

    // exit attributes
    tb_long_t i = 0;
    for (i = 0; i < TB_XML_READER_ATTRIBUTES_MAXN; i++)
    {
        tb_xml_node_ref_t node = (tb_xml_node_ref_t)(impl->attributes + i);
        tb_string_exit(&node->name);
        tb_string_exit(&node->data);
    }

    // free it
    tb_free(impl);
}
tb_bool_t tb_xml_reader_open(tb_xml_reader_ref_t reader, tb_stream_ref_t stream, tb_bool_t bowner)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl && stream, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // check
        tb_assert_and_check_break(!impl->rstream && !impl->istream);

        // init level
        impl->level = 0;

        // init owner
        impl->bowner = bowner;
        
        // init the input stream 
        impl->istream = stream;

        // init the reader stream
        impl->rstream = stream;

        // open the reader stream if be not opened
        if (!tb_stream_is_opened(impl->rstream) && !tb_stream_open(impl->rstream)) break;

        // clear text
        tb_string_clear(&impl->text);

        // clear element
        tb_string_clear(&impl->element);

        // clear name
        tb_string_clear(&impl->element_name);

        // clear attribute name
        tb_string_clear(&impl->attribute_name);

        // clear attribute data
        tb_string_clear(&impl->attribute_data);

        // clear attributes
        tb_long_t i = 0;
        for (i = 0; i < TB_XML_READER_ATTRIBUTES_MAXN; i++)
        {
            tb_xml_node_ref_t node = (tb_xml_node_ref_t)(impl->attributes + i);
            tb_string_clear(&node->name);
            tb_string_clear(&node->data);
        }

        // ok
        ok = tb_true;

    } while (0);

    // failed? close it
    if (!ok) tb_xml_reader_clos(reader);

    // ok?
    return ok;
}
tb_void_t tb_xml_reader_clos(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return(impl);

    // clos the reader stream
    if (impl->rstream) tb_stream_clos(impl->rstream);
    impl->rstream = tb_null;

    // exit the input stream
    if (impl->istream && impl->bowner) tb_stream_exit(impl->istream);
    impl->istream = tb_null;

    // clear level
    impl->level = 0;

    // clear owner
    impl->bowner = tb_false;

    // clear text
    tb_string_clear(&impl->text);

    // clear element
    tb_string_clear(&impl->element);

    // clear name
    tb_string_clear(&impl->element_name);

    // clear attribute name
    tb_string_clear(&impl->attribute_name);

    // clear attribute data
    tb_string_clear(&impl->attribute_data);

    // clear attributes
    tb_long_t i = 0;
    for (i = 0; i < TB_XML_READER_ATTRIBUTES_MAXN; i++)
    {
        tb_xml_node_ref_t node = (tb_xml_node_ref_t)(impl->attributes + i);
        tb_string_clear(&node->name);
        tb_string_clear(&node->data);
    }
}
tb_stream_ref_t tb_xml_reader_stream(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl, tb_null);

    return impl->rstream;
}
tb_size_t tb_xml_reader_level(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl, 0);

    return impl->level;
}
tb_size_t tb_xml_reader_next(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl && impl->rstream, TB_XML_READER_EVENT_NONE);

    // reset event
    impl->event = TB_XML_READER_EVENT_NONE;

    // next
    while (!impl->event)
    {
        // peek character
        tb_char_t* pc = tb_null;
        if (!tb_stream_need(impl->rstream, (tb_byte_t**)&pc, 1) || !pc) break;

        // is element?
        if (*pc == '<') 
        {
            // parse element: <...>
            tb_char_t const* element = tb_xml_reader_element_parse(impl);
            tb_assert_and_check_break(element);

            // is document begin: <?xml version="..." charset=".." ?>
            tb_size_t size = tb_string_size(&impl->element);
            if (size > 4 && !tb_strnicmp(element, "?xml", 4))
            {
                // update event
                impl->event = TB_XML_READER_EVENT_DOCUMENT;

                // update version & charset
                tb_xml_node_ref_t attr = (tb_xml_node_ref_t)tb_xml_reader_attributes(reader); 
                for (; attr; attr = attr->next)
                {
                    if (!tb_string_cstricmp(&attr->name, "version")) tb_string_strcpy(&impl->version, &attr->data);
                    if (!tb_string_cstricmp(&attr->name, "encoding")) tb_string_strcpy(&impl->charset, &attr->data);
                }

                // transform stream => utf-8
                if (tb_string_cstricmp(&impl->charset, "utf-8") && tb_string_cstricmp(&impl->charset, "utf8"))
                {
                    // charset
                    tb_size_t charset = TB_CHARSET_TYPE_UTF8;
                    if (!tb_string_cstricmp(&impl->charset, "gb2312") || !tb_string_cstricmp(&impl->charset, "gbk")) 
                        charset = TB_CHARSET_TYPE_GB2312;
                    else tb_trace_e("the charset: %s is not supported", tb_string_cstr(&impl->charset));

                    // init transform stream
                    if (charset != TB_CHARSET_TYPE_UTF8)
                    {
#ifdef TB_CONFIG_MODULE_HAVE_CHARSET
                        // init the filter stream
                        if (!impl->fstream) impl->fstream = tb_stream_init_filter_from_charset(impl->istream, charset, TB_CHARSET_TYPE_UTF8);
                        else
                        {
                            // ctrl stream
                            if (!tb_stream_ctrl(impl->fstream, TB_STREAM_CTRL_FLTR_SET_STREAM, impl->istream)) break;

                            // the filter
                            tb_filter_ref_t filter = tb_null;
                            if (!tb_stream_ctrl(impl->fstream, TB_STREAM_CTRL_FLTR_GET_FILTER, &filter)) break;
                            tb_assert_and_check_break(filter);

                            // ctrl filter
                            if (!tb_filter_ctrl(filter, TB_FILTER_CTRL_CHARSET_SET_FTYPE, charset)) break;
                        }

                        // open the filter stream
                        if (impl->fstream && tb_stream_open(impl->fstream))
                            impl->rstream = impl->fstream;
                        tb_string_cstrcpy(&impl->charset, "utf-8");
#else
                        // trace
                        tb_trace_e("unicode type is not supported, please enable charset module config if you want to use it!");
#endif
                    }
                }
            }
            // is document type: <!DOCTYPE ... >
            else if (size > 8 && !tb_strnicmp(element, "!DOCTYPE", 8))
            {
                // update event
                impl->event = TB_XML_READER_EVENT_DOCUMENT_TYPE;
            }
            // is element end: </name>
            else if (size > 1 && element[0] == '/')
            {
                // check
                tb_check_break(impl->level);

                // update event
                impl->event = TB_XML_READER_EVENT_ELEMENT_END;

                // leave
                impl->level--;
            }
            // is comment: <!-- text -->
            else if (size >= 3 && !tb_strncmp(element, "!--", 3))
            {
                // no comment end?
                if (element[size - 2] != '-' || element[size - 1] != '-')
                {
                    // patch '>'
                    tb_string_chrcat(&impl->element, '>');

                    // seek to comment end
                    tb_char_t ch = '\0';
                    tb_int_t n = 0;
                    while (tb_stream_bread_s8(impl->rstream, (tb_sint8_t*)&ch))
                    {
                        // -->
                        if (n == 2 && ch == '>') break;
                        else
                        {
                            // append it
                            tb_string_chrcat(&impl->element, ch);

                            if (ch == '-') n++;
                            else n = 0;
                        }
                    }

                    // update event
                    if (ch != '\0') impl->event = TB_XML_READER_EVENT_COMMENT;
                }
                else impl->event = TB_XML_READER_EVENT_COMMENT;
            }
            // is cdata: <![CDATA[ text ]]>
            else if (size >= 8 && !tb_strnicmp(element, "![CDATA[", 8))
            {
                if (element[size - 2] != ']' || element[size - 1] != ']')
                {
                    // patch '>'
                    tb_string_chrcat(&impl->element, '>');

                    // seek to cdata end
                    tb_char_t ch = '\0';
                    tb_int_t n = 0;
                    while (tb_stream_bread_s8(impl->rstream, (tb_sint8_t*)&ch))
                    {
                        // ]]>
                        if (n == 2 && ch == '>') break;
                        else
                        {
                            // append it
                            tb_string_chrcat(&impl->element, ch);

                            if (ch == ']') n++;
                            else n = 0;
                        }
                    }

                    // update event
                    if (ch != '\0') impl->event = TB_XML_READER_EVENT_CDATA;
                }
                else impl->event = TB_XML_READER_EVENT_CDATA;
            }
            // is empty element: <name/>
            else if (size > 1 && element[size - 1] == '/')
            {
                // update event
                impl->event = TB_XML_READER_EVENT_ELEMENT_EMPTY;
            }
            // is element begin: <name>
            else
            {
                // update event
                impl->event = TB_XML_READER_EVENT_ELEMENT_BEG;

                // enter
                impl->level++;
            }

            // trace
            tb_trace_d("<%s>", element);
        }
        // is text: <> text </>
        else if (*pc)
        {
            // parse text: <> ... <>
            tb_char_t const* text = tb_xml_reader_text_parse(impl);
            if (text && tb_string_cstrcmp(&impl->text, "\r\n") && tb_string_cstrcmp(&impl->text, "\n"))
                impl->event = TB_XML_READER_EVENT_TEXT;

            // trace
            tb_trace_d("%s", text);
        }
        else 
        {
            // skip the invalid character
            if (!tb_stream_skip(impl->rstream, 1)) break;
        }
    }

    // ok?
    return impl->event;
}
tb_bool_t tb_xml_reader_goto(tb_xml_reader_ref_t reader, tb_char_t const* path)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl && impl->rstream && path, tb_false);

    // trace
    tb_trace_d("goto: %s", path);

    // init level
    impl->level = 0;

    // seek to the stream head
    if (!tb_stream_seek(impl->rstream, 0)) return tb_false;

    // init
    tb_static_string_t  s;
    tb_char_t           data[8192];
    if (!tb_static_string_init(&s, data, 8192)) return tb_false;

    // save the current offset
    tb_hize_t save = tb_stream_offset(impl->rstream);

    // done
    tb_bool_t ok = tb_false;
    tb_bool_t leave = tb_false;
    tb_size_t event = TB_XML_READER_EVENT_NONE;
    while (!leave && !ok && (event = tb_xml_reader_next(reader)))
    {
        switch (event)
        {
        case TB_XML_READER_EVENT_ELEMENT_EMPTY: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader);
                tb_assert_and_check_break_state(name, leave, tb_true);

                // append 
                tb_size_t n = tb_static_string_size(&s);
                tb_static_string_chrcat(&s, '/');
                tb_static_string_cstrcat(&s, name);

                // ok?
                if (!tb_static_string_cstricmp(&s, path)) ok = tb_true;
                
                // trace
                tb_trace_d("path: %s", tb_static_string_cstr(&s));

                // remove 
                tb_static_string_strip(&s, n);

                // restore
                if (ok) if (!(ok = tb_stream_seek(impl->rstream, save))) leave = tb_true;
            }
            break;
        case TB_XML_READER_EVENT_ELEMENT_BEG: 
            {
                // name
                tb_char_t const* name = tb_xml_reader_element(reader);
                tb_assert_and_check_break_state(name, leave, tb_true);

                // append 
                tb_static_string_chrcat(&s, '/');
                tb_static_string_cstrcat(&s, name);

                // ok?
                if (!tb_static_string_cstricmp(&s, path)) ok = tb_true;

                // trace
                tb_trace_d("path: %s", tb_static_string_cstr(&s));

                // restore
                if (ok) if (!(ok = tb_stream_seek(impl->rstream, save))) leave = tb_true;
            }
            break;
        case TB_XML_READER_EVENT_ELEMENT_END: 
            {
                // remove 
                tb_long_t p = tb_static_string_strrchr(&s, 0, '/');
                if (p >= 0) tb_static_string_strip(&s, p);

                // ok?
                if (!tb_static_string_cstricmp(&s, path)) ok = tb_true;

                // trace
                tb_trace_d("path: %s", tb_static_string_cstr(&s));

                // restore
                if (ok) if (!(ok = tb_stream_seek(impl->rstream, save))) leave = tb_true;
            }
            break;
        default:
            break;
        }

        // save
        save = tb_stream_offset(impl->rstream);
    }

    // exit string
    tb_static_string_exit(&s);

    // clear level
    impl->level = 0;

    // failed? restore to the stream head
    if (!ok) tb_stream_seek(impl->rstream, 0);

    // ok?
    return ok;
}
tb_xml_node_ref_t tb_xml_reader_load(tb_xml_reader_ref_t reader)
{
    // check
    tb_assert_and_check_return_val(reader, tb_null);

    // done
    tb_bool_t           ok = tb_true;
    tb_xml_node_ref_t   node = tb_null;
    tb_size_t           event = TB_XML_READER_EVENT_NONE;
    while (ok && (event = tb_xml_reader_next(reader)))
    {
        // init document node
        if (!node)
        {
            node = tb_xml_node_init_document(tb_xml_reader_version(reader), tb_xml_reader_charset(reader));
            tb_assert_and_check_break_state(node && !node->parent, ok, tb_false);
        }

        switch (event)
        {
        case TB_XML_READER_EVENT_DOCUMENT:
            break;
        case TB_XML_READER_EVENT_DOCUMENT_TYPE:
            {
                // init
                tb_xml_node_ref_t doctype = tb_xml_node_init_document_type(tb_xml_reader_doctype(reader));
                tb_assert_and_check_break_state(doctype, ok, tb_false);
                
                // append
                tb_xml_node_append_ctail(node, doctype); 
                tb_assert_and_check_break_state(doctype->parent, ok, tb_false);
            }
            break;
        case TB_XML_READER_EVENT_ELEMENT_EMPTY: 
            {
                // init
                tb_xml_node_ref_t element = tb_xml_node_init_element(tb_xml_reader_element(reader));
                tb_assert_and_check_break_state(element, ok, tb_false);
                
                // attributes
                tb_xml_node_ref_t attr = tb_xml_reader_attributes(reader);
                for (; attr; attr = attr->next)
                    tb_xml_node_append_atail(element, tb_xml_node_init_attribute(tb_string_cstr(&attr->name), tb_string_cstr(&attr->data)));
                
                // append
                tb_xml_node_append_ctail(node, element); 
                tb_assert_and_check_break_state(element->parent, ok, tb_false);
            }
            break;
        case TB_XML_READER_EVENT_ELEMENT_BEG: 
            {
                // init
                tb_xml_node_ref_t element = tb_xml_node_init_element(tb_xml_reader_element(reader));
                tb_assert_and_check_break_state(element, ok, tb_false);

                // attributes
                tb_xml_node_ref_t attr = tb_xml_reader_attributes(reader);
                for (; attr; attr = attr->next)
                    tb_xml_node_append_atail(element, tb_xml_node_init_attribute(tb_string_cstr(&attr->name), tb_string_cstr(&attr->data)));
                
                // append
                tb_xml_node_append_ctail(node, element); 
                tb_assert_and_check_break_state(element->parent, ok, tb_false);

                // enter
                node = element;
            }
            break;
        case TB_XML_READER_EVENT_ELEMENT_END: 
            {
                // check
                tb_assert_and_check_break_state(node, ok, tb_false);

                // the parent node
                node = node->parent;
            }
            break;
        case TB_XML_READER_EVENT_TEXT: 
            {
                // init
                tb_xml_node_ref_t text = tb_xml_node_init_text(tb_xml_reader_text(reader));
                tb_assert_and_check_break_state(text, ok, tb_false);
                
                // append
                tb_xml_node_append_ctail(node, text); 
                tb_assert_and_check_break_state(text->parent, ok, tb_false);
            }
            break;
        case TB_XML_READER_EVENT_CDATA: 
            {
                // init
                tb_xml_node_ref_t cdata = tb_xml_node_init_cdata(tb_xml_reader_cdata(reader));
                tb_assert_and_check_break_state(cdata, ok, tb_false);
                
                // append
                tb_xml_node_append_ctail(node, cdata); 
                tb_assert_and_check_break_state(cdata->parent, ok, tb_false);

            }
            break;
        case TB_XML_READER_EVENT_COMMENT: 
            {
                // init
                tb_xml_node_ref_t comment = tb_xml_node_init_comment(tb_xml_reader_comment(reader));
                tb_assert_and_check_break_state(comment, ok, tb_false);
                
                // append
                tb_xml_node_append_ctail(node, comment); 
                tb_assert_and_check_break_state(comment->parent, ok, tb_false);
            }
            break;
        default:
            break;
        }
    }

    // failed?
    if (!ok)
    {
        // exit it
        if (node) tb_xml_node_exit(node);
        node = tb_null;
    }

    // ok
    return node;
}
tb_char_t const* tb_xml_reader_version(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl, tb_null);

    // text
    return tb_string_cstr(&impl->version);
}
tb_char_t const* tb_xml_reader_charset(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl, tb_null);

    // text
    return tb_string_cstr(&impl->charset);
}
tb_char_t const* tb_xml_reader_comment(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl && impl->event == TB_XML_READER_EVENT_COMMENT, tb_null);

    // init
    tb_char_t const*    p = tb_string_cstr(&impl->element);
    tb_size_t           n = tb_string_size(&impl->element);
    tb_assert_and_check_return_val(p && n >= 6, tb_null);

    // comment
    tb_string_cstrncpy(&impl->text, p + 3, n - 5);
    return tb_string_cstr(&impl->text);
}
tb_char_t const* tb_xml_reader_cdata(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl && impl->event == TB_XML_READER_EVENT_CDATA, tb_null);

    // init
    tb_char_t const*    p = tb_string_cstr(&impl->element);
    tb_size_t           n = tb_string_size(&impl->element);
    tb_assert_and_check_return_val(p && n >= 11, tb_null);

    // comment
    tb_string_cstrncpy(&impl->text, p + 8, n - 10);
    return tb_string_cstr(&impl->text);
}
tb_char_t const* tb_xml_reader_text(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl && impl->event == TB_XML_READER_EVENT_TEXT, tb_null);

    // text
    return tb_string_cstr(&impl->text);
}
tb_char_t const* tb_xml_reader_element(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl && ( impl->event == TB_XML_READER_EVENT_ELEMENT_BEG
                                            ||  impl->event == TB_XML_READER_EVENT_ELEMENT_END
                                            ||  impl->event == TB_XML_READER_EVENT_ELEMENT_EMPTY), tb_null);

    // init
    tb_char_t const* p = tb_null;
    tb_char_t const* b = tb_string_cstr(&impl->element);
    tb_char_t const* e = b + tb_string_size(&impl->element);
    tb_assert_and_check_return_val(b, tb_null);

    // </name> or <name ... />
    if (b < e && *b == '/') b++;
    for (p = b; p < e && *p && !tb_isspace(*p) && *p != '/'; p++) ;

    // ok?
    return p > b? tb_string_cstrncpy(&impl->element_name, b, p - b) : tb_null;
}
tb_char_t const* tb_xml_reader_doctype(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl && impl->event == TB_XML_READER_EVENT_DOCUMENT_TYPE, tb_null);

    // doctype
    tb_char_t const* p = tb_string_cstr(&impl->element);
    tb_assert_and_check_return_val(p, tb_null);

    // skip !DOCTYPE
    return (p + 9);
}
tb_xml_node_ref_t tb_xml_reader_attributes(tb_xml_reader_ref_t reader)
{
    // check
    tb_xml_reader_impl_t* impl = (tb_xml_reader_impl_t*)reader;
    tb_assert_and_check_return_val(impl && ( impl->event == TB_XML_READER_EVENT_DOCUMENT
                                            ||  impl->event == TB_XML_READER_EVENT_ELEMENT_BEG
                                            ||  impl->event == TB_XML_READER_EVENT_ELEMENT_END
                                            ||  impl->event == TB_XML_READER_EVENT_ELEMENT_EMPTY), tb_null);

    // init
    tb_char_t const* p = tb_string_cstr(&impl->element);
    tb_char_t const* e = p + tb_string_size(&impl->element);

    // skip name
    while (p < e && *p && !tb_isspace(*p)) p++;
    while (p < e && *p && tb_isspace(*p)) p++;

    // parse attributes
    tb_size_t n = 0;
    while (p < e)
    {
        // parse name
        tb_string_clear(&impl->attribute_name);
        for (; p < e && *p != '='; p++) if (!tb_isspace(*p)) tb_string_chrcat(&impl->attribute_name, *p);
        if (*p != '=') break;

        // parse data
        tb_string_clear(&impl->attribute_data);
        for (p++; p < e && (*p != '\'' && *p != '\"'); p++) ;
        if (*p != '\'' && *p != '\"') break;
        for (p++; p < e && (*p != '\'' && *p != '\"'); p++) tb_string_chrcat(&impl->attribute_data, *p);
        if (*p != '\'' && *p != '\"') break;
        p++;

        // append node
        if (tb_string_cstr(&impl->attribute_name) && tb_string_cstr(&impl->attribute_data))
        {
            // node
            tb_xml_node_ref_t prev = n > 0? (tb_xml_node_ref_t)&impl->attributes[n - 1] : tb_null;
            tb_xml_node_ref_t node = (tb_xml_node_ref_t)&impl->attributes[n];

            // init node
            tb_string_strcpy(&node->name, &impl->attribute_name);
            tb_string_strcpy(&node->data, &impl->attribute_data);

            // append node
            if (prev) prev->next = node;
            node->next = tb_null;

            // next
            n++;
        }
    }

    // ok?
    return n? (tb_xml_node_ref_t)&impl->attributes[0] : tb_null;
}
