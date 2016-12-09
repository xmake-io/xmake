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
#ifndef TB_COROUTINE_STACKLESS_SEMAPHORE_H
#define TB_COROUTINE_STACKLESS_SEMAPHORE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "coroutine.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/*! init semaphore
 *
 * @param sem           the semaphore pointer
 * @param val           the initial semaphore value
 */
#define tb_lo_semaphore_init(sem, val)      (sem)->value = val

/*! exit semaphore
 * 
 * @param sem           the semaphore pointer
 */
#define tb_lo_semaphore_exit(sem)           (sem)->value = 0

/*! get semaphore value
 * 
 * @param sem           the semaphore pointer
 *
 * @return              the semaphore value
 */
#define tb_lo_semaphore_value(sem)          ((sem)->value)

/*! post semaphore
 * 
 * @param sem           the semaphore pointer
 * @param post          the post semaphore value
 */
#define tb_lo_semaphore_post(sem, post)     \
do \
{ \
    (sem)->value += (post); \
    tb_lo_coroutine_yield(); \
 \
} while (0)

/*! wait semaphore
 * 
 * @param sem           the semaphore pointer
 */
#define tb_lo_semaphore_wait(sem) \
do \
{ \
    tb_lo_coroutine_wait_until((sem)->value > 0); \
    (sem)->value--; \
 \
} while(0)

/*! try to wait semaphore
 * 
 * @param sem           the semaphore pointer
 *
 * @return              tb_true or tb_false
 */
#define tb_lo_semaphore_wait_try(sem)   (((sem)->value > 0)? (sem)->value-- : 0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the stackless semaphore type
typedef struct  __tb_lo_semaphore_t
{
    // the semaphore value
    tb_long_t           value;

}tb_lo_semaphore_t, *tb_lo_semaphore_ref_t;

#endif
