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
 * @file        atomic64.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "spinlock.h"
#include "atomic64.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the atomic64 lock mac count
#define TB_ATOMIC64_LOCK_MAXN       (16)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the atomic64 lock type
typedef __tb_cacheline_aligned__ struct __tb_atomic64_lock_t
{
    // the lock
    tb_spinlock_t           lock;

    // the padding
    tb_byte_t               padding[TB_L1_CACHE_BYTES];

}__tb_cacheline_aligned__ tb_atomic64_lock_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the locks
static tb_atomic64_lock_t   g_locks[TB_ATOMIC64_LOCK_MAXN] = 
{
    {TB_SPINLOCK_INIT, {0}}
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

static __tb_inline_force__ tb_spinlock_ref_t tb_atomic64_lock(tb_atomic64_t* a)
{
    // trace
    tb_trace1_w("using generic atomic64, maybe slower!");

    // the addr
    tb_size_t addr = (tb_size_t)a;

    // compile the hash value
    addr >>= TB_L1_CACHE_SHIFT;
    addr ^= (addr >> 8) ^ (addr >> 16);

    // the lock
    return &g_locks[addr & (TB_ATOMIC64_LOCK_MAXN - 1)].lock;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_hong_t tb_atomic64_fetch_and_pset_generic(tb_atomic64_t* a, tb_hong_t p, tb_hong_t v)
{
    // the lock
    tb_spinlock_ref_t lock = tb_atomic64_lock(a);

    // enter
    tb_spinlock_enter(lock);

    // set value
    tb_hong_t o = (tb_hong_t)*a; if (o == p) *a = (tb_atomic64_t)v;

    // leave
    tb_spinlock_leave(lock);

    // ok?
    return o;
}
tb_hong_t tb_atomic64_fetch_and_set_generic(tb_atomic64_t* a, tb_hong_t v)
{
    // done
    tb_hong_t o;
    do
    {
        o = *a;

    } while (tb_atomic64_fetch_and_pset(a, o, v) != o);

    // ok
    return o;
}
tb_hong_t tb_atomic64_fetch_and_add_generic(tb_atomic64_t* a, tb_hong_t v)
{
    // done
    tb_hong_t o;
    do
    {
        o = *a;

    } while (tb_atomic64_fetch_and_pset(a, o, o + v) != o);

    // ok
    return o;
}
tb_hong_t tb_atomic64_fetch_and_xor_generic(tb_atomic64_t* a, tb_hong_t v)
{
    // done
    tb_hong_t o;
    do
    {
        o = *a;

    } while (tb_atomic64_fetch_and_pset(a, o, o ^ v) != o);

    // ok
    return o;
}
tb_hong_t tb_atomic64_fetch_and_and_generic(tb_atomic64_t* a, tb_hong_t v)
{
    // done
    tb_hong_t o;
    do
    {
        o = *a;

    } while (tb_atomic64_fetch_and_pset(a, o, o & v) != o);

    // ok
    return o;
}
tb_hong_t tb_atomic64_fetch_and_or_generic(tb_atomic64_t* a, tb_hong_t v)
{
    // done
    tb_hong_t o;
    do
    {
        o = *a;

    } while (tb_atomic64_fetch_and_pset(a, o, o | v) != o);

    // ok
    return o;
}
