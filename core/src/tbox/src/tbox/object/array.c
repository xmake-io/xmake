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
 * @file        array.c
 * @ingroup     object
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "oc_array"
#define TB_TRACE_MODULE_DEBUG       (0)
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "object.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the array type
typedef struct __tb_oc_array_t
{
    // the object base
    tb_object_t         base;

    // the vector
    tb_vector_ref_t     vector;

    // is increase refn?
    tb_bool_t           incr;

}tb_oc_array_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static __tb_inline__ tb_oc_array_t* tb_oc_array_cast(tb_object_ref_t object)
{
    // check
    tb_assert_and_check_return_val(object && object->type == TB_OBJECT_TYPE_ARRAY, tb_null);

    // cast
    return (tb_oc_array_t*)object;
}
static tb_object_ref_t tb_oc_array_copy(tb_object_ref_t object)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return_val(array && array->vector, tb_null);

    // init copy
    tb_oc_array_t* copy = (tb_oc_array_t*)tb_oc_array_init(tb_vector_grow(array->vector), array->incr);
    tb_assert_and_check_return_val(copy && copy->vector, tb_null);

    // refn++
    tb_for_all (tb_object_ref_t, item, array->vector)
    {
        if (item) tb_object_retain(item);
    }

    // copy
    tb_vector_copy(copy->vector, array->vector);

    // ok
    return (tb_object_ref_t)copy;
}
static tb_void_t tb_oc_array_exit(tb_object_ref_t object)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return(array);

    // exit vector
    if (array->vector) tb_vector_exit(array->vector);
    array->vector = tb_null;

    // exit it
    tb_free(array);
}
static tb_void_t tb_oc_array_clear(tb_object_ref_t object)
{
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return(array && array->vector);

    // clear vector
    tb_vector_clear(array->vector);
}
static tb_oc_array_t* tb_oc_array_init_base()
{
    // done
    tb_bool_t       ok = tb_false;
    tb_oc_array_t*  array = tb_null;
    do
    {
        // make array
        array = tb_malloc0_type(tb_oc_array_t);
        tb_assert_and_check_break(array);

        // init array
        if (!tb_object_init((tb_object_ref_t)array, TB_OBJECT_FLAG_NONE, TB_OBJECT_TYPE_ARRAY)) break;

        // init base
        array->base.copy    = tb_oc_array_copy;
        array->base.exit    = tb_oc_array_exit;
        array->base.clear   = tb_oc_array_clear;
        
        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (array) tb_object_exit((tb_object_ref_t)array);
        array = tb_null;
    }

    // ok?
    return array;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_object_ref_t tb_oc_array_init(tb_size_t grow, tb_bool_t incr)
{
    // done
    tb_bool_t       ok = tb_false;
    tb_oc_array_t*  array = tb_null;
    do
    {
        // make array
        array = tb_oc_array_init_base();
        tb_assert_and_check_break(array);

        // init element
        tb_element_t element = tb_element_obj();

        // init vector
        array->vector = tb_vector_init(grow, element);
        tb_assert_and_check_break(array->vector);

        // init incr
        array->incr = incr;

        // ok
        ok = tb_true;

    } while (0);
    
    // failed
    if (!ok)
    {
        // exit it
        if (array) tb_oc_array_exit((tb_object_ref_t)array);
        array = tb_null;
    }

    // ok?
    return (tb_object_ref_t)array;
}
tb_size_t tb_oc_array_size(tb_object_ref_t object)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return_val(array && array->vector, 0);

    // size
    return tb_vector_size(array->vector);
}
tb_object_ref_t tb_oc_array_item(tb_object_ref_t object, tb_size_t index)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return_val(array && array->vector, tb_null);

    // item
    return (tb_object_ref_t)tb_iterator_item(array->vector, index);
}
tb_iterator_ref_t tb_oc_array_itor(tb_object_ref_t object)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return_val(array, tb_null);

    // iterator
    return (tb_iterator_ref_t)array->vector;
}
tb_void_t tb_oc_array_remove(tb_object_ref_t object, tb_size_t index)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return(array && array->vector);

    // remove
    tb_vector_remove(array->vector, index);
}
tb_void_t tb_oc_array_append(tb_object_ref_t object, tb_object_ref_t item)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return(array && array->vector && item);

    // insert
    tb_vector_insert_tail(array->vector, item);

    // refn--
    if (!array->incr) tb_object_exit(item);
}
tb_void_t tb_oc_array_insert(tb_object_ref_t object, tb_size_t index, tb_object_ref_t item)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return(array && array->vector && item);

    // insert
    tb_vector_insert_prev(array->vector, index, item);

    // refn--
    if (!array->incr) tb_object_exit(item);
}
tb_void_t tb_oc_array_replace(tb_object_ref_t object, tb_size_t index, tb_object_ref_t item)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return(array && array->vector && item);

    // replace
    tb_vector_replace(array->vector, index, item);

    // refn--
    if (!array->incr) tb_object_exit(item);
}
tb_void_t tb_oc_array_incr(tb_object_ref_t object, tb_bool_t incr)
{
    // check
    tb_oc_array_t* array = tb_oc_array_cast(object);
    tb_assert_and_check_return(array);

    array->incr = incr;
}
