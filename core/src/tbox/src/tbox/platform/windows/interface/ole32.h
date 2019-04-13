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
 * @file        ole32.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_INTERFACE_OLE32_H
#define TB_PLATFORM_WINDOWS_INTERFACE_OLE32_H

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

// the CoCreateGuid func type
typedef HRESULT (WSAAPI* tb_ole32_CoCreateGuid_t)(GUID* pguid);

// the ole32 interfaces type
typedef struct __tb_ole32_t
{
    // CoCreateGuid
    tb_ole32_CoCreateGuid_t     CoCreateGuid;

}tb_ole32_t, *tb_ole32_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* the ole32 interfaces
 *
 * @return          the ole32 interfaces pointer
 */
tb_ole32_ref_t      tb_ole32(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
