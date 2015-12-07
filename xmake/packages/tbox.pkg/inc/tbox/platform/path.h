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

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
