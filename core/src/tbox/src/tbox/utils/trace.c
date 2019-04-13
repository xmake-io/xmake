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
 * @file        trace.c
 * @ingroup     utils
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "trace.h"
#include "../libc/libc.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the trace line maxn
#ifdef TB_CONFIG_MICRO_ENABLE
#       define TB_TRACE_LINE_MAXN       (256)
#else
#   ifdef __tb_small__
#       define TB_TRACE_LINE_MAXN       (8192)
#   else
#       define TB_TRACE_LINE_MAXN       (8192 << 1)
#   endif
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the mode
static tb_size_t        g_mode = TB_TRACE_MODE_PRINT;

#ifndef TB_CONFIG_MICRO_ENABLE
// the file
static tb_file_ref_t    g_file = tb_null;

// the file is referenced?
static tb_bool_t        g_bref = tb_false;
#endif

// the line
static tb_char_t        g_line[TB_TRACE_LINE_MAXN];

// the lock
static tb_spinlock_t    g_lock = TB_SPINLOCK_INIT; 

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_trace_init()
{
    // init lock
    return tb_spinlock_init(&g_lock);
}
tb_void_t tb_trace_exit()
{
    // sync trace
    tb_trace_sync();

    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // clear mode
    g_mode = TB_TRACE_MODE_PRINT;

    // clear file
#ifndef TB_CONFIG_MICRO_ENABLE
    if (g_file && !g_bref) tb_file_exit(g_file);
    g_file = tb_null;
    g_bref = tb_false;
#endif

    // leave
    tb_spinlock_leave(&g_lock);

    // exit lock
    tb_spinlock_exit(&g_lock);
}
tb_size_t tb_trace_mode()
{
    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // the mode
    tb_size_t mode = g_mode;

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return mode;
}
tb_bool_t tb_trace_mode_set(tb_size_t mode)
{
    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // set the mode
    g_mode = mode;

    // leave
    tb_spinlock_leave(&g_lock);

    // ok
    return tb_true;
}
#ifndef TB_CONFIG_MICRO_ENABLE
tb_file_ref_t tb_trace_file()
{
    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // the file
    tb_file_ref_t file = g_file;

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return file;
}
tb_bool_t tb_trace_file_set(tb_file_ref_t file)
{
    // check
    tb_check_return_val(file, tb_false);

    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // exit the previous file
    if (g_file && !g_bref) tb_file_exit(g_file);

    // set the file
    g_file = file;
    g_bref = tb_true;

    // leave
    tb_spinlock_leave(&g_lock);

    // ok
    return tb_true;
}
tb_bool_t tb_trace_file_set_path(tb_char_t const* path, tb_bool_t bappend)
{
    // check
    tb_check_return_val(path, tb_false);

    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // exit the previous file
    if (g_file && !g_bref) tb_file_exit(g_file);

    // set the file
    g_file = tb_file_init(path, TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | (bappend? TB_FILE_MODE_APPEND : TB_FILE_MODE_TRUNC));
    g_bref = tb_false;

    // ok?
    tb_bool_t ok = g_file? tb_true : tb_false;

    // leave
    tb_spinlock_leave(&g_lock);

    // ok?
    return ok;
}
#endif
tb_void_t tb_trace_done_with_args(tb_char_t const* prefix, tb_char_t const* module, tb_char_t const* format, tb_va_list_t args)
{
    // check
    tb_check_return(format);

    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // done
    do
    {
        // check
        tb_check_break(g_mode);

        // init
        tb_char_t*      p = g_line;
        tb_char_t*      e = g_line + sizeof(g_line);

        // print prefix to file
#ifndef TB_CONFIG_MICRO_ENABLE
        if ((g_mode & TB_TRACE_MODE_FILE) && g_file) 
        {
            // print time to file
            tb_tm_t lt = {0};
            if (p < e && tb_localtime(tb_time(), &lt))
                p += tb_snprintf(p, e - p, "[%04ld-%02ld-%02ld %02ld:%02ld:%02ld]: ", lt.year, lt.month, lt.mday, lt.hour, lt.minute, lt.second);

            // print self to file
            if (p < e) p += tb_snprintf(p, e - p, "[%lx]: ", tb_thread_self());
        }
#endif

        // append prefix
        tb_char_t*      b = p;
        if (prefix && p < e) p += tb_snprintf(p, e - p, "[%s]: ", prefix);

        // append module
        if (module && p < e) p += tb_snprintf(p, e - p, "[%s]: ", module);

        // append format
        if (p < e) p += tb_vsnprintf(p, e - p, format, args);

        // append end
        if (p < e) *p = '\0';
        e[-1] = '\0';

        // print it
        if (g_mode & TB_TRACE_MODE_PRINT) tb_print(b);

        // print it to file
#ifndef TB_CONFIG_MICRO_ENABLE
        if ((g_mode & TB_TRACE_MODE_FILE) && g_file) 
        {
            // done
            tb_size_t size = p - g_line;
            tb_size_t writ = 0;
            while (writ < size)
            {
                // writ it
                tb_long_t real = tb_file_writ(g_file, (tb_byte_t const*)g_line + writ, size - writ);
                tb_check_break(real > 0);

                // save size
                writ += real;
            }
        }
#endif

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);
}
tb_void_t tb_trace_done(tb_char_t const* prefix, tb_char_t const* module, tb_char_t const* format, ...)
{
    // check
    tb_check_return(format);

    // init args
    tb_va_list_t args;
    tb_va_start(args, format);

    // done trace
    tb_trace_done_with_args(prefix, module, format, args);

    // exit args
    tb_va_end(args);
}
tb_void_t tb_trace_tail(tb_char_t const* format, ...)
{
    // check
    tb_check_return(format);

    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // done
    do
    {
        // check
        tb_check_break(g_mode);

        // init
        tb_va_list_t    l;
        tb_char_t*      p = g_line;
        tb_char_t*      e = g_line + sizeof(g_line);
        tb_va_start(l, format);

        // append format
        if (p < e) p += tb_vsnprintf(p, e - p, format, l);

        // append end
        if (p < e) *p = '\0';
        e[-1] = '\0';

        // print it
        if (g_mode & TB_TRACE_MODE_PRINT) tb_print(g_line);

        // print it to file
#ifndef TB_CONFIG_MICRO_ENABLE
        if ((g_mode & TB_TRACE_MODE_FILE) && g_file) 
        {
            // done
            tb_size_t size = p - g_line;
            tb_size_t writ = 0;
            while (writ < size)
            {
                // writ it
                tb_long_t real = tb_file_writ(g_file, (tb_byte_t const*)g_line + writ, size - writ);
                tb_check_break(real > 0);

                // save size
                writ += real;
            }
        }
#endif

        // exit
        tb_va_end(l);

    } while (0);

    // leave
    tb_spinlock_leave(&g_lock);
}
tb_void_t tb_trace_sync()
{
    // enter
    tb_spinlock_enter_without_profiler(&g_lock);

    // sync it
    if (g_mode & TB_TRACE_MODE_PRINT) tb_print_sync();

    // sync it to file
#ifndef TB_CONFIG_MICRO_ENABLE
    if ((g_mode & TB_TRACE_MODE_FILE) && g_file) tb_file_sync(g_file);
#endif

    // leave
    tb_spinlock_leave(&g_lock);
}
