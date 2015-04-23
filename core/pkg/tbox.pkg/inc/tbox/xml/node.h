/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        node.h
 * @ingroup     xml
 *
 */
#ifndef TB_XML_NODE_H
#define TB_XML_NODE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the xml node type
 *
 * @note see http://www.w3.org/TR/REC-DOM-Level-1/
 *
 */
typedef enum __tb_xml_node_type_t
{
    TB_XML_NODE_TYPE_NONE                   = 0
,   TB_XML_NODE_TYPE_ELEMENT                = 1
,   TB_XML_NODE_TYPE_ATTRIBUTE              = 2
,   TB_XML_NODE_TYPE_TEXT                   = 3
,   TB_XML_NODE_TYPE_CDATA                  = 4
,   TB_XML_NODE_TYPE_ENTITY_REFERENCE       = 5
,   TB_XML_NODE_TYPE_ENTITY                 = 6
,   TB_XML_NODE_TYPE_PROCESSING_INSTRUCTION = 7
,   TB_XML_NODE_TYPE_COMMENT                = 8
,   TB_XML_NODE_TYPE_DOCUMENT               = 9
,   TB_XML_NODE_TYPE_DOCUMENT_TYPE          = 10
,   TB_XML_NODE_TYPE_DOCUMENT_FRAGMENT      = 11
,   TB_XML_NODE_TYPE_NOTATION               = 12

}tb_xml_node_type_t;

/// the xml node 
typedef struct __tb_xml_node_t
{
    /// the node type
    tb_size_t                   type;

    /// the node name
    tb_string_t                 name;

    /// the node data
    tb_string_t                 data;

    /// the next
    struct __tb_xml_node_t*     next;

    /// the childs head
    struct __tb_xml_node_t*     chead;

    /// the childs tail
    struct __tb_xml_node_t*     ctail;

    /// the childs size
    tb_size_t                   csize;

    /// the attributes head
    struct __tb_xml_node_t*     ahead;

    /// the attributes tail
    struct __tb_xml_node_t*     atail;

    /// the attributes size
    tb_size_t                   asize;

    /// the parent
    struct __tb_xml_node_t*     parent;

}tb_xml_node_t;

/// the xml element type
typedef struct __tb_xml_element_t
{
    /// the node base
    tb_xml_node_t               base;

}tb_xml_element_t;

/// the xml text type
typedef struct __tb_xml_text_t
{
    /// the node base
    tb_xml_node_t               base;

}tb_xml_text_t;

/// the xml cdata type
typedef struct __tb_xml_cdata_t
{
    /// the node base
    tb_xml_node_t               base;

}tb_xml_cdata_t;

/// the xml comment type
typedef struct __tb_xml_comment_t
{
    /// the node base
    tb_xml_node_t               base;

}tb_xml_comment_t;

/*! the xml attribute type
 *
 * <pre>
 * inherit node, 
 * but since they are not actually child nodes of the element they describe, 
 * the DOM does not consider them part of the document tree.
 * </pre>
 */
typedef struct __tb_xml_attribute_t
{
    /// the node base
    tb_xml_node_t               base;

}tb_xml_attribute_t;

/// the xml document type 
typedef struct __tb_xml_document_t
{
    /// the node base
    tb_xml_node_t               base;

    /// the version
    tb_string_t                 version;

    /// the charset 
    tb_string_t                 charset;

}tb_xml_document_t;

/// the xml document type type
typedef struct __tb_xml_document_type_t
{
    /// the node base
    tb_xml_node_t               base;

    /// the type 
    tb_string_t                 type;

}tb_xml_document_type_t;

/// the xml node ref type
typedef tb_xml_node_t*          tb_xml_node_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init element node
 *
 * @param name      the element name
 * @return          the element node
 */
tb_xml_node_ref_t   tb_xml_node_init_element(tb_char_t const* name);

/*! init text node 
 *
 * @param data      the element text
 * @return          the element node
 */
