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
 * @file        mutex.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_MUTEX_H
#define TB_PLATFORM_MUTEX_H

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

/*! init mutex
 *
 * @return          the mutex 
 */
tb_mutex_ref_t      tb_mutex_init(tb_noarg_t);

/* exit mutex
 *
 * @param mutex     the mutex 
 */
tb_void_t           tb_mutex_exit(tb_mutex_ref_t mutex);

/* enter mutex
 *
 * @param mutex     the mutex 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_mutex_enter(tb_mutex_ref_t mutex);

/* try to enter mutex
 *
 * @param mutex     the mutex 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_mutex_enter_try(tb_mutex_ref_t mutex);

/* leave mutex
 *
 * @param mutex     the mutex 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_mutex_leave(tb_mutex_ref_t mutex);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
