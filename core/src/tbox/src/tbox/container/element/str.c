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
 * @file        str.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "hash.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_size_t tb_element_str_hash(tb_element_ref_t element, tb_cpointer_t data, tb_size_t mask, tb_size_t index)
{
    return tb_element_hash_cstr((tb_char_t const*)data, mask, index);
}
static tb_long_t tb_element_str_comp(tb_element_ref_t element, tb_cpointer_t ldata, tb_cpointer_t rdata)
{
    // check
    tb_assert_and_check_return_val(element && ldata && rdata, 0);

    // compare it
    return element->flag? tb_strcmp((tb_char_t const*)ldata, (tb_char_t const*)rdata) : tb_stricmp((tb_char_t const*)ldata, (tb_char_t const*)rdata);
}
static tb_pointer_t tb_element_str_data(tb_element_ref_t element, tb_cpointer_t buff)
{
    // check
    tb_assert_and_check_return_val(buff, tb_null);

    // the element data
    return *((tb_pointer_t*)buff);
}
static tb_char_t const* tb_element_str_cstr(tb_element_ref_t element, tb_cpointer_t data, tb_char_t* cstr, tb_size_t maxn)
{
    // the c-string
    return (tb_char_t const*)data;
}
static tb_void_t tb_element_str_free(tb_element_ref_t element, tb_pointer_t buff)
{
    // check
    tb_assert_and_check_return(element && buff);

    // exists?
    tb_pointer_t cstr = *((tb_pointer_t*)buff);
    if (cstr) 
    {
        // free it
        tb_free(cstr);

        // clear it
        *((tb_pointer_t*)buff) = tb_null;
    }
}
static tb_void_t tb_element_str_dupl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return(element && buff);

    // duplicate it
    if (data) *((tb_char_t const**)buff) = tb_strdup((tb_char_t const*)data);
    // clear it
    else *((tb_char_t const**)buff) = tb_null;
}
static tb_void_t tb_element_str_repl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return(element && element->dupl && buff);

#if 0
    // free it
    if (element->free) element->free(element, buff);

    // dupl it
    element->dupl(element, buff, data);
#else
    // replace it
    tb_pointer_t cstr = *((tb_pointer_t*)buff);
    if (cstr && data)
    {
        // attempt to replace it
        tb_char_t*          p = (tb_char_t*)cstr;
        tb_char_t const*    q = (tb_char_t const*)data;
        while (*p && *q) *p++ = *q++;

        // not enough space?
        if (!*p && *q)
        {
            // the left size
            tb_size_t left = tb_strlen(q);
            tb_assert(left);

            // the copy size
            tb_size_t copy = p - (tb_char_t*)cstr;

            // grow size
            cstr = tb_ralloc(cstr, copy + left + 1);
            tb_assert(cstr);

            // copy the left data
            tb_memcpy((tb_char_t*)cstr + copy, q, left + 1); 

            // update the cstr
            *((tb_pointer_t*)buff) = cstr;
        }
        // end
        else *p = '\0';
    }
    // duplicate it
    else if (data) element->dupl(element, buff, data);
    // free it
    else if (element->free) element->free(element, buff);
    // clear it
    else *((tb_char_t const**)buff) = tb_null;
#endif
}
static tb_void_t tb_element_str_copy(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return(buff);

    // copy it
    *((tb_cpointer_t*)buff) = data;
}
static tb_void_t tb_element_str_nfree(tb_element_ref_t element, tb_pointer_t buff, tb_size_t size)
{
    // check
    tb_assert_and_check_return(element && buff);

    // free elements 
    if (element->free)
    {
        tb_size_t n = size;
        while (n--) element->free(element, (tb_byte_t*)buff + n * sizeof(tb_char_t*));
    }

    // clear
    if (size) tb_memset(buff, 0, size * sizeof(tb_char_t*));
}
static tb_void_t tb_element_str_ndupl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(element && buff);

    // dupl elements
    if (element->dupl) while (size--) element->dupl(element, (tb_byte_t*)buff + size * sizeof(tb_char_t*), data);
}
static tb_void_t tb_element_str_nrepl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(element && buff && data);

    // repl elements
    if (element->repl) while (size--) element->repl(element, (tb_byte_t*)buff + size * sizeof(tb_char_t*), data);
}
static tb_void_t tb_element_str_ncopy(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(buff);

    // fill elements
    if (size) tb_memset_ptr(buff, data, size);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_element_t tb_element_str(tb_bool_t bcase)
{
    // init element
    tb_element_t element = {0};
    element.type   = TB_ELEMENT_TYPE_STR;
    element.flag   = !!bcase;
    element.hash   = tb_element_str_hash;
    element.comp   = tb_element_str_comp;
    element.data   = tb_element_str_data;
    element.cstr   = tb_element_str_cstr;
    element.free   = tb_element_str_free;
    element.dupl   = tb_element_str_dupl;
    element.repl   = tb_element_str_repl;
    element.copy   = tb_element_str_copy;
    element.nfree  = tb_element_str_nfree;
    element.ndupl  = tb_element_str_ndupl;
    element.nrepl  = tb_element_str_nrepl;
    element.ncopy  = tb_element_str_ncopy;
    element.size   = sizeof(tb_char_t*);

    // ok?
    return element;
}
