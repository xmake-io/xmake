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
 * @file        signal.h
 * @ingroup     libc
 *
 */
#ifndef TB_LIBC_MISC_SIGNAL_H
#define TB_LIBC_MISC_SIGNAL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#ifdef TB_CONFIG_LIBC_HAVE_SIGNAL
#   include <signal.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifdef TB_CONFIG_LIBC_HAVE_SIGNAL
#   define tb_signal(sig, func)             signal(sig, func)
#else
#   undef tb_signal
#endif

#ifdef TB_CONFIG_LIBC_HAVE_SIGNAL
#   define TB_SIGHUP                        (1)                     // hangup (posix).
#   define TB_SIGINT                        (2)                     // interrupt (ansi).
#   define TB_SIGQUIT                       (3)                     // quit (posix).
#   define TB_SIGILL                        (4)                     // illegal instruction (ansi).
#   define TB_SIGTRAP                       (5)                     // trace trap (posix).
#   define TB_SIGABRT                       (6)                     // abort (ansi).
#   define TB_SIGIOT                        (6)                     // iot trap (4.2 bsd).
#   define TB_SIGBUS                        (7)                     // bus error (4.2 bsd).
#   define TB_SIGFPE                        (8)                     // floating-point exception (ansi).
#   define TB_SIGKILL                       (9)                     // kill, unblockable (posix).
#   define TB_SIGUSR1                       (10)                    // user-defined signal 1 (posix).
#   define TB_SIGSEGV                       (11)                    // segmentation violation (ansi).
#   define TB_SIGUSR2                       (12)                    // user-defined signal 2 (posix).
#   define TB_SIGPIPE                       (13)                    // broken pipe (posix).
#   define TB_SIGALRM                       (14)                    // alarm clock (posIX).
#   define TB_SIGTERM                       (15)                    // termination (ansi).
#   define TB_SIGSTKFLT                     (16)                    // stack fault.
#   define TB_SIGCLD                        (TB_SIGCHLD)            // same as sigchld (system v).
#   define TB_SIGCHLD                       (17)                    // child status has changed (posix).
#   define TB_SIGCONT                       (18)                    // continue (posix).
#   define TB_SIGSTOP                       (19)                    // stop, unblockable (posix).
#   define TB_SIGTSTP                       (20)                    // keyboard stop (posix).
#   define TB_SIGTTIN                       (21)                    // background read from tty (posix).
#   define TB_SIGTTOU                       (22)                    // background write to tty (posix).
#   define TB_SIGURG                        (23)                    // urgent condition on socket (4.2 bsd).
#   define TB_SIGXCPU                       (24)                    // cpu limit exceeded (4.2 bsd).
#   define TB_SIGXFSZ                       (25)                    // file size limit exceeded (4.2 bsd).
#   define TB_SIGVTALRM                     (26)                    // virtual alarm clock (4.2 bsd).
#   define TB_SIGPROF                       (27)                    // profiling alarm clock (4.2 bsd).
#   define TB_SIGWINCH                      (28)                    // window size change (4.3 bsd, sun).
#   define TB_SIGPOLL                       (TB_SIGIO)              // pollable event occurred (system v).
#   define TB_SIGIO                         (29)                    // i/o now possible (4.2 bsd).
#   define TB_SIGPWR                        (30)                    // power failure restart (system v).
#   define TB_SIGSYS                        (31)                    // bad system call.
#   define TB_SIGUNUSED                     (31)

#   define TB_SIG_DFL                       ((tb_void_t (*)(tb_int_t))0)
#endif

#endif
