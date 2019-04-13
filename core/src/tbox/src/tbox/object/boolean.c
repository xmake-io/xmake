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
 * @file        boolean.c
 * @ingroup     object
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "oc_boolean"
#define TB_TRACE_MODULE_DEBUG       (0)
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "object.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the boolean type
typedef struct __tb_oc_boolean_t
{
    // the object base
    tb_object_t      base;

    // the boolean value
    tb_bool_t           value;

}tb_oc_boolean_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_oc_boolean_t* tb_oc_boolean_cast(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && object->type == TB_OBJECT_TYPE_BOOLEAN, tb_null);

    // cast
    return (tb_oc_boolean_t*)object;
}

static tb_object_ref_t tb_oc_boolean_copy(tb_object_ref_t object)
{
    // check
    tb_oc_boolean_t* boolean = (tb_oc_boolean_t*)object;
    tb_assert_and_check_return_val(boolean, tb_null);

    // copy
    return object;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
  
// true
static tb_oc_boolean_t const g_boolean_true = 
{
    {
        TB_OBJECT_FLAG_READONLY | TB_OBJECT_FLAG_SINGLETON
    ,   TB_OBJECT_TYPE_BOOLEAN
    ,   1
    ,   tb_null
    ,   tb_oc_boolean_copy
    ,   tb_null
    ,   tb_null
    }
,   tb_true

};

// false
static tb_oc_boolean_t const g_boolean_false = 
{
    {
        TB_OBJECT_FLAG_READONLY | TB_OBJECT_FLAG_SINGLETON
    ,   TB_OBJECT_TYPE_BOOLEAN
    ,   1
    ,   tb_null
    ,   tb_oc_boolean_copy
    ,   tb_null
    ,   tb_null
    }
,   tb_false

};

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_object_ref_t tb_oc_boolean_init(tb_bool_t value)
{
    return value? tb_oc_boolean_true() : tb_oc_boolean_false();
}
tb_object_ref_t tb_oc_boolean_true()
{
    return (tb_object_ref_t)&g_boolean_true;
}
tb_object_ref_t tb_oc_boolean_false()
{
    return (tb_object_ref_t)&g_boolean_false;
}
tb_bool_t tb_oc_boolean_bool(tb_object_ref_t object)
{
    tb_oc_boolean_t* boolean = tb_oc_boolean_cast(object);
    tb_assert_and_check_return_val(boolean, tb_false);

    return boolean->value;
}

