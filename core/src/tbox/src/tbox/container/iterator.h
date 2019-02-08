/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
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
 * @file        iterator.h
 * @ingroup     container
 *
 */
#ifndef TB_CONTAINER_ITERATOR_H
#define TB_CONTAINER_ITERATOR_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the iterator mode type
typedef enum __tb_iterator_mode_t
{
    TB_ITERATOR_MODE_FORWARD        = 1     //!< forward iterator
,   TB_ITERATOR_MODE_REVERSE        = 2     //!< reverse iterator
,   TB_ITERATOR_MODE_RACCESS        = 4     //!< random access iterator
,   TB_ITERATOR_MODE_MUTABLE        = 8     //!< mutable iterator, the item of the same iterator is mutable for removing and moving, .e.g vector, hash, ...
,   TB_ITERATOR_MODE_READONLY       = 16    //!< readonly iterator

}tb_iterator_mode_t;

/// the iterator operation type
struct __tb_iterator_t;
typedef struct __tb_iterator_op_t
{
    /// the iterator size
    tb_size_t               (*size)(struct __tb_iterator_t* iterator);

    /// the iterator head
    tb_size_t               (*head)(struct __tb_iterator_t* iterator);

    /// the iterator last
    tb_size_t               (*last)(struct __tb_iterator_t* iterator);

    /// the iterator tail
    tb_size_t               (*tail)(struct __tb_iterator_t* iterator);

    /// the iterator prev
    tb_size_t               (*prev)(struct __tb_iterator_t* iterator, tb_size_t itor);

    /// the iterator next
    tb_size_t               (*next)(struct __tb_iterator_t* iterator, tb_size_t itor);

    /// the iterator item
    tb_pointer_t            (*item)(struct __tb_iterator_t* iterator, tb_size_t itor);

    /// the iterator comp
    tb_long_t               (*comp)(struct __tb_iterator_t* iterator, tb_cpointer_t litem, tb_cpointer_t ritem);

    /// the iterator copy
    tb_void_t               (*copy)(struct __tb_iterator_t* iterator, tb_size_t itor, tb_cpointer_t item);

    /// the iterator remove
    tb_void_t               (*remove)(struct __tb_iterator_t* iterator, tb_size_t itor);

    /// the iterator nremove 
    tb_void_t               (*nremove)(struct __tb_iterator_t* iterator, tb_size_t prev, tb_size_t next, tb_size_t size);

}tb_iterator_op_t;

/// the iterator operation ref type
typedef tb_iterator_op_t const* tb_iterator_op_ref_t;

/// the iterator type
typedef struct __tb_iterator_t
{
    /// the iterator mode
    tb_size_t               mode;

    /// the iterator step
    tb_size_t               step;

    /// the iterator priv
    tb_pointer_t            priv;

    /// the iterator operation
    tb_iterator_op_ref_t    op;

}tb_iterator_t, *tb_iterator_ref_t;

/// the iterator comp func type
typedef tb_long_t           (*tb_iterator_comp_t)(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the iterator mode
 * 
 * @param iterator  the iterator
 *
 * @return          the iterator mode
 */
tb_size_t           tb_iterator_mode(tb_iterator_ref_t iterator);

/*! the iterator step
 * 
 * @param iterator  the iterator
 *
 * @return          the iterator step
 */
tb_size_t           tb_iterator_step(tb_iterator_ref_t iterator);

/*! the iterator size
 * 
 * @param iterator  the iterator
 *
 * @return          the iterator size
 */
tb_size_t           tb_iterator_size(tb_iterator_ref_t iterator);

/*! the iterator head
 * 
 * @param iterator  the iterator
 *
 * @return          the iterator head
 */
tb_size_t           tb_iterator_head(tb_iterator_ref_t iterator);

/*! the iterator last
 * 
 * @param iterator  the iterator
 *
 * @return          the iterator last
 */
tb_size_t           tb_iterator_last(tb_iterator_ref_t iterator);

/*! the iterator tail
 * 
 * @param iterator  the iterator
 *
 * @return          the iterator tail
 */
tb_size_t           tb_iterator_tail(tb_iterator_ref_t iterator);

/*! the iterator prev
 * 
 * @param iterator  the iterator
 * @param itor      the item itor
 *
 * @return          the iterator prev
 */
tb_size_t           tb_iterator_prev(tb_iterator_ref_t iterator, tb_size_t itor);

/*! the iterator next
 * 
 * @param iterator  the iterator
 * @param itor      the item itor
 *
 * @return          the iterator next
 */
tb_size_t           tb_iterator_next(tb_iterator_ref_t iterator, tb_size_t itor);

/*! the iterator item
 * 
 * @param iterator  the iterator
 * @param itor      the item itor
 *
 * @return          the iterator item
 */
tb_pointer_t        tb_iterator_item(tb_iterator_ref_t iterator, tb_size_t itor);

/*! remove the iterator item
 * 
 * @param iterator  the iterator
 * @param itor      the item itor
 */
tb_void_t           tb_iterator_remove(tb_iterator_ref_t iterator, tb_size_t itor);

/*! remove the iterator items from range(prev, next)
 * 
 * @param iterator  the iterator
 * @param prev      the prev item
 * @param next      the next item
 * @param size      the removed size
 */
tb_void_t           tb_iterator_nremove(tb_iterator_ref_t iterator, tb_size_t prev, tb_size_t next, tb_size_t size);

/*! copy the iterator item
 * 
 * @param iterator  the iterator
 * @param itor      the item itor
 * @param item      the copied item
 */
tb_void_t           tb_iterator_copy(tb_iterator_ref_t iterator, tb_size_t itor, tb_cpointer_t item);

/*! compare the iterator item
 * 
 * @param iterator  the iterator
 * @param itor      the item 
 * @param item      the compared item 
 *
 * @return          =: 0, >: 1, <: -1
 */
tb_long_t           tb_iterator_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
