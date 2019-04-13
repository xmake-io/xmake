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
 * @file        context.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if defined(TB_CONFIG_POSIX_HAVE_GETCONTEXT) && \
        defined(TB_CONFIG_POSIX_HAVE_SETCONTEXT) && \
        defined(TB_CONFIG_POSIX_HAVE_MAKECONTEXT)
#   include <ucontext.h>
#   include <signal.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_context_size()
{
    return sizeof(ucontext_t);
}
tb_context_ref_t tb_context_init(tb_byte_t* data, tb_size_t size)
{
    // check size
    tb_size_t context_size = tb_context_size();
    tb_assert_and_check_return_val(data && context_size && context_size <= size, tb_null);

    // get context
    tb_context_ref_t context = (tb_context_ref_t)data;

    // init context 
    tb_memset(data, 0, context_size);

#if defined(TB_CONFIG_POSIX_HAVE_GETCONTEXT) && \
        defined(TB_CONFIG_POSIX_HAVE_SETCONTEXT) && \
        defined(TB_CONFIG_POSIX_HAVE_MAKECONTEXT)
    // init sigmask
    sigset_t zero;
    sigemptyset(&zero);
    sigprocmask(SIG_BLOCK, &zero, &((ucontext_t*)context)->uc_sigmask);
#endif

    // ok
    return context;
}
tb_void_t tb_context_exit(tb_context_ref_t context)
{
    // do nothing
}
tb_bool_t tb_context_save(tb_context_ref_t context)
{
    // check
    tb_assert(context);

    // get it
    return getcontext((ucontext_t*)context) == 0;
}
tb_void_t tb_context_switch(tb_context_ref_t context)
{
    // check
    tb_assert(context);

    // set it 
    setcontext((ucontext_t*)context);
}
tb_bool_t tb_context_make(tb_context_ref_t context, tb_pointer_t stack, tb_size_t stacksize, tb_context_func_t func, tb_cpointer_t priv)
{
    // check
    ucontext_t* ucontext = (ucontext_t*)context;
    tb_assert_and_check_return_val(ucontext && stack && stacksize && func, tb_false);

    // get context first
    if (getcontext(ucontext) == 0)
    {
        // init stack and size
        ucontext->uc_stack.ss_sp    = stack;
        ucontext->uc_stack.ss_size  = stacksize;

        // init link
        ucontext->uc_link = tb_null;

        // make it
        makecontext(ucontext, (tb_void_t(*)())func, 1, (tb_size_t)priv);
    }

    // ok
    return tb_true;
}
#ifdef TB_CONFIG_POSIX_HAVE_SWAPCONTEXT
tb_void_t tb_context_swap(tb_context_ref_t context, tb_context_ref_t context_new)
{
    // check
    tb_assert(context && context_new);

    // swap it
    swapcontext((ucontext_t*)context, (ucontext_t*)context_new);
}
#else
tb_void_t tb_context_swap(tb_context_ref_t context, tb_context_ref_t context_new)
{
    // check
    tb_assert(context && context_new);

    // swap it
    if (getcontext((ucontext_t*)context) == 0) 
        setcontext((ucontext_t*)context_new);
}
#endif
