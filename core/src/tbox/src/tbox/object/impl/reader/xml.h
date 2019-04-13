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
 * @file        xml.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_IMPL_READER_XML_H
#define TB_OBJECT_IMPL_READER_XML_H

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

/// the xml reader type
typedef struct __tb_oc_xml_reader_t
{
    /// the xml reader
    tb_xml_reader_ref_t         reader;

}tb_oc_xml_reader_t;

/// the xml reader func type
typedef tb_object_ref_t         (*tb_oc_xml_reader_func_t)(tb_oc_xml_reader_t* reader, tb_size_t event);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the xml object reader
 *
 * @return                      the xml object reader
 */
tb_oc_reader_t*                 tb_oc_xml_reader(tb_noarg_t);

/*! hook the xml reader
 *
 * @param type                  the object type name
 * @param func                  the reader func
 *
 * @return                      tb_true or tb_false
 */
tb_bool_t                       tb_oc_xml_reader_hook(tb_char_t const* type, tb_oc_xml_reader_func_t func);

/*! the xml reader func
 *
 * @param type                  the object type name
 *
 * @return                      the object reader func
 */
tb_oc_xml_reader_func_t         tb_oc_xml_reader_func(tb_char_t const* type);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

