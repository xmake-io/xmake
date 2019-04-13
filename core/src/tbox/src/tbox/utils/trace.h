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
 * @file        trace.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_TRACE_H
#define TB_UTILS_TRACE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the trace mode enum
typedef enum __tb_trace_mode_e
{
    TB_TRACE_MODE_NONE      = 0
,   TB_TRACE_MODE_FILE      = 1
,   TB_TRACE_MODE_PRINT     = 2

}tb_trace_mode_e;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init trace 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_trace_init(tb_noarg_t);

/*! exit trace 
 */
tb_void_t           tb_trace_exit(tb_noarg_t);

/*! the trace mode
 *
 * @return          the trace mode
 */
tb_size_t           tb_trace_mode(tb_noarg_t);

/*! set the trace mode
 *
 * @param mode      the trace mode
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_trace_mode_set(tb_size_t mode);

/*! the trace file
 *
 * @return          the trace file handle
 */
tb_file_ref_t       tb_trace_file(tb_noarg_t);

/*! set the trace file 
 *
 * @param file      the trace file handle
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_trace_file_set(tb_file_ref_t file);

/*! set the trace file path
 *
 * @param path      the trace file path
 * @param bappend   is appended?
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_trace_file_set_path(tb_char_t const* path, tb_bool_t bappend);

/*! done trace with arguments
 *
 * @param prefix    the trace prefix
 * @param module    the trace module
 * @param format    the trace format
 * @param args      the trace arguments
 */
tb_void_t           tb_trace_done_with_args(tb_char_t const* prefix, tb_char_t const* module, tb_char_t const* format, tb_va_list_t args);

/*! done trace
 *
 * @param prefix    the trace prefix
 * @param module    the trace module
 * @param format    the trace format
 */
tb_void_t           tb_trace_done(tb_char_t const* prefix, tb_char_t const* module, tb_char_t const* format, ...);

/*! done trace tail
 *
 * @param format    the trace format
 */
tb_void_t           tb_trace_tail(tb_char_t const* format, ...);

/*! sync trace
 */
tb_void_t           tb_trace_sync(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

