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
