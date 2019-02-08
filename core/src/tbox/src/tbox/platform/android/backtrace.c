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
 * @file        backtrace.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../atomic.h"
#include "../memory.h"
#include "../dynamic.h"
#if 0
#   include <unwind.h>
#   include <dlfcn.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/* a single frame of a backtrace.
 *
 * from corkscrew/backtrace.h
 */
typedef struct __tb_backtrace_frame_t
{
    // absolute PC offset
    tb_size_t               absolute_pc;

    // top of stack for this frame
    tb_size_t               stack_top; 

    // size of this stack frame
    tb_size_t               stack_size;

} tb_backtrace_frame_t, *tb_backtrace_frame_ref_t;

/* the symbols associated with a backtrace frame.
 *
 * from corkscrew/backtrace.h
 */
typedef struct __tb_backtrace_symbol_t
{
    /* relative frame PC offset from the start of the library,
     * or the absolute PC if the library is unknown
     */
    tb_size_t               relative_pc;      

    /* relative offset of the symbol from the start of the
     * library or 0 if the library is unknown 
     */
    tb_size_t               relative_symbol_addr; 

    // executable or library name, or NULL if unknown
    tb_char_t*              map_name;

    // symbol name, or NULL if unknown
    tb_char_t*              symbol_name; 

    // demangled symbol name, or NULL if unknown
    tb_char_t*              demangled_name;

} tb_backtrace_symbol_t, *tb_backtrace_symbol_ref_t;

// the symbols type
typedef struct __tb_backtrace_symbols_t
{
    // the symbols 
    tb_backtrace_symbol_t   symbols[64];

    // the info
    tb_char_t               info[256];

    // the frame count
    tb_size_t               nframe;

} tb_backtrace_symbols_t, *tb_backtrace_symbols_ref_t;

// the unwind_backtrace function type
typedef tb_long_t   (*tb_backtrace_unwind_backtrace_func_t)(tb_backtrace_frame_ref_t, tb_size_t, tb_size_t);  

// the get_backtrace_symbols function type
typedef tb_void_t   (*tb_backtrace_get_backtrace_symbols_func_t)(tb_backtrace_frame_ref_t, tb_size_t, tb_backtrace_symbol_ref_t);  

