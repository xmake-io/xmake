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
 * @file        thread.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_THREAD_H
#define TB_PLATFORM_THREAD_H

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

/*! the thread func type
 *
 * @param priv          the passed private data
 *
 * @return              the return value
 */
typedef tb_int_t        (*tb_thread_func_t)(tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init thread
 *
 * @code
    static tb_int_t tb_demo_thread_func(tb_cpointer_t priv)
    {
        // self
        tb_size_t self = tb_thread_self();

        // trace
        tb_trace_i("thread[%lx: %s]: init", priv, self);

        // exit thread and return failed value: -1
        // tb_thread_return(-1);

        // trace
        tb_trace_i("thread[%lx: %s]: exit", priv, self);

        // ok
        return 0;
    }

    // init thread
    tb_thread_ref_t thread = tb_thread_init(tb_null, tb_demo_thread_func, "hello", 0);
    if (thread)
    {
        // wait thread
        tb_int_t retval = 0;
        if (tb_thread_wait(thread, -1, &retval) > 0)
        {
            // trace
            tb_trace_i("wait: ok, retval: %d", retval);
        }
    
        // exit thread
        tb_thread_exit(thread);
    }
 * @endcode
 *
 * @param name          the thread name, maybe null
 * @param func          the thread func
 * @param priv          the thread func private data
 * @param stack         the thread stack, using the default stack size if be zero 
 *
 * @return              the thread handle
 */
tb_thread_ref_t         tb_thread_init(tb_char_t const* name, tb_thread_func_t func, tb_cpointer_t priv, tb_size_t stack);

/*! exit thread
 *
 * @param thread        the thread 
 */
tb_void_t               tb_thread_exit(tb_thread_ref_t thread);

/*! wait thread
 *
 * @param thread        the thread 
 * @param timeout       the timeout
 * @param retval        the return value pointer of the thread (optional)
 *
 * @return              ok: 1, timeout: 0, error: -1
 */
tb_long_t               tb_thread_wait(tb_thread_ref_t thread, tb_long_t timeout, tb_int_t* retval);

/*! suspend thread
 *
 * @param thread        the thread 
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_thread_suspend(tb_thread_ref_t thread);

/*! resume thread
 *
 * @param thread        the thread 
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_thread_resume(tb_thread_ref_t thread);

/*! the self thread identifier
 *
 * @return              the self thread identifier
 */
tb_size_t               tb_thread_self(tb_noarg_t);

/*! return the thread value
 *
 * @param value         the return value of the thread 
 */
tb_void_t               tb_thread_return(tb_int_t value);

/*! run the given function only once
 *
 * @code
    
    // the once function
    static tb_bool_t tb_thread_once_func(tb_cpointer_t priv)
    {
        // trace
        tb_trace_i("%s", priv);

        // ok
        return tb_true;
    }
 
    // run the once function
    static tb_atomic_t once = 0;
    if (tb_thread_once(&once, tb_thread_once_func, "hello"))
    {
        // ok
        // ...
    }

 * @endcode
 *
 * @param lock          the global or static atomic lock pointer (need be initialized as zero)
 * @param func          the function
 * @param priv          the user private data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_thread_once(tb_atomic_t* lock, tb_bool_t (*func)(tb_cpointer_t), tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
