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
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_ATOMIC_H
#define TB_PLATFORM_ATOMIC_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if defined(TB_CONFIG_OS_WINDOWS)
#   include "windows/atomic.h"
#elif defined(TB_COMPILER_IS_GCC) \
        && defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_4) && __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4
#   include "compiler/gcc/atomic.h"
#endif
#include "arch/atomic.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifndef tb_atomic_fetch_and_pset
#   define tb_atomic_fetch_and_pset(a, p, v)  tb_atomic_fetch_and_pset_generic(a, p, v)
#endif

#ifndef tb_atomic_fetch_and_set
#   define tb_atomic_fetch_and_set(a, v)      tb_atomic_fetch_and_set_generic(a, v)
#endif

#ifndef tb_atomic_fetch_and_add
#   define tb_atomic_fetch_and_add(a, v)      tb_atomic_fetch_and_add_generic(a, v)
#endif

#ifndef tb_atomic_fetch_and_or
#   define tb_atomic_fetch_and_or(a, v)       tb_atomic_fetch_and_or_generic(a, v)
#endif

#ifndef tb_atomic_fetch_and_xor
#   define tb_atomic_fetch_and_xor(a, v)      tb_atomic_fetch_and_xor_generic(a, v)
#endif

#ifndef tb_atomic_fetch_and_and
#   define tb_atomic_fetch_and_and(a, v)      tb_atomic_fetch_and_and_generic(a, v)
#endif

#ifndef tb_atomic_get
#   define tb_atomic_get(a)                   tb_atomic_fetch_and_pset(a, 0, 0)
#endif

#ifndef tb_atomic_set
#   define tb_atomic_set(a, v)                tb_atomic_fetch_and_set(a, v)
#endif

#ifndef tb_atomic_set0
#   define tb_atomic_set0(a)                  tb_atomic_set(a, 0)
#endif

#ifndef tb_atomic_pset
#   define tb_atomic_pset(a, p, v)            tb_atomic_fetch_and_pset(a, p, v)
#endif

#ifndef tb_atomic_fetch_and_set0
#   define tb_atomic_fetch_and_set0(a)        tb_atomic_fetch_and_set(a, 0)
#endif

#ifndef tb_atomic_fetch_and_inc
#   define tb_atomic_fetch_and_inc(a)         tb_atomic_fetch_and_add(a, 1)
#endif

#ifndef tb_atomic_fetch_and_dec
#   define tb_atomic_fetch_and_dec(a)         tb_atomic_fetch_and_add(a, -1)
#endif

#ifndef tb_atomic_fetch_and_sub
#   define tb_atomic_fetch_and_sub(a, v)      tb_atomic_fetch_and_add(a, -(v))
#endif

#ifndef tb_atomic_add_and_fetch
#   define tb_atomic_add_and_fetch(a, v)      (tb_atomic_fetch_and_add(a, v) + (v))
#endif

#ifndef tb_atomic_inc_and_fetch
#   define tb_atomic_inc_and_fetch(a)         tb_atomic_add_and_fetch(a, 1)
#endif

#ifndef tb_atomic_dec_and_fetch
#   define tb_atomic_dec_and_fetch(a)         tb_atomic_add_and_fetch(a, -1)
#endif

#ifndef tb_atomic_sub_and_fetch
#   define tb_atomic_sub_and_fetch(a, v)      tb_atomic_add_and_fetch(a, -(v))
#endif

#ifndef tb_atomic_or_and_fetch
#   define tb_atomic_or_and_fetch(a, v)       (tb_atomic_fetch_and_or(a, v) | (v))
#endif

#ifndef tb_atomic_xor_and_fetch
#   define tb_atomic_xor_and_fetch(a, v)      (tb_atomic_fetch_and_xor(a, v) ^ (v))
#endif

#ifndef tb_atomic_and_and_fetch
#   define tb_atomic_and_and_fetch(a, v)      (tb_atomic_fetch_and_and(a, v) & (v))
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * inlines
 */
static __tb_inline__ tb_long_t tb_atomic_fetch_and_pset_generic(tb_atomic_t* a, tb_long_t p, tb_long_t v)
{
    // FIXME
    // no safe

    // done
    tb_long_t o = *a; if (o == p) *a = v;

    // ok
    return o;
}
static __tb_inline__ tb_long_t tb_atomic_fetch_and_set_generic(tb_atomic_t* a, tb_long_t v)
{
    // done
    tb_long_t o;
    do
    {
        o = *a;

    } while (tb_atomic_fetch_and_pset(a, o, v) != o);

    // ok
    return o;
}
static __tb_inline__ tb_long_t tb_atomic_fetch_and_add_generic(tb_atomic_t* a, tb_long_t v)
{
    // done
    tb_long_t o;
    do
    {
        o = *a;

    } while (tb_atomic_fetch_and_pset(a, o, o + v) != o);

    // ok
    return o;
}
static __tb_inline__ tb_long_t tb_atomic_fetch_and_xor_generic(tb_atomic_t* a, tb_long_t v)
{
    // done
    tb_long_t o;
    do
    {
        o = *a;

    } while (tb_atomic_fetch_and_pset(a, o, o ^ v) != o);

    // ok
    return o;
}
static __tb_inline__ tb_long_t tb_atomic_fetch_and_and_generic(tb_atomic_t* a, tb_long_t v)
{
    // done
    tb_long_t o;
    do
    {
        o = *a;

    } while (tb_atomic_fetch_and_pset(a, o, o & v) != o);

    // ok
    return o;
}
static __tb_inline__ tb_long_t tb_atomic_fetch_and_or_generic(tb_atomic_t* a, tb_long_t v)
{
    // done
    tb_long_t o;
    do
    {
        o = *a;

    } while (tb_atomic_fetch_and_pset(a, o, o | v) != o);

    // ok
    return o;
}


#endif
