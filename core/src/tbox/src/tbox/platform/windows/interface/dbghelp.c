/*!The Treasure Box Library
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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        dbghelp.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "dbghelp.h"
#include "../../../utils/singleton.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_dbghelp_instance_init(tb_handle_t instance, tb_cpointer_t priv)
{
    // check
    tb_dbghelp_ref_t dbghelp = (tb_dbghelp_ref_t)instance;
    tb_check_return_val(dbghelp, tb_false);

    // the dbghelp module
    HANDLE module = GetModuleHandleA("dbghelp.dll");
    if (!module) module = (HANDLE)tb_dynamic_init("dbghelp.dll");
    tb_check_return_val(module, tb_false);

    // init interfaces
    TB_INTERFACE_LOAD(dbghelp, SymInitialize);
    tb_check_return_val(dbghelp->SymInitialize, tb_false);
 
    // init symbols
    if (!dbghelp->SymInitialize(GetCurrentProcess(), tb_null, TRUE)) return tb_false;

    // init interfaces
    TB_INTERFACE_LOAD(dbghelp, SymFromAddr);
    TB_INTERFACE_LOAD(dbghelp, SymSetOptions);

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_dbghelp_ref_t tb_dbghelp()
{
    // init
    static tb_atomic_t      s_binited = 0;
    static tb_dbghelp_t     s_dbghelp = {0};

    // init the static instance
    tb_singleton_static_init(&s_binited, &s_dbghelp, tb_dbghelp_instance_init, tb_null);

    // ok
    return &s_dbghelp;
}
