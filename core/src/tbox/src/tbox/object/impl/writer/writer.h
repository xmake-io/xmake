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
 * @file        writer.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_IMPL_WRITER_H
#define TB_OBJECT_IMPL_WRITER_H

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
tb_bool_t           tb_oc_writer_set(tb_size_t format, tb_oc_writer_t* writer);

/*! get object writer
 *
 * @param format    the writer format
 *
 * @return          the object writer
 */
tb_oc_writer_t*     tb_oc_writer_get(tb_size_t format);

/*! remove object writer
 *
 * @param format    the writer format
 */
tb_void_t           tb_oc_writer_remove(tb_size_t format);

/*! done writer
 *
 * @param object    the object
 * @param stream    the stream
 * @param format    the object format
 *
 * @return          the writed size, failed: -1
 */
tb_long_t           tb_oc_writer_done(tb_object_ref_t object, tb_stream_ref_t stream, tb_size_t format);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
