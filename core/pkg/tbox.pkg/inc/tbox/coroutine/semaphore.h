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
 * @file        semaphore.h
 * @ingroup     coroutine
 *
 */
#ifndef TB_COROUTINE_SEMAPHORE_H
#define TB_COROUTINE_SEMAPHORE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the coroutine semaphore ref type
typedef __tb_typeref__(co_semaphore);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init semaphore
 *
 * @param value         the initial semaphore value
 * 
 * @return              the semaphore 
 */
tb_co_semaphore_ref_t   tb_co_semaphore_init(tb_size_t value);

/*! exit semaphore
 * 
 * @return              the semaphore 
 */
tb_void_t               tb_co_semaphore_exit(tb_co_semaphore_ref_t semaphore);

/*! post semaphore
 * 
 * @param semaphore     the semaphore 
 * @param post          the post semaphore value
 *
 * @return              tb_true or tb_false
 */
tb_void_t               tb_co_semaphore_post(tb_co_semaphore_ref_t semaphore, tb_size_t post);

/*! the semaphore value
 * 
 * @param semaphore     the semaphore 
 *
 * @return              the semaphore value
 */
tb_size_t               tb_co_semaphore_value(tb_co_semaphore_ref_t semaphore);

/*! wait semaphore
 * 
 * @param semaphore     the semaphore 
 * @param timeout       the timeout
 *
 * @return              ok: 1, timeout: 0, fail: -1
 */
tb_long_t               tb_co_semaphore_wait(tb_co_semaphore_ref_t semaphore, tb_long_t timeout);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
