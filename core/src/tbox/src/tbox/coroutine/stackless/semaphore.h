/*!The Treasure Box Library
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
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
