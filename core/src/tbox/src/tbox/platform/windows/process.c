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
 * @file        process.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../path.h"
#include "../file.h"
#include "../process.h"
#include "../environment.h"
#include "../../string/string.h"
#include "interface/interface.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the process type
typedef struct __tb_process_t
{
    // the startup info
    STARTUPINFO             si;

    // the process info
    PROCESS_INFORMATION     pi;

    // the attributes
    tb_process_attr_t       attr;

}tb_process_t; 

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_process_ref_t tb_process_init(tb_char_t const* pathname, tb_char_t const* argv[], tb_process_attr_ref_t attr)
{
    // check
    tb_assert_and_check_return_val(pathname || argv, tb_null);

    // done
    tb_string_t         args;
    tb_process_ref_t    process = tb_null;
    do
    {
        // init args
        if (!tb_string_init(&args)) break;

        // make arguments
        if (argv)
        {
            tb_char_t ch;
            tb_char_t const* p = tb_null;
            while ((p = *argv++)) 
            {
                // has space?
                tb_bool_t has_space = !!tb_strchr(p, ' ');

                // patch '\"'
                if (has_space) tb_string_chrcat(&args, '\"');

                // add argument
                while ((ch = *p))
                {
                    if (ch == '\"') tb_string_chrcat(&args, '\\');
                    tb_string_chrcat(&args, ch);
                    p++;
                }

                // patch '\"'
                if (has_space) tb_string_chrcat(&args, '\"');
                
                // add space 
                tb_string_chrcat(&args, ' ');
            }
        }
        // only path name?
        else tb_string_cstrcpy(&args, pathname);

        // init process
        process = tb_process_init_cmd(tb_string_cstr(&args), attr);

    } while (0);

    // exit arguments
    tb_string_exit(&args);

    // ok?
    return process;
}
tb_process_ref_t tb_process_init_cmd(tb_char_t const* cmd, tb_process_attr_ref_t attr)
{
    // check
    tb_assert_and_check_return_val(cmd, tb_null);

    // done
    tb_bool_t       ok          = tb_false;
    tb_process_t*   process     = tb_null;
    tb_char_t*      environment = tb_null;
    tb_bool_t       userenv     = tb_false;
    tb_wchar_t*     command     = tb_null;
    do
    {
        // make process
        process = tb_malloc0_type(tb_process_t);
        tb_assert_and_check_break(process);

        // init startup info
        process->si.cb = sizeof(process->si);

        // init attributes
        if (attr)
        {
            // save it
            process->attr = *attr;

            // do not save envp, maybe stack pointer
            process->attr.envp = tb_null;
        }

        // init flags
        DWORD flags = 0;
        if (attr && attr->flags & TB_PROCESS_FLAG_SUSPEND) flags |= CREATE_SUSPENDED;
//        if (attr && attr->envp) flags |= CREATE_UNICODE_ENVIRONMENT;

        // get the cmd size
        tb_size_t cmdn = tb_strlen(cmd);
        tb_assert_and_check_break(cmdn);

        // init unicode command 
        command = tb_nalloc_type(cmdn + 1, tb_wchar_t);
        tb_assert_and_check_break(command);

        // make command
        tb_size_t size = tb_atow(command, cmd, cmdn + 1);
        tb_assert_and_check_break(size != -1);

        // reset size
        size = 0;

        // FIXME no effect
        // make environment
        tb_char_t const*    p = tb_null;
        tb_size_t           maxn = 0;
        tb_char_t const**   envp = attr? attr->envp : tb_null;
        while (envp && (p = *envp++))
        {
            // get size
            tb_size_t n = tb_strlen(p);

            // ensure data space
            if (!environment) 
            {
                maxn = n + 2 + TB_PATH_MAXN;
                environment = (tb_char_t*)tb_malloc(maxn);
            }
            else if (size + n + 2 > maxn)
            {
                maxn = size + n + 2 + TB_PATH_MAXN;
                environment = (tb_char_t*)tb_ralloc(environment, maxn);
            }
            tb_assert_and_check_break(environment);

            // append it
            tb_memcpy(environment + size, p, n);

            // fill '\0'
            environment[size + n] = '\0'; 

            // update size
            size += n + 1;
        }

        // end
        if (environment) environment[size++] = '\0';
        // uses the current user environment if be null
        else
        {
            // uses the unicode environment
            flags |= CREATE_UNICODE_ENVIRONMENT;

            // get user environment
            environment = (tb_char_t*)tb_kernel32()->GetEnvironmentStringsW();

            // mark as the user environment
            userenv = tb_true;
        }

        // redirect the stdout
        BOOL bInheritHandle = FALSE;
        if (attr && attr->outfile)
        {
            // the outmode
            tb_size_t outmode = attr->outmode;

            // no mode? uses the default mode
            if (!outmode) outmode = TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC;

            // enable handles
            process->si.dwFlags |= STARTF_USESTDHANDLES;

            // open file
            process->si.hStdOutput = (HANDLE)tb_file_init(attr->outfile, outmode);
            tb_assertf_pass_and_check_break(process->si.hStdOutput, "cannot redirect stdout to file: %s", attr->outfile);

            // enable inherit
            tb_kernel32()->SetHandleInformation(process->si.hStdOutput, HANDLE_FLAG_INHERIT, TRUE);
            bInheritHandle = TRUE;
        }

        // redirect the stderr
        if (attr && attr->errfile)
        {
            // the errmode
            tb_size_t errmode = attr->errmode;

            // no mode? uses the default mode
            if (!errmode) errmode = TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC;

            // enable handles
            process->si.dwFlags |= STARTF_USESTDHANDLES;

            // open file
            process->si.hStdError = (HANDLE)tb_file_init(attr->errfile, errmode);
            tb_assertf_pass_and_check_break(process->si.hStdError, "cannot redirect stderr to file: %s", attr->errfile);

            // enable inherit
            tb_kernel32()->SetHandleInformation(process->si.hStdError, HANDLE_FLAG_INHERIT, TRUE);
            bInheritHandle = TRUE;
        }

        // init process security attributes
        SECURITY_ATTRIBUTES sap     = {0};
        sap.nLength                 = sizeof(SECURITY_ATTRIBUTES);
        sap.lpSecurityDescriptor    = tb_null;
        sap.bInheritHandle          = bInheritHandle;

        // init thread security attributes
        SECURITY_ATTRIBUTES sat     = {0};
        sat.nLength                 = sizeof(SECURITY_ATTRIBUTES);
        sat.lpSecurityDescriptor    = tb_null;
        sat.bInheritHandle          = bInheritHandle;

        // create process
        if (!tb_kernel32()->CreateProcessW(tb_null, command, &sap, &sat, bInheritHandle, flags, (LPVOID)environment, tb_null, &process->si, &process->pi))
            break;

        // check it
        tb_assert_and_check_break(process->pi.hThread != INVALID_HANDLE_VALUE);
        tb_assert_and_check_break(process->pi.hProcess != INVALID_HANDLE_VALUE);

        // ok
        ok = tb_true;

    } while (0);

    // uses the user environment?
    if (userenv)
    {
        // exit it
        if (environment) tb_kernel32()->FreeEnvironmentStringsW((LPWCH)environment);
        environment = tb_null;
    }
    else
    {
        // exit it
        if (environment) tb_free(environment);
        environment = tb_null;
    }

    // exit command 
    if (command) tb_free(command);
    command = tb_null;

    // failed?
    if (!ok)
    {
        // exit it
        if (process) tb_process_exit((tb_process_ref_t)process);
        process = tb_null;
    }

    // ok?
    return (tb_process_ref_t)process;
}
tb_void_t tb_process_exit(tb_process_ref_t self)
{
    // check
    tb_process_t* process = (tb_process_t*)self;
    tb_assert_and_check_return(process);

    // close thread handle
    if (process->pi.hThread != INVALID_HANDLE_VALUE)
        tb_kernel32()->CloseHandle(process->pi.hThread);
    process->pi.hThread = INVALID_HANDLE_VALUE;

    // close process handle
    if (process->pi.hProcess != INVALID_HANDLE_VALUE)
        tb_kernel32()->CloseHandle(process->pi.hProcess);
    process->pi.hProcess = INVALID_HANDLE_VALUE;

    // exit stdout file
    if (process->si.hStdOutput) tb_file_exit((tb_file_ref_t)process->si.hStdOutput);
    process->si.hStdOutput = tb_null;

    // exit stderr file
    if (process->si.hStdError) tb_file_exit((tb_file_ref_t)process->si.hStdError);
    process->si.hStdError = tb_null;

    // exit it
    tb_free(process);
}
tb_void_t tb_process_kill(tb_process_ref_t self)
{
    // check
    tb_process_t* process = (tb_process_t*)self;
    tb_assert_and_check_return(process);

    // kill it
    if (process->pi.hProcess != INVALID_HANDLE_VALUE)
        tb_kernel32()->TerminateProcess(process->pi.hProcess, -1);
}
tb_void_t tb_process_resume(tb_process_ref_t self)
{
    // check
    tb_process_t* process = (tb_process_t*)self;
    tb_assert_and_check_return(process);

    // resume it
    if (process->pi.hThread != INVALID_HANDLE_VALUE)
        tb_kernel32()->ResumeThread(process->pi.hThread);
}
tb_void_t tb_process_suspend(tb_process_ref_t self)
{
    // check
    tb_process_t* process = (tb_process_t*)self;
    tb_assert_and_check_return(process);

    // suspend it
    if (process->pi.hThread != INVALID_HANDLE_VALUE)
        tb_kernel32()->SuspendThread(process->pi.hThread);
}
tb_long_t tb_process_wait(tb_process_ref_t self, tb_long_t* pstatus, tb_long_t timeout)
{
    // check
    tb_process_t* process = (tb_process_t*)self;
    tb_assert_and_check_return_val(process && process->pi.hProcess != INVALID_HANDLE_VALUE && process->pi.hThread != INVALID_HANDLE_VALUE, -1);

    // wait it
    tb_long_t   ok = -1;
    DWORD       result = tb_kernel32()->WaitForSingleObject(process->pi.hProcess, timeout < 0? INFINITE : (DWORD)timeout);
    switch (result)
    {
    case WAIT_OBJECT_0: // ok
        {
            // save exit code
            DWORD exitcode = 0;
            if (pstatus) *pstatus = tb_kernel32()->GetExitCodeProcess(process->pi.hProcess, &exitcode)? (tb_long_t)exitcode : -1;  

            // close thread handle
            tb_kernel32()->CloseHandle(process->pi.hThread);
            process->pi.hThread = INVALID_HANDLE_VALUE;

            // close process
            tb_kernel32()->CloseHandle(process->pi.hProcess);
            process->pi.hProcess = INVALID_HANDLE_VALUE;

            // ok
            ok = 1;
        }
        break;
    case WAIT_TIMEOUT: // timeout 
        ok = 0;
        break;
    case WAIT_FAILED: // failed
    default:
        break;
    }

    // ok?
    return ok;
}
tb_long_t tb_process_waitlist(tb_process_ref_t const* processes, tb_process_waitinfo_ref_t infolist, tb_size_t infomaxn, tb_long_t timeout)
{
    // check
    tb_assert_and_check_return_val(processes && infolist && infomaxn, -1);

    // make the process list
    tb_size_t               procsize = 0;
    HANDLE                  proclist[256] = {0};
    tb_process_t const**    pprocess = (tb_process_t const**)processes;
    for (; *pprocess && procsize < tb_arrayn(proclist); pprocess++, procsize++)
        proclist[procsize] = (*pprocess)->pi.hProcess;
    tb_assertf(procsize < tb_arrayn(proclist), "too much waited processes!");


    // wait processes
    DWORD       exitcode = 0;
    tb_long_t   infosize = 0;
    DWORD result = tb_kernel32()->WaitForMultipleObjects((DWORD)procsize, proclist, FALSE, timeout < 0? INFINITE : (DWORD)timeout);
    switch (result)
    {
    case WAIT_TIMEOUT:
        break;
    case WAIT_FAILED:
        return -1;
    default:
        {
            // the process index
            DWORD index = result - WAIT_OBJECT_0;

            // the process
            tb_process_t* process = (tb_process_t*)processes[index];
            tb_assert_and_check_return_val(process, -1);

            // save process info
            infolist[infosize].index    = index;
            infolist[infosize].process  = (tb_process_ref_t)process;
            infolist[infosize].status   = tb_kernel32()->GetExitCodeProcess(process->pi.hProcess, &exitcode)? (tb_long_t)exitcode : -1;  
            infosize++;

            // close thread handle
            tb_kernel32()->CloseHandle(process->pi.hThread);
            process->pi.hThread = INVALID_HANDLE_VALUE;

            // close process
            tb_kernel32()->CloseHandle(process->pi.hProcess);
            process->pi.hProcess = INVALID_HANDLE_VALUE;

            // next index
            index++;
            while (index < procsize)
            {
                // attempt to wait next process
                result = tb_kernel32()->WaitForMultipleObjects((DWORD)(procsize - index), proclist + index, FALSE, 0);
                switch (result)
                {
                case WAIT_TIMEOUT:
                    // no more, exit loop
                    index = (DWORD)procsize;
                    break;
                case WAIT_FAILED:
                    return -1;
                default:
                    {
                        // the process index
                        index += result - WAIT_OBJECT_0;

                        // the process
                        process = (tb_process_t*)processes[index];
                        tb_assert_and_check_return_val(process, -1);

                        // save process info
                        infolist[infosize].index    = index;
                        infolist[infosize].process  = (tb_process_ref_t)process;
                        infolist[infosize].status   = tb_kernel32()->GetExitCodeProcess(process->pi.hProcess, &exitcode)? (tb_long_t)exitcode : -1;  
                        infosize++;

                        // close thread handle
                        tb_kernel32()->CloseHandle(process->pi.hThread);
                        process->pi.hThread = INVALID_HANDLE_VALUE;

                        // close process
                        tb_kernel32()->CloseHandle(process->pi.hProcess);
                        process->pi.hProcess = INVALID_HANDLE_VALUE;

                        // next index
                        index++;
                    }
                    break;
                }
            }
        }
        break;
    }

    // ok?
    return infosize;
}
