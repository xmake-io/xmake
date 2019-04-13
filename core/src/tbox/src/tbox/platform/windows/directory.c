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
 * @file        directory.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../file.h"
#include "../path.h"
#include "../print.h"
#include "../directory.h"
#include "interface/interface.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t tb_directory_walk_remove(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(path && info, tb_false);

    // remove file
    if (info->type == TB_FILE_TYPE_FILE) tb_file_remove(path);
    // remvoe directory
    else if (info->type == TB_FILE_TYPE_DIRECTORY)
    {
        tb_wchar_t temp[TB_PATH_MAXN];
        if (tb_atow(temp, path, TB_PATH_MAXN) != -1)
            RemoveDirectoryW(temp);
    }

    // continue 
    return tb_true;
}
static tb_bool_t tb_directory_walk_copy(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_value_t* tuple = (tb_value_t*)priv;
    tb_assert_and_check_return_val(path && info && tuple, tb_false);

    // the dest directory
    tb_char_t const* dest = tuple[0].cstr;
    tb_assert_and_check_return_val(dest, tb_false);

    // the file name
    tb_size_t size = tuple[1].ul;
    tb_char_t const* name = path + size;

    // the dest file path
    tb_char_t dpath[8192] = {0};
    tb_snprintf(dpath, 8192, "%s\\%s", dest, name[0] == '\\'? name + 1 : name);

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
static tb_bool_t tb_directory_walk_impl(tb_wchar_t const* path, tb_long_t recursion, tb_bool_t prefix, tb_directory_walk_func_t func, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return_val(path && func, tb_false);

    // last
    tb_long_t           last = tb_wcslen(path) - 1;
    tb_assert_and_check_return_val(last >= 0, tb_false);

    // add \*.*
    tb_wchar_t          temp_w[4096] = {0};
    tb_char_t           temp_a[4096] = {0};
    tb_swprintf(temp_w, 4095, L"%s%s*.*", path, path[last] == L'\\'? L"" : L"\\");

    // done 
    tb_bool_t           ok = tb_true;
    WIN32_FIND_DATAW    find = {0};
    HANDLE              directory = INVALID_HANDLE_VALUE;
    if (INVALID_HANDLE_VALUE != (directory = FindFirstFileW(temp_w, &find)))
    {
        // walk
        do
        {
            // check
            if (tb_wcscmp(find.cFileName, L".") && tb_wcscmp(find.cFileName, L".."))
            {
                // the temp path
                tb_long_t n = tb_swprintf(temp_w, 4095, L"%s%s%s", path, path[last] == L'\\'? L"" : L"\\", find.cFileName);
                if (n >= 0 && n < 4096) temp_w[n] = L'\0';

                // wtoa temp
                n = tb_wtoa(temp_a, temp_w, 4095);
                tb_assert_and_check_break(n != -1);

                // the file info
                tb_file_info_t info = {0};
                if (tb_file_info(temp_a, &info))
                {
                    // do callback
                    if (prefix) ok = func(temp_a, &info, priv);
                    tb_check_break(ok);

                    // walk to the next directory
                    if (info.type == TB_FILE_TYPE_DIRECTORY && recursion) ok = tb_directory_walk_impl(temp_w, recursion > 0? recursion - 1 : recursion, prefix, func, priv);
                    tb_check_break(ok);
    
                    // do callback
                    if (!prefix) ok = func(temp_a, &info, priv);
                    tb_check_break(ok);
                }
            }

        } while (FindNextFileW(directory, &find));

        // exit directory
        FindClose(directory);
    }

    // continue?
    return ok;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_directory_create(tb_char_t const* path)
{
    // check
    tb_assert_and_check_return_val(path, tb_false);

    // the absolute path
    tb_wchar_t full[TB_PATH_MAXN];
    if (!tb_path_absolute_w(path, full, TB_PATH_MAXN)) return tb_false;

    // make it
    tb_bool_t ok = CreateDirectoryW(full, tb_null)? tb_true : tb_false;
    if (!ok)
    {
        // make directory
        tb_wchar_t          temp[TB_PATH_MAXN] = {0};
        tb_wchar_t const*   p = full;
        tb_wchar_t*         t = temp;
        tb_wchar_t const*   e = temp + TB_PATH_MAXN - 1;
        for (; t < e && *p; t++) 
        {
            *t = *p;
            if (*p == L'\\' || *p == L'/')
            {
                // make directory if not exists
                if (INVALID_FILE_ATTRIBUTES == GetFileAttributesW(temp)) CreateDirectoryW(temp, tb_null);

                // skip repeat '\\' or '/'
                while (*p && (*p == L'\\' || *p == L'/')) p++;
            }
            else p++;
        }

        // make it again
        ok = CreateDirectoryW(full, tb_null)? tb_true : tb_false;
    }

    // ok?
    return ok;
}
tb_bool_t tb_directory_remove(tb_char_t const* path)
{
    // check
    tb_assert_and_check_return_val(path, tb_false);

    // the absolute path
    tb_wchar_t full[TB_PATH_MAXN];
    if (!tb_path_absolute_w(path, full, TB_PATH_MAXN)) return tb_false;

    // walk remove
    tb_directory_walk_impl(full, -1, tb_false, tb_directory_walk_remove, tb_null);

    // remove it
    return RemoveDirectoryW(full)? tb_true : tb_false;
}
tb_size_t tb_directory_home(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn, 0);

    // the home directory
    tb_bool_t   ok = tb_false;
    tb_handle_t pidl = tb_null;
    tb_wchar_t  home[TB_PATH_MAXN] = {0};
    do
    {
        // get the appdata folder location
        if (S_OK != tb_shell32()->SHGetSpecialFolderLocation(tb_null, 0x1a /* CSIDL_APPDATA */, &pidl)) break;
        tb_check_break(pidl);

        // get the home directory   
        if (!tb_shell32()->SHGetPathFromIDListW(pidl, home)) break;

        // ok
        ok = tb_true;

    } while (0);

    // exit pidl
    if (pidl) GlobalFree(pidl);
    pidl = tb_null;

    // wtoa
    tb_size_t size = ok? tb_wtoa(path, home, maxn) : 0;

    // ok?
    return size != -1? size : 0;
}
tb_size_t tb_directory_current(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn > 4, 0);

    // the current directory
    tb_wchar_t current[TB_PATH_MAXN] = {0};
    GetCurrentDirectoryW(TB_PATH_MAXN, current);

    // wtoa
    tb_size_t size = tb_wtoa(path, current, maxn);

    // ok?
    return size != -1? size : 0;
}
tb_bool_t tb_directory_current_set(tb_char_t const* path)
{
    // the absolute path
    tb_wchar_t full[TB_PATH_MAXN];
    if (!tb_path_absolute_w(path, full, TB_PATH_MAXN)) return tb_false;

    // change to the directory
    return SetCurrentDirectoryW(full);
}
tb_size_t tb_directory_temporary(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn > 4, 0);

    // the temporary directory
    tb_wchar_t temporary[TB_PATH_MAXN] = {0};
    GetTempPathW(TB_PATH_MAXN, temporary);

    // wtoa
    tb_size_t size = tb_wtoa(path, temporary, maxn);

    // ok?
    return size != -1? size : 0;
}
tb_void_t tb_directory_walk(tb_char_t const* path, tb_long_t recursion, tb_bool_t prefix, tb_directory_walk_func_t func, tb_cpointer_t priv)
{
    // check
    tb_assert_and_check_return(path && func);

    // walk it directly if rootdir is relative path
    tb_file_info_t info = {0};
    if (!tb_path_is_absolute(path) && tb_file_info(path, &info) && info.type == TB_FILE_TYPE_DIRECTORY) 
    {
        tb_wchar_t path_w[TB_PATH_MAXN];
        if (tb_atow(path_w, path, tb_arrayn(path_w)) != -1)
            tb_directory_walk_impl(path_w, recursion, prefix, func, priv);
    }
    else
    {
        // the absolute path (translate "~/")
        tb_wchar_t full_w[TB_PATH_MAXN];
        if (tb_path_absolute_w(path, full_w, TB_PATH_MAXN))
            tb_directory_walk_impl(full_w, recursion, prefix, func, priv);
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
    tb_directory_walk(path, -1, tb_true, tb_directory_walk_copy, tuple);

    // ok?
    tb_bool_t ok = tuple[2].b;

    // copy empty directory?
    if (ok && !tb_file_info(dest, tb_null)) 
        return tb_directory_create(dest);

    // ok?
    return ok;
}
