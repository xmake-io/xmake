/*!The Treasure Box Library
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
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        shell32.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "shell32.h"
#include "../../../utils/singleton.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_shell32_instance_init(tb_handle_t instance, tb_cpointer_t priv)
{
    // check
    tb_shell32_ref_t shell32 = (tb_shell32_ref_t)instance;
    tb_check_return_val(shell32, tb_false);

    // the shell32 module
    HANDLE module = GetModuleHandleA("shell32.dll");
    if (!module) module = tb_dynamic_init("shell32.dll");
    tb_check_return_val(module, tb_false);

    // init interfaces
    TB_INTERFACE_LOAD(shell32, SHGetSpecialFolderLocation);
    TB_INTERFACE_LOAD(shell32, SHGetPathFromIDListW);

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_shell32_ref_t tb_shell32()
{
    // init
    static tb_atomic_t      s_binited = 0;
    static tb_shell32_t     s_shell32 = {0};

    // init the static instance
    tb_singleton_static_init(&s_binited, &s_shell32, tb_shell32_instance_init, tb_null);

    // ok
    return &s_shell32;
}
