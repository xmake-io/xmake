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
 * @path        path.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_PATH_H
#define TB_PLATFORM_PATH_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the path maximum
#define TB_PATH_MAXN        (4096)

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! translate the path to the native path
 * 
 * - transform the path separator
 * - remove the repeat path separator
 * - expand the user directory with the prefix: ~
 *
 * @param path          the path 
 * @param size          the path size, optional
 * @param maxn          the path maxn
 *
 * @return              tb_true or tb_false
 */
tb_size_t               tb_path_translate(tb_char_t* path, tb_size_t size, tb_size_t maxn);

/*! the path is absolute?
 * 
 * @param path          the path 
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_path_is_absolute(tb_char_t const* path);

/*! get the absolute path which relative to the current directory
 * 
 * @param path          the path 
 * @param data          the path data
 * @param maxn          the path maxn
 *
 * @return              the absolute path
 */
tb_char_t const*        tb_path_absolute(tb_char_t const* path, tb_char_t* data, tb_size_t maxn);

/*! get the absolute path which relative to the given root directory
 * 
 * @param root          the root path 
 * @param path          the path 
 * @param data          the path data
 * @param maxn          the path maxn
 *
 * @return              the absolute path
 */
tb_char_t const*        tb_path_absolute_to(tb_char_t const* root, tb_char_t const* path, tb_char_t* data, tb_size_t maxn);

/*! get the path which relative to the current directory
 * 
 * @param path          the path 
 * @param data          the path data
 * @param maxn          the path maxn
 *
 * @return              the relative path
 */
tb_char_t const*        tb_path_relative(tb_char_t const* path, tb_char_t* data, tb_size_t maxn);

/*! get the path which relative to the given root directory
 * 
 * @param root          the root path 
 * @param path          the path 
 * @param data          the path data
 * @param maxn          the path maxn
 *
 * @return              the relative path
 */
tb_char_t const*        tb_path_relative_to(tb_char_t const* root, tb_char_t const* path, tb_char_t* data, tb_size_t maxn);

/*! get the directory of path
 *
 * @param path          the path
 * @param data          the path data
 * @param maxn          the path maxn
 *
 * @return              the directory of path
 */
tb_char_t const*        tb_path_directory(tb_char_t const* path, tb_char_t* data, tb_size_t maxn);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
