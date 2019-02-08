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
 * @file        directory.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../file.h"
#include "../path.h"
#include "../directory.h"
#include "../environment.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <dirent.h>
#include <unistd.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t tb_directory_walk_remove(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(path && info, tb_false);

    // remove file, directory and dead symbol link (info->type is none, file not exists)
    remove(path);

    // continue
    return tb_true;
}
static tb_bool_t tb_directory_walk_copy(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_value_t* tuple = (tb_value_t*)priv;
    tb_assert_and_check_return_val(path && info && priv, tb_false);

    // the dest directory
    tb_char_t const* dest = tuple[0].cstr;
    tb_assert_and_check_return_val(dest, tb_false);

    // the file name
    tb_size_t size = tuple[1].ul;
    tb_char_t const* name = path + size;

    // the dest file path
    tb_char_t dpath[8192] = {0};
    tb_snprintf(dpath, 8192, "%s/%s", dest, name[0] == '/'? name + 1 : name);

    // remove the dest file first
    tb_file_info_t dinfo = {0};
    if (tb_file_info(dpath, &dinfo))
    {
        if (dinfo.type == TB_FILE_TYPE_FILE)
            tb_file_remove(dpath);
        if (dinfo.type == TB_FILE_TYPE_DIRECTORY)
            tb_directory_remove(dpath);
    }

    // copy 
    switch (info->type)
    {
    case TB_FILE_TYPE_FILE:
        if (!tb_file_copy(path, dpath)) tuple[2].b = tb_false;
        break;
    case TB_FILE_TYPE_DIRECTORY:
        if (!tb_directory_create(dpath)) tuple[2].b = tb_false;
        break;
    default:
        break;
    }

    // continue
    return tb_true;
}
static tb_bool_t tb_directory_walk_impl(tb_char_t const* path, tb_long_t recursion, tb_bool_t prefix, tb_directory_walk_func_t func, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(path && func, tb_false);

    // last
    tb_long_t       last = tb_strlen(path) - 1;
    tb_assert_and_check_return_val(last >= 0, tb_false);

    // done 
    tb_bool_t       ok = tb_true;
    tb_char_t       temp[4096] = {0};
    DIR*            directory = tb_null;
    if ((directory = opendir(path)))
    {
        // walk
        struct dirent* item = tb_null;
        while ((item = readdir(directory)))
        {
            // check
            tb_assert_and_check_continue(item->d_reclen);

            // the item name
            tb_char_t name[1024] = {0};
            tb_strncpy(name, item->d_name, tb_min(item->d_reclen, sizeof(name) - 1));
            if (tb_strcmp(name, ".") && tb_strcmp(name, ".."))
            {
                // the temp path
                tb_long_t n = tb_snprintf(temp, 4095, "%s%s%s", path, path[last] == '/'? "" : "/", name);
                if (n >= 0) temp[n] = '\0';

                // get the file info (file maybe not exists, dead symbol link)
                tb_file_info_t info = {0};
                tb_file_info(temp, &info);

                // do callback
                if (prefix) ok = func(temp, &info, priv);
                tb_check_break(ok);

                // walk to the next directory
                if (info.type == TB_FILE_TYPE_DIRECTORY && recursion) ok = tb_directory_walk_impl(temp, recursion > 0? recursion - 1 : recursion, prefix, func, priv);
                tb_check_break(ok);

                // do callback
                if (!prefix) ok = func(temp, &info, priv);
                tb_check_break(ok);
            }
        }

        // exit directory
        closedir(directory);
    }

    // continue ?
    return ok;
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_directory_create(tb_char_t const* path)
{
    // check
    tb_assert_and_check_return_val(path, tb_false);

    // the full path
    tb_char_t full[TB_PATH_MAXN];
    path = tb_path_absolute(path, full, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_false);

    // make it (0755: drwxr-xr-x)
    tb_bool_t ok = !mkdir(path, S_IRWXU | S_IRWXG | S_IRWXO)? tb_true : tb_false;
    if (!ok)
    {
        // make directory
        tb_char_t           temp[TB_PATH_MAXN] = {0};
        tb_char_t const*    p = full;
        tb_char_t*          t = temp;
        tb_char_t const*    e = temp + TB_PATH_MAXN - 1;
        for (; t < e && *p; t++) 
        {
            *t = *p;
            if (*p == '/')
            {
                // make directory if not exists
                if (!tb_file_info(temp, tb_null)) mkdir(temp, S_IRWXU | S_IRWXG | S_IRWXO);

                // skip repeat '/'
                while (*p && *p == '/') p++;
            }
            else p++;
        }

        // make it again
        ok = !mkdir(path, S_IRWXU | S_IRWXG | S_IRWXO)? tb_true : tb_false;
    }

    // ok?
    return ok;
}
tb_bool_t tb_directory_remove(tb_char_t const* path)
{
    // the full path
    tb_char_t full[TB_PATH_MAXN];
    path = tb_path_absolute(path, full, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_false);

    // walk remove
    tb_directory_walk_impl(path, -1, tb_false, tb_directory_walk_remove, tb_null);

    // remove it
    return !remove(path)? tb_true : tb_false;
}
tb_size_t tb_directory_current(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn, 0);

    // the current directory
    tb_size_t size = 0;
    if (getcwd(path, maxn - 1)) size = tb_strlen(path);

    // ok?
    return size;
}
tb_bool_t tb_directory_current_set(tb_char_t const* path)
{
    // the absolute path
    tb_char_t full[TB_PATH_MAXN];
    path = tb_path_absolute(path, full, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_false);

    // change to the directory
    return !chdir(path);
}
#if !defined(TB_CONFIG_OS_IOS) && !defined(TB_CONFIG_OS_ANDROID)
tb_size_t tb_directory_home(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn, 0);

    // get the home directory
    tb_size_t size = 0;
    if (!(size = tb_environment_first("XDG_CONFIG_HOME", path, maxn)))
        size = tb_environment_first("HOME", path, maxn);

    // ok
    return size;
}
tb_size_t tb_directory_temporary(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn > 4, 0);

    // the temporary directory
    return tb_strlcpy(path, "/tmp", maxn);
}
#endif
tb_void_t tb_directory_walk(tb_char_t const* path, tb_long_t recursion, tb_bool_t prefix, tb_directory_walk_func_t func, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return(path && func);

    // walk it directly if rootdir is relative path
    tb_file_info_t info = {0};
    if (!tb_path_is_absolute(path) && tb_file_info(path, &info) && info.type == TB_FILE_TYPE_DIRECTORY) 
        tb_directory_walk_impl(path, recursion, prefix, func, priv);
    else
    {
        // the absolute path (translate "~/")
        tb_char_t full[TB_PATH_MAXN];
        path = tb_path_absolute(path, full, TB_PATH_MAXN);
        tb_assert_and_check_return(path);

        // walk
        tb_directory_walk_impl(path, recursion, prefix, func, priv);
    }
}
tb_bool_t tb_directory_copy(tb_char_t const* path, tb_char_t const* dest)
{
    // the absolute path
    tb_char_t full0[TB_PATH_MAXN];
    path = tb_path_absolute(path, full0, TB_PATH_MAXN);
    tb_assert_and_check_return_val(path, tb_false);

    // the dest path
    tb_char_t full1[TB_PATH_MAXN];
    dest = tb_path_absolute(dest, full1, TB_PATH_MAXN);
    tb_assert_and_check_return_val(dest, tb_false);

    // walk copy
    tb_value_t tuple[3];
    tuple[0].cstr = dest;
    tuple[1].ul = tb_strlen(path);
    tuple[2].b = tb_true;
    tb_directory_walk_impl(path, -1, tb_true, tb_directory_walk_copy, tuple);

    // ok?
    tb_bool_t ok = tuple[2].b;

    // copy empty directory?
    if (ok && !tb_file_info(dest, tb_null)) 
        return tb_directory_create(dest);

    // ok?
    return ok;
}
