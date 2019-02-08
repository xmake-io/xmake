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
 * @file        coroutine.h
 * @ingroup     coroutine
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "coroutine"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "coroutine.h"
#include "scheduler.h"
#if defined(__tb_valgrind__) && defined(TB_CONFIG_VALGRIND_HAVE_VALGRIND_STACK_REGISTER)
#   include "valgrind/valgrind.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the stack guard magic
#define TB_COROUTINE_STACK_GUARD            (0xbeef)

// the default stack size
#define TB_COROUTINE_STACK_DEFSIZE          (8192 << 1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_void_t tb_coroutine_entry(tb_context_from_t from)
{
    // get the from-coroutine 
    tb_coroutine_t* coroutine_from = (tb_coroutine_t*)from.priv;
    tb_assert(coroutine_from && from.context);

    // update the context
    coroutine_from->context = from.context;
    tb_assert(from.context);

    // get the current coroutine
    tb_coroutine_t* coroutine = (tb_coroutine_t*)tb_coroutine_self();
    tb_assert(coroutine);

#ifdef __tb_debug__
    // check it
    tb_coroutine_check(coroutine);
#endif

    // trace
    tb_trace_d("entry: %p stack: %p - %p from coroutine(%p)", coroutine, coroutine->stackbase - coroutine->stacksize, coroutine->stackbase, coroutine_from);

    // get function and private data
    tb_coroutine_func_t func = coroutine->rs.func.func;
    tb_cpointer_t       priv = coroutine->rs.func.priv;
    tb_assert(func);

    // reset rs data first for waiting io
    tb_memset(&coroutine->rs, 0, sizeof(coroutine->rs));

    // call the coroutine function
    func(priv);

    // finish the current coroutine and switch to the other coroutine
    tb_co_scheduler_finish((tb_co_scheduler_t*)tb_co_scheduler_self());
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_coroutine_t* tb_coroutine_init(tb_co_scheduler_ref_t scheduler, tb_coroutine_func_t func, tb_cpointer_t priv, tb_size_t stacksize)
{
    // check
    tb_assert_and_check_return_val(scheduler && func, tb_null);

    // done
    tb_bool_t       ok = tb_false;
    tb_coroutine_t* coroutine = tb_null;
    do
    {
        // init stack size
        if (!stacksize) stacksize = TB_COROUTINE_STACK_DEFSIZE;

#ifdef __tb_debug__
        // patch debug stack size for (assert, trace ..)
        stacksize <<= 1;
#endif

        /* make coroutine
         *
         * TODO: 
         *
         * - segment stack 
         *
         *  -----------------------------------------------
         * | coroutine | guard | ... stacksize ... | guard |
         *  -----------------------------------------------
         */
        coroutine = (tb_coroutine_t*)tb_malloc_bytes(sizeof(tb_coroutine_t) + stacksize + sizeof(tb_uint16_t));
        tb_assert_and_check_break(coroutine);

        // save scheduler
        coroutine->scheduler = scheduler;

        // init stack
        coroutine->stackbase = (tb_byte_t*)&(coroutine[1]) + stacksize;
        coroutine->stacksize = stacksize;

        // fill guard
        coroutine->guard = TB_COROUTINE_STACK_GUARD;
        tb_bits_set_u16_ne(coroutine->stackbase, TB_COROUTINE_STACK_GUARD);

        // init function and user private data
        coroutine->rs.func.func = func;
        coroutine->rs.func.priv = priv;

        // make context
        coroutine->context = tb_context_make(coroutine->stackbase - stacksize, stacksize, tb_coroutine_entry);
        tb_assert_and_check_break(coroutine->context);

#if defined(__tb_valgrind__) && defined(TB_CONFIG_VALGRIND_HAVE_VALGRIND_STACK_REGISTER)
        // register valgrind stack 
        coroutine->valgrind_stack_id = VALGRIND_STACK_REGISTER(coroutine->stackbase - stacksize, coroutine->stackbase);
#endif

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (coroutine) tb_coroutine_exit(coroutine); 
        coroutine = tb_null;
    }

    // trace
    tb_trace_d("init %p", coroutine);

    // ok?
    return coroutine;
}
tb_coroutine_t* tb_coroutine_reinit(tb_coroutine_t* coroutine, tb_coroutine_func_t func, tb_cpointer_t priv, tb_size_t stacksize)
{
    // check
    tb_assert_and_check_return_val(coroutine && func, tb_null);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // init stack size
        if (!stacksize) stacksize = TB_COROUTINE_STACK_DEFSIZE;

#ifdef __tb_debug__
        // patch debug stack size for (assert, trace ..)
        stacksize <<= 1;

        // check coroutine
        tb_coroutine_check(coroutine);
#endif

#if defined(__tb_valgrind__) && defined(TB_CONFIG_VALGRIND_HAVE_VALGRIND_STACK_REGISTER)
        // deregister valgrind stack 
        VALGRIND_STACK_DEREGISTER(coroutine->valgrind_stack_id);
#endif

        // remake coroutine
        if (stacksize > coroutine->stacksize)
            coroutine = (tb_coroutine_t*)tb_ralloc_bytes(coroutine, sizeof(tb_coroutine_t) + stacksize + sizeof(tb_uint16_t));
        else stacksize = coroutine->stacksize;
        tb_assert_and_check_break(coroutine && coroutine->scheduler);

        // init stack
        coroutine->stackbase = (tb_byte_t*)&(coroutine[1]) + stacksize;
        coroutine->stacksize = stacksize;

        // fill guard
        coroutine->guard = TB_COROUTINE_STACK_GUARD;
        tb_bits_set_u16_ne(coroutine->stackbase, TB_COROUTINE_STACK_GUARD);

        // init function and user private data
        coroutine->rs.func.func = func;
        coroutine->rs.func.priv = priv;

        // make context
        coroutine->context = tb_context_make(coroutine->stackbase - stacksize, stacksize, tb_coroutine_entry);
        tb_assert_and_check_break(coroutine->context);

#if defined(__tb_valgrind__) && defined(TB_CONFIG_VALGRIND_HAVE_VALGRIND_STACK_REGISTER)
        // re-register valgrind stack 
        coroutine->valgrind_stack_id = VALGRIND_STACK_REGISTER(coroutine->stackbase - stacksize, coroutine->stackbase);
#endif

        // ok
        ok = tb_true;

    } while (0);

    // failed? reset it
    if (!ok) coroutine = tb_null;

    // trace
    tb_trace_d("reinit %p", coroutine);

    // ok?
    return coroutine;
}
tb_void_t tb_coroutine_exit(tb_coroutine_t* coroutine)
{
    // check
    tb_assert_and_check_return(coroutine);

    // trace
    tb_trace_d("exit: %p", coroutine);

#ifdef __tb_debug__
    // check it
    tb_coroutine_check(coroutine);
#endif

#if defined(__tb_valgrind__) && defined(TB_CONFIG_VALGRIND_HAVE_VALGRIND_STACK_REGISTER)
    // deregister valgrind stack 
    VALGRIND_STACK_DEREGISTER(coroutine->valgrind_stack_id);
#endif

    // exit it
    tb_free(coroutine);
}
#ifdef __tb_debug__
tb_void_t tb_coroutine_check(tb_coroutine_t* coroutine)
{
    // check
    tb_assert(coroutine);

    // this coroutine is original for scheduler?
    tb_check_return(!tb_coroutine_is_original(coroutine));

    // check stack underflow
    if (coroutine->guard != TB_COROUTINE_STACK_GUARD)
    {
        // trace
        tb_trace_e("this coroutine stack is underflow!");

        // dump stack
        tb_dump_data(coroutine->stackbase - coroutine->stacksize, coroutine->stacksize);

        // abort
        tb_abort();
    }

    // check stack overflow
    if (tb_bits_get_u16_ne(coroutine->stackbase) != TB_COROUTINE_STACK_GUARD)
    {
        // trace
        tb_trace_e("this coroutine stack is overflow!");

        // dump stack
        tb_dump_data(coroutine->stackbase - coroutine->stacksize, coroutine->stacksize);

        // abort
        tb_abort();
    }

    // check
    tb_assert(coroutine->context);
}
#endif

