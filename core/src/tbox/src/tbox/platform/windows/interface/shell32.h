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
 * @file        shell32.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_INTERFACE_SHELL32_H
#define TB_PLATFORM_WINDOWS_INTERFACE_SHELL32_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the SHGetSpecialFolderLocation func type
typedef HRESULT (WINAPI* tb_shell32_SHGetSpecialFolderLocation_t)(HWND hwndOwner, tb_int_t nFolder, tb_handle_t *ppidl);

// the SHGetPathFromIDListW func type
typedef BOOL (WINAPI* tb_shell32_SHGetPathFromIDListW_t)(tb_handle_t pidl, LPWSTR pszPath);

// the shell32 interfaces type
typedef struct __tb_shell32_t
{
    // SHGetSpecialFolderLocation
    tb_shell32_SHGetSpecialFolderLocation_t     SHGetSpecialFolderLocation;

    // SHGetPathFromIDListW
    tb_shell32_SHGetPathFromIDListW_t           SHGetPathFromIDListW;

}tb_shell32_t, *tb_shell32_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* the shell32 interfaces
 *
 * @return          the shell32 interfaces pointer
 */
tb_shell32_ref_t    tb_shell32(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
