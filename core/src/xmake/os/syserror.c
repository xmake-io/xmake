/*!A cross-platform build utility based on Lua
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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        syserror.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "syserror"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_syserror(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get syserror state
    tb_int_t  err = 0;
    tb_size_t syserror = tb_syserror_state();
    switch (syserror)
    {
    case TB_STATE_SYSERROR_NOT_PERM:            err = 1; break;
    case TB_STATE_SYSERROR_NOT_FILEDIR:         err = 2; break;
    case TB_STATE_SYSERROR_UNKNOWN_ERROR:       err = -1; break;
    }
    lua_pushinteger(lua, err);
    return 1;
}
