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
 * @file        vector.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "vector"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "vector.h"
#include "../libc/libc.h"
#include "../utils/utils.h"
#include "../memory/memory.h"
#include "../stream/stream.h"
#include "../platform/platform.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the vector grow
#ifdef __tb_small__ 
#   define TB_VECTOR_GROW             (128)
#else
#   define TB_VECTOR_GROW             (256)
#endif

// the vector maxn
#ifdef __tb_small__
#   define TB_VECTOR_MAXN             (1 << 16)
#else
#   define TB_VECTOR_MAXN             (1 << 30)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the vector type
typedef struct __tb_vector_t
{
    // the itor
    tb_iterator_t           itor;

    // the data
    tb_byte_t*              data;

    // the size
    tb_size_t               size;

    // the grow
    tb_size_t               grow;

    // the maxn
    tb_size_t               maxn;

    // the element
    tb_element_t            element;

}tb_vector_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_size_t tb_vector_itor_size(tb_iterator_ref_t iterator)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)iterator;
    tb_assert(vector);

    // size
    return vector->size;
}
static tb_size_t tb_vector_itor_head(tb_iterator_ref_t iterator)
{
    // head
    return 0;
}
static tb_size_t tb_vector_itor_last(tb_iterator_ref_t iterator)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)iterator;
    tb_assert(vector);

    // last
    return vector->size? vector->size - 1 : 0;
}
static tb_size_t tb_vector_itor_tail(tb_iterator_ref_t iterator)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)iterator;
    tb_assert(vector);

    // tail
    return vector->size;
}
static tb_size_t tb_vector_itor_next(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)iterator;
    tb_assert(vector);
    tb_assert_and_check_return_val(itor < vector->size, vector->size);

    // next
    return itor + 1;
}
static tb_size_t tb_vector_itor_prev(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)iterator;
    tb_assert(vector);
    tb_assert_and_check_return_val(itor && itor <= vector->size, 0);

    // prev
    return itor - 1;
}
static tb_pointer_t tb_vector_itor_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)iterator;
    tb_assert_and_check_return_val(vector && itor < vector->size, tb_null);
    
    // data
    return vector->element.data(&vector->element, vector->data + itor * iterator->step);
}
static tb_void_t tb_vector_itor_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)iterator;
    tb_assert(vector);

    // copy
    vector->element.copy(&vector->element, vector->data + itor * iterator->step, item);
}
static tb_long_t tb_vector_itor_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)iterator;
    tb_assert(vector && vector->element.comp);

    // comp
    return vector->element.comp(&vector->element, litem, ritem);
}
static tb_void_t tb_vector_itor_remove(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // remove it
    tb_vector_remove((tb_vector_ref_t)iterator, itor);
}
static tb_void_t tb_vector_itor_nremove(tb_iterator_ref_t iterator, tb_size_t prev, tb_size_t next, tb_size_t size)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)iterator;
    tb_assert(vector);

    // remove the items
    if (size) tb_vector_nremove((tb_vector_ref_t)iterator, prev != vector->size? prev + 1 : 0, size);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_vector_ref_t tb_vector_init(tb_size_t grow, tb_element_t element)
{
    // check
    tb_assert_and_check_return_val(element.size && element.data && element.dupl && element.repl && element.ndupl && element.nrepl, tb_null);

    // done
    tb_bool_t       ok = tb_false;
    tb_vector_t*    vector = tb_null;
    do
    {
        // using the default grow
        if (!grow) grow = TB_VECTOR_GROW;

        // make vector
        vector = tb_malloc0_type(tb_vector_t);
        tb_assert_and_check_break(vector);

        // init vector
        vector->size      = 0;
        vector->grow      = grow;
        vector->maxn      = grow;
        vector->element   = element;
        tb_assert_and_check_break(vector->maxn < TB_VECTOR_MAXN);

        // init operation
        static tb_iterator_op_t op = 
        {
            tb_vector_itor_size
        ,   tb_vector_itor_head
        ,   tb_vector_itor_last
        ,   tb_vector_itor_tail
        ,   tb_vector_itor_prev
        ,   tb_vector_itor_next
        ,   tb_vector_itor_item
        ,   tb_vector_itor_comp
        ,   tb_vector_itor_copy
        ,   tb_vector_itor_remove
        ,   tb_vector_itor_nremove
        };

        // init iterator
        vector->itor.priv = tb_null;
        vector->itor.step = element.size;
        vector->itor.mode = TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_REVERSE | TB_ITERATOR_MODE_RACCESS | TB_ITERATOR_MODE_MUTABLE;
        vector->itor.op   = &op;

        // make data
        vector->data = (tb_byte_t*)tb_nalloc0(vector->maxn, element.size);
        tb_assert_and_check_break(vector->data);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (vector) tb_vector_exit((tb_vector_ref_t)vector);
        vector = tb_null;
    }

    // ok?
    return (tb_vector_ref_t)vector;
}
tb_void_t tb_vector_exit(tb_vector_ref_t self)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector);

    // clear data
    tb_vector_clear(self);

    // free data
    if (vector->data) tb_free(vector->data);
    vector->data = tb_null;

    // free it
    tb_free(vector);
}
tb_void_t tb_vector_clear(tb_vector_ref_t self)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector);

    // free data
    if (vector->element.nfree)
        vector->element.nfree(&vector->element, vector->data, vector->size);

    // reset size 
    vector->size = 0;
}
tb_void_t tb_vector_copy(tb_vector_ref_t self, tb_vector_ref_t copy)
{
    // check
    tb_vector_t*       vector = (tb_vector_t*)self;
    tb_vector_t const* vector_copy = (tb_vector_t const*)copy;
    tb_assert_and_check_return(vector && vector_copy);

    // check element
    tb_assert_and_check_return(vector->element.type == vector_copy->element.type);
    tb_assert_and_check_return(vector->element.size == vector_copy->element.size);

    // check itor
    tb_assert_and_check_return(vector->itor.step == vector_copy->itor.step);

    // null? clear it
    if (!vector_copy->size) 
    {
        tb_vector_clear(self);
        return ;
    }
    
    // resize if small
    if (vector->size < vector_copy->size) tb_vector_resize(self, vector_copy->size);
    tb_assert_and_check_return(vector->data && vector_copy->data && vector->size >= vector_copy->size);

    // copy data
    if (vector_copy->data != vector->data) tb_memcpy(vector->data, vector_copy->data, vector_copy->size * vector_copy->element.size);

    // copy size
    vector->size = vector_copy->size;
}
tb_pointer_t tb_vector_data(tb_vector_ref_t self)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return_val(vector, tb_null);

    // data
    return vector->data;
}
tb_pointer_t tb_vector_head(tb_vector_ref_t self)
{
    return tb_iterator_item(self, tb_iterator_head(self));
}
tb_pointer_t tb_vector_last(tb_vector_ref_t self)
{
    return tb_iterator_item(self, tb_iterator_last(self));
}
tb_size_t tb_vector_size(tb_vector_ref_t self)
{
    // check
    tb_vector_t const* vector = (tb_vector_t const*)self;
    tb_assert_and_check_return_val(vector, 0);

    // size
    return vector->size;
}
tb_size_t tb_vector_grow(tb_vector_ref_t self)
{
    // check
    tb_vector_t const* vector = (tb_vector_t const*)self;
    tb_assert_and_check_return_val(vector, 0);

    // grow
    return vector->grow;
}
tb_size_t tb_vector_maxn(tb_vector_ref_t self)
{
    // check
    tb_vector_t const* vector = (tb_vector_t const*)self;
    tb_assert_and_check_return_val(vector, 0);

    // maxn
    return vector->maxn;
}
tb_bool_t tb_vector_resize(tb_vector_ref_t self, tb_size_t size)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return_val(vector, tb_false);
    
    // free items if the vector is decreased
    if (size < vector->size)
    {
        // free data
        if (vector->element.nfree) 
            vector->element.nfree(&vector->element, vector->data + size * vector->element.size, vector->size - size);
    }

    // resize buffer
    if (size > vector->maxn)
    {
        tb_size_t maxn = tb_align4(size + vector->grow);
        tb_assert_and_check_return_val(maxn < TB_VECTOR_MAXN, tb_false);

        // realloc data
        vector->data = (tb_byte_t*)tb_ralloc(vector->data, maxn * vector->element.size);
        tb_assert_and_check_return_val(vector->data, tb_false);

        // must be align by 4-bytes
        tb_assert_and_check_return_val(!(((tb_size_t)(vector->data)) & 3), tb_false);

        // clear the grow data
        tb_memset(vector->data + vector->size * vector->element.size, 0, (maxn - vector->maxn) * vector->element.size);

        // save maxn
        vector->maxn = maxn;
    }

    // update size
    vector->size = size;
    return tb_true;
}
tb_void_t tb_vector_insert_prev(tb_vector_ref_t self, tb_size_t itor, tb_cpointer_t data)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && vector->data && vector->element.size && itor <= vector->size);

    // save size
    tb_size_t osize = vector->size;

    // grow a item
    if (!tb_vector_resize(self, osize + 1)) 
    {
        tb_trace_d("vector resize: %u => %u failed", osize, osize + 1);
        return ;
    }

    // move items if not at tail
    if (osize != itor) tb_memmov(vector->data + (itor + 1) * vector->element.size, vector->data + itor * vector->element.size, (osize - itor) * vector->element.size);

    // save data
    vector->element.dupl(&vector->element, vector->data + itor * vector->element.size, data);
}
tb_void_t tb_vector_insert_next(tb_vector_ref_t self, tb_size_t itor, tb_cpointer_t data)
{
    tb_vector_insert_prev(self, tb_iterator_next(self, itor), data);
}
tb_void_t tb_vector_insert_head(tb_vector_ref_t self, tb_cpointer_t data)
{
    tb_vector_insert_prev(self, 0, data);
}
tb_void_t tb_vector_insert_tail(tb_vector_ref_t self, tb_cpointer_t data)
{
    tb_vector_insert_prev(self, tb_vector_size(self), data);
}
tb_void_t tb_vector_ninsert_prev(tb_vector_ref_t self, tb_size_t itor, tb_cpointer_t data, tb_size_t size)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && vector->data && size && itor <= vector->size);

    // save size
    tb_size_t osize = vector->size;

    // grow size
    if (!tb_vector_resize(self, osize + size)) 
    {
        tb_trace_d("vector resize: %u => %u failed", osize, osize + 1);
        return ;
    }

    // move items if not at tail
    if (osize != itor) tb_memmov(vector->data + (itor + size) * vector->element.size, vector->data + itor * vector->element.size, (osize - itor) * vector->element.size);

    // duplicate data
    vector->element.ndupl(&vector->element, vector->data + itor * vector->element.size, data, size);
}
tb_void_t tb_vector_ninsert_next(tb_vector_ref_t self, tb_size_t itor, tb_cpointer_t data, tb_size_t size)
{
    tb_vector_ninsert_prev(self, tb_iterator_next(self, itor), data, size);
}
tb_void_t tb_vector_ninsert_head(tb_vector_ref_t self, tb_cpointer_t data, tb_size_t size)
{
    tb_vector_ninsert_prev(self, 0, data, size);
}
tb_void_t tb_vector_ninsert_tail(tb_vector_ref_t self, tb_cpointer_t data, tb_size_t size)
{
    tb_vector_ninsert_prev(self, tb_vector_size(self), data, size);
}
tb_void_t tb_vector_replace(tb_vector_ref_t self, tb_size_t itor, tb_cpointer_t data)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && vector->data && itor <= vector->size);

    // replace data
    vector->element.repl(&vector->element, vector->data + itor * vector->element.size, data);
}
tb_void_t tb_vector_replace_head(tb_vector_ref_t self, tb_cpointer_t data)
{
    tb_vector_replace(self, 0, data);
}
tb_void_t tb_vector_replace_last(tb_vector_ref_t self, tb_cpointer_t data)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && vector->size);

    // replace
    tb_vector_replace(self, vector->size - 1, data);
}
tb_void_t tb_vector_nreplace(tb_vector_ref_t self, tb_size_t itor, tb_cpointer_t data, tb_size_t size)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && vector->data && vector->size && itor <= vector->size && size);

    // strip size
    if (itor + size > vector->size) size = vector->size - itor;

    // replace data
    vector->element.nrepl(&vector->element, vector->data + itor * vector->element.size, data, size);
}
tb_void_t tb_vector_nreplace_head(tb_vector_ref_t self, tb_cpointer_t data, tb_size_t size)
{
    tb_vector_nreplace(self, 0, data, size);
}
tb_void_t tb_vector_nreplace_last(tb_vector_ref_t self, tb_cpointer_t data, tb_size_t size)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && vector->size && size);

    // replace
    tb_vector_nreplace(self, size >= vector->size? 0 : vector->size - size, data, size);
}
tb_void_t tb_vector_remove(tb_vector_ref_t self, tb_size_t itor)
{   
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && itor < vector->size);

    if (vector->size)
    {
        // do free
        if (vector->element.free) vector->element.free(&vector->element, vector->data + itor * vector->element.size);

        // move data if itor is not last
        if (itor < vector->size - 1) tb_memmov(vector->data + itor * vector->element.size, vector->data + (itor + 1) * vector->element.size, (vector->size - itor - 1) * vector->element.size);

        // resize
        vector->size--;
    }
}
tb_void_t tb_vector_remove_head(tb_vector_ref_t self)
{
    tb_vector_remove(self, 0);
}
tb_void_t tb_vector_remove_last(tb_vector_ref_t self)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector);

    if (vector->size)
    {
        // do free
        if (vector->element.free) vector->element.free(&vector->element, vector->data + (vector->size - 1) * vector->element.size);

        // resize
        vector->size--;
    }
}
tb_void_t tb_vector_nremove(tb_vector_ref_t self, tb_size_t itor, tb_size_t size)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && size && itor < vector->size);

    // clear it
    if (!itor && size >= vector->size) 
    {
        tb_vector_clear(self);
        return ;
    }
    
    // strip size
    if (itor + size > vector->size) size = vector->size - itor;

    // compute the left size
    tb_size_t left = vector->size - itor - size;

    // free data
    if (vector->element.nfree)
        vector->element.nfree(&vector->element, vector->data + itor * vector->element.size, size);

    // move the left data
    if (left)
    {
        tb_byte_t* pd = vector->data + itor * vector->element.size;
        tb_byte_t* ps = vector->data + (itor + size) * vector->element.size;
        tb_memmov(pd, ps, left * vector->element.size);
    }

    // update size
    vector->size -= size;
}
tb_void_t tb_vector_nremove_head(tb_vector_ref_t self, tb_size_t size)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && size);

    // clear it
    if (size >= vector->size)
    {
        tb_vector_clear(self);
        return ;
    }

    // remove head
    tb_vector_nremove(self, 0, size);
}
tb_void_t tb_vector_nremove_last(tb_vector_ref_t self, tb_size_t size)
{   
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector && size);

    // clear it
    if (size >= vector->size)
    {
        tb_vector_clear(self);
        return ;
    }

    // remove last
    tb_vector_nremove(self, vector->size - size, size);
}
#ifdef __tb_debug__
tb_void_t tb_vector_dump(tb_vector_ref_t self)
{
    // check
    tb_vector_t* vector = (tb_vector_t*)self;
    tb_assert_and_check_return(vector);

    // trace
    tb_trace_i("vector: size: %lu", tb_vector_size(self));

    // done
    tb_char_t cstr[4096];
    tb_for_all (tb_pointer_t, data, self)
    {
        // trace
        if (vector->element.cstr) 
        {
            tb_trace_i("    %s", vector->element.cstr(&vector->element, data, cstr, sizeof(cstr)));
        }
        else
        {
            tb_trace_i("    %p", data);
        }
    }
}
#endif
