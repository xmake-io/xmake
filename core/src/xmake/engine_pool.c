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
 * @file        engine_pool.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "engine_pool"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "xmake.h"
#include "engine.h"
#include "engine_pool.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the max engine pool count
#define XM_ENGINE_POOL_MAXN     (128)

// the singleton type of engine pool
#define XM_ENGINE_POOL          (TB_SINGLETON_TYPE_USER + 4)

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_handle_t xm_engine_pool_instance_init(tb_cpointer_t* ppriv)
{
    xm_engine_pool_ref_t engine_pool = xm_engine_pool_init();
    tb_assert_and_check_return_val(engine_pool, tb_null);

    return (tb_handle_t)engine_pool;
}

static tb_void_t xm_engine_pool_instance_exit(tb_handle_t engine_pool, tb_cpointer_t priv)
{
    if (engine_pool) xm_engine_pool_exit((xm_engine_pool_ref_t)engine_pool);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
xm_engine_pool_ref_t xm_engine_pool()
{
    return (xm_engine_pool_ref_t)tb_singleton_instance(XM_ENGINE_POOL, xm_engine_pool_instance_init, xm_engine_pool_instance_exit, tb_null, tb_null);
}

xm_engine_pool_ref_t xm_engine_pool_init()
{
    return tb_single_list_init(0, tb_element_ptr(tb_null, tb_null));
}

tb_void_t xm_engine_pool_exit(xm_engine_pool_ref_t engine_pool)
{
    if (engine_pool)
    {
        tb_for_all (xm_engine_ref_t, engine, engine_pool)
        {
            if (engine)
                xm_engine_exit(engine);
        }
        tb_single_list_exit(engine_pool);
    }
}

xm_engine_ref_t xm_engine_pool_alloc(xm_engine_pool_ref_t engine_pool)
{
    xm_engine_ref_t engine = tb_null;
    if (tb_single_list_size(engine_pool) > 0)
    {
        engine = (xm_engine_ref_t)tb_single_list_head(engine_pool);
        tb_single_list_remove_head(engine_pool);
    }
    return engine;
}

tb_void_t xm_engine_pool_free(xm_engine_pool_ref_t engine_pool, xm_engine_ref_t engine)
{
    if (tb_single_list_size(engine_pool) < XM_ENGINE_POOL_MAXN)
        tb_single_list_insert_tail(engine_pool, engine);
    else xm_engine_exit(engine);
}

