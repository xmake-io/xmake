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
 * Copyright (C) 2015 - 2017, TBOOX Open Source Group.
 *
 * @author      TitanSnow
 * @file        getwinsize.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "getwinsize"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_OS_LINUX
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_getwinsize(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // def w&h
    unsigned short w=80, h=40;

    // get winsize
#   ifdef TB_CONFIG_OS_LINUX
    struct winsize size;
    ioctl(STDOUT_FILENO, TIOCGWINSZ, &size);
    w=size.ws_col;
    h=size.ws_row;
#   endif

    // done os.getwinsize()
    lua_newtable(lua);
    lua_pushstring(lua, "width");
    lua_pushinteger(lua, w);
    lua_settable(lua, -3);
    lua_pushstring(lua, "height");
    lua_pushinteger(lua, h);
    lua_settable(lua, -3);

    // ok
    return 1;
}
