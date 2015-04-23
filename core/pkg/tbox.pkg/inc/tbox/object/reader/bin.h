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
 * @file        bin.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_READER_BIN_H
#define TB_OBJECT_READER_BIN_H

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

/// the bin reader type
typedef struct __tb_object_bin_reader_t
{
    /// the stream
    tb_stream_ref_t              stream;

    /// the object list
    tb_vector_ref_t                list;

}tb_object_bin_reader_t;

/// the bin reader func type
typedef tb_object_ref_t            (*tb_object_bin_reader_func_t)(tb_object_bin_reader_t* reader, tb_size_t type, tb_uint64_t size);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the bin object reader
 *
 * @return                      the bin object reader
 */
tb_object_reader_t*             tb_object_bin_reader(tb_noarg_t);

/*! hook the bin reader
 *
 * @param type                  the object type 
 * @param func                  the reader func
 *
 * @return                      tb_true or tb_false
 */
tb_bool_t                       tb_object_bin_reader_hook(tb_size_t type, tb_object_bin_reader_func_t func);

/*! the bin reader func
 *
 * @param type                  the object type 
 *
 * @return                      the object reader func
 */
tb_object_bin_reader_func_t     tb_object_bin_reader_func(tb_size_t type);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

