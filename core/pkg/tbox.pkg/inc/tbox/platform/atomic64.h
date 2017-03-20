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
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        atomic64.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_ATOMIC64_H
#define TB_PLATFORM_ATOMIC64_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "atomic.h"
#if !TB_CPU_BIT64
#   if defined(TB_CONFIG_OS_WINDOWS)
#       include "windows/atomic64.h"
#   elif defined(TB_COMPILER_IS_GCC) \
        && defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_8) && __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8
#       include "compiler/gcc/atomic64.h"
#   endif
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#if TB_CPU_BIT64

#   define tb_atomic64_get(a)                   tb_atomic_get(a)
#   define tb_atomic64_set(a, v)                tb_atomic_set(a, v)
#   define tb_atomic64_set0(a)                  tb_atomic_set0(a)
#   define tb_atomic64_pset(a, p, v)            tb_atomic_pset(a, p, v)
#   define tb_atomic64_fetch_and_set0(a)        tb_atomic_fetch_and_set0(a)
#   define tb_atomic64_fetch_and_set(a, v)      tb_atomic_fetch_and_set(a, v)
#   define tb_atomic64_fetch_and_pset(a, p, v)  tb_atomic_fetch_and_pset(a, p, v)

#   define tb_atomic64_fetch_and_inc(a)         tb_atomic_fetch_and_inc(a)
#   define tb_atomic64_fetch_and_dec(a)         tb_atomic_fetch_and_dec(a)
#   define tb_atomic64_fetch_and_add(a, v)      tb_atomic_fetch_and_add(a, v)
#   define tb_atomic64_fetch_and_sub(a, v)      tb_atomic_fetch_and_sub(a, v)
#   define tb_atomic64_fetch_and_or(a, v)       tb_atomic_fetch_and_or(a, v)
#   define tb_atomic64_fetch_and_xor(a, v)      tb_atomic_fetch_and_xor(a, v)
#   define tb_atomic64_fetch_and_and(a, v)      tb_atomic_fetch_and_and(a, v)

#   define tb_atomic64_inc_and_fetch(a)         tb_atomic_inc_and_fetch(a)
#   define tb_atomic64_dec_and_fetch(a)         tb_atomic_dec_and_fetch(a)
#   define tb_atomic64_add_and_fetch(a, v)      tb_atomic_add_and_fetch(a, v)
#   define tb_atomic64_sub_and_fetch(a, v)      tb_atomic_sub_and_fetch(a, v)
#   define tb_atomic64_or_and_fetch(a, v)       tb_atomic_or_and_fetch(a, v)
#   define tb_atomic64_xor_and_fetch(a, v)      tb_atomic_xor_and_fetch(a, v)
#   define tb_atomic64_and_and_fetch(a, v)      tb_atomic_and_and_fetch(a, v)

#endif

#ifndef tb_atomic64_fetch_and_pset
#   define tb_atomic64_fetch_and_pset(a, p, v)  tb_atomic64_fetch_and_pset_generic(a, p, v)
#endif

#ifndef tb_atomic64_fetch_and_set
#   define tb_atomic64_fetch_and_set(a, v)      tb_atomic64_fetch_and_set_generic(a, v)
#endif

#ifndef tb_atomic64_fetch_and_add
#   define tb_atomic64_fetch_and_add(a, v)      tb_atomic64_fetch_and_add_generic(a, v)
#endif

#ifndef tb_atomic64_fetch_and_or
#   define tb_atomic64_fetch_and_or(a, v)       tb_atomic64_fetch_and_or_generic(a, v)
#endif

#ifndef tb_atomic64_fetch_and_xor
#   define tb_atomic64_fetch_and_xor(a, v)      tb_atomic64_fetch_and_xor_generic(a, v)
#endif

#ifndef tb_atomic64_fetch_and_and
#   define tb_atomic64_fetch_and_and(a, v)      tb_atomic64_fetch_and_and_generic(a, v)
#endif

#ifndef tb_atomic64_get
#   define tb_atomic64_get(a)                   tb_atomic64_fetch_and_pset(a, 0, 0)
#endif

