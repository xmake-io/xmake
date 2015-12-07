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
#ifndef TB_PLATFORM_ARCH_x86_ATOMIC_H
#define TB_PLATFORM_ARCH_x86_ATOMIC_H


/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifdef TB_ASSEMBLER_IS_GAS

#ifndef tb_atomic_fetch_and_set
#   define tb_atomic_fetch_and_set(a, v)        tb_atomic_fetch_and_set_x86(a, v)
#endif

#ifndef tb_atomic_fetch_and_pset
#   define tb_atomic_fetch_and_pset(a, p, v)    tb_atomic_fetch_and_pset_x86(a, p, v)
#endif

#ifndef tb_atomic_fetch_and_add
#   define tb_atomic_fetch_and_add(a, v)        tb_atomic_fetch_and_add_x86(a, v)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * inlines
 */
static __tb_inline__ tb_long_t tb_atomic_fetch_and_set_x86(tb_atomic_t* a, tb_long_t v)
{
    __tb_asm__ __tb_volatile__ 
    (
#if TB_CPU_BITSIZE == 64
        "lock xchgq %0, %1\n"   //!< xchgq v, [a]
#else
        "lock xchgl %0, %1\n"   //!< xchgl v, [a]
#endif

        : "+r" (v) 
        : "m" (*a)
        : "memory"
    );

    return v;
}
static __tb_inline__ tb_long_t tb_atomic_fetch_and_pset_x86(tb_atomic_t* a, tb_long_t p, tb_long_t v)
{
    /*
     * cmpxchgl v, [a]:
     *
     * if (eax == [a]) 
     * {
     *      zf = 1;
     *      [a] = v;
     * } 
     * else 
     * {
     *      zf = 0;
     *      eax = [a];
     * }
     *
     */
    tb_long_t o;
    __tb_asm__ __tb_volatile__ 
    (
#if TB_CPU_BITSIZE == 64
        "lock cmpxchgq  %3, %1  \n"     //!< cmpxchgl v, [a]
#else
        "lock cmpxchgl  %3, %1  \n"     //!< cmpxchgq v, [a]
#endif

        : "=a" (o) 
        : "m" (*a), "a" (p), "r" (v) 
        : "cc", "memory"                //!< "cc" means that flags were changed.
    );

    return o;
}
static __tb_inline__ tb_long_t tb_atomic_fetch_and_add_x86(tb_atomic_t* a, tb_long_t v)
{
    /*
     * xaddl v, [a]:
     *
     * o = [a]
     * [a] += v;
     * v = o;
     *
     * cf, ef, of, sf, zf, pf... maybe changed
     */
    __tb_asm__ __tb_volatile__ 
    (
#if TB_CPU_BITSIZE == 64
        "lock xaddq %0, %1 \n"          //!< xaddq v, [a]
#else
        "lock xaddl %0, %1 \n"          //!< xaddl v, [a]
#endif

        : "+r" (v) 
        : "m" (*a) 
        : "cc", "memory"
    );

    return v;
}


#endif // TB_ASSEMBLER_IS_GAS


#endif
