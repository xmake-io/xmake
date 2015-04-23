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
 * @file        xmake.c
 *
 */

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

        // TODO
        // ...

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
tb_int_t xm_machine_main(xm_machine_ref_t machine, tb_int_t argc, tb_char_t** argv, tb_char_t const* code_path)
{
    // check
    xm_machine_impl_t* impl = (xm_machine_impl_t*)machine;
    tb_assert_and_check_return_val(impl && impl->lua && code_path, -1);

    return 0;
}
