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
