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
 * Copyright (C) 2015-present, Xmake Open Source Community.
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
#include "../engine_pool.h"

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
    xm_engine_ref_t engine = xm_engine_pool_alloc(xm_engine_pool());
    if (!engine) engine = xm_engine_init(XM_THREAD_ENGINE_NAME, tb_null);
    if (engine)
    {
        lua_State* lua = xm_engine_lua(engine);
        tb_assert(lua);

        // pass callback
        tb_char_t const* callback_data = tb_string_cstr(&thread->callback);
        tb_size_t        callback_size = tb_string_size(&thread->callback);
        if (callback_data && callback_size)
        {
            lua_pushlstring(lua, callback_data, callback_size);
            lua_setglobal(lua, "_THREAD_CALLBACK");
        }

        // pass callinfo
        tb_char_t const* callinfo_data = tb_string_cstr(&thread->callinfo);
        tb_size_t        callinfo_size = tb_string_size(&thread->callinfo);
        if (callinfo_data && callinfo_size)
        {
            lua_pushlstring(lua, callinfo_data, callinfo_size);
            lua_setglobal(lua, "_THREAD_CALLINFO");
        }

        // start engine
        tb_char_t* argv[] = {XM_THREAD_ENGINE_NAME, tb_null};
        xm_engine_main(engine, 1, argv, tb_null);
        if (!xm_engine_pool_free(xm_engine_pool(), engine))
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

        // get callinfo
        size_t              callinfo_size = 0;
        tb_char_t const*    callinfo_data = luaL_checklstring(lua, 3, &callinfo_size);
        tb_assert_and_check_break(callinfo_data && callinfo_size);

        // get stack size
        tb_size_t stacksize = (tb_size_t)luaL_checkinteger(lua, 4);

        // init thread
        thread = tb_malloc0_type(xm_thread_t);
        tb_assert_and_check_break(thread);

        tb_string_init(&thread->callback);
        tb_string_cstrncpy(&thread->callback, callback_data, callback_size);

        tb_string_init(&thread->callinfo);
        tb_string_cstrncpy(&thread->callinfo, callinfo_data, callinfo_size);

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
            tb_string_exit(&thread->callinfo);
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
