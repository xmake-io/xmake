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
 * @file        scheduler.h
 *
 */
#ifndef TB_COROUTINE_IMPL_STACKLESS_SCHEDULER_H
#define TB_COROUTINE_IMPL_STACKLESS_SCHEDULER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "coroutine.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// get the running coroutine
#define tb_lo_scheduler_running(scheduler)             ((scheduler)->running)

// get the ready coroutines count
#define tb_lo_scheduler_ready_count(scheduler)         tb_list_entry_size(&(scheduler)->coroutines_ready)

// get the suspended coroutines count
#define tb_lo_scheduler_suspend_count(scheduler)       tb_list_entry_size(&(scheduler)->coroutines_suspend)

// get the io scheduler
#define tb_lo_scheduler_io(scheduler)                  ((scheduler)->scheduler_io)

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the io scheduler type
struct __tb_lo_scheduler_io_t;

/// the stackless coroutine scheduler type
typedef struct __tb_lo_scheduler_t
{
    // is stopped
    tb_bool_t                       stopped;

    // the running coroutine
    tb_lo_coroutine_t*              running;

    // the io scheduler
    struct __tb_lo_scheduler_io_t*  scheduler_io;

    // the dead coroutines
    tb_list_entry_head_t            coroutines_dead;

    /* the ready coroutines
     * 
     * ready: head -> ready -> .. -> running -> .. -> ready -> ..->
     *         |                                                   |
     *          ---------------------------<-----------------------
     */
    tb_list_entry_head_t            coroutines_ready;

    // the suspend coroutines
    tb_list_entry_head_t            coroutines_suspend;

}tb_lo_scheduler_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* start coroutine 
 *
 * @param scheduler     the scheduler 
 * @param func          the coroutine function
 * @param priv          the passed user private data as the argument of function
 * @param free          the user private data free function
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_lo_scheduler_start(tb_lo_scheduler_t* scheduler, tb_lo_coroutine_func_t func, tb_cpointer_t priv, tb_lo_coroutine_free_t free);

/* resume the given coroutine
 *
 * @param scheduler     the scheduler
 * @param coroutine     the coroutine 
 */
tb_void_t               tb_lo_scheduler_resume(tb_lo_scheduler_t* scheduler, tb_lo_coroutine_t* coroutine);

/* get the current scheduler
 *
 * @return              the scheduler
 */
tb_lo_scheduler_ref_t   tb_lo_scheduler_self_(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
