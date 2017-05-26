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
 * @file        versioninfo.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "versioninfo"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

static tb_void_t xm_os_insert_set(lua_State* lua, tb_char_t const** p)
{
    for (; *p; ++p)
    {
        lua_pushstring(lua, *p);
        lua_pushboolean(lua, tb_true);
        lua_settable(lua, -3);
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// get versioninfo
tb_int_t xm_os_versioninfo(lua_State* lua)
{
    // features
    static tb_char_t const* features_table[] = 
    {
#ifdef XM_CONFIG_API_HAVE_READLINE
        "readline",
#endif
        tb_null
    };

    // configuration table
    lua_newtable(lua);
    lua_pushstring(lua, "features");

    // table for features
    lua_newtable(lua);

    // insert
    xm_os_insert_set(lua, features_table);

    // set back to table
    lua_settable(lua, -3);

    // table for version
    lua_pushstring(lua, "version");
    lua_newtable(lua);
    // major
    lua_pushstring(lua, "major");
    lua_pushinteger(lua, XM_VERSION_MAJOR);
    lua_settable(lua, -3);
    // minor
    lua_pushstring(lua, "minor");
    lua_pushinteger(lua, XM_VERSION_MINOR);
    lua_settable(lua, -3);
    // alter
    lua_pushstring(lua, "alter");
    lua_pushinteger(lua, XM_VERSION_ALTER);
    lua_settable(lua, -3);
    // build
    lua_pushstring(lua, "build");
    lua_pushnumber(lua, XM_VERSION_BUILD);
    lua_settable(lua, -3);
    // build string
    lua_pushstring(lua, "build_string");
    lua_pushstring(lua, XM_VERSION_BUILD_STRING);
    lua_settable(lua, -3);
    // version string
    lua_pushstring(lua, "version_string");
    lua_pushstring(lua, XM_VERSION_STRING);
    lua_settable(lua, -3);
    // short version string
    lua_pushstring(lua, "short_version_string");
    lua_pushstring(lua, XM_VERSION_SHORT_STRING);
    lua_settable(lua, -3);

    // table for tbox version
    lua_pushstring(lua, "tbox");
    lua_newtable(lua);
    // major
    lua_pushstring(lua, "major");
    lua_pushinteger(lua, TB_VERSION_MAJOR);
    lua_settable(lua, -3);
    // minor
    lua_pushstring(lua, "minor");
    lua_pushinteger(lua, TB_VERSION_MINOR);
    lua_settable(lua, -3);
    // alter
    lua_pushstring(lua, "alter");
    lua_pushinteger(lua, TB_VERSION_ALTER);
    lua_settable(lua, -3);
    // build
    lua_pushstring(lua, "build");
    lua_pushnumber(lua, TB_VERSION_BUILD);
    lua_settable(lua, -3);
    // build string
    lua_pushstring(lua, "build_string");
    lua_pushstring(lua, TB_VERSION_BUILD_STRING);
    lua_settable(lua, -3);
    // version string
    lua_pushstring(lua, "version_string");
    lua_pushstring(lua, TB_VERSION_STRING);
    lua_settable(lua, -3);
    // short version string
    lua_pushstring(lua, "short_version_string");
    lua_pushstring(lua, TB_VERSION_SHORT_STRING);
    lua_settable(lua, -3);

    // set back to table
    lua_settable(lua, -3);

    // table for lua version
    lua_pushstring(lua, "lua");
    lua_newtable(lua);

    // version
    lua_pushstring(lua, "version");
    lua_pushstring(lua, LUA_RELEASE);
    lua_settable(lua, -3);

    // version num
    lua_pushstring(lua, "version_num");
    lua_pushinteger(lua, LUA_VERSION_NUM);
    lua_settable(lua, -3);

    // set back to table
    lua_settable(lua, -3);

    // table for luajit version
    lua_pushstring(lua, "luajit");
    lua_newtable(lua);

    // version
    lua_pushstring(lua, "version");
    lua_pushstring(lua, LUAJIT_VERSION);
    lua_settable(lua, -3);

    // version num
    lua_pushstring(lua, "version_num");
    lua_pushinteger(lua, LUAJIT_VERSION_NUM);
    lua_settable(lua, -3);

    // set back to table
    lua_settable(lua, -3);

    // set back to table
    lua_settable(lua, -3);

    // mode table
    static tb_char_t const* mode_table[] = 
    {
#ifdef __xm_small__
        "small",
#endif
#ifdef __xm_debug__
        "debug",
#endif
        tb_null
    };

    // table for mode
    lua_pushstring(lua, "modes");
    lua_newtable(lua);

    // insert
    xm_os_insert_set(lua, mode_table);

    // set back to table
    lua_settable(lua, -3);

    // packages table
    tb_char_t const* packages_table[] = 
    {
#ifdef XM_CONFIG_PACKAGE_HAVE_TBOX
        "tbox",
#endif
#ifdef XM_CONFIG_PACKAGE_HAVE_LUAJIT
        "luajit",
#endif
#ifdef XM_CONFIG_PACKAGE_HAVE_BASE
        "base",
#endif
        tb_null
    };

    // table for packages
    lua_pushstring(lua, "packages");
    lua_newtable(lua);

    // insert
    xm_os_insert_set(lua, packages_table);

    // set back to table
    lua_settable(lua, -3);

    lua_pushstring(lua, "host");
    // init host
#if defined(TB_CONFIG_OS_WINDOWS)
    lua_pushstring(lua, "windows");
#elif defined(TB_CONFIG_OS_MACOSX)
    lua_pushstring(lua, "macosx");
#elif defined(TB_CONFIG_OS_LINUX)
    lua_pushstring(lua, "linux");
#elif defined(TB_CONFIG_OS_IOS)
    lua_pushstring(lua, "ios");
#elif defined(TB_CONFIG_OS_ANDROID)
    lua_pushstring(lua, "android");
#elif defined(TB_CONFIG_OS_LIKE_UNIX)
    lua_pushstring(lua, "unix");
#else
    lua_pushstring(lua, "unknown");
#endif
    lua_settable(lua, -3);

    lua_pushstring(lua, "arch");
    // init architecture
#if defined(TB_ARCH_x86)
    lua_pushstring(lua, "i386");
#elif defined(TB_ARCH_x64)
    lua_pushstring(lua, "x86_64");
#else
    lua_pushstring(lua, TB_ARCH_STRING);
#endif
    lua_settable(lua, -3);

    lua_pushstring(lua, "nuldev");
    // init redirect to null
#if defined(TB_CONFIG_OS_WINDOWS)
    lua_pushstring(lua, "nul");
#else
    lua_pushstring(lua, "/dev/null");
#endif
    lua_settable(lua, -3);

    // ok
    return 1;
}
