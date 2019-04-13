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
 * @file        cache.c
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "cache"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the cache filter type
typedef struct __tb_filter_cache_t
{
    // the filter base
    tb_filter_t          base;

}tb_filter_cache_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_filter_cache_t* tb_filter_cache_cast(tb_filter_t* filter)
{
    // check
    tb_assert_and_check_return_val(filter && filter->type == TB_FILTER_TYPE_CACHE, tb_null);
    return (tb_filter_cache_t*)filter;
}
static tb_long_t tb_filter_cache_spak(tb_filter_t* filter, tb_static_stream_ref_t istream, tb_static_stream_ref_t ostream, tb_long_t sync)
{
    // check
    tb_filter_cache_t* cfilter = tb_filter_cache_cast(filter);
    tb_assert_and_check_return_val(cfilter && istream && ostream, -1);
    tb_assert_and_check_return_val(tb_static_stream_valid(istream) && tb_static_stream_valid(ostream), -1);

    // the idata
    tb_byte_t const*    ip = tb_static_stream_pos(istream);
    tb_byte_t const*    ie = tb_static_stream_end(istream);

    // the odata
    tb_byte_t*          op = (tb_byte_t*)tb_static_stream_pos(ostream);
    tb_byte_t*          oe = (tb_byte_t*)tb_static_stream_end(ostream);
    tb_byte_t*          ob = op;

    // the need 
    tb_size_t           need = tb_min(ie - ip, oe - op);

    // copy data
    if (need) tb_memcpy(op, ip, need);
    ip += need;
    op += need;

    // update stream
    tb_static_stream_goto(istream, (tb_byte_t*)ip);
    tb_static_stream_goto(ostream, (tb_byte_t*)op);

    // no data and sync end? end
    if (sync < 0 && op == ob && !tb_static_stream_left(istream)) return -1;

    // ok
    return (op - ob);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_filter_ref_t tb_filter_init_from_cache(tb_size_t size)
{
    // done
    tb_bool_t                   ok = tb_false;
    tb_filter_cache_t*   filter = tb_null;
    do
    {
        // make filter
        filter = tb_malloc0_type(tb_filter_cache_t);
        tb_assert_and_check_break(filter);

        // init filter 
        if (!tb_filter_init((tb_filter_t*)filter, TB_FILTER_TYPE_CACHE)) break;
        filter->base.spak = tb_filter_cache_spak;

        // init the cache size
        if (size) tb_queue_buffer_resize(&filter->base.odata, size);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit filter
        tb_filter_exit((tb_filter_ref_t)filter);
        filter = tb_null;
    }

    // ok?
    return (tb_filter_ref_t)filter;
}

