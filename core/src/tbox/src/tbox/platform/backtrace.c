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
 * trace
 */
#define TB_TRACE_MODULE_NAME                "backtrace"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "backtrace.h"
#if defined(TB_CONFIG_OS_WINDOWS)
#   include "windows/backtrace.c"
#elif defined(TB_CONFIG_OS_ANDROID)
#   include "android/backtrace.c"
#else
#   include "libc/backtrace.c"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_backtrace_dump(tb_char_t const* prefix, tb_pointer_t* frames, tb_size_t nframe)
{
    // check
    tb_check_return(nframe < 256);

    // the frames
    tb_pointer_t frames_data[256] = {0};
    if (!frames)
    {
        nframe = tb_backtrace_frames(frames_data, nframe, 2);
        frames = frames_data;
    }

    // dump frames
    if (frames && nframe)
    {
        // init symbols
        tb_handle_t symbols = tb_backtrace_symbols_init(frames, nframe);
        if (symbols)
        {
            // walk
            tb_size_t i = 0;
            for (i = 0; i < nframe; i++)
            {
#if TB_CPU_BIT64
                tb_trace_i("%s[%016p]: %s", prefix? prefix : "", frames[i], tb_backtrace_symbols_name(symbols, frames, nframe, i));
#else
                tb_trace_i("%s[%08p]: %s", prefix? prefix : "", frames[i], tb_backtrace_symbols_name(symbols, frames, nframe, i));
#endif
            }
        
            // exit symbols
            tb_backtrace_symbols_exit(symbols);
        }
        else
        {
            // walk
            tb_size_t i = 0;
            for (i = 0; i < nframe; i++)
            {
#if TB_CPU_BIT64
                tb_trace_i("%s[%016p]", prefix? prefix : "", frames[i]);
#else
                tb_trace_i("%s[%08p]", prefix? prefix : "", frames[i]);
#endif              
            }
        }
    }
}
