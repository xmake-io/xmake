/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
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
