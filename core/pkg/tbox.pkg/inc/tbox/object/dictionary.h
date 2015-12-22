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
 * @file        dictionary.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_DICTIONARY_H
#define TB_OBJECT_DICTIONARY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define TB_OBJECT_DICTIONARY_SIZE_MICRO                (64)
#define TB_OBJECT_DICTIONARY_SIZE_SMALL                (256)
#define TB_OBJECT_DICTIONARY_SIZE_LARGE                (65536)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the dictionary item type
typedef struct __tb_object_dictionary_item_t
{
    /// the key
    tb_char_t const*        key;

    /// the value
    tb_object_ref_t         val;

}tb_object_dictionary_item_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init dictionary
 *
 * @param size          the dictionary size, using the default size if be zero
 * @param incr          is increase refn?
 *
 * @return              the dictionary object
 */
tb_object_ref_t         tb_object_dictionary_init(tb_size_t size, tb_size_t incr);

/*! the dictionary size
 *
 * @param dictionary    the dictionary object
 *
 * @return              the dictionary size
 */
tb_size_t               tb_object_dictionary_size(tb_object_ref_t dictionary);

/*! set the dictionary incr
 *
 * @param dictionary    the dictionary object
 * @param incr          is increase refn?
 */
tb_void_t               tb_object_dictionary_incr(tb_object_ref_t dictionary, tb_bool_t incr);

/*! the dictionary iterator
 *
 * @param dictionary    the dictionary object
 *
 * @return              the dictionary iterator
 *
 * @code
 * tb_for_all (tb_object_dictionary_item_t*, item, tb_object_dictionary_itor(dictionary))
 * {
 *      if (item)
 *      {
 *          tb_char_t const*    key = item->key;
 *          tb_object_ref_t     val = item->val;
 *
 *          // ...
 *      }
 * }
 * @endcode
 */
tb_iterator_ref_t       tb_object_dictionary_itor(tb_object_ref_t dictionary);

/*! get the dictionary value
 *
 * @param dictionary    the dictionary object
 * @param key           the key
 *
 * @return              the dictionary value
 */
tb_object_ref_t         tb_object_dictionary_value(tb_object_ref_t dictionary, tb_char_t const* key);

/*! insert dictionary item
 *
 * @param dictionary    the dictionary object
 * @param key           the key
 * @param val           the value
 */
tb_void_t               tb_object_dictionary_insert(tb_object_ref_t dictionary, tb_char_t const* key, tb_object_ref_t val);

/*! remove dictionary item
 *
 * @param dictionary    the dictionary object
 * @param key           the key
 */
tb_void_t               tb_object_dictionary_remove(tb_object_ref_t dictionary, tb_char_t const* key);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