tb_xml_node_ref_t   tb_xml_node_init_text(tb_char_t const* data);

/*! init cdata node 
 *
 * @param cdata     the element cdata
 * @return          the element node
 */
tb_xml_node_ref_t   tb_xml_node_init_cdata(tb_char_t const* cdata);

/*! init comment node 
 *
 * @param comment   the element comment
 * @return          the element node
 */
tb_xml_node_ref_t   tb_xml_node_init_comment(tb_char_t const* comment);

/*! init attribute node 
 *
 * @param name      the attribute name
 * @param data      the attribute data
 * @return          the element node
 */
tb_xml_node_ref_t   tb_xml_node_init_attribute(tb_char_t const* name, tb_char_t const* data);

/*! init document node 
 *
 * @param version   the xml version
 * @param encoding  the xml encoding
 * @return          the element node
 */
tb_xml_node_ref_t   tb_xml_node_init_document(tb_char_t const* version, tb_char_t const* encoding);

/*! init document type node 
 *
 * @param type      the document type
 * @return          the element node
 */
tb_xml_node_ref_t   tb_xml_node_init_document_type(tb_char_t const* type);

/*! exit the xml node 
 *
 * @param node      the element node
 */
tb_void_t           tb_xml_node_exit(tb_xml_node_ref_t node);

/*! goto node by the gived path
 *
 * @param node      the root node
 * @return          the goto node
 */
tb_xml_node_ref_t   tb_xml_node_goto(tb_xml_node_ref_t node, tb_char_t const* path);

/*! the xml childs head node
 *
 * @param node      the xml node
 * @return          the xml childs head node
 */
tb_xml_node_ref_t   tb_xml_node_chead(tb_xml_node_ref_t node);

/*! the xml childs count
 *
 * @param node      the xml node
 * @return          the xml childs count
 */
tb_size_t           tb_xml_node_csize(tb_xml_node_ref_t node);

/*! the xml attributes head node
 *
 * @param node      the xml node
 * @return          the xml attributes head node
 */
tb_xml_node_ref_t   tb_xml_node_ahead(tb_xml_node_ref_t node);

/*! the xml attributes count
 *
 * @param node      the xml node
 * @return          the xml attributes count
 */
tb_size_t           tb_xml_node_asize(tb_xml_node_ref_t node);

/*! insert to the next node
 *
 * @param node      the xml node
 * @param next      the xml next node
 */
tb_void_t           tb_xml_node_insert_next(tb_xml_node_ref_t node, tb_xml_node_ref_t next);

/*! remove the next node
 *
 * @param node      the xml node
 */
tb_void_t           tb_xml_node_remove_next(tb_xml_node_ref_t node);

/*! append the node to the childs head
 *
 * @param node      the xml node
 * @param child     the xml child node
 */
tb_void_t           tb_xml_node_append_chead(tb_xml_node_ref_t node, tb_xml_node_ref_t child);

/*! append the node to the childs tail
 *
 * @param node      the xml node
 * @param child     the xml child node
 */
tb_void_t           tb_xml_node_append_ctail(tb_xml_node_ref_t node, tb_xml_node_ref_t child);

/*! remove the node from the childs head
 *
 * @param node      the xml node
 */
tb_void_t           tb_xml_node_remove_chead(tb_xml_node_ref_t node);

/*! remove the node from the childs tail
 *
 * @param node      the xml node
 */
tb_void_t           tb_xml_node_remove_ctail(tb_xml_node_ref_t node);

/*! append the node to the attributes head
 *
 * @param node      the xml node
 * @param attribute the xml attribute node
 */
tb_void_t           tb_xml_node_append_ahead(tb_xml_node_ref_t node, tb_xml_node_ref_t attribute);

/*! append the node to the attributes tail
 *
 * @param node      the xml node
 * @param attribute the xml attribute node
 */
tb_void_t           tb_xml_node_append_atail(tb_xml_node_ref_t node, tb_xml_node_ref_t attribute);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
