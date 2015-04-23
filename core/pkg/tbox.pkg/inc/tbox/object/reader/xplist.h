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
 * @file        xplist.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_READER_XPLIST_H
#define TB_OBJECT_READER_XPLIST_H

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

/// the xplist reader type
typedef struct __tb_object_xplist_reader_t
{
    /// the xplist reader
    tb_xml_reader_ref_t         reader;

}tb_object_xplist_reader_t;

/// the xplist reader func type
typedef tb_object_ref_t         (*tb_object_xplist_reader_func_t)(tb_object_xplist_reader_t* reader, tb_size_t event);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the xplist object reader
 *
 * @return                      the xplist object reader
 */
tb_object_reader_t*             tb_object_xplist_reader(tb_noarg_t);

/*! hook the xplist reader
 *
 * @param type                  the object type name
 * @param func                  the reader func
 *
 * @return                      tb_true or tb_false
 */
tb_bool_t                       tb_object_xplist_reader_hook(tb_char_t const* type, tb_object_xplist_reader_func_t func);

/*! the xplist reader func
 *
 * @param type                  the object type name
 *
 * @return                      the object reader func
 */
tb_object_xplist_reader_func_t  tb_object_xplist_reader_func(tb_char_t const* type);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

