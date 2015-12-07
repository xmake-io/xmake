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
 * @file        date.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_DATE_H
#define TB_OBJECT_DATE_H

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

/*! init date reader
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_date_init_reader(tb_noarg_t);

/*! init date writer
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_date_init_writer(tb_noarg_t);

/*! init date from now
 *
 * @return          the date object
 */
tb_object_ref_t     tb_object_date_init_from_now(tb_noarg_t);

/*! init date from time
 *
 * @param           the date time
 *
 * @return          the date object
 */
tb_object_ref_t     tb_object_date_init_from_time(tb_time_t time);

/*! the date time
 *
 * @param           the date object
 *
 * @return          the date time
 */
tb_time_t           tb_object_date_time(tb_object_ref_t date);

/*! set the date time
 *
 * @param           the date object
 * @param           the date time
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_date_time_set(tb_object_ref_t date, tb_time_t time);

/*! set the date time for now
 *
 * @param           the date object
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_date_time_set_now(tb_object_ref_t date);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

