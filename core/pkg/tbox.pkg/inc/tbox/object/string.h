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
 * @file        string.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_STRING_H
#define TB_OBJECT_STRING_H

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

/*! init string from c-string
 *
 * @param cstr      the c-string
 *
 * @return          the string object
 */
tb_object_ref_t     tb_object_string_init_from_cstr(tb_char_t const* cstr);

/*! init string from string
 *
 * @param str       the string
 *
 * @return          the string object
 */
tb_object_ref_t     tb_object_string_init_from_str(tb_string_ref_t str);

/*! the c-string
 *
 * @param string    the string object
 *
 * @return          the c-string
 */
tb_char_t const*    tb_object_string_cstr(tb_object_ref_t string);

/*! set the c-string
 *
 * @param string    the string object
 * @param cstr      the c-string
 *
 * @return          the string size
 */
tb_size_t           tb_object_string_cstr_set(tb_object_ref_t string, tb_char_t const* cstr);

/*! the string size
 *
 * @param string    the string object
 *
 * @return          the string size
 */
tb_size_t           tb_object_string_size(tb_object_ref_t string);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

