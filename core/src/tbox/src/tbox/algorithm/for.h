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
 * @file        for.h
 * @ingroup     algorithm
 *
 */
#ifndef TB_ALGORITHM_FOR_H
#define TB_ALGORITHM_FOR_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/*! for items using iterator
 *
 * @code
 * tb_for(tb_char_t*, item, tb_iterator_head(iterator), tb_iterator_tail(iterator), iterator)
 * {
 *      tb_trace_d("item: %s", item);
 * }
 *
 * tb_for(tb_size_t, item, tb_iterator_head(iterator), tb_iterator_tail(iterator), iterator)
 * {
 *      tb_trace_d("item: %lu", item);
 * }
 *
 * tb_for(tb_hash_map_item_ref_t, item, tb_iterator_head(iterator), tb_iterator_tail(iterator), iterator)
 * {
 *      if (item) tb_trace_d("item: %p => %p", item->name, item->data);
 * }
 * @endcode
 */
#define tb_for(type, item, head, tail, iterator) \
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
                        item##_itor = tb_iterator_next(item##_iterator, item##_itor))

/*! for all items using iterator
 *
 * @code
 *
 * tb_for_all(tb_char_t*, item, iterator)
 * {
 *      tb_trace_d("item: %s", item);
 * }
 *
 * tb_for_all(tb_size_t, item, iterator)
 * {
 *      tb_trace_d("item: %lu", item);
 * }
 *
 * tb_for_all(tb_hash_map_item_ref_t, item, iterator)
 * {
 *      if (item) tb_trace_d("item: %p => %p", item->name, item->data);
 * }
 * @endcode
 */
#define tb_for_all(type, item, iterator) \
            tb_iterator_ref_t item##_iterator_all = (tb_iterator_ref_t)iterator; \
            tb_for(type, item, tb_iterator_head(item##_iterator_all), tb_iterator_tail(item##_iterator_all), item##_iterator_all)

#endif
