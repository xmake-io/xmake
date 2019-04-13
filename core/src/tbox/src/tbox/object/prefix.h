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
    tb_uint8_t                  flag;

    /// the object type
    tb_uint16_t                 type;

    /// the object reference count
    tb_size_t                   refn;

    /// the object private data
    tb_cpointer_t               priv;

    /// the copy func
    struct __tb_object_t*    (*copy)(struct __tb_object_t* object);

    /// the clear func
    tb_void_t                   (*clear)(struct __tb_object_t* object);

    /// the exit func
    tb_void_t                   (*exit)(struct __tb_object_t* object);

}tb_object_t, *tb_object_ref_t;

#endif
