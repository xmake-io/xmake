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
 * @file        charset.c
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../../../charset/charset.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the charset filter type
typedef struct __tb_filter_charset_t
{
    // the filter base
    tb_filter_t     base;

    // the from type
    tb_size_t                   ftype;

    // the to type
    tb_size_t                   ttype;

}tb_filter_charset_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_filter_charset_t* tb_filter_charset_cast(tb_filter_t* filter)
{
    // check
    tb_assert_and_check_return_val(filter && filter->type == TB_FILTER_TYPE_CHARSET, tb_null);
    return (tb_filter_charset_t*)filter;
}
static tb_long_t tb_filter_charset_spak(tb_filter_t* filter, tb_static_stream_ref_t istream, tb_static_stream_ref_t ostream, tb_long_t sync)
{
    // check
    tb_filter_charset_t* cfilter = tb_filter_charset_cast(filter);
    tb_assert_and_check_return_val(cfilter && TB_CHARSET_TYPE_OK(cfilter->ftype) && TB_CHARSET_TYPE_OK(cfilter->ttype) && istream && ostream, -1);

    // spak it
    tb_long_t real = tb_charset_conv_bst(cfilter->ftype, cfilter->ttype, istream, ostream);

    // no data and sync end? end it
    if (!real && sync < 0) real = -1;

    // ok?
    return real;
}
static tb_bool_t tb_filter_charset_ctrl(tb_filter_t* filter, tb_size_t ctrl, tb_va_list_t args)
{
    // check
    tb_filter_charset_t* cfilter = tb_filter_charset_cast(filter);
    tb_assert_and_check_return_val(cfilter && ctrl, tb_false);

    // ctrl
    switch (ctrl)
    {
    case TB_FILTER_CTRL_CHARSET_GET_FTYPE:
        {
            // the pftype
            tb_size_t* pftype = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_break(pftype);

            // get ftype
            *pftype = cfilter->ftype;

            // ok
            return tb_true;
        }
    case TB_FILTER_CTRL_CHARSET_SET_FTYPE:
        {
            // set ftype
            cfilter->ftype = (tb_size_t)tb_va_arg(args, tb_size_t);

            // ok
            return tb_true;
        }
    case TB_FILTER_CTRL_CHARSET_GET_TTYPE:
        {
            // the pttype
            tb_size_t* pttype = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_break(pttype);

            // get ttype
            *pttype = cfilter->ttype;

            // ok
            return tb_true;
        }
    case TB_FILTER_CTRL_CHARSET_SET_TTYPE:
        {
            // set ttype
            cfilter->ttype = (tb_size_t)tb_va_arg(args, tb_size_t);

            // ok
            return tb_true;
        }
    default:
        break;
    }
    return tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_filter_ref_t tb_filter_init_from_charset(tb_size_t fr, tb_size_t to)
{
    // done
    tb_bool_t                       ok = tb_false;
    tb_filter_charset_t*     filter = tb_null;
    do
    {
        // make filter
        filter = tb_malloc0_type(tb_filter_charset_t);
        tb_assert_and_check_break(filter);

        // init filter 
        if (!tb_filter_init((tb_filter_t*)filter, TB_FILTER_TYPE_CHARSET)) break;
        filter->base.spak = tb_filter_charset_spak;
        filter->base.ctrl = tb_filter_charset_ctrl;

        // init the from and to charset
        filter->ftype = fr;
        filter->ttype = to;

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

