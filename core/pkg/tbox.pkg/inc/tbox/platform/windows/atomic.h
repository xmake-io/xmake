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
 * @file        atomic.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_ATOMIC_H
#define TB_PLATFORM_WINDOWS_ATOMIC_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#if !defined(tb_atomic_fetch_and_set) && !TB_CPU_BIT64
#   define tb_atomic_fetch_and_set(a, v)        tb_atomic_fetch_and_set_windows(a, v)
#endif

#if !defined(tb_atomic_fetch_and_pset)
#   define tb_atomic_fetch_and_pset(a, p, v)    tb_atomic_fetch_and_pset_windows(a, p, v)
#endif

#if !defined(tb_atomic_fetch_and_add) && !TB_CPU_BIT64
#   define tb_atomic_fetch_and_add(a, v)        tb_atomic_fetch_and_add_windows(a, v)
#endif

#if !defined(tb_atomic_inc_and_fetch) && !TB_CPU_BIT64
#   define tb_atomic_inc_and_fetch(a)           tb_atomic_inc_and_fetch_windows(a)
#endif

#if !defined(tb_atomic_dec_and_fetch) && !TB_CPU_BIT64
#   define tb_atomic_dec_and_fetch(a)           tb_atomic_dec_and_fetch_windows(a)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * inlines
 */
#if TB_CPU_BIT64
static __tb_inline__ tb_long_t tb_atomic_fetch_and_pset_windows(tb_atomic_t* a, tb_long_t p, tb_long_t v)
{
    // check
    tb_assert_static(sizeof(tb_atomic_t) == sizeof(LONGLONG));

    // done
    return (tb_long_t)InterlockedCompareExchange64((LONGLONG __tb_volatile__*)a, v, p);
}
#else
static __tb_inline__ tb_long_t tb_atomic_fetch_and_set_windows(tb_atomic_t* a, tb_long_t v)
{
    return (tb_long_t)InterlockedExchange((LONG __tb_volatile__*)a, v);
}
static __tb_inline__ tb_long_t tb_atomic_fetch_and_pset_windows(tb_atomic_t* a, tb_long_t p, tb_long_t v)
{
    return (tb_long_t)InterlockedCompareExchange((LONG __tb_volatile__*)a, v, p);
}
static __tb_inline__ tb_long_t tb_atomic_fetch_and_add_windows(tb_atomic_t* a, tb_long_t v)
{
    return (tb_long_t)InterlockedExchangeAdd((LONG __tb_volatile__*)a, v);
}
static __tb_inline__ tb_long_t tb_atomic_inc_and_fetch_windows(tb_atomic_t* a)
{
    return (tb_long_t)InterlockedIncrement((LONG __tb_volatile__*)a);
}
static __tb_inline__ tb_long_t tb_atomic_dec_and_fetch_windows(tb_atomic_t* a)
{
    return (tb_long_t)InterlockedDecrement((LONG __tb_volatile__*)a);
}
#endif

#endif
