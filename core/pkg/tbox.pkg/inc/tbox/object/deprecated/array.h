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
 * @file        array.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_DEPRECATED_ARRAY_H
#define TB_OBJECT_DEPRECATED_ARRAY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

#define tb_object_array_init    tb_oc_array_init
#define tb_object_array_size    tb_oc_array_size
#define tb_object_array_item    tb_oc_array_item
#define tb_object_array_incr    tb_oc_array_incr
#define tb_object_array_itor    tb_oc_array_itor
#define tb_object_array_remove  tb_oc_array_remove
#define tb_object_array_append  tb_oc_array_append
#define tb_object_array_insert  tb_oc_array_insert
#define tb_object_array_replace tb_oc_array_replace

#endif

