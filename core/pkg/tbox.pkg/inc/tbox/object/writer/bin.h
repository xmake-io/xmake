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
#ifndef TB_OBJECT_WRITER_BIN_H
#define TB_OBJECT_WRITER_BIN_H

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

/// the object bin writer type
typedef struct __tb_object_bin_writer_t
{
    /// the stream
    tb_stream_ref_t              stream;

    /// the object hash
    tb_hash_ref_t                  ohash;

    /// the string hash
    tb_hash_ref_t                  shash;

    /// the object index
    tb_size_t                   index;

    /// the encoder data
    tb_byte_t*                  data;

    /// the encoder maxn
    tb_size_t                   maxn;

}tb_object_bin_writer_t;

/// the bin writer func type
typedef tb_bool_t               (*tb_object_bin_writer_func_t)(tb_object_bin_writer_t* writer, tb_object_ref_t object);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the bin object writer
 *
 * @return                      the bin object writer
 */
tb_object_writer_t*             tb_object_bin_writer(tb_noarg_t);

/*! hook the bin writer
 *
 * @param type                  the object type 
 * @param func                  the writer func
 *
 * @return                      tb_true or tb_false
 */
tb_bool_t                       tb_object_bin_writer_hook(tb_size_t type, tb_object_bin_writer_func_t func);

/*! the bin writer func
 *
 * @param type                  the object type 
 *
 * @return                      the object writer func
 */
tb_object_bin_writer_func_t     tb_object_bin_writer_func(tb_size_t type);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

