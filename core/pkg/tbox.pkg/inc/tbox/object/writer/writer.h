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
 * @file        writer.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_WRITER_H
#define TB_OBJECT_WRITER_H

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

/*! set object writer
 *
 * @param format    the writer format
 * @param writer    the writer
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_writer_set(tb_size_t format, tb_object_writer_t* writer);

/*! del object writer
 *
 * @param format    the writer format
 */
tb_void_t           tb_object_writer_del(tb_size_t format);

/*! get object writer
 *
 * @param format    the writer format
 *
 * @return          the object writer
 */
tb_object_writer_t* tb_object_writer_get(tb_size_t format);

/*! done writer
 *
 * @param object    the object
 * @param stream    the stream
 * @param format    the object format
 *
 * @return          the writed size, failed: -1
 */
tb_long_t           tb_object_writer_done(tb_object_ref_t object, tb_stream_ref_t stream, tb_size_t format);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