// the free_backtrace_symbols function type
typedef tb_void_t   (*tb_backtrace_free_backtrace_symbols_func_t)(tb_backtrace_symbol_ref_t, tb_size_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
 
// the unwind_backtrace function 
static tb_backtrace_unwind_backtrace_func_t         g_unwind_backtrace = tb_null;

// the get_backtrace_symbols function 
static tb_backtrace_get_backtrace_symbols_func_t    g_get_backtrace_symbols = tb_null;

// the free_backtrace_symbols function
static tb_backtrace_free_backtrace_symbols_func_t   g_free_backtrace_symbols = tb_null;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#if 0
static _Unwind_Reason_Code tb_backtrace_unwind(struct _Unwind_Context* context, tb_pointer_t args) 
{
    // check
    tb_value_ref_t info = (tb_value_ref_t)args;
    tb_check_return_val(context && info, _URC_END_OF_STACK);

    // get info
    tb_backtrace_frame_ref_t    frames      = (tb_backtrace_frame_ref_t)info[0].ptr;
    tb_size_t                   nskip       = info[1].ul;
    tb_size_t                   nframe_maxn = info[2].ul;
    tb_long_t                   count       = info[3].l;
    tb_check_return_val(frames && nframe_maxn && count < nframe_maxn, _URC_END_OF_STACK);

    // get ip
#ifdef HAVE_GETIPINFO
    tb_int_t ip_before_insn = 0;
    tb_size_t ip = (tb_size_t)_Unwind_GetIPInfo (context, &ip_before_insn);
    if (!ip_before_insn) ip--;
#else
    tb_size_t ip = (tb_size_t)_Unwind_GetIP (context);
#endif

    // trace
    tb_trace_d("unwind: count: %ld, nframe_maxn: %lu, ip: %p", count, nframe_maxn, ip);

    // skip and save frame
    if (ip) 
    {
        if (nskip > 0) nskip--;
        else
        {
            frames[count].absolute_pc   = ip;
            frames[count].stack_top     = 0;
            frames[count].stack_size    = 0;
            count++;
        }
    }

    // update info
    info[1].ul  = nskip;
    info[3].l   = count;

    // ok
    return _URC_OK;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_backtrace_frames(tb_pointer_t* frames, tb_size_t nframe, tb_size_t nskip)
{
    // check
    tb_check_return_val(frames && nframe, 0);

    // done
    tb_long_t count = 0;
    do
    {
        // load libcorkscrew.so?
        static tb_atomic_t g_loaded = 0;
        if (!tb_atomic_fetch_and_set(&g_loaded, 1))
        {
            // init dynamic
            tb_dynamic_ref_t dynamic = tb_dynamic_init("/system/lib/libcorkscrew.so");
            tb_check_break(dynamic); 
            
            // get the unwind_backtrace function 
            g_unwind_backtrace = (tb_backtrace_unwind_backtrace_func_t)tb_dynamic_func(dynamic, "unwind_backtrace");

            // get the get_backtrace_symbols function 
            g_get_backtrace_symbols = (tb_backtrace_get_backtrace_symbols_func_t)tb_dynamic_func(dynamic, "get_backtrace_symbols");

            // get the free_backtrace_symbols function
            g_free_backtrace_symbols = (tb_backtrace_free_backtrace_symbols_func_t)tb_dynamic_func(dynamic, "free_backtrace_symbols");
        }
        tb_check_break(g_unwind_backtrace && g_get_backtrace_symbols && g_free_backtrace_symbols);

        // calculate max frames count which can be storaged
        tb_size_t nframe_maxn = (sizeof(tb_pointer_t) * nframe) / sizeof(tb_backtrace_frame_t);
        tb_check_break(nframe_maxn && nframe_maxn < 64);

#if 1
        // unwind backtrace
        count = g_unwind_backtrace((tb_backtrace_frame_ref_t)frames, nskip, nframe_maxn);  
        tb_check_break_state(count >= 0, count, 0);
#else
        // need add cxflags: -funwind-tables
        tb_value_t info[4];
        info[0].ptr     = (tb_pointer_t)frames;
        info[1].ul      = nskip;
        info[2].ul      = nframe_maxn;
        info[3].l       = 0;
        _Unwind_Backtrace(tb_backtrace_unwind, info);
        count = info[3].l;
#endif

    } while (0);

    // ok?
    return count;
}
tb_handle_t tb_backtrace_symbols_init(tb_pointer_t* frames, tb_size_t nframe)
{
    // check
    tb_check_return_val(frames && nframe, tb_null);
    tb_check_return_val(g_get_backtrace_symbols, tb_null);

    // done
    tb_backtrace_symbols_ref_t symbols = tb_null;
    do
    {
        // the real frames count
        tb_size_t nframe_real = tb_min(nframe, 64);

        // make symbols
        symbols = (tb_backtrace_symbols_ref_t)tb_native_memory_malloc0(sizeof(tb_backtrace_symbols_t));
        tb_check_break(symbols);

        // get backtrace symbols
        g_get_backtrace_symbols((tb_backtrace_frame_ref_t)frames, nframe_real, symbols->symbols);

        // save the frame count
        symbols->nframe = nframe_real;

    } while (0);

    // ok?
    return (tb_handle_t)symbols;
}
#if 1
tb_char_t const* tb_backtrace_symbols_name(tb_handle_t handle, tb_pointer_t* frames, tb_size_t nframe, tb_size_t iframe)
{
    // check
    tb_backtrace_symbols_ref_t symbols = (tb_backtrace_symbols_ref_t)handle;
    tb_check_return_val(symbols && symbols->nframe && frames && iframe < symbols->nframe && symbols->nframe == nframe, tb_null);

    // get symbol
    tb_backtrace_symbol_ref_t symbol = &symbols->symbols[iframe];

    // get map name
    tb_char_t const* map_name = symbol->map_name? symbol->map_name : "<unknown>";  

    // get symbol name
    tb_char_t const* symbol_name = symbol->demangled_name? symbol->demangled_name : symbol->symbol_name;  

    // make symbol info
    tb_long_t info_size = 0;
    if (symbol_name) 
    {  
        // the pc offset relative symbol
        tb_size_t relative_symbol_pc_offset = symbol->relative_pc - symbol->relative_symbol_addr;  
        if (relative_symbol_pc_offset) 
        {  
            // make it
            info_size = tb_snprintf(    symbols->info
                                    ,   sizeof(symbols->info)
                                    ,   "[%08lx]: %2lu   %s %08lx %s + %lu"
                                    ,   symbol->relative_pc
                                    ,   iframe
                                    ,   map_name
                                    ,   symbol->relative_pc
                                    ,   symbol_name
                                    ,   relative_symbol_pc_offset);  
        }
        else 
        {  
            // make it
            info_size = tb_snprintf(    symbols->info
                                    ,   sizeof(symbols->info)
                                    ,   "[%08lx]: %2lu   %s %08lx %s"
                                    ,   symbol->relative_pc
                                    ,   iframe
                                    ,   map_name
                                    ,   symbol->relative_pc
                                    ,   symbol_name);  
        }  
    } 
    else
    {  
        // make it
        info_size = tb_snprintf(    symbols->info
                                ,   sizeof(symbols->info)
                                ,   "[%08lx]: %2lu   %s %08lx"
                                ,   symbol->relative_pc
                                ,   iframe
                                ,   map_name
                                ,   symbol->relative_pc);     
    }  

    // end
    if (info_size >= 0 && info_size < sizeof(symbols->info))
        symbols->info[info_size] = '\0';

    // ok?
    return symbols->info;
}
#else
tb_char_t const* tb_backtrace_symbols_name(tb_handle_t handle, tb_pointer_t* frames, tb_size_t nframe, tb_size_t iframe)
{
    // check
    tb_backtrace_symbols_ref_t symbols = (tb_backtrace_symbols_ref_t)handle;
    tb_check_return_val(symbols && frames && iframe < nframe, tb_null);

    // get frame address
    tb_size_t addr = ((tb_backtrace_frame_ref_t)frames)[iframe].absolute_pc;

    // make symbol info
    Dl_info     info;
    tb_long_t   info_size = 0;
    if (dladdr((tb_pointer_t)addr, &info) && info.dli_sname) 
    {
        // make it
        info_size = tb_snprintf(    symbols->info
                                ,   sizeof(symbols->info)
                                ,   "[%08lx]: %2lu   %s %08lx %s + %lu"
                                ,   addr
                                ,   iframe
                                ,   ""
                                ,   addr
                                ,   info.dli_sname
                                ,   0);  
    }
    else
    {  
        // make it
        info_size = tb_snprintf(    symbols->info
                                ,   sizeof(symbols->info)
                                ,   "[%08lx]: %2lu   %s %08lx"
                                ,   addr
                                ,   iframe
                                ,   ""
                                ,   addr);     
    }  

    // end
    if (info_size >= 0 && info_size < sizeof(symbols->info))
        symbols->info[info_size] = '\0';

    // ok?
    return symbols->info;
}
#endif
tb_void_t tb_backtrace_symbols_exit(tb_handle_t handle)
{
    // check
    tb_backtrace_symbols_ref_t symbols = (tb_backtrace_symbols_ref_t)handle;
    tb_check_return(symbols && g_free_backtrace_symbols);

    // free symbols
    if (symbols->nframe) g_free_backtrace_symbols(symbols->symbols, symbols->nframe);

    // exit it
    tb_native_memory_free(symbols);
}
