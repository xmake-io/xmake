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
