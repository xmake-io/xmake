/*!The Automatic Cross-platform Build Tool
 * 
 * XMake is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * XMake is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with XMake; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        machine.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "machine"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "xmake.h"
#include "luajit/luajit.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the machine impl type
typedef struct __xm_machine_impl_t
{
    // the lua 
    lua_State*              lua;

}xm_machine_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */

// the os functions
tb_int_t xm_os_find(lua_State* lua);
tb_int_t xm_os_isdir(lua_State* lua);
tb_int_t xm_os_rmdir(lua_State* lua);
tb_int_t xm_os_mkdir(lua_State* lua);
tb_int_t xm_os_cpdir(lua_State* lua);
tb_int_t xm_os_chdir(lua_State* lua);
tb_int_t xm_os_mtime(lua_State* lua);
tb_int_t xm_os_curdir(lua_State* lua);
tb_int_t xm_os_tmpdir(lua_State* lua);
tb_int_t xm_os_isfile(lua_State* lua);
tb_int_t xm_os_rmfile(lua_State* lua);
tb_int_t xm_os_cpfile(lua_State* lua);
tb_int_t xm_os_rename(lua_State* lua);
tb_int_t xm_os_exists(lua_State* lua);
tb_int_t xm_os_setenv(lua_State* lua);
tb_int_t xm_os_getenv(lua_State* lua);
tb_int_t xm_os_emptydir(lua_State* lua);
tb_int_t xm_os_strerror(lua_State* lua);

// the path functions
tb_int_t xm_path_relative(lua_State* lua);
tb_int_t xm_path_absolute(lua_State* lua);
tb_int_t xm_path_translate(lua_State* lua);
tb_int_t xm_path_is_absolute(lua_State* lua);

// the string functions
tb_int_t xm_string_endswith(lua_State* lua);
tb_int_t xm_string_startswith(lua_State* lua);

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the os functions
static luaL_Reg const g_os_functions[] = 
{
    { "find",           xm_os_find      }
,   { "isdir",          xm_os_isdir     }
,   { "rmdir",          xm_os_rmdir     }
,   { "mkdir",          xm_os_mkdir     }
,   { "cpdir",          xm_os_cpdir     }
,   { "chdir",          xm_os_chdir     }
,   { "mtime",          xm_os_mtime     }
,   { "curdir",         xm_os_curdir    }
,   { "tmpdir",         xm_os_tmpdir    }
,   { "isfile",         xm_os_isfile    }
,   { "rmfile",         xm_os_rmfile    }
,   { "cpfile",         xm_os_cpfile    }
,   { "rename",         xm_os_rename    }
,   { "exists",         xm_os_exists    }
,   { "setenv",         xm_os_setenv    }
,   { "getenv",         xm_os_getenv    }
,   { "emptydir",       xm_os_emptydir  }
,   { "strerror",       xm_os_strerror  }
,   { tb_null,          tb_null         }
};

// the path functions
static luaL_Reg const g_path_functions[] = 
{
    { "relative",       xm_path_relative    }
,   { "absolute",       xm_path_absolute    }
,   { "translate",      xm_path_translate   }
,   { "is_absolute",    xm_path_is_absolute }
,   { tb_null,          tb_null             }
};

