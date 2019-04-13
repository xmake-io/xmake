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

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_context_size()
{
    return sizeof(CONTEXT);
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
    LPCONTEXT mcontext = (LPCONTEXT)context;
    tb_assert_and_check_return_val(mcontext, tb_false);

    // save and restore the full machine context 
    mcontext->ContextFlags = CONTEXT_FULL;

    // get it
    return GetThreadContext(GetCurrentThread(), mcontext);
}
tb_void_t tb_context_switch(tb_context_ref_t context)
{
    // check
    LPCONTEXT mcontext = (LPCONTEXT)context;
    tb_assert_and_check_return(mcontext);

    // set it
    SetThreadContext(GetCurrentThread(), mcontext);
}
#ifdef TB_ARCH_x64
tb_bool_t tb_context_make(tb_context_ref_t context, tb_pointer_t stack, tb_size_t stacksize, tb_context_func_t func, tb_cpointer_t priv)
{
    // check
    LPCONTEXT mcontext = (LPCONTEXT)context;
    tb_assert_and_check_return_val(mcontext && stack && stacksize && func, tb_false);

    // save and restore the full machine context 
    mcontext->ContextFlags = CONTEXT_FULL;

    // get context first
    if (!GetThreadContext(GetCurrentThread(), mcontext)) return tb_false;

    // make stack address
    tb_uint64_t* sp = (tb_uint64_t*)stack + stacksize / sizeof(tb_uint64_t);
 
    // 16-align 
    sp = (tb_uint64_t*)((tb_size_t)sp & ~0xf);

    // push return address(unused, only reverse the stack space)
    *--sp = 0;

    // FIXME cannot access this argument(priv) in the callback function
    // ...

    // push arguments
    mcontext->Rcx = tb_p2u64(priv);

    /* save function and stack address
     *
     * rcx:     arg1
     * sp:      return address(0)   => rsp 
     */
    mcontext->Rip = (tb_uint64_t)func;
    mcontext->Rsp = (tb_uint64_t)sp;

    // ok
    return tb_true;
}
#else
tb_bool_t tb_context_make(tb_context_ref_t context, tb_pointer_t stack, tb_size_t stacksize, tb_context_func_t func, tb_cpointer_t priv)
{
    // check
    LPCONTEXT mcontext = (LPCONTEXT)context;
    tb_assert_and_check_return_val(mcontext && stack && stacksize && func, tb_false);

    // save and restore the full machine context 
    mcontext->ContextFlags = CONTEXT_FULL;

    // get context first
    if (!GetThreadContext(GetCurrentThread(), mcontext)) return tb_false;

    // make stack address
    tb_uint32_t* sp = (tb_uint32_t*)stack + stacksize / sizeof(tb_uint32_t);
 
    // 16-align 
    sp = (tb_uint32_t*)((tb_size_t)sp & ~0xf);

    // push arguments
    *--sp = tb_p2u32(priv);

    // push return address(unused, only reverse the stack space)
    *--sp = 0;

    /* save function and stack address
     *
     * sp + 4:  arg1                         
     * sp:      return address(0)   => esp 
     */
    mcontext->Eip = (tb_uint32_t)func;
    mcontext->Esp = (tb_uint32_t)sp;

    // ok
    return tb_true;
}
#endif
tb_void_t tb_context_swap(tb_context_ref_t context, tb_context_ref_t context_new)
{
    // check
    tb_assert_and_check_return(context && context_new);

    // save and restore the full machine context 
    ((LPCONTEXT)context)->ContextFlags      = CONTEXT_FULL;
    ((LPCONTEXT)context_new)->ContextFlags  = CONTEXT_FULL;

    // get it
    HANDLE thread = GetCurrentThread();
    if (GetThreadContext(thread, (LPCONTEXT)context))
        SetThreadContext(thread, (LPCONTEXT)context_new);
}

