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
 * @file        backtrace.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_BACKTRACE_H
#define TB_PLATFORM_BACKTRACE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! get backtrace frames
 *
 * @param frames        the backtrace frames
 * @param nframe        the backtrace frame maxn
 * @param nskip         the backtrace frame skip
 *
 * @return              the real backtrace frame count
 */
tb_size_t               tb_backtrace_frames(tb_pointer_t* frames, tb_size_t nframe, tb_size_t nskip);

/*! init backtrace frame symbols
 *
 * @param frames        the backtrace frames
 * @param nframe        the backtrace frame count
 *
 * @return              the backtrace frame symbols handle
 */
tb_handle_t             tb_backtrace_symbols_init(tb_pointer_t* frames, tb_size_t nframe);

/*! get backtrace frame symbol name
 *
 * @param symbols       the symbols handle
 * @param frames        the backtrace frames
 * @param nframe        the backtrace frame count
 * @param frame         the backtrace frame index
 *
 * @return              the symbol name
 */
tb_char_t const*        tb_backtrace_symbols_name(tb_handle_t symbols, tb_pointer_t* frames, tb_size_t nframe, tb_size_t iframe);

/*! exit backtrace frame symbols
 *
 * @param symbols       the symbols handle
 */
tb_void_t               tb_backtrace_symbols_exit(tb_handle_t symbols);

/*! dump backtrace
 *
 * @param prefix        the backtrace prefix
 * @param frames        the backtrace frames, dump the current frames if null
 * @param nframe        the backtrace frame count
 */
tb_void_t               tb_backtrace_dump(tb_char_t const* prefix, tb_pointer_t* frames, tb_size_t nframe);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
