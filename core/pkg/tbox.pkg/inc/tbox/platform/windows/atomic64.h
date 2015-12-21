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
 * @file        atomic64.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_ATOMIC64_H
#define TB_PLATFORM_WINDOWS_ATOMIC64_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "interface/interface.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#if !defined(tb_atomic64_fetch_and_pset)
#   define tb_atomic64_fetch_and_pset(a, p, v)      tb_atomic64_fetch_and_pset_windows(a, p, v)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */
tb_hong_t tb_atomic64_fetch_and_pset_generic(tb_atomic64_t* a, tb_hong_t p, tb_hong_t v);

/* //////////////////////////////////////////////////////////////////////////////////////
 * inlines
 */

/* fetch and set the 64bits value if old_value == p
 *
 * @param a                     the atomic value
 * @param p                     the compared value
 * @param v                     the assigned value
 *
 * @return                      the old value
 */
static __tb_inline__ tb_hong_t  tb_atomic64_fetch_and_pset_windows(tb_atomic64_t* a, tb_hong_t p, tb_hong_t v)
{
    // the InterlockedCompareExchange64 func
    tb_kernel32_InterlockedCompareExchange64_t pInterlockedCompareExchange64 = tb_kernel32()->InterlockedCompareExchange64;

    // done
    if (pInterlockedCompareExchange64) return (tb_hong_t)pInterlockedCompareExchange64((LONGLONG __tb_volatile__*)a, v, p);

    // using the generic implementation
    return tb_atomic64_fetch_and_pset_generic(a, p, v);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
