/*!The Make-like Build Utility based on Lua
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2015 - 2018, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        isatty.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "isatty"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_OS_WINDOWS
#   include <io.h>
#else
#   include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* stdout: io.isatty()
 * stderr: io.isatty(io.stderr)
 * stdin:  io.isatty(io.stdin)
 */
tb_int_t xm_io_isatty(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get file pointer
    FILE** fp = (FILE**)luaL_checkudata(lua, 1, LUA_FILEHANDLE);

    // no arguments? default: stdout
    tb_int_t answer = 1;
#ifdef TB_CONFIG_OS_WINDOWS
    if (fp) answer = _isatty(_fileno(*fp));
#else
    if (fp) answer = isatty(fileno(*fp));
#endif

    // return answer
	lua_pushboolean(lua, answer);

    // ok
    return 1;
}
