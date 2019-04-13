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
 * @file        filter.h
 *
 */
#ifndef TB_STREAM_IMPL_FILTER_H
#define TB_STREAM_IMPL_FILTER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../filter.h"
#include "../static_stream.h"
#include "../../memory/memory.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the filter type
typedef struct __tb_filter_t
{
    // the type
    tb_size_t           type;

    // the input is eof?
    tb_bool_t           beof;

    // is opened?
    tb_bool_t           bopened;

    // the input limit size 
    tb_hong_t           limit;
    
    // the input offset 
    tb_hize_t           offset;

    // the input data
    tb_buffer_t         idata;

    // the output data 
    tb_queue_buffer_t   odata;

    // the open
    tb_bool_t           (*open)(struct __tb_filter_t* filter);

    // the clos
    tb_void_t           (*clos)(struct __tb_filter_t* filter);

    // the spak
    tb_long_t           (*spak)(struct __tb_filter_t* filter, tb_static_stream_ref_t istream, tb_static_stream_ref_t ostream, tb_long_t sync);

    // the ctrl
    tb_bool_t           (*ctrl)(struct __tb_filter_t* filter, tb_size_t ctrl, tb_va_list_t args);

    // the exit
    tb_void_t           (*exit)(struct __tb_filter_t* filter);

}tb_filter_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
static __tb_inline__ tb_bool_t tb_filter_init(tb_filter_t* filter, tb_size_t type)
{
    // check
    tb_assert_and_check_return_val(filter, tb_false);
    
    // init type
    filter->type = type;

    // init the input eof
    filter->beof = tb_false;

    // init input limit size
    filter->limit = -1;

    // init the input offset
    filter->offset = 0;

    // init idata
    if (!tb_buffer_init(&filter->idata)) return tb_false;

    // init odata
    if (!tb_queue_buffer_init(&filter->odata, 8192)) return tb_false;

    // ok
    return tb_true;
}

#endif
