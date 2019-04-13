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
 * @file        page.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the page size
static tb_size_t g_page_size = 0;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_page_init()
{
    // init page size
    if (!g_page_size)
    {
        SYSTEM_INFO info;
        GetSystemInfo(&info);
        g_page_size = info.dwPageSize;
    }

    // ok?
    return g_page_size? tb_true : tb_false;
}
tb_void_t tb_page_exit()
{
}
tb_size_t tb_page_size()
{
    return g_page_size;
}


