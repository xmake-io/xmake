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
 * @file        kernel32.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "kernel32.h"
#include "ws2_32.h"

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
    if (!module) module = (HANDLE)tb_dynamic_init("kernel32.dll");
    tb_assert_and_check_return_val(module, tb_false);

    // init interfaces
    TB_INTERFACE_LOAD(kernel32, RtlCaptureStackBackTrace);
    TB_INTERFACE_LOAD(kernel32, GetFileSizeEx);
    TB_INTERFACE_LOAD(kernel32, GetQueuedCompletionStatusEx);
    TB_INTERFACE_LOAD(kernel32, InterlockedCompareExchange64);
    TB_INTERFACE_LOAD(kernel32, GetEnvironmentVariableW);
    TB_INTERFACE_LOAD(kernel32, SetEnvironmentVariableW);
    TB_INTERFACE_LOAD(kernel32, CreateProcessW);
    TB_INTERFACE_LOAD(kernel32, WaitForSingleObject);
    TB_INTERFACE_LOAD(kernel32, WaitForMultipleObjects);
    TB_INTERFACE_LOAD(kernel32, GetExitCodeProcess);
    TB_INTERFACE_LOAD(kernel32, TerminateProcess);
    TB_INTERFACE_LOAD(kernel32, SuspendThread);
    TB_INTERFACE_LOAD(kernel32, ResumeThread);
    TB_INTERFACE_LOAD(kernel32, GetEnvironmentStringsW);
    TB_INTERFACE_LOAD(kernel32, FreeEnvironmentStringsW);
    TB_INTERFACE_LOAD(kernel32, SetHandleInformation);
    TB_INTERFACE_LOAD(kernel32, SetFileCompletionNotificationModes);
    TB_INTERFACE_LOAD(kernel32, CreateSymbolicLinkW);

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
tb_bool_t tb_kernel32_has_SetFileCompletionNotificationModes()
{
    static tb_long_t s_ok = 0;
    if (!s_ok)
    {
        LPWSAPROTOCOL_INFOW lpProtocolInfo = tb_null;
        do
        {
            // no this interface?
            if (!tb_kernel32()->SetFileCompletionNotificationModes)
                break;

            // allocate a 16K buffer to retrieve all the protocol providers
            DWORD dwBufferLen = 16384;
            lpProtocolInfo = (LPWSAPROTOCOL_INFOW)tb_malloc(dwBufferLen);
            tb_assert_and_check_break(lpProtocolInfo);

            // get protocol info
            tb_int_t iNuminfo = tb_ws2_32()->WSAEnumProtocolsW(tb_null, lpProtocolInfo, &dwBufferLen);
            tb_check_break(iNuminfo != SOCKET_ERROR);

            // has XP1_IFS_HANDLES? see https://support.microsoft.com/kb/2568167 for details
            tb_int_t i = 0;
            for (i = 0; i < iNuminfo; i++) 
            {
                if (!(lpProtocolInfo[i].dwServiceFlags1 & XP1_IFS_HANDLES))
                    break;
            }
            tb_check_break(i == iNuminfo);

            // ok
            s_ok = 1;

        } while (0);

        // free protocol info
        if (lpProtocolInfo) tb_free(lpProtocolInfo);
        lpProtocolInfo = tb_null;

        // failed
        if (!s_ok) s_ok = -1;
    }

    // ok?
    return s_ok == 1;
}
