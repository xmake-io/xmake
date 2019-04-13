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
 * @file        bplist.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_IMPL_WRITER_BPLIST_H
#define TB_OBJECT_IMPL_WRITER_BPLIST_H

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

/// the object bplist writer type
typedef struct __tb_oc_bplist_writer_t
{
    /// the stream
    tb_stream_ref_t              stream;

}tb_oc_bplist_writer_t;

/// the bplist writer func type
typedef tb_bool_t               (*tb_oc_bplist_writer_func_t)(tb_oc_bplist_writer_t* writer, tb_object_ref_t object, tb_size_t item_size);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the bplist object writer
 *
 * @return                      the bplist object writer
 */
tb_oc_writer_t*                 tb_oc_bplist_writer(tb_noarg_t);

/*! hook the bplist writer
 *
 * @param type                  the object type 
 * @param func                  the writer func
 *
 * @return                      tb_true or tb_false
 */
tb_bool_t                       tb_oc_bplist_writer_hook(tb_size_t type, tb_oc_bplist_writer_func_t func);

/*! the bplist writer func
 *
 * @param type                  the object type 
 *
 * @return                      the object writer func
 */
tb_oc_bplist_writer_func_t  tb_oc_bplist_writer_func(tb_size_t type);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

