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
 * @file        obj.c
 * @ingroup     container
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_char_t const* tb_element_obj_cstr(tb_element_ref_t element, tb_cpointer_t data, tb_char_t* cstr, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(cstr, "");

    // format string
    tb_long_t n = tb_snprintf(cstr, maxn, "<object: %p>", data);
    if (n >= 0 && n < (tb_long_t)maxn) cstr[n] = '\0';

    // ok?
    return (tb_char_t const*)cstr;
}
static tb_void_t tb_element_obj_free(tb_element_ref_t element, tb_pointer_t buff)
{
    // check
    tb_assert_and_check_return(element && buff);

    // exit
    tb_object_ref_t object = *((tb_object_ref_t*)buff);
    if (object)
    {
        tb_object_exit(object);
        *((tb_object_ref_t*)buff) = tb_null;
    }
}
static tb_void_t tb_element_obj_dupl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return(element && buff);

    // refn++
    if (data) tb_object_retain((tb_object_ref_t)data);

    // copy it
    *((tb_cpointer_t*)buff) = data;
}
static tb_void_t tb_element_obj_repl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return(element && buff);

    // save the previous object
    tb_object_ref_t object = *((tb_object_ref_t*)buff);

    // refn++
    if (data) tb_object_retain((tb_object_ref_t)data);

    // copy it
    *((tb_cpointer_t*)buff) = data;

    // refn--
    if (object) tb_object_exit(object);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_element_t tb_element_obj()
{
    // the ptr element
    tb_element_t element_ptr = tb_element_ptr(tb_null, tb_null);

    // the str element
    tb_element_t element_str = tb_element_str(tb_true);

    // init element
    tb_element_t element = {0};
    element.type   = TB_ELEMENT_TYPE_OBJ;
    element.flag   = 0;
    element.hash   = element_ptr.hash;
    element.comp   = element_ptr.comp;
    element.data   = element_ptr.data;
    element.cstr   = tb_element_obj_cstr;
    element.free   = tb_element_obj_free;
    element.dupl   = tb_element_obj_dupl;
    element.repl   = tb_element_obj_repl;
    element.copy   = element_ptr.copy;
    element.nfree  = element_str.nfree;
    element.ndupl  = element_str.ndupl;
    element.nrepl  = element_str.nrepl;
    element.ncopy  = element_ptr.ncopy;
    element.size   = sizeof(tb_object_ref_t);
    
    // ok?
    return element;
}
