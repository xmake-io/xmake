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
 * @file        dbghelp.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_INTERFACE_DBGHELP_H
#define TB_PLATFORM_WINDOWS_INTERFACE_DBGHELP_H

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

// the symbol info type
typedef struct __tb_dbghelp_symbol_info_t 
{
    ULONG       SizeOfStruct;
    ULONG       TypeIndex;
    ULONG64     Reserved[2];
    ULONG       info;
    ULONG       Size;
    ULONG64     ModBase;
    ULONG       Flags;
    ULONG64     Value;
    ULONG64     Address;
    ULONG       Register;
    ULONG       Scope;
    ULONG       Tag;
    ULONG       NameLen;
    ULONG       MaxNameLen;
    CHAR        Name[1];

}tb_dbghelp_symbol_info_t;

// the SymInitialize func type
typedef BOOL (WINAPI* tb_dbghelp_SymInitialize_t)(HANDLE hProcess, LPCTSTR UserSearchPath, BOOL fInvadeProcess);

// the SymFromAddr func type
typedef BOOL (WINAPI* tb_dbghelp_SymFromAddr_t)(HANDLE hProcess, DWORD64 Address, PDWORD64 Displacement, tb_dbghelp_symbol_info_t* Symbol);

// the SymSetOptions func type
typedef DWORD (WINAPI* tb_dbghelp_SymSetOptions_t)(DWORD SymOptions);

// the dbghelp interfaces type
typedef struct __tb_dbghelp_t
{
    // SymInitialize
    tb_dbghelp_SymInitialize_t          SymInitialize;

    // SymFromAddr
    tb_dbghelp_SymFromAddr_t            SymFromAddr;

    // SymSetOptions
    tb_dbghelp_SymSetOptions_t          SymSetOptions;

}tb_dbghelp_t, *tb_dbghelp_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* the dbghelp interfaces
 *
 * @return          the dbghelp interfaces pointer
 */
tb_dbghelp_ref_t    tb_dbghelp(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