// the string functions
static luaL_Reg const g_string_functions[] = 
{
    { "endswith",       xm_string_endswith      }
,   { "startswith",     xm_string_startswith    }
,   { tb_null,          tb_null                 }
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_machine_main_save_arguments(xm_machine_impl_t* impl, tb_int_t argc, tb_char_t** argv)
{
    // check
    tb_assert_and_check_return_val(impl && impl->lua && argc >= 1 && argv, tb_false);

    // put a new table into the stack
    lua_newtable(impl->lua);

    // save all arguments to the new table
    tb_int_t i = 0;
    for (i = 1; i < argc; i++)
    {
        // table_new[table.getn(table_new) + 1] = argv[i]
        lua_pushstring(impl->lua, argv[i]);
        lua_rawseti(impl->lua, -2, luaL_getn(impl->lua, -2) + 1);
    }

    // _ARGV = table_new
    lua_setglobal(impl->lua, "_ARGV");

    // ok
    return tb_true;
}
static tb_bool_t xm_machine_main_get_program_directory(xm_machine_impl_t* impl, tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(impl && path && maxn, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // get it from the environment variable 
        tb_char_t data[TB_PATH_MAXN] = {0};
        if (!tb_environment_get_one("XMAKE_PROGRAM_DIR", data, sizeof(data)))
        {
            // error
            tb_printf("error: please set XMAKE_PROGRAM_DIR first!\n");
            break;
        }

        // get the full path
        if (!tb_path_absolute(data, path, maxn)) break;

        // trace
        tb_trace_d("program: %s", path);

        // save the directory to the global variable: _PROGRAM_DIR
        lua_pushstring(impl->lua, path);
        lua_setglobal(impl->lua, "_PROGRAM_DIR");

        // ok
        ok = tb_true;

    } while (0);

    // ok?
    return ok;
}
static tb_bool_t xm_machine_main_get_project_directory(xm_machine_impl_t* impl, tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(impl && path && maxn, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // attempt to get it from the environment variable first
        tb_char_t data[TB_PATH_MAXN] = {0};
        if (    !tb_environment_get_one("XMAKE_PROJECT_DIR", data, sizeof(data))
            ||  !tb_path_absolute(data, path, maxn))
        {
            // get it from the current directory
            if (!tb_directory_current(path, maxn)) break;
        }

        // trace
        tb_trace_d("project: %s", path);

        // save the directory to the global variable: _PROJECT_DIR
        lua_pushstring(impl->lua, path);
        lua_setglobal(impl->lua, "_PROJECT_DIR");

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok) tb_printf("error: not found the project directory!\n");

    // ok?
    return ok;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
xm_machine_ref_t xm_machine_init()
{
    // done
    tb_bool_t           ok = tb_false;
    xm_machine_impl_t*  impl = tb_null;
    do
    {
        // init machine
        impl = tb_malloc0_type(xm_machine_impl_t);
        tb_assert_and_check_break(impl);

        // init lua 
        impl->lua = lua_open();
        tb_assert_and_check_break(impl->lua);

        // open lua libraries
        luaL_openlibs(impl->lua);

        // bind os functions
        luaL_register(impl->lua, "os", g_os_functions);

        // bind path functions
        luaL_register(impl->lua, "path", g_path_functions);

        // bind string functions
        luaL_register(impl->lua, "string", g_string_functions);

        // init host
#if defined(TB_CONFIG_OS_WINDOWS)
        lua_pushstring(impl->lua, "windows");
#elif defined(TB_CONFIG_OS_MACOSX)
        lua_pushstring(impl->lua, "macosx");
#elif defined(TB_CONFIG_OS_LINUX)
        lua_pushstring(impl->lua, "linux");
#elif defined(TB_CONFIG_OS_IOS)
        lua_pushstring(impl->lua, "ios");
#elif defined(TB_CONFIG_OS_ANDROID)
        lua_pushstring(impl->lua, "android");
#elif defined(TB_CONFIG_OS_LIKE_UNIX)
        lua_pushstring(impl->lua, "unix");
#else
        lua_pushstring(impl->lua, "unknown");
#endif
        lua_setglobal(impl->lua, "_HOST");

        // init architecture
#if defined(TB_ARCH_x86) || defined(TB_CONFIG_OS_WINDOWS)
        lua_pushstring(impl->lua, "i386");
#elif defined(TB_ARCH_x64)
        lua_pushstring(impl->lua, "x86_64");
#else
        lua_pushstring(impl->lua, TB_ARCH_STRING);
#endif
        lua_setglobal(impl->lua, "_ARCH");

        // init redirect to null
#if defined(TB_CONFIG_OS_WINDOWS)
        lua_pushstring(impl->lua, "nul");
#else
        lua_pushstring(impl->lua, "/dev/null");
#endif
        lua_setglobal(impl->lua, "_NULDEV");

        // init version
        tb_version_t const* version = xm_version();
        if (version)
        {
            tb_char_t version_cstr[256] = {0};
            tb_snprintf(version_cstr, sizeof(version_cstr), "XMake v%u.%u.%u.%llu", version->major, version->minor, version->alter, version->build);
            lua_pushstring(impl->lua, version_cstr);
        }
        else lua_pushstring(impl->lua, "XMake");
        lua_setglobal(impl->lua, "_VERSION");

        // init namespace: xmake
        lua_newtable(impl->lua);
        lua_setglobal(impl->lua, "xmake");

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (impl) xm_machine_exit((xm_machine_ref_t)impl);
        impl = tb_null;
    }

    return (xm_machine_ref_t)impl;
}
tb_void_t xm_machine_exit(xm_machine_ref_t machine)
{
    // check
    xm_machine_impl_t* impl = (xm_machine_impl_t*)machine;
    tb_assert_and_check_return(impl);

    // exit lua
    if (impl->lua) lua_close(impl->lua);
    impl->lua = tb_null;

    // exit it
    tb_free(impl);
}
tb_int_t xm_machine_main(xm_machine_ref_t machine, tb_int_t argc, tb_char_t** argv)
{
    // check
    xm_machine_impl_t* impl = (xm_machine_impl_t*)machine;
    tb_assert_and_check_return_val(impl && impl->lua, -1);

    // save main arguments to the global variable: _ARGV
    if (!xm_machine_main_save_arguments(impl, argc, argv)) return -1;

    // get the project directory
    tb_char_t path[TB_PATH_MAXN] = {0};
    if (!xm_machine_main_get_project_directory(impl, path, sizeof(path))) return -1;

    // get the program directory
    if (!xm_machine_main_get_program_directory(impl, path, sizeof(path))) return -1;

    // append the main script path
    tb_strcat(path, "/core/_xmake_main.lua");

    // exists this script?
    if (!tb_file_info(path, tb_null))
    {
        // error
        tb_printf("not found main script: %s\n", path);

        // failed
        return -1;
    }

    // trace
    tb_trace_d("main: %s", path);

    // load and execute the main script
    if (luaL_dofile(impl->lua, path))
    {
        // error
        tb_printf("error: %s\n", lua_tostring(impl->lua, -1));

        // failed
        return -1;
    }

    // set the error function
    lua_getglobal(impl->lua, "debug");
    lua_getfield(impl->lua, -1, "traceback");

    // call the main function
    lua_getglobal(impl->lua, "_xmake_main");
    if (lua_pcall(impl->lua, 0, 1, -2)) 
    {
        // error
        tb_printf("error: %s\n", lua_tostring(impl->lua, -1));

        // failed
        return -1;
    }

    // get the error code
    return (tb_int_t)lua_tonumber(impl->lua, -1);
}
