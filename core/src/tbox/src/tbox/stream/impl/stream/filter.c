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
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the stream filter type
typedef struct __tb_stream_filter_t
{
    // the filter 
    tb_filter_ref_t         filter;

    // the filter is referenced? need not exit it
    tb_bool_t               bref;

    // is eof?
    tb_bool_t               beof;

    // is wait?
    tb_bool_t               wait;

    // the last
    tb_long_t               last;

    // the mode, none: 0, read: 1, writ: -1
    tb_long_t               mode;

    // the stream
    tb_stream_ref_t         stream;

}tb_stream_filter_t;
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_stream_filter_t* tb_stream_filter_cast(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream && tb_stream_type(stream) == TB_STREAM_TYPE_FLTR, tb_null);

    // ok?
    return (tb_stream_filter_t*)stream;
}
static tb_bool_t tb_stream_filter_open(tb_stream_ref_t stream)
{
    // check
    tb_stream_filter_t* stream_filter = tb_stream_filter_cast(stream);
    tb_assert_and_check_return_val(stream_filter && stream_filter->stream, tb_false);

    // clear mode
    stream_filter->mode = 0;

    // clear last
    stream_filter->last = 0;

    // clear wait
    stream_filter->wait = tb_false;

    // clear eof
    stream_filter->beof = tb_false;

    // open filter
    if (stream_filter->filter && !tb_filter_open(stream_filter->filter)) return tb_false;

    // ok
    return tb_stream_open(stream_filter->stream);
}
static tb_bool_t tb_stream_filter_clos(tb_stream_ref_t stream)
{
    // check
    tb_stream_filter_t* stream_filter = tb_stream_filter_cast(stream);
    tb_assert_and_check_return_val(stream_filter && stream_filter->stream, tb_false);
    
    // sync the end filter data
    if (stream_filter->filter && stream_filter->mode == -1)
    {
        // spak data
        tb_byte_t const*    data = tb_null;
        tb_long_t           size = tb_filter_spak(stream_filter->filter, tb_null, 0, &data, 0, -1);
        if (size > 0 && data)
        {
            // writ data
            if (!tb_stream_bwrit(stream_filter->stream, data, size)) return tb_false;
        }
    }

    // done
    tb_bool_t ok = tb_stream_clos(stream_filter->stream);

    // ok?
    if (ok) 
    {
        // clear mode
        stream_filter->mode = 0;

        // clear last
        stream_filter->last = 0;

        // clear wait
        stream_filter->wait = tb_false;

        // clear eof
        stream_filter->beof = tb_false;

        // close the filter
        if (stream_filter->filter) tb_filter_clos(stream_filter->filter);
    }

    // ok?
    return ok;
}
static tb_void_t tb_stream_filter_exit(tb_stream_ref_t stream)
{   
    // check
    tb_stream_filter_t* stream_filter = tb_stream_filter_cast(stream);
    tb_assert_and_check_return(stream_filter);

    // exit it
    if (!stream_filter->bref && stream_filter->filter) tb_filter_exit(stream_filter->filter);
    stream_filter->filter = tb_null;
    stream_filter->bref = tb_false;
}
static tb_void_t tb_stream_filter_kill(tb_stream_ref_t stream)
{   
    // check
    tb_stream_filter_t* stream_filter = tb_stream_filter_cast(stream);
    tb_assert_and_check_return(stream_filter);

    // kill it
    if (stream_filter->stream) tb_stream_kill(stream_filter->stream);
}
static tb_long_t tb_stream_filter_read(tb_stream_ref_t stream, tb_byte_t* data, tb_size_t size)
{
    // check
    tb_stream_filter_t* stream_filter = tb_stream_filter_cast(stream);
    tb_assert_and_check_return_val(stream_filter && stream_filter->stream, -1);

    // read 
    tb_long_t real = tb_stream_read(stream_filter->stream, data, size);

    // done filter
    if (stream_filter->filter)
    {
        // save mode: read
        if (!stream_filter->mode) stream_filter->mode = 1;

        // check mode
        tb_assert_and_check_return_val(stream_filter->mode == 1, -1);

        // save last
        stream_filter->last = real;

        // eof?
        if (real < 0 || (!real && stream_filter->wait) || tb_filter_beof(stream_filter->filter))
            stream_filter->beof = tb_true;
        // clear wait
        else if (real > 0) stream_filter->wait = tb_false;

        // spak data
        tb_byte_t const* odata = tb_null;
        if (real) real = tb_filter_spak(stream_filter->filter, data, real < 0? 0 : real, &odata, size, stream_filter->beof? -1 : 0);
        // no data? try to sync it
        if (!real) real = tb_filter_spak(stream_filter->filter, tb_null, 0, &odata, size, stream_filter->beof? -1 : 1);

        // has data? save it
        if (real > 0 && odata) tb_memcpy(data, odata, real);

        // eof?
        if (stream_filter->beof && !real) real = -1;
    }

    // ok? 
    return real;
}
static tb_long_t tb_stream_filter_writ(tb_stream_ref_t stream, tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_stream_filter_t* stream_filter = tb_stream_filter_cast(stream);
    tb_assert_and_check_return_val(stream_filter && stream_filter->stream, -1);

    // done filter
    if (stream_filter->filter && data && size)
    {
        // save mode: writ
        if (!stream_filter->mode) stream_filter->mode = -1;

        // check mode
        tb_assert_and_check_return_val(stream_filter->mode == -1, -1);

        // spak data
        tb_long_t real = tb_filter_spak(stream_filter->filter, data, size, &data, size, 0);
        tb_assert_and_check_return_val(real >= 0, -1);

        // no data?
        tb_check_return_val(real, 0);

        // save size
        size = real;
    }

    // writ 
    return tb_stream_writ(stream_filter->stream, data, size);
}
static tb_bool_t tb_stream_filter_sync(tb_stream_ref_t stream, tb_bool_t bclosing)
{
    // check
    tb_stream_filter_t* stream_filter = tb_stream_filter_cast(stream);
    tb_assert_and_check_return_val(stream_filter && stream_filter->stream, tb_false);

    // done filter
    if (stream_filter->filter)
    {
        // save mode: writ
        if (!stream_filter->mode) stream_filter->mode = -1;

        // check mode
        tb_assert_and_check_return_val(stream_filter->mode == -1, tb_false);

        // spak data
        tb_byte_t const*    data = tb_null;
        tb_long_t           real = -1;
        while ( !tb_stream_is_killed(stream)
            &&  (real = tb_filter_spak(stream_filter->filter, tb_null, 0, &data, 0, bclosing? -1 : 1)) > 0
            &&  data)
        {
            if (!tb_stream_bwrit(stream_filter->stream, data, real)) return tb_false;
        }
    }

    // writ 
    return tb_stream_sync(stream_filter->stream, bclosing);
}
static tb_long_t tb_stream_filter_wait(tb_stream_ref_t stream, tb_size_t wait, tb_long_t timeout)
{
    // check
    tb_stream_filter_t* stream_filter = tb_stream_filter_cast(stream);
    tb_assert_and_check_return_val(stream_filter && stream_filter->stream, -1);

    // done
    tb_long_t ok = -1;
    if (stream_filter->filter && stream_filter->mode == 1)
    {
        // wait ok
        if (stream_filter->last > 0) ok = wait;
        // need wait
        else if (!stream_filter->last && !stream_filter->beof && !tb_filter_beof(stream_filter->filter))
        {
            // wait
            ok = tb_stream_wait(stream_filter->stream, wait, timeout);

            // eof?
            if (!ok) 
            {
                // wait ok and continue to read or writ
                ok = wait;

                // set eof
                stream_filter->beof = tb_true;
            }
            // wait ok
            else stream_filter->wait = tb_true;
        }
        // eof
        else 
        {   
            // wait ok and continue to read or writ
            ok = wait;

            // set eof
            stream_filter->beof = tb_true;
        }
    }
    else ok = tb_stream_wait(stream_filter->stream, wait, timeout);

    // ok?
    return ok;
}
static tb_bool_t tb_stream_filter_ctrl(tb_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args)
{
    // check
    tb_stream_filter_t* stream_filter = tb_stream_filter_cast(stream);
    tb_assert_and_check_return_val(stream_filter, tb_false);

    // ctrl
    switch (ctrl)
    {
    case TB_STREAM_CTRL_FLTR_SET_STREAM:
        {
            // check
            tb_assert_and_check_break(tb_stream_is_closed(stream));

            // set stream
            stream_filter->stream = (tb_stream_ref_t)tb_va_arg(args, tb_stream_ref_t);

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FLTR_GET_STREAM:
        {
            // the pstream
            tb_stream_ref_t* pstream = (tb_stream_ref_t*)tb_va_arg(args, tb_stream_ref_t*);
            tb_assert_and_check_break(pstream);

            // set stream
            *pstream = stream_filter->stream;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FLTR_SET_FILTER:
        {
            // check
            tb_assert_and_check_break(tb_stream_is_closed(stream));

            // exit filter first if exists
            if (!stream_filter->bref && stream_filter->filter) tb_filter_exit(stream_filter->filter);

            // set filter
            tb_filter_ref_t filter = (tb_filter_ref_t)tb_va_arg(args, tb_filter_ref_t);
            stream_filter->filter = filter;
            stream_filter->bref = filter? tb_true : tb_false;

            // ok
            return tb_true;
        }
    case TB_STREAM_CTRL_FLTR_GET_FILTER:
        {
            // the pfilter
            tb_filter_ref_t* pfilter = (tb_filter_ref_t*)tb_va_arg(args, tb_filter_ref_t*);
            tb_assert_and_check_break(pfilter);

            // set filter
            *pfilter = stream_filter->filter;

            // ok
            return tb_true;
        }
    default:
        break;
    }

    // failed
    return tb_false;
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_stream_ref_t tb_stream_init_filter()
{
    return tb_stream_init(  TB_STREAM_TYPE_FLTR
                        ,   sizeof(tb_stream_filter_t)
                        ,   0
                        ,   tb_stream_filter_open
                        ,   tb_stream_filter_clos
                        ,   tb_stream_filter_exit
                        ,   tb_stream_filter_ctrl
                        ,   tb_stream_filter_wait
                        ,   tb_stream_filter_read
                        ,   tb_stream_filter_writ
                        ,   tb_null
                        ,   tb_stream_filter_sync
                        ,   tb_stream_filter_kill);
}
tb_stream_ref_t tb_stream_init_filter_from_null(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     stream_filter = tb_null;
    do
    {
        // init stream
        stream_filter = tb_stream_init_filter();
        tb_assert_and_check_break(stream_filter);

        // set stream
        if (!tb_stream_ctrl(stream_filter, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (stream_filter) tb_stream_exit(stream_filter);
        stream_filter = tb_null;
    }

    // ok
    return stream_filter;
}
#ifdef TB_CONFIG_MODULE_HAVE_ZIP
tb_stream_ref_t tb_stream_init_filter_from_zip(tb_stream_ref_t stream, tb_size_t algo, tb_size_t action)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     stream_filter = tb_null;
    do
    {
        // init stream
        stream_filter = tb_stream_init_filter();
        tb_assert_and_check_break(stream_filter);

        // set stream
        if (!tb_stream_ctrl(stream_filter, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // set filter
        ((tb_stream_filter_t*)stream_filter)->bref = tb_false;
        ((tb_stream_filter_t*)stream_filter)->filter = tb_filter_init_from_zip(algo, action);
        tb_assert_and_check_break(((tb_stream_filter_t*)stream_filter)->filter);
 
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (stream_filter) tb_stream_exit(stream_filter);
        stream_filter = tb_null;
    }

    // ok
    return stream_filter;
}
#endif
tb_stream_ref_t tb_stream_init_filter_from_cache(tb_stream_ref_t stream, tb_size_t size)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     stream_filter = tb_null;
    do
    {
        // init stream
        stream_filter = tb_stream_init_filter();
        tb_assert_and_check_break(stream_filter);

        // set stream
        if (!tb_stream_ctrl(stream_filter, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // set filter
        ((tb_stream_filter_t*)stream_filter)->bref = tb_false;
        ((tb_stream_filter_t*)stream_filter)->filter = tb_filter_init_from_cache(size);
        tb_assert_and_check_break(((tb_stream_filter_t*)stream_filter)->filter);
 
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (stream_filter) tb_stream_exit(stream_filter);
        stream_filter = tb_null;
    }

    // ok
    return stream_filter;
}
#ifdef TB_CONFIG_MODULE_HAVE_CHARSET
tb_stream_ref_t tb_stream_init_filter_from_charset(tb_stream_ref_t stream, tb_size_t fr, tb_size_t to)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     stream_filter = tb_null;
    do
    {
        // init stream
        stream_filter = tb_stream_init_filter();
        tb_assert_and_check_break(stream_filter);

        // set stream
        if (!tb_stream_ctrl(stream_filter, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // set filter
        ((tb_stream_filter_t*)stream_filter)->bref = tb_false;
        ((tb_stream_filter_t*)stream_filter)->filter = tb_filter_init_from_charset(fr, to);
        tb_assert_and_check_break(((tb_stream_filter_t*)stream_filter)->filter);
 
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (stream_filter) tb_stream_exit(stream_filter);
        stream_filter = tb_null;
    }

    // ok
    return stream_filter;
}
#endif
tb_stream_ref_t tb_stream_init_filter_from_chunked(tb_stream_ref_t stream, tb_bool_t dechunked)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_stream_ref_t     stream_filter = tb_null;
    do
    {
        // init stream
        stream_filter = tb_stream_init_filter();
        tb_assert_and_check_break(stream_filter);

        // set stream
        if (!tb_stream_ctrl(stream_filter, TB_STREAM_CTRL_FLTR_SET_STREAM, stream)) break;

        // set filter
        ((tb_stream_filter_t*)stream_filter)->bref = tb_false;
        ((tb_stream_filter_t*)stream_filter)->filter = tb_filter_init_from_chunked(dechunked);
        tb_assert_and_check_break(((tb_stream_filter_t*)stream_filter)->filter);
 
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (stream_filter) tb_stream_exit(stream_filter);
        stream_filter = tb_null;
    }

    // ok
    return stream_filter;
}
