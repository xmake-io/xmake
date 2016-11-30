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
 * @file        string.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_DEPRECATED_STRING_H
#define TB_OBJECT_DEPRECATED_STRING_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

#define tb_object_string_init_from_cstr tb_oc_string_init_from_cstr
#define tb_object_string_init_from_str  tb_oc_string_init_from_str
#define tb_object_string_cstr           tb_oc_string_cstr
#define tb_object_string_cstr_set       tb_oc_string_cstr_set
#define tb_object_string_size           tb_oc_string_size

#endif

