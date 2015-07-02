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
#include "../thread_store.h"
#include "../../libc/misc/signal.h"
#include "../../libc/misc/setjmp.h"
#include "../../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

#if defined(tb_signal) && defined(tb_sigsetjmp) && defined(tb_siglongjmp)

// the exception data type
typedef struct __tb_exception_list_t
{
    // the thread store base
    tb_thread_store_data_t  base;

    // the stack
    tb_stack_ref_t             stack;

}tb_exception_list_t;

#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#if defined(tb_signal) && defined(tb_sigsetjmp) && defined(tb_siglongjmp)

    // try
#   define __tb_try \
    do \
    { \
        /* init exception first */ \
        tb_exception_init_impl(); \
        \
        /* init exception data */ \
        tb_exception_list_t* __l = tb_null; \
        if (!(__l = (tb_exception_list_t*)tb_thread_store_getp())) \
        { \
            __l = tb_malloc0(sizeof(tb_exception_list_t)); \
            if (__l) \
            { \
                __l->base.type = TB_THREAD_STORE_DATA_TYPE_EXCEPTION; \
                __l->base.free = tb_exception_list_free; \
                __l->stack = tb_stack_init(16, tb_element_mem(sizeof(tb_sigjmpbuf_t), tb_null, tb_null)); \
                tb_thread_store_setp((tb_thread_store_data_t const*)__l); \
            } \
        } \
        \
        /* push jmpbuf */ \
        tb_sigjmpbuf_t* __top = tb_null; \
        if (__l && __l->stack) \
        { \
            tb_sigjmpbuf_t __buf; \
            tb_stack_put(__l->stack, &__buf); \
            __top = (tb_sigjmpbuf_t*)tb_stack_top(__l->stack); \
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
        if (__l && __l->stack) tb_stack_pop(__l->stack); \
        /* do not this catch? */ \
        if (__j && !(x)) \
        { \
            /* goto the top exception stack */ \
            if (__l && __l->stack && tb_stack_size(__l->stack)) \
            { \
                tb_sigjmpbuf_t* jmpbuf = (tb_sigjmpbuf_t*)tb_stack_top(__l->stack); \
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

    // end
#   define __tb_end \
    } while (0);

    // leave
#   define __tb_leave   break

    // init
#   define tb_exception_init tb_exception_init_impl

#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * handler
 */

#if defined(tb_signal) && defined(tb_sigsetjmp) && defined(tb_siglongjmp)
static __tb_inline__ tb_void_t tb_exception_func_impl(tb_int_t sig)
{
    tb_exception_list_t* list = (tb_exception_list_t*)tb_thread_store_getp();
    if (list && list->stack && tb_stack_size(list->stack)) 
    {
        tb_sigjmpbuf_t* jmpbuf = (tb_sigjmpbuf_t*)tb_stack_top(list->stack);
        if (jmpbuf) tb_siglongjmp(*jmpbuf, 1);
    }
    else tb_trace_e("exception: unknown signal: %d", sig);
}
static __tb_inline__ tb_void_t tb_exception_init_impl()
{
    static tb_atomic_t s_init = 0;
    if (!tb_atomic_fetch_and_set(&s_init, 1))
    {
//      tb_signal(TB_SIGINT, tb_exception_func_impl);
        tb_signal(TB_SIGILL, tb_exception_func_impl);
        tb_signal(TB_SIGFPE, tb_exception_func_impl);
        tb_signal(TB_SIGBUS, tb_exception_func_impl);
        tb_signal(TB_SIGSEGV, tb_exception_func_impl);
//      tb_signal(TB_SIGTRAP, tb_exception_func_impl);
    }
}
static __tb_inline__ tb_void_t tb_exception_list_free(tb_thread_store_data_t* data)
{
    tb_exception_list_t* list = (tb_exception_list_t*)data;
    if (list)
    {
        // exit stack
        if (list->stack) tb_stack_exit(list->stack);
        list->stack = tb_null;

        // exit exception
        tb_free(list);
    }
}
#endif

#endif


