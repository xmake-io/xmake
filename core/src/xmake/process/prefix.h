/*!A cross-platform build utility based on Lua
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this subprocess except in compliance with the License.
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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @subprocess        prefix.h
 *
 */
#ifndef XM_PROCESS_PREFIX_H
#define XM_PROCESS_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macross
 */

// the subprocess udata type
#define xm_subprocess_udata    "process._subprocess*"

// return lock success
#define xm_subprocess_return_success()       do { return 1; } while (0)

// return lock error with reason
#define xm_subprocess_return_error(lua, subprocess, reason)                                                           \
    do                                                                                                                \
    {                                                                                                                 \
        lua_pushnil(lua);                                                                                             \
        lua_pushfstring(lua, "error: %s (%s)", reason, subprocess->name);                                             \
        return 2;                                                                                                     \
    } while (0)

// return closed error
#define xm_subprocess_return_error_closed(lua)                                                                        \
    do                                                                                                                \
    {                                                                                                                 \
        lua_pushnil(lua);                                                                                             \
        lua_pushliteral(lua, "error: subprocess has been closed");                                                    \
        return 2;                                                                                                     \
    } while (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the subprocess type
typedef struct __xm_subprocess_t
{
    // the process reference
    tb_process_ref_t    process;

    // is opened?
    tb_bool_t           is_opened;

    // the process name
    tb_char_t           name[32];

} xm_subprocess_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
static __tb_inline__ xm_subprocess_t* xm_subprocess_new(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, tb_null);

    // new subprocess
    xm_subprocess_t* subprocess = (xm_subprocess_t*)lua_newuserdata(lua, sizeof(xm_subprocess_t));
    tb_assert_and_check_return_val(subprocess, tb_null);

    // init subprocess
    luaL_getmetatable(lua, xm_subprocess_udata);
    lua_setmetatable(lua, -2);
    tb_memset(subprocess, 0, sizeof(xm_subprocess_t));
    return subprocess;
}

static __tb_inline__ xm_subprocess_t* xm_subprocess_get(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, tb_null);

    // get subprocess
    xm_subprocess_t* subprocess = (xm_subprocess_t*)luaL_checkudata(lua, 1, xm_subprocess_udata);
    tb_assert(subprocess);
    return subprocess;
}


#endif


