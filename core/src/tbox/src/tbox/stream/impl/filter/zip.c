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
 * @file        zip.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../../../zip/zip.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the zip filter type
typedef struct __tb_filter_zip_t
{
    // the filter base
    tb_filter_t     base;

    // the algo
    tb_size_t                   algo;

    // the action
    tb_size_t                   action;

    // the zip 
    tb_zip_ref_t                zip;

}tb_filter_zip_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_filter_zip_t* tb_filter_zip_cast(tb_filter_t* filter)
{
    // check
    tb_assert_and_check_return_val(filter && filter->type == TB_FILTER_TYPE_ZIP, tb_null);
    return (tb_filter_zip_t*)filter;
}
static tb_bool_t tb_filter_zip_open(tb_filter_t* filter)
{
    // check
    tb_filter_zip_t* zfilter = tb_filter_zip_cast(filter);
    tb_assert_and_check_return_val(zfilter && !zfilter->zip, tb_false);

    // init zip
    zfilter->zip = tb_zip_init(zfilter->algo, zfilter->action);
    tb_assert_and_check_return_val(zfilter->zip, tb_false);

    // ok
    return tb_true;
}
static tb_void_t tb_filter_zip_clos(tb_filter_t* filter)
{
    // check
    tb_filter_zip_t* zfilter = tb_filter_zip_cast(filter);
    tb_assert_and_check_return(zfilter);

    // exit zip
    if (zfilter->zip) tb_zip_exit(zfilter->zip);
    zfilter->zip = tb_null;
}
static tb_long_t tb_filter_zip_spak(tb_filter_t* filter, tb_static_stream_ref_t istream, tb_static_stream_ref_t ostream, tb_long_t sync)
{
    // check
    tb_filter_zip_t* zfilter = tb_filter_zip_cast(filter);
    tb_assert_and_check_return_val(zfilter && zfilter->zip && istream && ostream, -1);

    // spak it
    return tb_zip_spak(zfilter->zip, istream, ostream, sync);
}
static tb_void_t tb_filter_zip_exit(tb_filter_t* filter)
{
    // check
    tb_filter_zip_t* zfilter = tb_filter_zip_cast(filter);
    tb_assert_and_check_return(zfilter);

    // exit zip
    if (zfilter->zip) tb_zip_exit(zfilter->zip);
    zfilter->zip = tb_null;
}
static tb_bool_t tb_filter_zip_ctrl(tb_filter_t* filter, tb_size_t ctrl, tb_va_list_t args)
{
    // check
    tb_filter_zip_t* zfilter = tb_filter_zip_cast(filter);
    tb_assert_and_check_return_val(zfilter && ctrl, tb_false);

    // ctrl
    switch (ctrl)
    {
    case TB_FILTER_CTRL_ZIP_GET_ALGO:
        {
            // the palgo
            tb_size_t* palgo = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_break(palgo);

            // get algo
            *palgo = zfilter->algo;

            // ok
            return tb_true;
        }
    case TB_FILTER_CTRL_ZIP_SET_ALGO:
        {
            // set algo
            zfilter->algo = (tb_size_t)tb_va_arg(args, tb_size_t);

            // ok
            return tb_true;
        }
    case TB_FILTER_CTRL_ZIP_GET_ACTION:
        {
            // the paction
            tb_size_t* paction = (tb_size_t*)tb_va_arg(args, tb_size_t*);
            tb_assert_and_check_break(paction);

            // get action
            *paction = zfilter->action;

            // ok
            return tb_true;
        }
    case TB_FILTER_CTRL_ZIP_SET_ACTION:
        {
            // set action
            zfilter->action = (tb_size_t)tb_va_arg(args, tb_size_t);

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
tb_filter_ref_t tb_filter_init_from_zip(tb_size_t algo, tb_size_t action)
{
    // done
    tb_bool_t               ok = tb_false;
    tb_filter_zip_t* filter = tb_null;
    do
    {
        // make filter
        filter = tb_malloc0_type(tb_filter_zip_t);
        tb_assert_and_check_break(filter);

        // init filter 
        if (!tb_filter_init((tb_filter_t*)filter, TB_FILTER_TYPE_ZIP)) break;
        filter->base.open   = tb_filter_zip_open;
        filter->base.clos   = tb_filter_zip_clos;
        filter->base.spak   = tb_filter_zip_spak;
        filter->base.exit   = tb_filter_zip_exit;
        filter->base.ctrl   = tb_filter_zip_ctrl;
        filter->algo        = algo;
        filter->action      = action;

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

