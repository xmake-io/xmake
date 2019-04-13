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
 * @file        exception.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_LIBC_EXCEPTION_H
#define TB_PLATFORM_LIBC_EXCEPTION_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../thread_local.h"
#include "../../libc/misc/setjmp.h"
#include "../../container/container.h"
#ifdef TB_CONFIG_LIBC_HAVE_KILL
#   include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
extern tb_thread_local_t g_exception_local;

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#if defined(tb_sigsetjmp) && defined(tb_siglongjmp)

    // try
#   define __tb_try \
    do \
    { \
        /* init exception stack */ \
        tb_stack_ref_t __stack = tb_null; \
        if (!(__stack = (tb_stack_ref_t)tb_thread_local_get(&g_exception_local))) \
        { \
            tb_stack_ref_t __stack_new = tb_stack_init(16, tb_element_mem(sizeof(tb_sigjmpbuf_t), tb_null, tb_null)); \
            if (__stack_new && tb_thread_local_set(&g_exception_local, __stack_new)) \
                __stack = __stack_new; \
            else if (__stack_new) \
                tb_stack_exit(__stack_new); \
        } \
        \
        /* push jmpbuf */ \
        tb_sigjmpbuf_t* __top = tb_null; \
        if (__stack) \
        { \
            tb_sigjmpbuf_t __buf; \
            tb_stack_put(__stack, &__buf); \
            __top = (tb_sigjmpbuf_t*)tb_stack_top(__stack); \
        } \
        \
        /* init jmpbuf and save sigmask */ \
        __tb_volatile__ tb_int_t __j = __top? tb_sigsetjmp(*__top, 1) : 0; \
        /* done try */ \
        if (!__j) \
        {

    // except
#   define __tb_except(x) \
        } \
        \
        /* check */ \
        tb_assert(x >= 0); \
        /* pop the jmpbuf */ \
        if (__stack) tb_stack_pop(__stack); \
        /* do not this catch? */ \
        if (__j && !(x)) \
        { \
            /* goto the top exception stack */ \
            if (__stack && tb_stack_size(__stack)) \
            { \
                tb_sigjmpbuf_t* jmpbuf = (tb_sigjmpbuf_t*)tb_stack_top(__stack); \
                if (jmpbuf) tb_siglongjmp(*jmpbuf, 1); \
            } \
            else \
            { \
                /* no exception handler */ \
                tb_assert_and_check_break(0); \
            } \
        } \
        /* exception been catched? */ \
        if (__j)

#else

    // try
#   define __tb_try \
    do \
    { \
        /* init exception stack */ \
        tb_stack_ref_t __stack = tb_null; \
        if (!(__stack = (tb_stack_ref_t)tb_thread_local_get(&g_exception_local))) \
        { \
            tb_stack_ref_t __stack_new = tb_stack_init(16, tb_element_mem(sizeof(tb_jmpbuf_t), tb_null, tb_null)); \
            if (__stack_new && tb_thread_local_set(&g_exception_local, __stack_new)) \
                __stack = __stack_new; \
            else if (__stack_new) \
                tb_stack_exit(__stack_new); \
        } \
        \
        /* push jmpbuf */ \
        tb_jmpbuf_t* __top = tb_null; \
        if (__stack) \
        { \
            tb_jmpbuf_t __buf; \
            tb_stack_put(__stack, &__buf); \
            __top = (tb_jmpbuf_t*)tb_stack_top(__stack); \
        } \
        \
        /* init jmpbuf */ \
        __tb_volatile__ tb_int_t __j = __top? tb_setjmp(*__top) : 0; \
        /* done try */ \
        if (!__j) \
        {

    // except
#   define __tb_except(x) \
        } \
        \
        /* check */ \
        tb_assert(x >= 0); \
        /* pop the jmpbuf */ \
        if (__stack) tb_stack_pop(__stack); \
        /* do not this catch? */ \
        if (__j && !(x)) \
        { \
            /* goto the top exception stack */ \
            if (__stack && tb_stack_size(__stack)) \
            { \
                tb_jmpbuf_t* jmpbuf = (tb_jmpbuf_t*)tb_stack_top(__stack); \
                if (jmpbuf) tb_longjmp(*jmpbuf, 1); \
            } \
            else \
            { \
                /* no exception handler */ \
                tb_assert_and_check_break(0); \
            } \
        } \
        /* exception been catched? */ \
        if (__j)

#endif

    // end
#define __tb_end \
    } while (0);

    // leave
#define __tb_leave   break


#endif


