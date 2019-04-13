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
