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
