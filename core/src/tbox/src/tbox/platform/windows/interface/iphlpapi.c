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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        iphlpapi.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "iphlpapi.h"
#include "../../../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_iphlpapi_instance_init(tb_handle_t instance, tb_cpointer_t priv)
{
    // check
    tb_iphlpapi_ref_t iphlpapi = (tb_iphlpapi_ref_t)instance;
    tb_assert_and_check_return_val(iphlpapi, tb_false);

    // the iphlpapi module
    HANDLE module = GetModuleHandleA("iphlpapi.dll");
    if (!module) module = (HANDLE)tb_dynamic_init("iphlpapi.dll");
    tb_check_return_val(module, tb_false);

    // init interfaces
    TB_INTERFACE_LOAD(iphlpapi, GetNetworkParams);
    TB_INTERFACE_LOAD(iphlpapi, GetAdaptersInfo);
    TB_INTERFACE_LOAD(iphlpapi, GetAdaptersAddresses);

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_iphlpapi_ref_t tb_iphlpapi()
{
    // init
    static tb_atomic_t      s_binited = 0;
    static tb_iphlpapi_t    s_iphlpapi = {0};

    // init the static instance
    tb_bool_t ok = tb_singleton_static_init(&s_binited, &s_iphlpapi, tb_iphlpapi_instance_init, tb_null);
    tb_assert(ok); tb_used(ok);

    // ok
    return &s_iphlpapi;
}
