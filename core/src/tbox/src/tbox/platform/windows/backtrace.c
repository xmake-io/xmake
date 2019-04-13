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
 * @file        backtrace.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <malloc.h>
#include "interface/interface.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define TB_MAX_SYM_NAME             (2000)
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_backtrace_frames(tb_pointer_t* frames, tb_size_t nframe, tb_size_t nskip)
{
    // check
    tb_check_return_val(tb_kernel32()->RtlCaptureStackBackTrace && frames && nframe, 0);

    // note: cannot use assert
    return (tb_size_t)tb_kernel32()->RtlCaptureStackBackTrace((DWORD)nskip, (DWORD)(nframe < 63? nframe : 62), frames, tb_null);
}
tb_handle_t tb_backtrace_symbols_init(tb_pointer_t* frames, tb_size_t nframe)
{
    // check
    tb_check_return_val(frames && nframe, tb_null);

    // make symbol
    tb_dbghelp_symbol_info_t* symbol = (tb_dbghelp_symbol_info_t*)calloc(sizeof(tb_dbghelp_symbol_info_t) + TB_MAX_SYM_NAME * sizeof(tb_char_t), 1);
    tb_check_return_val(symbol, tb_null);

    // init symbol
    symbol->MaxNameLen = TB_MAX_SYM_NAME;
    symbol->SizeOfStruct = sizeof(tb_dbghelp_symbol_info_t);

    // ok
    return symbol;
}
tb_char_t const* tb_backtrace_symbols_name(tb_handle_t handle, tb_pointer_t* frames, tb_size_t nframe, tb_size_t iframe)
{
    // check
    tb_dbghelp_symbol_info_t* symbol = (tb_dbghelp_symbol_info_t*)handle;
    tb_check_return_val(symbol && tb_dbghelp()->SymFromAddr && frames && nframe && iframe < nframe, tb_null);

    // done symbol
    if (!tb_dbghelp()->SymFromAddr(GetCurrentProcess(), (DWORD64)(tb_size_t)(frames[iframe]), 0, symbol)) return tb_null;
    
    // the symbol name
    return symbol->Name;
}
tb_void_t tb_backtrace_symbols_exit(tb_handle_t handle)
{
    if (handle) free(handle);
}
