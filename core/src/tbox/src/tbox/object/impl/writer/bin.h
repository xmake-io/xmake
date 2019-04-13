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
 * @file        bin.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_IMPL_WRITER_BIN_H
#define TB_OBJECT_IMPL_WRITER_BIN_H

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
typedef struct __tb_oc_bin_writer_t
{
    /// the stream
    tb_stream_ref_t             stream;

    /// the object hash
    tb_hash_map_ref_t           ohash;

    /// the string hash
    tb_hash_map_ref_t           shash;

    /// the object index
    tb_size_t                   index;

    /// the encoder data
    tb_byte_t*                  data;

    /// the encoder maxn
    tb_size_t                   maxn;

}tb_oc_bin_writer_t;

/// the bin writer func type
typedef tb_bool_t               (*tb_oc_bin_writer_func_t)(tb_oc_bin_writer_t* writer, tb_object_ref_t object);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the bin object writer
 *
 * @return                      the bin object writer
 */
tb_oc_writer_t*                 tb_oc_bin_writer(tb_noarg_t);

/*! hook the bin writer
 *
 * @param type                  the object type 
 * @param func                  the writer func
 *
 * @return                      tb_true or tb_false
 */
tb_bool_t                       tb_oc_bin_writer_hook(tb_size_t type, tb_oc_bin_writer_func_t func);

/*! the bin writer func
 *
 * @param type                  the object type 
 *
 * @return                      the object writer func
 */
tb_oc_bin_writer_func_t         tb_oc_bin_writer_func(tb_size_t type);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

