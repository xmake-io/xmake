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
