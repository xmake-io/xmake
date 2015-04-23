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
 * @file        timer.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_TIMER_H
#define TB_PLATFORM_TIMER_H

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

/*! the timer task func type
 *
 * @param killed    is killed?
 * @param data      the timer data
 */
typedef tb_void_t   (*tb_timer_task_func_t)(tb_bool_t killed, tb_cpointer_t priv);

/// the timer ref type
typedef struct{}*   tb_timer_ref_t;

/// the timer task ref type
typedef struct{}*   tb_timer_task_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init timer
 *
 * lower tick and limit range, but faster
 * 
 * @param maxn      the timer maxn
 * @param ctime     using ctime?
 *
 * @return          the timer
 */
tb_timer_ref_t      tb_timer_init(tb_size_t maxn, tb_bool_t ctime);

/*! exit timer
 *
 * @param timer     the timer 
 */
tb_void_t           tb_timer_exit(tb_timer_ref_t timer);

/*! clear timer
 *
 * @param timer     the timer 
 */
tb_void_t           tb_timer_clear(tb_timer_ref_t timer);

/*! the timer delay for spak 
 *
 * @param timer     the timer 
 *
 * @return          the timer delay, (tb_size_t)-1: error or no task
 */
tb_size_t           tb_timer_delay(tb_timer_ref_t timer);

/*! the timer top when
 *
 * @param timer     the timer 
 *
 * @return          the top when, -1: no task
 */
tb_hize_t           tb_timer_top(tb_timer_ref_t timer);

/*! spak timer for the external loop at the single thread
 *
 * @code
 * tb_void_t tb_timer_loop()
 * {
 *      while (1)
 *      {
 *          // wait
 *          wait(tb_timer_delay(timer))
 *
 *          // spak timer
 *          tb_timer_spak(timer);
 *      }
 * }
 * @endcode
 *
 * @param timer     the timer 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_timer_spak(tb_timer_ref_t timer);

/*! loop timer for the external thread
 *
 * @code
 * tb_void_t tb_timer_thread(tb_cpointer_t priv)
 * {
 *      tb_timer_loop(timer);
 * }
 * @endcode
 *
 * @param timer     the timer 
 *
 * @return          tb_true or tb_false
 */
tb_void_t           tb_timer_loop(tb_timer_ref_t timer);

/*! post timer task after delay and will be auto-remove it after be expired
 *
 * @param timer     the timer 
 * @param delay     the delay time, ms
 * @param repeat    is repeat?
 * @param func      the timer func
 * @param priv      the timer priv
 *
 */
tb_void_t           tb_timer_task_post(tb_timer_ref_t timer, tb_size_t delay, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv);

/*! post timer task at the absolute time and will be auto-remove it after be expired
 *
 * @param timer     the timer 
 * @param when      the absolute time, ms
 * @param period    the period time, ms
 * @param repeat    is repeat?
 * @param func      the timer func
 * @param priv      the timer priv
 *
 */
tb_void_t           tb_timer_task_post_at(tb_timer_ref_t timer, tb_hize_t when, tb_size_t period, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv);

/*! post timer task after the relative time and will be auto-remove it after be expired
 *
 * @param timer     the timer 
 * @param after     the after time, ms
 * @param period    the period time, ms
 * @param repeat    is repeat?
 * @param func      the timer func
 * @param priv      the timer priv
 *
 */
tb_void_t           tb_timer_task_post_after(tb_timer_ref_t timer, tb_hize_t after, tb_size_t period, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv);

/*! init and post timer task after delay and need remove it manually
 *
 * @param timer     the timer 
 * @param delay     the delay time, ms
 * @param repeat    is repeat?
 * @param func      the timer func
 * @param priv      the timer priv
 *
 * @return          the timer task
 */
tb_timer_task_ref_t tb_timer_task_init(tb_timer_ref_t timer, tb_size_t delay, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv);

/*! init and post timer task at the absolute time and need remove it manually
 *
 * @param timer     the timer 
 * @param when      the absolute time, ms
 * @param period    the period time, ms
 * @param repeat    is repeat?
 * @param func      the timer func
 * @param priv      the timer priv
 *
 * @return          the timer task
 */
tb_timer_task_ref_t tb_timer_task_init_at(tb_timer_ref_t timer, tb_hize_t when, tb_size_t period, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv);

/*! init and post timer task after the relative time and need remove it manually
 *
 * @param timer     the timer 
 * @param after     the after time, ms
 * @param period    the period time, ms
 * @param repeat    is repeat?
 * @param func      the timer func
 * @param priv      the timer priv
 *
 * @return          the timer task
 */
tb_timer_task_ref_t tb_timer_task_init_after(tb_timer_ref_t timer, tb_hize_t after, tb_size_t period, tb_bool_t repeat, tb_timer_task_func_t func, tb_cpointer_t priv);

/*! exit timer task, the task will be not called if have been not called
 *
 * @param timer     the timer 
 * @param task      the timer task
 */
tb_void_t           tb_timer_task_exit(tb_timer_ref_t timer, tb_timer_task_ref_t task);

/*! kill timer task, the task will be called immediately if have been not called
 *
 * @param timer     the timer 
 * @param task      the timer task
 */
tb_void_t           tb_timer_task_kill(tb_timer_ref_t timer, tb_timer_task_ref_t task);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
