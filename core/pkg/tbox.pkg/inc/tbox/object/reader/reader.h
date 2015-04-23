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
 * @file        reader.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_READER_H
#define TB_OBJECT_READER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "xml.h"
#include "bin.h"
#include "json.h"
#include "xplist.h"
#include "bplist.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! set object reader
 *
 * @param format    the reader format
 * @param reader    the reader
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_reader_set(tb_size_t format, tb_object_reader_t* reader);

/*! del object reader
 *
 * @param format    the reader format
 */
tb_void_t           tb_object_reader_del(tb_size_t format);

/*! get object reader
 *
 * @param format    the reader format
 *
 * @return          the object reader
 */
tb_object_reader_t* tb_object_reader_get(tb_size_t format);

/*! done reader
 *
 * @param stream    the stream
 *
 * @return          the object
 */
tb_object_ref_t        tb_object_reader_done(tb_stream_ref_t stream);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
