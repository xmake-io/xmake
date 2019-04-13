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
 * @file        null.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_size_t tb_element_null_hash(tb_element_ref_t element, tb_cpointer_t data, tb_size_t size, tb_size_t index)
{
    return 0;
}
static tb_long_t tb_element_null_comp(tb_element_ref_t element, tb_cpointer_t ldata, tb_cpointer_t rdata)
{
    // always be equal
    return 0;
}
static tb_pointer_t tb_element_null_data(tb_element_ref_t element, tb_cpointer_t buff)
{
    // the element data
    return (tb_pointer_t)tb_null;
}
static tb_char_t const* tb_element_null_cstr(tb_element_ref_t element, tb_cpointer_t data, tb_char_t* cstr, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(element && cstr && maxn, "");

    // format string
    tb_strlcpy(cstr, "null", maxn);

    // ok?
    return (tb_char_t const*)cstr;
}
static tb_void_t tb_element_null_free(tb_element_ref_t element, tb_pointer_t buff)
{
}
static tb_void_t tb_element_null_nfree(tb_element_ref_t element, tb_pointer_t buff, tb_size_t size)
{
}
static tb_void_t tb_element_null_repl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data)
{
    tb_assert(data == tb_null);
}
static tb_void_t tb_element_null_nrepl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size)
{
    tb_assert(data == tb_null);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_element_t tb_element_null()
{
    // init element
    tb_element_t element = {0};
    element.type   = TB_ELEMENT_TYPE_NULL;
    element.flag   = 0;
    element.hash   = tb_element_null_hash;
    element.comp   = tb_element_null_comp;
    element.data   = tb_element_null_data;
    element.cstr   = tb_element_null_cstr;
    element.free   = tb_element_null_free;
    element.dupl   = tb_element_null_repl;
    element.repl   = tb_element_null_repl;
    element.copy   = tb_element_null_repl;
    element.nfree  = tb_element_null_nfree;
    element.ndupl  = tb_element_null_nrepl;
    element.nrepl  = tb_element_null_nrepl;
    element.ncopy  = tb_element_null_nrepl;
    element.size   = 0;

    // ok?
    return element;
}
