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
