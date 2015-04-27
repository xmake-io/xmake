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

    // print verbose info?
    tb_bool_t               verbose;

}xm_machine_impl_t;

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
        // print verbose info
        if (!tb_strncmp(argv[i], "--verbose", 9) || !tb_strncmp(argv[i], "-v", 2)) 
            impl->verbose = tb_true;

        // get the project directory
        if (!tb_strncmp(argv[i], "--project=", 10))
        {
            // save it to the environment variable
            tb_environment_set_one("XMAKE_PROJECT_DIR", argv[i] + 10);
            continue ;
        }

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
            // trace
            if (impl->verbose) tb_trace_i("please set XMAKE_PROGRAM_DIR first!");
            break;
        }

        // get the full path
        if (!tb_path_full(data, path, maxn)) break;

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
            ||  !tb_path_full(data, path, maxn))
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
    if (!ok && impl->verbose) tb_trace_i("not found the project directory!");

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

        // TODO: bind lua interfaces
        // ...

        // init verbose
        impl->verbose = tb_false;

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
    tb_strcat(path, "/scripts/xmake_main.lua");

    // exists this script?
    if (!tb_file_info(path, tb_null))
    {
        // trace
        if (impl->verbose) tb_trace_i("not found main script: %s", path);
        return -1;
    }

    // trace
    tb_trace_d("main: %s", path);

    // exec the script file
    tb_int_t error = luaL_dofile(impl->lua, path);

    // failed? print the error info
    if (error && impl->verbose)
    {
        // trace
        tb_trace_i("%s", lua_tostring(impl->lua, -1));
    }

    // ok?
    return error;
}
