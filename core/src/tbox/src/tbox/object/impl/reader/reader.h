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
 * @file        reader.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_IMPL_READER_H
#define TB_OBJECT_IMPL_READER_H

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
 * @param format        the reader format
 * @param reader        the reader
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_oc_reader_set(tb_size_t format, tb_oc_reader_t* reader);

/*! get object reader
 *
 * @param format        the reader format
 *
 * @return              the object reader
 */
tb_oc_reader_t*         tb_oc_reader_get(tb_size_t format);

/*! remove object reader
 *
 * @param format        the reader format
 */
tb_void_t               tb_oc_reader_remove(tb_size_t format);

/*! done reader
 *
 * @param stream        the stream
 *
 * @return              the object
 */
tb_object_ref_t      tb_oc_reader_done(tb_stream_ref_t stream);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
