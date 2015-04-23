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
 * @file        json.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_WRITER_JSON_H
#define TB_OBJECT_WRITER_JSON_H

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

/// the object json writer type
typedef struct __tb_object_json_writer_t
{
    /// the stream
    tb_stream_ref_t              stream;

    /// is deflate?
    tb_bool_t                   deflate;

}tb_object_json_writer_t;

/// the json writer func type
typedef tb_bool_t               (*tb_object_json_writer_func_t)(tb_object_json_writer_t* writer, tb_object_ref_t object, tb_size_t level);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the json object writer
 *
 * @return                      the json object writer
 */
tb_object_writer_t*             tb_object_json_writer(tb_noarg_t);

/*! hook the json writer
 *
 * @param type                  the object type 
 * @param func                  the writer func
 *
 * @return                      tb_true or tb_false
 */
tb_bool_t                       tb_object_json_writer_hook(tb_size_t type, tb_object_json_writer_func_t func);

/*! the json writer func
 *
 * @param type                  the object type 
 *
 * @return                      the object writer func
 */
tb_object_json_writer_func_t    tb_object_json_writer_func(tb_size_t type);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

