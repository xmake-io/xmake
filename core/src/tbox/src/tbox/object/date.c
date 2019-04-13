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
 * @file        date.c
 * @ingroup     object
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "oc_date"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "object.h"
#include "../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
 
// the date type
typedef struct __tb_oc_date_t
{
    // the object base
    tb_object_t         base;

    // the date time
    tb_time_t           time;

}tb_oc_date_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_oc_date_t* tb_oc_date_cast(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && object->type == TB_OBJECT_TYPE_DATE, tb_null);

    // cast
    return (tb_oc_date_t*)object;
}
static tb_object_ref_t tb_oc_date_copy(tb_object_ref_t object)
{
    return tb_oc_date_init_from_time(tb_oc_date_time(object));
}
static tb_void_t tb_oc_date_exit(tb_object_ref_t object)
{
    if (object) tb_free(object);
}
static tb_void_t tb_oc_date_clear(tb_object_ref_t object)
{
    tb_oc_date_t* date = tb_oc_date_cast(object);
    if (date) date->time = 0;
}
static tb_oc_date_t* tb_oc_date_init_base()
{
    // done
    tb_bool_t       ok = tb_false;
    tb_oc_date_t*   date = tb_null;
    do
    {
        // make date
        date = tb_malloc0_type(tb_oc_date_t);
        tb_assert_and_check_break(date);

        // init date
        if (!tb_object_init((tb_object_ref_t)date, TB_OBJECT_FLAG_NONE, TB_OBJECT_TYPE_DATE)) break;

        // init base
        date->base.copy     = tb_oc_date_copy;
        date->base.exit     = tb_oc_date_exit;
        date->base.clear    = tb_oc_date_clear;
        
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (date) tb_object_exit((tb_object_ref_t)date);
        date = tb_null;
    }

    // ok?
    return date;
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_object_ref_t tb_oc_date_init_from_now()
{
    // make
    tb_oc_date_t* date = tb_oc_date_init_base();
    tb_assert_and_check_return_val(date, tb_null);

    // init time
    date->time = tb_time();

    // ok
    return (tb_object_ref_t)date;
}
tb_object_ref_t tb_oc_date_init_from_time(tb_time_t time)
{
    // make
    tb_oc_date_t* date = tb_oc_date_init_base();
    tb_assert_and_check_return_val(date, tb_null);

    // init time
    if (time > 0) date->time = time;

    // ok
    return (tb_object_ref_t)date;
}
tb_time_t tb_oc_date_time(tb_object_ref_t object)
{
    // check
    tb_oc_date_t* date = tb_oc_date_cast(object);
    tb_assert_and_check_return_val(date, -1);

    // time
    return date->time;
}
tb_bool_t tb_oc_date_time_set(tb_object_ref_t object, tb_time_t time)
{
    // check
    tb_oc_date_t* date = tb_oc_date_cast(object);
    tb_assert_and_check_return_val(date, tb_false);

    // set time
    date->time = time;

    // ok
    return tb_true;
}
tb_bool_t tb_oc_date_time_set_now(tb_object_ref_t object)
{
    // check
    tb_oc_date_t* date = tb_oc_date_cast(object);
    tb_assert_and_check_return_val(date, tb_false);

    // set time
    date->time = tb_time();

    // ok
    return tb_true;
}
