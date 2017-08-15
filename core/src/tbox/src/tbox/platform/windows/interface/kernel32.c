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
 * @file        kernel32.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "kernel32.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t tb_kernel32_instance_init(tb_handle_t instance, tb_cpointer_t priv)
{
    // check
    tb_kernel32_ref_t kernel32 = (tb_kernel32_ref_t)instance;
    tb_assert_and_check_return_val(kernel32, tb_false);

    // the kernel32 module
    HANDLE module = GetModuleHandleA("kernel32.dll");
    if (!module) module = tb_dynamic_init("kernel32.dll");
    tb_assert_and_check_return_val(module, tb_false);

    // init interfaces
//    TB_INTERFACE_LOAD(kernel32, CancelIoEx);
    TB_INTERFACE_LOAD(kernel32, RtlCaptureStackBackTrace);
    TB_INTERFACE_LOAD(kernel32, GetFileSizeEx);
    TB_INTERFACE_LOAD(kernel32, GetQueuedCompletionStatusEx);
    TB_INTERFACE_LOAD(kernel32, InterlockedCompareExchange64);
    TB_INTERFACE_LOAD(kernel32, GetEnvironmentVariableW);
    TB_INTERFACE_LOAD(kernel32, SetEnvironmentVariableW);
    TB_INTERFACE_LOAD(kernel32, CreateProcessW);
    TB_INTERFACE_LOAD(kernel32, CloseHandle);
    TB_INTERFACE_LOAD(kernel32, WaitForSingleObject);
    TB_INTERFACE_LOAD(kernel32, WaitForMultipleObjects);
    TB_INTERFACE_LOAD(kernel32, GetExitCodeProcess);
    TB_INTERFACE_LOAD(kernel32, TerminateProcess);
    TB_INTERFACE_LOAD(kernel32, SuspendThread);
    TB_INTERFACE_LOAD(kernel32, ResumeThread);
    TB_INTERFACE_LOAD(kernel32, GetEnvironmentStringsW);
    TB_INTERFACE_LOAD(kernel32, FreeEnvironmentStringsW);
    TB_INTERFACE_LOAD(kernel32, SetHandleInformation);

    // ok
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_kernel32_ref_t tb_kernel32()
{
    // init
    static tb_atomic_t      s_binited = 0;
    static tb_kernel32_t    s_kernel32 = {0};

    // init the static instance
    tb_bool_t ok = tb_singleton_static_init(&s_binited, &s_kernel32, tb_kernel32_instance_init, tb_null);
    tb_assert(ok); tb_used(ok);

    // ok
    return &s_kernel32;
}
