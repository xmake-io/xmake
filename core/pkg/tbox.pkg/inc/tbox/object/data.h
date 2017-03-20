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
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        data.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_DATA_H
#define TB_OBJECT_DATA_H

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

/*! init data from url
 *
 * @param data      the data
 * @param size      the size
 *
 * @return          the data object
 */
tb_object_ref_t     tb_oc_data_init_from_url(tb_char_t const* url);

/*! init data from data
 *
 * @param data      the data
 * @param size      the size
 *
 * @return          the data object
 */
tb_object_ref_t     tb_oc_data_init_from_data(tb_pointer_t data, tb_size_t size);

/*! init data from buffer
 *
 * @param buffer    the buffer
 *
 * @return          the data object
 */
tb_object_ref_t     tb_oc_data_init_from_buffer(tb_buffer_ref_t buffer);

/*! get the data 
 *
 * @param data      the data object
 *
 * @return          the data address
 */
tb_pointer_t        tb_oc_data_getp(tb_object_ref_t data);

/*! set the data 
 *
 * @param data      the data object
 * @param addr      the data address
 * @param size      the data size
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_oc_data_setp(tb_object_ref_t data, tb_pointer_t addr, tb_size_t size);

/*! the data size
 *
 * @param data      the data object
 *
 * @return          the data size
 */
tb_size_t           tb_oc_data_size(tb_object_ref_t data);

/*! the data buffer
 *
 * @param data      the data object
 *
 * @return          the data buffer
 */
tb_buffer_ref_t     tb_oc_data_buffer(tb_object_ref_t data);

/*! writ data to url
 *
 * @param data      the data object
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_oc_data_writ_to_url(tb_object_ref_t data, tb_char_t const* url);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

