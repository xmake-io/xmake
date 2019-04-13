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
