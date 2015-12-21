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
 * @file        spinlock.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_SPINLOCK_H
#define TB_PLATFORM_SPINLOCK_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "sched.h"
#include "atomic.h"
#include "../utils/lock_profiler.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the initial value
#define TB_SPINLOCK_INIT            (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init spinlock 
 *
 * @param lock      the lock
 *
 * @return          tb_true or tb_false
 */
static __tb_inline_force__ tb_bool_t tb_spinlock_init(tb_spinlock_ref_t lock)
{
    // check
    tb_assert(lock);

    // init 
    *lock = 0;

    // ok
    return tb_true;
}

/*! exit spinlock
 *
 * @param lock      the lock
 */
static __tb_inline_force__ tb_void_t tb_spinlock_exit(tb_spinlock_ref_t lock)
{
    // check
    tb_assert(lock);

    // exit 
    *lock = 0;
}

/*! enter spinlock
 *
 * @param lock      the lock
 */
static __tb_inline_force__ tb_void_t tb_spinlock_enter(tb_spinlock_ref_t lock)
{
    // check
    tb_assert(lock);

    // init tryn
    tb_size_t tryn = 5;
    
    // init occupied
#ifdef TB_LOCK_PROFILER_ENABLE
    tb_bool_t occupied = tb_false;
#endif

    // lock it
    while (tb_atomic_fetch_and_pset((tb_atomic_t*)lock, 0, 1))
    {
#ifdef TB_LOCK_PROFILER_ENABLE
        // occupied
        if (!occupied)
        {
            // occupied++
            occupied = tb_true;
            tb_lock_profiler_occupied(tb_lock_profiler(), (tb_pointer_t)lock);

            // dump backtrace
#if 0//def __tb_debug__
            tb_backtrace_dump("spinlock", tb_null, 10);
#endif
        }
#endif

        // yield the processor
        if (!tryn--)
        {
            // yield
            tb_sched_yield();
//          tb_usleep(1);

            // reset tryn
            tryn = 5;
        }
    }
}

/*! enter spinlock without the lock profiler
 *
 * @param lock      the lock
 */
static __tb_inline_force__ tb_void_t tb_spinlock_enter_without_profiler(tb_spinlock_ref_t lock)
{
    // check
    tb_assert(lock);

    // init tryn
    tb_size_t tryn = 5;
    
    // lock it
    while (tb_atomic_fetch_and_pset((tb_atomic_t*)lock, 0, 1))
    {
        // yield the processor
        if (!tryn--)
        {
            // yield
            tb_sched_yield();
//          tb_usleep(1);

            // reset tryn
            tryn = 5;
        }
    }
}

/*! try to enter spinlock
 *
 * @param lock      the lock
 *
 * @return          tb_true or tb_false
 */
static __tb_inline_force__ tb_bool_t tb_spinlock_enter_try(tb_spinlock_ref_t lock)
{
    // check
    tb_assert(lock);

#ifndef TB_LOCK_PROFILER_ENABLE
    // try locking it
    return !tb_atomic_fetch_and_pset((tb_atomic_t*)lock, 0, 1);
#else
    // try locking it
    tb_bool_t ok = !tb_atomic_fetch_and_pset((tb_atomic_t*)lock, 0, 1);

    // occupied?
    if (!ok) tb_lock_profiler_occupied(tb_lock_profiler(), (tb_pointer_t)lock);

    // ok?
    return ok;
#endif
}

/*! try to enter spinlock without the lock profiler
 *
 * @param lock      the lock
 *
 * @return          tb_true or tb_false
 */
static __tb_inline_force__ tb_bool_t tb_spinlock_enter_try_without_profiler(tb_spinlock_ref_t lock)
{
    // check
    tb_assert(lock);

    // try locking it
    return !tb_atomic_fetch_and_pset((tb_atomic_t*)lock, 0, 1);
}

/*! leave spinlock
 *
 * @param lock      the lock
 */
static __tb_inline_force__ tb_void_t tb_spinlock_leave(tb_spinlock_ref_t lock)
{
    // check
    tb_assert(lock);

    // leave
    *((tb_atomic_t*)lock) = 0;
}

#endif
