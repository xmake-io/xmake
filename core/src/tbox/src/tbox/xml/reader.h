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
 * @file        reader.h
 * @ingroup     xml
 *
 */
#ifndef TB_XML_READER_H
#define TB_XML_READER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "node.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the xml reader event type for iterator
typedef enum __tb_xml_reader_event_t
{
    TB_XML_READER_EVENT_NONE                    = 0
,   TB_XML_READER_EVENT_DOCUMENT_TYPE           = 1
,   TB_XML_READER_EVENT_DOCUMENT                = 2
,   TB_XML_READER_EVENT_ELEMENT_BEG             = 3
,   TB_XML_READER_EVENT_ELEMENT_END             = 4
,   TB_XML_READER_EVENT_ELEMENT_EMPTY           = 5
,   TB_XML_READER_EVENT_COMMENT                 = 6
,   TB_XML_READER_EVENT_TEXT                    = 7
,   TB_XML_READER_EVENT_CDATA                   = 8

}tb_xml_reader_event_t;

/// the xml reader ref type
typedef __tb_typeref__(xml_reader);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the xml reader
 *
 * @return              the reader 
 */
tb_xml_reader_ref_t     tb_xml_reader_init(tb_noarg_t);

/*! exit the xml reader
 *
 * @param reader        the xml reader
 */
tb_void_t               tb_xml_reader_exit(tb_xml_reader_ref_t reader);

/*! open the xml reader
 *
 * @param reader        the xml reader
 * @param stream        the stream, will open it if be not opened
 * @param bowner        the xml reader is owner of the stream?
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_xml_reader_open(tb_xml_reader_ref_t reader, tb_stream_ref_t stream, tb_bool_t bowner);

/*! clos the xml reader
 *
 * @param reader        the xml reader
 */
tb_void_t               tb_xml_reader_clos(tb_xml_reader_ref_t reader);

/*! the next iterator for the xml reader
 *
 * @param reader        the xml reader
 * @return              the iterator event 
 *
 * @code
 *
    // init reader
    tb_xml_reader_ref_t reader = tb_xml_reader_init();
    if (reader)
    {
        // open reader
        if (tb_xml_reader_open(reader, tb_stream_init_from_url(argv[1]), tb_true))
        {
            // goto
            tb_bool_t ok = tb_true;
            if (argv[2]) ok = tb_xml_reader_goto(reader, argv[2]);

            // walk
            tb_size_t event = TB_XML_READER_EVENT_NONE;
            while (ok && (event = tb_xml_reader_next(reader)))
            {
                switch (event)
                {
                case TB_XML_READER_EVENT_DOCUMENT: 
                    {
                        tb_printf("<?xml version = \"%s\" encoding = \"%s\" ?>\n"
                            , tb_xml_reader_version(reader), tb_xml_reader_charset(reader));
                    }
                    break;
                case TB_XML_READER_EVENT_DOCUMENT_TYPE: 
                    {
                        tb_printf("<!DOCTYPE>\n");
                    }
                    break;
                case TB_XML_READER_EVENT_ELEMENT_EMPTY: 
                    {
                        tb_char_t const*    name = tb_xml_reader_element(reader);
                        tb_xml_node_ref_t   attr = tb_xml_reader_attributes(reader);
                        tb_size_t           t = tb_xml_reader_level(reader);
                        while (t--) tb_printf("\t");
                        if (!attr) tb_printf("<%s/>\n", name);
                        else
                        {
                            tb_printf("<%s", name);
                            for (; attr; attr = attr->next)
                                tb_printf(" %s = \"%s\"", tb_string_cstr(&attr->name), tb_string_cstr(&attr->data));
                            tb_printf("/>\n");
                        }
                    }
                    break;
                case TB_XML_READER_EVENT_ELEMENT_BEG: 
                    {
                        tb_char_t const*    name = tb_xml_reader_element(reader);
                        tb_xml_node_ref_t   attr = tb_xml_reader_attributes(reader);    
                        tb_size_t           t = tb_xml_reader_level(reader) - 1;
                        while (t--) tb_printf("\t");
                        if (!attr) tb_printf("<%s>\n", name);
                        else
                        {
                            tb_printf("<%s", name);
                            for (; attr; attr = attr->next)
                                tb_printf(" %s = \"%s\"", tb_string_cstr(&attr->name), tb_string_cstr(&attr->data));
                            tb_printf(">\n");
                        }
                    }
                    break;
                case TB_XML_READER_EVENT_ELEMENT_END: 
                    {
                        tb_size_t t = tb_xml_reader_level(reader);
                        while (t--) tb_printf("\t");
                        tb_printf("</%s>\n", tb_xml_reader_element(reader));
                    }
                    break;
                case TB_XML_READER_EVENT_TEXT: 
                    {
                        tb_size_t t = tb_xml_reader_level(reader);
                        while (t--) tb_printf("\t");
                        tb_printf("%s", tb_xml_reader_text(reader));
                        tb_printf("\n");
                    }
                    break;
                case TB_XML_READER_EVENT_CDATA: 
                    {
                        tb_size_t t = tb_xml_reader_level(reader);
                        while (t--) tb_printf("\t");
                        tb_printf("<![CDATA[%s]]>", tb_xml_reader_cdata(reader));
                        tb_printf("\n");
                    }
                    break;
                case TB_XML_READER_EVENT_COMMENT: 
                    {
                        tb_size_t t = tb_xml_reader_level(reader);
                        while (t--) tb_printf("\t");
                        tb_printf("<!--%s-->", tb_xml_reader_comment(reader));
                        tb_printf("\n");
                    }
                    break;
                default:
                    break;
                }
            }
        }

        // exit reader
        tb_xml_reader_exit(reader);
    }
    
 * @endcode
 */
