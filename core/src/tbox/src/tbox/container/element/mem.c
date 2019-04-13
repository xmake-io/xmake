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
 * @file        mem.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "hash.h"
#include "../../hash/hash.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_size_t tb_element_mem_hash(tb_element_ref_t element, tb_cpointer_t data, tb_size_t mask, tb_size_t index)
{   
    return tb_element_hash_data((tb_byte_t const*)data, element->size, mask, index);
}
static tb_long_t tb_element_mem_comp(tb_element_ref_t element, tb_cpointer_t ldata, tb_cpointer_t rdata)
{
    // check
    tb_assert_and_check_return_val(element && element->size && ldata && rdata, 0);

    // comp
    return tb_memcmp(ldata, rdata, element->size);
}
static tb_pointer_t tb_element_mem_data(tb_element_ref_t element, tb_cpointer_t buff)
{
    // check
    tb_assert_and_check_return_val(element && buff, tb_null);

    // the element data
    return (tb_pointer_t)buff;
}
static tb_char_t const* tb_element_mem_cstr(tb_element_ref_t element, tb_cpointer_t data, tb_char_t* cstr, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(element && element->size && cstr && data, tb_null);

    // make info
    tb_long_t size = tb_snprintf(cstr, maxn, "0x%x", tb_adler32_make((tb_byte_t const*)data, element->size, 0));
    if (size >= 0) cstr[size] = '\0';

    // ok?
    return cstr;
}
static tb_void_t tb_element_mem_free(tb_element_ref_t element, tb_pointer_t buff)
{
    // check
    tb_assert_and_check_return(element && element->size && buff);

    // clear it
    tb_memset(buff, 0, element->size);
}
static tb_void_t tb_element_mem_dupl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return(element && element->size && buff && data);

    // copy element
    tb_memcpy(buff, data, element->size);
}
static tb_void_t tb_element_mem_repl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return(element && element->size && buff && data);

    // the free is hooked? free it 
    if (element->free != tb_element_mem_free && element->free)
        element->free(element, buff);

    // copy element
    tb_memcpy(buff, data, element->size);
}
static tb_void_t tb_element_mem_copy(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data)
{
    // check
    tb_assert_and_check_return(element && element->size && buff && data);

    // copy element
    tb_memcpy(buff, data, element->size);
}
static tb_void_t tb_element_mem_nfree(tb_element_ref_t element, tb_pointer_t buff, tb_size_t size)
{
    // check
    tb_assert_and_check_return(element && element->size && buff);

    // the free is hooked? free it 
    if (element->free != tb_element_mem_free && element->free)
    {
        tb_size_t n = size;
        while (n--) element->free(element, (tb_byte_t*)buff + n * element->size);
    }

    // clear
    if (size) tb_memset(buff, 0, size * element->size);
}
static tb_void_t tb_element_mem_ndupl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(element && element->size && buff && data);

    // copy elements
    if (element->ncopy) element->ncopy(element, buff, data, size);
}
static tb_void_t tb_element_mem_nrepl(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(element && element->size && buff && data);

    // free elements
    if (element->nfree) element->nfree(element, buff, size);

    // copy elements
    if (element->ncopy) element->ncopy(element, buff, data, size);
}
static tb_void_t tb_element_mem_ncopy(tb_element_ref_t element, tb_pointer_t buff, tb_cpointer_t data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(element && element->size && buff && data);

    // copy elements
    while (size--) tb_memcpy((tb_byte_t*)buff + size * element->size, data, element->size);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_element_t tb_element_mem(tb_size_t size, tb_element_free_func_t free, tb_cpointer_t priv)
{
    // check
    tb_assert(size < TB_MAXU16);

    // init element
    tb_element_t element = {0};
    element.type   = TB_ELEMENT_TYPE_MEM;
    element.flag   = 0;
    element.hash   = tb_element_mem_hash;
    element.comp   = tb_element_mem_comp;
    element.data   = tb_element_mem_data;
    element.cstr   = tb_element_mem_cstr;
    element.free   = free? free : tb_element_mem_free;
    element.dupl   = tb_element_mem_dupl;
    element.repl   = tb_element_mem_repl;
    element.copy   = tb_element_mem_copy;
    element.nfree  = tb_element_mem_nfree;
    element.ndupl  = tb_element_mem_ndupl;
    element.nrepl  = tb_element_mem_nrepl;
    element.ncopy  = tb_element_mem_ncopy;
    element.size   = (tb_uint16_t)size;
    element.priv   = priv;

    // ok?
    return element;
}
