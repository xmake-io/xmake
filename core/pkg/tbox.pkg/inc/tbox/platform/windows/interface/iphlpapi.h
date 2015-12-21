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
 * @file        iphlpapi.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_INTERFACE_IPHLPAPI_H
#define TB_PLATFORM_WINDOWS_INTERFACE_IPHLPAPI_H

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

// the GetNetworkParams func type
typedef DWORD (WINAPI* tb_iphlpapi_GetNetworkParams_t)(PFIXED_INFO pFixedInfo, PULONG pOutBufLen);

// the GetAdaptersInfo func type
typedef DWORD (WINAPI* tb_iphlpapi_GetAdaptersInfo_t)(PIP_ADAPTER_INFO pAdapterInfo, PULONG pOutBufLen);

// the GetAdaptersAddresses func type
typedef ULONG (WINAPI* tb_iphlpapi_GetAdaptersAddresses_t)(ULONG Family, ULONG Flags, PVOID Reserved, PIP_ADAPTER_ADDRESSES AdapterAddresses, PULONG SizePointer);

// the iphlpapi interfaces type
typedef struct __tb_iphlpapi_t
{
    // GetNetworkParams
    tb_iphlpapi_GetNetworkParams_t          GetNetworkParams;

    // GetAdaptersInfo
    tb_iphlpapi_GetAdaptersInfo_t           GetAdaptersInfo;

    // GetAdaptersAddresses
    tb_iphlpapi_GetAdaptersAddresses_t      GetAdaptersAddresses;

}tb_iphlpapi_t, *tb_iphlpapi_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* the iphlpapi interfaces
 *
 * @return          the iphlpapi interfaces pointer
 */
tb_iphlpapi_ref_t   tb_iphlpapi(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
