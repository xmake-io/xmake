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
 * @file        prefix.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_PREFIX_H
#define TB_OBJECT_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../xml/xml.h"
#include "../stream/stream.h"
#include "../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the object type enum
typedef enum __tb_object_type_e
{
    TB_OBJECT_TYPE_NONE         = 0
,   TB_OBJECT_TYPE_DATA         = 1
,   TB_OBJECT_TYPE_DATE         = 2
,   TB_OBJECT_TYPE_ARRAY        = 3
,   TB_OBJECT_TYPE_STRING       = 4
,   TB_OBJECT_TYPE_NUMBER       = 5
,   TB_OBJECT_TYPE_BOOLEAN      = 6
,   TB_OBJECT_TYPE_DICTIONARY   = 7
,   TB_OBJECT_TYPE_NULL         = 8
,   TB_OBJECT_TYPE_USER         = 9 //!< the user defined type, ...

}tb_object_type_e;

/// the object flag enum
typedef enum __tb_object_flag_e
{
    TB_OBJECT_FLAG_NONE         = 0
,   TB_OBJECT_FLAG_READONLY     = 1
,   TB_OBJECT_FLAG_SINGLETON    = 2

}tb_object_flag_e;

/// the object format enum
typedef enum __tb_object_format_e
{
    TB_OBJECT_FORMAT_NONE       = 0x0000    //!< none
,   TB_OBJECT_FORMAT_BIN        = 0x0001    //!< the tbox binary format
,   TB_OBJECT_FORMAT_BPLIST     = 0x0002    //!< the bplist format for apple
,   TB_OBJECT_FORMAT_XPLIST     = 0x0003    //!< the xplist format for apple
,   TB_OBJECT_FORMAT_XML        = 0x0004    //!< the xml format
,   TB_OBJECT_FORMAT_JSON       = 0x0005    //!< the json format
,   TB_OBJECT_FORMAT_MAXN       = 0x000f    //!< the format maxn
,   TB_OBJECT_FORMAT_DEFLATE    = 0x0100    //!< deflate?

}tb_object_format_e;

/// the object type
typedef struct __tb_object_t
{
    /// the object flag
    tb_uint8_t              flag;

    /// the object type
    tb_uint16_t             type;

    /// the object reference count
    tb_size_t               refn;

    /// the object private data
    tb_cpointer_t           priv;

    /// the copy func
    struct __tb_object_t*   (*copy)(struct __tb_object_t* object);

    /// the clear func
    tb_void_t               (*clear)(struct __tb_object_t* object);

    /// the exit func
    tb_void_t               (*exit)(struct __tb_object_t* object);

}tb_object_t;

/// the object ref type
typedef tb_object_t*        tb_object_ref_t;

/// the object reader type
typedef struct __tb_object_reader_t
{
    /// the hooker
    tb_hash_map_ref_t       hooker;

    /// probe format
    tb_size_t               (*probe)(tb_stream_ref_t stream);

    /// read it
    tb_object_ref_t         (*read)(tb_stream_ref_t stream);

}tb_object_reader_t;

/// the object writer type
typedef struct __tb_object_writer_t
{
    /// the hooker
    tb_hash_map_ref_t       hooker;

    /// writ it
    tb_long_t               (*writ)(tb_stream_ref_t stream, tb_object_ref_t object, tb_bool_t deflate);

}tb_object_writer_t;

#endif