tb_size_t               tb_xml_reader_next(tb_xml_reader_ref_t reader);

/*! the xml stream
 *
 * @param reader        the xml reader
 * @return              the xml stream
 */
tb_stream_ref_t         tb_xml_reader_stream(tb_xml_reader_ref_t reader);

/*! the xml level
 *
 * @param reader        the xml reader
 * @return              the xml level for tab spaces
 */
tb_size_t               tb_xml_reader_level(tb_xml_reader_ref_t reader);

/*! seek to the given node for xml, .e.g /root/node/item
 *
 * @param reader        the reader handle
 * @param path          the xml path
 * @return              tb_true or tb_false
 *
 * @note the stream will be reseted
 */
tb_bool_t               tb_xml_reader_goto(tb_xml_reader_ref_t reader, tb_char_t const* path);

/*! load the xml 
 *
 * @param reader        the xml reader
 * @return              the xml root node
 */
tb_xml_node_ref_t       tb_xml_reader_load(tb_xml_reader_ref_t reader);

/*! the xml version
 *
 * @param reader        the xml reader
 * @return              the xml version
 */
tb_char_t const*        tb_xml_reader_version(tb_xml_reader_ref_t reader);

/*! the xml charset
 *
 * @param reader        the xml reader
 * @return              the xml charset
 */
tb_char_t const*        tb_xml_reader_charset(tb_xml_reader_ref_t reader);

/*! the current xml element name
 *
 * @param reader        the xml reader
 * @return              the current xml element name
 */
tb_char_t const*        tb_xml_reader_element(tb_xml_reader_ref_t reader);

/*! the current xml node text
 *
 * @param reader        the xml reader
 * @return              the current xml node text
 */
tb_char_t const*        tb_xml_reader_text(tb_xml_reader_ref_t reader);

/*! the current xml node cdata
 *
 * @param reader        the xml reader
 * @return              the current xml node cdata
 */
tb_char_t const*        tb_xml_reader_cdata(tb_xml_reader_ref_t reader);

/*! the current xml node comment
 *
 * @param reader        the xml reader
 * @return              the current xml node comment
 */
tb_char_t const*        tb_xml_reader_comment(tb_xml_reader_ref_t reader);

/*! the xml document type
 *
 * @param reader        the xml reader
 * @return              the xml document type
 */
tb_char_t const*        tb_xml_reader_doctype(tb_xml_reader_ref_t reader);

/*! the current xml node attributes
 *
 * @param reader        the xml reader
 * @return              the current xml node attributes
 */
tb_xml_node_ref_t       tb_xml_reader_attributes(tb_xml_reader_ref_t reader);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
