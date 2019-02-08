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
 * @file        process.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "process"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "process.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_CONFIG_OS_WINDOWS
#   include "windows/process.c"
#elif defined(TB_CONFIG_POSIX_HAVE_WAITPID) && \
        defined(TB_CONFIG_POSIX_HAVE_POSIX_SPAWNP)
#   include "posix/process.c"
#elif defined(TB_CONFIG_POSIX_HAVE_WAITPID) && \
         (defined(TB_CONFIG_POSIX_HAVE_FORK) || defined(TB_CONFIG_POSIX_HAVE_VFORK)) && \
            (defined(TB_CONFIG_POSIX_HAVE_EXECVP) || defined(TB_CONFIG_POSIX_HAVE_EXECVPE)) 
#   include "posix/process.c"
#else
tb_process_ref_t tb_process_init(tb_char_t const* pathname, tb_char_t const* argv[], tb_process_attr_ref_t attr)
{
    tb_trace_noimpl();
    return tb_null;
}
tb_process_ref_t tb_process_init_cmd(tb_char_t const* cmd, tb_process_attr_ref_t attr)
{
    tb_trace_noimpl();
    return tb_null;
}
tb_void_t tb_process_exit(tb_process_ref_t self)
{
    tb_trace_noimpl();
}
tb_void_t tb_process_kill(tb_process_ref_t self)
{
    tb_trace_noimpl();
}
tb_void_t tb_process_resume(tb_process_ref_t self)
{
    tb_trace_noimpl();
}
tb_void_t tb_process_suspend(tb_process_ref_t self)
{
    tb_trace_noimpl();
}
tb_long_t tb_process_wait(tb_process_ref_t self, tb_long_t* pstatus, tb_long_t timeout)
{
    tb_trace_noimpl();
    return -1;
}
tb_long_t tb_process_waitlist(tb_process_ref_t const* processes, tb_process_waitinfo_ref_t infolist, tb_size_t infomaxn, tb_long_t timeout)
{
    tb_trace_noimpl();
    return -1;
}
#endif
tb_long_t tb_process_run(tb_char_t const* pathname, tb_char_t const* argv[], tb_process_attr_ref_t attr)
{
    // remove suspend
    if (attr) attr->flags &= ~TB_PROCESS_FLAG_SUSPEND;

    // init process
    tb_long_t           ok = -1;
    tb_process_ref_t    process = tb_process_init(pathname, argv, attr);
    if (process)
    {
        // wait process
        tb_long_t status = 0;
        if (tb_process_wait(process, &status, -1) > 0)
            ok = status;

        // exit process
        tb_process_exit(process);
    }

    // ok?
    return ok;
}
tb_long_t tb_process_run_cmd(tb_char_t const* cmd, tb_process_attr_ref_t attr)
{
    // remove suspend
    if (attr) attr->flags &= ~TB_PROCESS_FLAG_SUSPEND;

    // init process
    tb_long_t           ok = -1;
    tb_process_ref_t    process = tb_process_init_cmd(cmd, attr);
    if (process)
    {
        // wait process
        tb_long_t status = 0;
        if (tb_process_wait(process, &status, -1) > 0)
            ok = status;

        // exit process
        tb_process_exit(process);
    }

    // ok?
    return ok;
}
