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
 * @file        array_iterator.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_ARRAY_ITERATOR_H
#define TB_CONTAINER_ARRAY_ITERATOR_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the array iterator type
typedef struct __tb_array_iterator_t
{
    /// the iterator base
    tb_iterator_t           base;

    /// the items
    tb_pointer_t            items;

    /// the items count
    tb_size_t               count;

}tb_array_iterator_t, *tb_array_iterator_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init array iterator for pointer element
 * 
 * @param iterator  the array iterator
 * @param items     the items
 * @param count     the count
 *
 * @return          the iterator
 */
tb_iterator_ref_t   tb_array_iterator_init_ptr(tb_array_iterator_ref_t iterator, tb_pointer_t* items, tb_size_t count);

/*! init array iterator for memory element
 * 
 * @param iterator  the array iterator
 * @param items     the items
 * @param count     the count
 * @param size      the element size
 *
 * @return          the iterator
 */
tb_iterator_ref_t   tb_array_iterator_init_mem(tb_array_iterator_ref_t iterator, tb_pointer_t items, tb_size_t count, tb_size_t size);

/*! init array iterator for c-string element
 * 
 * @param iterator  the array iterator
 * @param items     the items
 * @param count     the count
 *
 * @return          the iterator
 */
tb_iterator_ref_t   tb_array_iterator_init_str(tb_array_iterator_ref_t iterator, tb_char_t** items, tb_size_t count);

/*! init array iterator for c-string element and ignore case
 * 
 * @param iterator  the array iterator
 * @param items     the items
 * @param count     the count
 *
 * @return          the iterator
 */
tb_iterator_ref_t   tb_array_iterator_init_istr(tb_array_iterator_ref_t iterator, tb_char_t** items, tb_size_t count);

/*! init array iterator for long element
 * 
 * @param iterator  the array iterator
 * @param items     the items
 * @param count     the count
 *
 * @return          the iterator
 */
tb_iterator_ref_t   tb_array_iterator_init_long(tb_array_iterator_ref_t iterator, tb_long_t* items, tb_size_t count);

/*! init array iterator for size element
 * 
 * @param iterator  the array iterator
 * @param items     the items
 * @param count     the count
 *
 * @return          the iterator
 */
tb_iterator_ref_t   tb_array_iterator_init_size(tb_array_iterator_ref_t iterator, tb_size_t* items, tb_size_t count);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
