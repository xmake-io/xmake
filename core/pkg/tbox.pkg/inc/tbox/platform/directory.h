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
 * @param recursion     is recursion?
 * @param prefix        is prefix recursion? directory is the first item
 * @param func          the callback func
 * @param data          the callback data
 * 
 */
tb_void_t               tb_directory_walk(tb_char_t const* path, tb_bool_t recursion, tb_bool_t prefix, tb_directory_walk_func_t func, tb_cpointer_t priv);

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
