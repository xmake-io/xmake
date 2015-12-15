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
 * @file        boolean.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_BOOLEAN_H
#define TB_OBJECT_BOOLEAN_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init boolean
 *
 * @param value     the value
 *
 * @return          the boolean object
 */
tb_object_ref_t     tb_object_boolean_init(tb_bool_t value);

/*! the boolean value: true
 *
 * @return          the boolean object
 */
tb_object_ref_t     tb_object_boolean_true(tb_noarg_t);

/*! the boolean value: false
 *
 * @return          the boolean object
 */
tb_object_ref_t     tb_object_boolean_false(tb_noarg_t);

/*! the boolean value
 *
 * @param           the boolean object
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_boolean_bool(tb_object_ref_t boolean);


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

