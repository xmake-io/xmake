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
 * @file        zip.h
 *
 */
#ifndef TB_ZIP_H
#define TB_ZIP_H

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

/*! init zip
 *
 * @param algo      the zip zlgo
 * @param action    the zip action
 *
 * @return          the zip
 */
tb_zip_ref_t        tb_zip_init(tb_size_t algo, tb_size_t action);

/*! exit zip
 *
 * @param zip       the zip
 */
tb_void_t           tb_zip_exit(tb_zip_ref_t zip);

/*! spak
 *
 * @param zip       the zip
 * @param ist       the input stream
 * @param ost       the output stream
 * @param sync      sync? 1: sync, 0: no sync, -1: end
 *
 * @return          1: ok, 0: continue, -1: end
 */
tb_long_t           tb_zip_spak(tb_zip_ref_t zip, tb_static_stream_ref_t ist, tb_static_stream_ref_t ost, tb_long_t sync);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
