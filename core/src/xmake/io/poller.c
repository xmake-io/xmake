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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        poller.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "poller"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "poller.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the singleton type of poller
#define XM_IO_POLLER    (TB_SINGLETON_TYPE_USER + 4)

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_handle_t xm_io_poller_instance_init(tb_cpointer_t* ppriv)
{
    // init poller
    tb_poller_ref_t poller = tb_poller_init(tb_null);
    tb_assert_and_check_return_val(poller, tb_null);

    // attach poller to the current thread
    tb_poller_attach(poller);
    return (tb_handle_t)poller;
}
static tb_void_t xm_io_poller_instance_exit(tb_handle_t poller, tb_cpointer_t priv)
{
    if (poller) tb_poller_exit((tb_poller_ref_t)poller);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_poller_ref_t xm_io_poller()
{
    return (tb_poller_ref_t)tb_singleton_instance(XM_IO_POLLER, xm_io_poller_instance_init, xm_io_poller_instance_exit, tb_null, tb_null);
}

