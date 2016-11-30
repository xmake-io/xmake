/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
 *
 * @author      ruki
 * @file        process.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_PROCESS_H
#define TB_PLATFORM_PROCESS_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the process flag enum
typedef enum __tb_process_flag_e
{
    TB_PROCESS_FLAG_NONE    = 0
,   TB_PROCESS_FLAG_SUSPEND = 1     //!< suspend process

}tb_process_flag_e;

/// the process attribute type
typedef struct __tb_process_attr_t
{
    /// the flags
    tb_size_t           flags;

    /// the stdout filename 
    tb_char_t const*    outfile;

    /*! the stdout filemode
     *
     * default: TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC
     * 
     * support:
     *
     * - TB_FILE_MODE_WO
     * - TB_FILE_MODE_RW 
     * - TB_FILE_MODE_CREAT 
     * - TB_FILE_MODE_APPEND 
     * - TB_FILE_MODE_TRUNC
     */
    tb_size_t           outmode;

    /// the stderr filename
    tb_char_t const*    errfile;

    /// the stderr filemode
    tb_size_t           errmode;

    /*! the environment
     *
     * @code
     
        tb_char_t const* envp[] = 
        {
            "path=/usr/bin"
        ,   tb_null
        };

        attr.envp = envp;

     * @endcode
     *
     * the envp argument is an array of pointers to null-terminated strings
     * and must be terminated by a null pointer
     *
     * if the value of envp is null, then the child process inherits 
     * the environment of the parent process.
     */
    tb_char_t const**   envp;

}tb_process_attr_t, *tb_process_attr_ref_t;

/// the process ref type
typedef __tb_typeref__(process);

/// the process wait info type
typedef struct __tb_process_waitinfo_t
{
    // the index of the processes
    tb_size_t           index;

    // the process
    tb_process_ref_t    process;

    // the status
    tb_long_t           status;

}tb_process_waitinfo_t, *tb_process_waitinfo_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! run a given process 
 *
 * @code
 
    // init argv
    tb_char_t const* argv[] = 
    {
        "echo"
    ,   "hello"
    ,   tb_null
    };
 
    // init envp
    tb_char_t const* envp[] = 
    {
        "path=/usr/bin"
    ,   tb_null
    };

    // init attr
    tb_process_attr_t attr = {0};
    attr.envp = envp;
    
    // run bash
    if (tb_process_run("echo", argv, &attr) == 0)
    {
        // trace
        tb_trace_i("ok");
    }
 
    // run bash
    if (tb_process_run("/bin/echo", tb_null, tb_null) == 0)
    {
        // trace
        tb_trace_i("ok");
    }

 * @endcode
 * 
 * @param pathname      the process path or name
 * @param argv          the list of arguments must be terminated by a null pointer
 *                      and must be terminated by a null pointer
 *                      and argv[0] is the self path name
 * @param attr          the process attributes
 *
 * @return              the status value, failed: -1, ok: 0, other: error code
 */
tb_long_t               tb_process_run(tb_char_t const* pathname, tb_char_t const* argv[], tb_process_attr_ref_t attr);

/*! run a given process from the command line 
 * 
 * @param cmd           the command line
 * @param attr          the process attributes
 *
 * @return              the status value, failed: -1, ok: 0, other: error code
 */
tb_long_t               tb_process_run_cmd(tb_char_t const* cmd, tb_process_attr_ref_t attr);

/*! init a given process 
 * 
 * @code
 
    // init process
    tb_process_ref_t process = tb_process_init("/bin/echo", tb_null, tb_null);
    if (process)
    {
        // wait process
        tb_long_t status = 0;
        if (tb_process_wait(process, &status, 10) > 0)
        {
            // trace
            tb_trace_i("process exited: %ld", status);
        }
        // kill process
        else 
        {
            // kill it
            tb_process_kill(process);

            // wait it again
            tb_process_wait(process, &status, -1);
        }

        // exit process
        tb_process_exit(process);
    }

 * @endcode
 *
 * @param pathname      the process path or name
 *
 * @param argv          the list of arguments must be terminated by a null pointer
 *                      and must be terminated by a null pointer
 *                      and argv[0] is the self path name
 *
 * @param attr          the process attributes
 *
 * @return              the process 
 */
tb_process_ref_t        tb_process_init(tb_char_t const* pathname, tb_char_t const* argv[], tb_process_attr_ref_t attr);

/*! init a given process from the command line 
 * 
 * @param cmd           the command line
 * @param attr          the process attributes
 *
 * @return              the process 
 */
tb_process_ref_t        tb_process_init_cmd(tb_char_t const* cmd, tb_process_attr_ref_t attr);

/*! exit the process
 *
 * @param process       the process
 */
tb_void_t               tb_process_exit(tb_process_ref_t process);

/*! kill the process
 *
 * @param process       the process
 */
tb_void_t               tb_process_kill(tb_process_ref_t process);

/*! resume the process
 *
 * @param process       the process
 */
tb_void_t               tb_process_resume(tb_process_ref_t process);

/*! suspend the process
 *
 * @param process       the process
 */
tb_void_t               tb_process_suspend(tb_process_ref_t process);

/*! wait the process
 *
 * @param process       the process
 * @param pstatus       the process exited status pointer, maybe null
 * @param timeout       the timeout (ms), infinity: -1
 *
 * @return              wait failed: -1, timeout: 0, ok: 1
 */
tb_long_t               tb_process_wait(tb_process_ref_t process, tb_long_t* pstatus, tb_long_t timeout);

/*! wait the process list
 *
 * @code
 
    // init processes
    tb_size_t        count1 = 0;
    tb_process_ref_t processes1[5] = {0};
    tb_process_ref_t processes2[5] = {0};
    for (; count1 < 4; count1++)
    {
        processes1[count1] = tb_process_init(argv[1], (tb_char_t const**)(argv + 1), tb_null);
        tb_assert_and_check_break(processes1[count1]);
    }

    // ok?
    while (count1)
    {
        // trace
        tb_trace_i("waiting: %ld", count1);

        // wait processes
        tb_long_t               infosize = -1;
        tb_process_waitinfo_t   infolist[4];
        if ((infosize = tb_process_waitlist(processes1, infolist, tb_arrayn(infolist), -1)) > 0)
        {
            tb_size_t i = 0;
            for (i = 0; i < infosize; i++)
            {
                // trace
                tb_trace_i("process(%ld:%p) exited: %ld", infolist[i].index, infolist[i].process, infolist[i].status);

                // exit process
                if (infolist[i].process) tb_process_exit(infolist[i].process);

                // remove this process
                processes1[infolist[i].index] = tb_null;
            }

            // update processes
            tb_size_t count2 = 0;
            for (i = 0; i < count1; i++) 
            {
                if (processes1[i]) processes2[count2++] = processes1[i];
            }
            tb_memcpy(processes1, processes2, count2 * sizeof(tb_process_ref_t));
            processes1[count2] = tb_null;
            count1 = count2;
        }
    }

 * @endcode
 *
 * @param processes     the null-terminated process list 
 * @param infolist      the info list
 * @param infomaxn      the info maxn
 * @param timeout       the timeout (ms), infinity: -1
 *
 * @return              > 0: the info list size, 0: timeout, -1: failed
 */
tb_long_t               tb_process_waitlist(tb_process_ref_t const* processes, tb_process_waitinfo_ref_t infolist, tb_size_t infomaxn, tb_long_t timeout);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
