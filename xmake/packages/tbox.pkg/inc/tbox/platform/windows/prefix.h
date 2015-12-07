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
 * @file        prefix.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_PREFIX_H
#define TB_PLATFORM_WINDOWS_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../path.h"
#include "../../libc/libc.h"
#include "../../utils/utils.h"
#include "../../network/ipaddr.h"
#include <winsock2.h>
#include <mswsock.h>
#include <windows.h>
#include <iphlpapi.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * inlines
 */

// FILETIME => tb_time_t
static __tb_inline__ tb_time_t tb_filetime_to_time(FILETIME ft)
{
    ULARGE_INTEGER  ui = {{0}};  
    ui.LowPart      = ft.dwLowDateTime;  
    ui.HighPart     = ft.dwHighDateTime;  
    return (tb_time_t)((LONGLONG)(ui.QuadPart - 116444736000000000ull) / 10000000ul);  
}

// the path full for wchar
static __tb_inline__ tb_wchar_t const* tb_path_absolute_w(tb_char_t const* path, tb_wchar_t* full, tb_size_t maxn)
{
    // the path full
    tb_char_t full_a[TB_PATH_MAXN] = {0};
    if (!tb_path_absolute(path, full_a, TB_PATH_MAXN)) return tb_null;

    // atow
    tb_size_t size = tb_atow(full, full_a, maxn);
    if (size < maxn) full[size] = L'\0';

    // ok?
    return size? full : tb_null;
}

#endif
