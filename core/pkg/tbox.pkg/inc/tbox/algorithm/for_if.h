/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        for_if.h
 * @ingroup     algorithm
 *
 */
#ifndef TB_ALGORITHM_FOR_IF_H
#define TB_ALGORITHM_FOR_IF_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/*! for items using iterator if the condition ok
 *
 * @code
 * tb_for_if(tb_char_t*, item, tb_iterator_head(iterator), tb_iterator_tail(iterator), iterator, item)
 * {
 *      tb_trace_d("item: %s", item);
 * }
 *
 * tb_for_if(tb_size_t, item, tb_iterator_head(iterator), tb_iterator_tail(iterator), iterator, item > 10)
 * {
 *      tb_trace_d("item: %lu", item);
 * }
 *
 * tb_for_if(tb_hash_map_item_ref_t, item, tb_iterator_head(iterator), tb_iterator_tail(iterator), iterator, item != tb_null)
 * {
 *      tb_trace_d("item: %p => %p", item->name, item->data);
 * }
 * @endcode
 */
#define tb_for_if(type, item, head, tail, iterator, cond) \
            /* iterator */ \
            tb_iterator_ref_t item##_iterator = (tb_iterator_ref_t)iterator; \
            tb_assert(!item##_iterator || (tb_iterator_mode(item##_iterator) & (TB_ITERATOR_MODE_FORWARD | TB_ITERATOR_MODE_RACCESS))); \
            /* init */ \
            type item; \
            tb_size_t item##_itor = head; \
            tb_size_t item##_head = head; \
            tb_size_t item##_tail = tail; \
            /* walk */ \
            if (item##_iterator && item##_head != item##_tail) \
                for (   ; \
                        item##_itor != item##_tail && ((item = (type)tb_iterator_item(item##_iterator, item##_itor)), 1); \
                        item##_itor = tb_iterator_next(item##_iterator, item##_itor)) if ((cond))

/*! for all items using iterator if the condition ok
 *
 * @code
 *
 * tb_for_all_if(tb_char_t*, item, iterator, item)
 * {
 *      tb_trace_d("item: %s", item);
 * }
 *
 * tb_for_all_if(tb_size_t, item, iterator, item > 10)
 * {
 *      tb_trace_d("item: %lu", item);
 * }
 *
 * tb_for_all_if(tb_hash_map_item_ref_t, item, iterator, item != tb_null)
 * {
 *      if (item) tb_trace_d("item: %p => %p", item->name, item->data);
 * }
 * @endcode
 */
#define tb_for_all_if(type, item, iterator, cond) \
            tb_iterator_ref_t item##_iterator_all = (tb_iterator_ref_t)iterator; \
            tb_for_if(type, item, tb_iterator_head(item##_iterator_all), tb_iterator_tail(item##_iterator_all), item##_iterator_all, cond)

#endif
