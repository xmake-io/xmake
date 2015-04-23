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
