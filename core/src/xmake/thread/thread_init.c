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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        thread_init.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "thread"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../engine.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define XM_THREAD_ENGINE_NAME   "xmake"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

static tb_int_t xm_thread_func(tb_cpointer_t priv)
{
    xm_thread_t* thread = (xm_thread_t*)priv;
    tb_assert_and_check_return_val(thread, 0);

    tb_trace_i("thread: start ..");
    xm_engine_ref_t engine = xm_engine_init(XM_THREAD_ENGINE_NAME, tb_null);
    if (engine)
    {
        tb_char_t* taskargv[] = {"lua", (tb_char_t*)tb_string_cstr(&thread->callback), tb_null};

        tb_char_t* argv[] = {XM_THREAD_ENGINE_NAME, tb_null};
        xm_engine_main(engine, 1, argv, taskargv);
        xm_engine_exit(engine);
    }
    tb_trace_i("thread: end");
    return 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_thread_init(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_bool_t ok = tb_false;
    xm_thread_t* thread = tb_null;
    do
    {
        // get thread name
        tb_char_t const* name = luaL_checkstring(lua, 1);

        // get callback
        size_t              callback_size = 0;
        tb_char_t const*    callback_data = luaL_checklstring(lua, 2, &callback_size);
        tb_assert_and_check_break(callback_data && callback_size);

        // get argv
        size_t              argv_size = 0;
        tb_char_t const*    argv_data = luaL_checklstring(lua, 3, &argv_size);
        tb_assert_and_check_break(argv_data && argv_size);

        // get stack size
        tb_size_t stacksize = (tb_size_t)luaL_checkinteger(lua, 4);

        // init thread
        thread = tb_malloc0_type(xm_thread_t);
        tb_assert_and_check_break(thread);

        tb_string_init(&thread->callback);
        tb_string_cstrncpy(&thread->callback, callback_data, callback_size);

        tb_string_init(&thread->argv);
        tb_string_cstrncpy(&thread->argv, argv_data, argv_size);

        // create and start thread
        thread->handle = tb_thread_init(name, xm_thread_func, thread, stacksize);
        tb_assert_and_check_break(thread->handle);

        xm_lua_pushpointer(lua, (tb_pointer_t)thread);
        ok = tb_true;

    } while (0);

    if (!ok)
    {
        if (thread)
        {
            tb_string_exit(&thread->callback);
            tb_string_exit(&thread->argv);
            if (thread->handle)
            {
                tb_thread_exit(thread->handle);
                thread->handle = tb_null;
            }
            tb_free(thread);
        }
        lua_pushnil(lua);
    }
    return 1;
}
