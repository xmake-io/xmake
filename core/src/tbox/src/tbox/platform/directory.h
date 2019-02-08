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
 * @file        directory.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_DIRECTORY_H
#define TB_PLATFORM_DIRECTORY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "file.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the directory walk func type
 *
 * @param path          the file path
 * @param info          the file info
 * @param priv          the user private data
 *
 * @return              continue: tb_true, break: tb_false
 */
typedef tb_bool_t       (*tb_directory_walk_func_t)(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! create the directory
 * 
 * @param path          the directory path
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_directory_create(tb_char_t const* path);

/*! remove the directory
 * 
 * @param path          the directory path
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_directory_remove(tb_char_t const* path);

/*! the home directory
 * 
 * @param path          the directory path data
 * @param maxn          the directory path maxn
 *
 * @return              the directory path size
 */
tb_size_t               tb_directory_home(tb_char_t* path, tb_size_t maxn);

/*! the current directory
 * 
 * @param path          the directory path data
 * @param maxn          the directory path maxn
 *
 * @return              the directory path size
 */
tb_size_t               tb_directory_current(tb_char_t* path, tb_size_t maxn);

/*! set the current directory
 * 
 * @param path          the directory path 
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_directory_current_set(tb_char_t const* path);

/*! the temporary directory
 * 
 * @param path          the directory path data
 * @param maxn          the directory path maxn
 *
 * @return              the directory path size
 */
tb_size_t               tb_directory_temporary(tb_char_t* path, tb_size_t maxn);

/*! the directory walk
 *
 * @param path          the directory path
 * @param recursion     the recursion level, 0, 1, 2, .. or -1 (infinite)
 * @param prefix        is prefix recursion? directory is the first item
 * @param func          the callback func
 * @param data          the callback data
 * 
 */
tb_void_t               tb_directory_walk(tb_char_t const* path, tb_long_t recursion, tb_bool_t prefix, tb_directory_walk_func_t func, tb_cpointer_t priv);

/*! copy directory
 * 
 * @param path          the directory path
 * @param dest          the directory dest
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_directory_copy(tb_char_t const* path, tb_char_t const* dest);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
