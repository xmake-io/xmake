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
 * @file        user32.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_INTERFACE_USER32_H
#define TB_PLATFORM_WINDOWS_INTERFACE_USER32_H

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

// the GetSystemMetrics func type 
typedef tb_int_t (WINAPI* tb_user32_GetSystemMetrics_t)(tb_int_t index);

// the user32 interfaces type
typedef struct __tb_user32_t
{
    // GetSystemMetrics
    tb_user32_GetSystemMetrics_t      GetSystemMetrics;

}tb_user32_t, *tb_user32_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* the user32 interfaces
 *
 * @return          the user32 interfaces pointer
 */
tb_user32_ref_t    tb_user32(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
