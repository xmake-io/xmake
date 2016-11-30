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
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
 *
 * @author      ruki
 * @file        dictionary.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_DEPRECATED_DICTIONARY_H
#define TB_OBJECT_DEPRECATED_DICTIONARY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

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
    tb_char_t const*    key;

    /// the value
    tb_object_ref_t     val;

}tb_object_dictionary_item_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
#define tb_object_dictionary_init       tb_oc_dictionary_init
#define tb_object_dictionary_size       tb_oc_dictionary_size
#define tb_object_dictionary_incr       tb_oc_dictionary_incr
#define tb_object_dictionary_itor       tb_oc_dictionary_itor
#define tb_object_dictionary_value      tb_oc_dictionary_value
#define tb_object_dictionary_insert     tb_oc_dictionary_insert
#define tb_object_dictionary_remove     tb_oc_dictionary_remove

#endif

