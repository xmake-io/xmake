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
 * @file        filter.c
 * @ingroup     stream
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "filter"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "filter.h"
#include "impl/filter.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_filter_open(tb_filter_ref_t self)
{
    // check
    tb_filter_t* filter = (tb_filter_t*)self;
    tb_assert_and_check_return_val(filter, tb_false);

    // opened?
    tb_check_return_val(!filter->bopened, tb_true);

    // open it
    filter->bopened = filter->open? filter->open(filter) : tb_true;

    // ok?
    return filter->bopened;
}
tb_void_t tb_filter_clos(tb_filter_ref_t self)
{
    // check
    tb_filter_t* filter = (tb_filter_t*)self;
    tb_assert_and_check_return(filter);

    // opened?
    tb_check_return(filter->bopened);

    // clos it
    if (filter->clos) filter->clos(filter);

    // clear eof
    filter->beof = tb_false;
    
    // clear limit
    filter->limit = -1;
    
    // clear offset
    filter->offset = 0;
    
    // exit idata
    tb_buffer_clear(&filter->idata);

    // exit odata
    tb_queue_buffer_clear(&filter->odata);

    // closed
    filter->bopened = tb_false;
}
tb_void_t tb_filter_exit(tb_filter_ref_t self)
{
    // check
    tb_filter_t* filter = (tb_filter_t*)self;
    tb_assert_and_check_return(filter);
    
    // exit it
    if (filter->exit) filter->exit(filter);

    // exit idata
    tb_buffer_exit(&filter->idata);

    // exit odata
    tb_queue_buffer_exit(&filter->odata);

    // free it
    tb_free(filter);
}
tb_bool_t tb_filter_ctrl(tb_filter_ref_t self, tb_size_t ctrl, ...)
{
    // check
    tb_filter_t* filter = (tb_filter_t*)self;
    tb_assert_and_check_return_val(filter && filter->ctrl && ctrl, tb_false);

    // init args
    tb_va_list_t args;
    tb_va_start(args, ctrl);

    // ctrl it
    tb_bool_t ok = filter->ctrl(filter, ctrl, args);

    // exit args
    tb_va_end(args);

    // ok?
    return ok;
}
tb_long_t tb_filter_spak(tb_filter_ref_t self, tb_byte_t const* data, tb_size_t size, tb_byte_t const** pdata, tb_size_t need, tb_long_t sync)
{
    // check
    tb_filter_t* filter = (tb_filter_t*)self;
    tb_assert_and_check_return_val(filter && filter->spak && pdata, -1);

    // init odata
    *pdata = tb_null;

    // save the input offset
    filter->offset += size;

    // eof?
    if (filter->limit >= 0 && filter->offset == filter->limit)
        filter->beof = tb_true;

    // eof? sync it
    if (filter->beof) sync = -1;

    // the idata
    tb_byte_t const*    idata = tb_buffer_data(&filter->idata);
    tb_size_t           isize = tb_buffer_size(&filter->idata);
    if (data && size)
    {
        // append data to cache if have the cache data
        if (idata && isize) 
        {
            // trace
            tb_trace_d("[%p]: append idata: %lu", self, size);

            // append data
            idata = tb_buffer_memncat(&filter->idata, data, size);
            isize = tb_buffer_size(&filter->idata);
        }
        // using the data directly if no cache data
        else
        {
            // trace
            tb_trace_d("[%p]: using idata directly: %lu", self, size);

            // using it directly
            idata = data;
            isize = size;
        }
    }
    // sync data if null
    else
    {
        // check sync
        tb_assert_and_check_return_val(sync, 0);
    }

    // the need
    if (!need) need = tb_max(size, tb_queue_buffer_maxn(&filter->odata));
    tb_assert_and_check_return_val(need, -1);

    // init pull
    tb_size_t   omaxn = 0;
    tb_byte_t*  odata = tb_queue_buffer_pull_init(&filter->odata, &omaxn);
    if (odata)
    {
        // the osize
        tb_long_t osize = omaxn >= need? need : 0;

        // exit pull
        if (odata) tb_queue_buffer_pull_exit(&filter->odata, osize > 0? osize : 0);

        // enough? 
        if (osize > 0)
        {
            // append to the cache if idata is not belong to the cache
            if (size && idata == data) tb_buffer_memncat(&filter->idata, data, size);

            // return it directly 
            *pdata = odata;
            return osize;
        }
    }

    // grow odata maxn if not enough
    if (need > tb_queue_buffer_maxn(&filter->odata))
        tb_queue_buffer_resize(&filter->odata, need);

    // the odata
    omaxn = 0;
    odata = tb_queue_buffer_push_init(&filter->odata, &omaxn);
    tb_assert_and_check_return_val(odata && omaxn, -1);

    // init stream
    tb_static_stream_t istream = {0};
    tb_static_stream_t ostream = {0};
    if (idata && isize) 
    {
        // @note istream maybe null for sync the end data
        if (!tb_static_stream_init(&istream, (tb_byte_t*)idata, isize)) return -1;
    }
    if (!tb_static_stream_init(&ostream, (tb_byte_t*)odata, omaxn)) return -1;

    // trace
    tb_trace_d("[%p]: spak: ileft: %lu, oleft: %lu, offset: %llu, limit: %lld, beof: %d: ..", self, tb_buffer_size(&filter->idata), tb_queue_buffer_size(&filter->odata), filter->offset, filter->limit, filter->beof);

    // spak data
    tb_long_t osize = filter->spak(filter, &istream, &ostream, sync);

    // eof?
    if (osize < 0) filter->beof = tb_true;

    // no data and eof?
    if (!osize && !tb_static_stream_left(&istream) && filter->beof) osize = -1;

    // eof? sync it
    if (filter->beof) sync = -1;

    // exit odata
    tb_queue_buffer_push_exit(&filter->odata, osize > 0? osize : 0);

    // have the left idata? 
    tb_size_t left = tb_static_stream_left(&istream);
    if (left) 
    {
        // move to the cache head if idata is belong to the cache
        if (idata != data) 
        {
            // trace
            tb_trace_d("[%p]: move to the cache head: %lu", self, left);

            tb_buffer_memnmov(&filter->idata, tb_static_stream_offset(&istream), left);
        }
        // append to the cache if idata is not belong to the cache
        else 
        {
            // trace
            tb_trace_d("[%p]: append to the cache: %lu", self, left);

            tb_buffer_memncat(&filter->idata, tb_static_stream_pos(&istream), left);
        }
    }
    // clear the cache
    else tb_buffer_clear(&filter->idata);

    // init pull
    omaxn = 0;
    odata = tb_queue_buffer_pull_init(&filter->odata, &omaxn);

    // no sync? cache the output data
    if (!sync) osize = omaxn >= need? need : 0;
    // sync and has data? return it directly 
    else if (omaxn) osize = tb_min(omaxn, need);
    // sync, no data or end?
//  else osize = osize;

    // exit pull
    if (odata) tb_queue_buffer_pull_exit(&filter->odata, osize > 0? osize : 0);

    // return it if have the odata
    if (osize > 0) *pdata = odata;

    // trace
    tb_trace_d("[%p]: spak: ileft: %lu, oleft: %lu, offset: %llu, limit: %lld, beof: %d: %ld", self, tb_buffer_size(&filter->idata), tb_queue_buffer_size(&filter->odata), filter->offset, filter->limit, filter->beof, osize);

    // ok?
    return osize;
}
tb_bool_t tb_filter_push(tb_filter_ref_t self, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_filter_t* filter = (tb_filter_t*)self;
    tb_assert_and_check_return_val(filter && data && size, tb_false);

    // push data
    tb_bool_t ok = tb_buffer_memncat(&filter->idata, data, size)? tb_true : tb_false;

    // save the input offset
    if (ok) filter->offset += size;

    // ok?
    return ok;
}
tb_bool_t tb_filter_beof(tb_filter_ref_t self)
{
    // check
    tb_filter_t* filter = (tb_filter_t*)self;
    tb_assert_and_check_return_val(filter, tb_false);

    // is eof?
    return filter->beof;
}
tb_void_t tb_filter_limit(tb_filter_ref_t self, tb_hong_t limit)
{
    // check
    tb_filter_t* filter = (tb_filter_t*)self;
    tb_assert_and_check_return(filter);

    // limit the input size
    filter->limit = limit;
}