#ifndef tb_atomic64_set
#   define tb_atomic64_set(a, v)                tb_atomic64_fetch_and_set(a, v)
#endif

#ifndef tb_atomic64_set0
#   define tb_atomic64_set0(a)                  tb_atomic64_set(a, 0)
#endif

#ifndef tb_atomic64_pset
#   define tb_atomic64_pset(a, p, v)            tb_atomic64_fetch_and_pset(a, p, v)
#endif

#ifndef tb_atomic64_fetch_and_set0
#   define tb_atomic64_fetch_and_set0(a)        tb_atomic64_fetch_and_set(a, 0)
#endif

#ifndef tb_atomic64_fetch_and_inc
#   define tb_atomic64_fetch_and_inc(a)         tb_atomic64_fetch_and_add(a, 1)
#endif

#ifndef tb_atomic64_fetch_and_dec
#   define tb_atomic64_fetch_and_dec(a)         tb_atomic64_fetch_and_add(a, -1)
#endif

#ifndef tb_atomic64_fetch_and_sub
#   define tb_atomic64_fetch_and_sub(a, v)      tb_atomic64_fetch_and_add(a, -(v))
#endif

#ifndef tb_atomic64_add_and_fetch
#   define tb_atomic64_add_and_fetch(a, v)      (tb_atomic64_fetch_and_add(a, v) + (v))
#endif

#ifndef tb_atomic64_inc_and_fetch
#   define tb_atomic64_inc_and_fetch(a)         tb_atomic64_add_and_fetch(a, 1)
#endif

#ifndef tb_atomic64_dec_and_fetch
#   define tb_atomic64_dec_and_fetch(a)         tb_atomic64_add_and_fetch(a, -1)
#endif

#ifndef tb_atomic64_sub_and_fetch
#   define tb_atomic64_sub_and_fetch(a, v)      tb_atomic64_add_and_fetch(a, -(v))
#endif

#ifndef tb_atomic64_or_and_fetch
#   define tb_atomic64_or_and_fetch(a, v)       (tb_atomic64_fetch_and_or(a, v) | (v))
#endif

#ifndef tb_atomic64_xor_and_fetch
#   define tb_atomic64_xor_and_fetch(a, v)      (tb_atomic64_fetch_and_xor(a, v) ^ (v))
#endif

#ifndef tb_atomic64_and_and_fetch
#   define tb_atomic64_and_and_fetch(a, v)      (tb_atomic64_fetch_and_and(a, v) & (v))
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* fetch and set the 64bits value 
 *
 * @param a                     the atomic value
 * @param v                     the assigned value
 *
 * @return                      the old value
 */
tb_hong_t                       tb_atomic64_fetch_and_set_generic(tb_atomic64_t* a, tb_hong_t v);

/* fetch and set the 64bits value if old_value == p
 *
 * @param a                     the atomic value
 * @param p                     the compared value
 * @param v                     the assigned value
 *
 * @return                      the old value
 */
tb_hong_t                       tb_atomic64_fetch_and_pset_generic(tb_atomic64_t* a, tb_hong_t p, tb_hong_t v);

/* fetch and add the 64bits value 
 *
 * @param a                     the atomic value
 * @param v                     the added value
 *
 * @return                      the old value
 */
tb_hong_t                       tb_atomic64_fetch_and_add_generic(tb_atomic64_t* a, tb_hong_t v);

/* fetch and xor the 64bits value 
 *
 * @param a                     the atomic value
 * @param v                     the xor-value
 *
 * @return                      the old value
 */
tb_hong_t                       tb_atomic64_fetch_and_xor_generic(tb_atomic64_t* a, tb_hong_t v);

/* fetch and and the 64bits value 
 *
 * @param a                     the atomic value
 * @param v                     the and-value
 *
 * @return                      the old value
 */
tb_hong_t                       tb_atomic64_fetch_and_and_generic(tb_atomic64_t* a, tb_hong_t v);

/* fetch and or the 64bits value 
 *
 * @param a                     the atomic value
 * @param v                     the or-value
 *
 * @return                      the old value
 */
tb_hong_t                       tb_atomic64_fetch_and_or_generic(tb_atomic64_t* a, tb_hong_t v);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
