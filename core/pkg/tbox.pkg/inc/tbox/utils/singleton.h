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
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        singleton.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_SINGLETON_H
#define TB_UTILS_SINGLETON_H

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

/// the singleton type enum
typedef enum __tb_singleton_type_e
{
    /// the default allocator
    TB_SINGLETON_TYPE_DEFAULT_ALLOCATOR     = 0

    /// the static allocator
,   TB_SINGLETON_TYPE_STATIC_ALLOCATOR      = 1

    /// the lock profiler type
,   TB_SINGLETON_TYPE_LOCK_PROFILER         = 2

    /// the random type
,   TB_SINGLETON_TYPE_RANDOM                = 3

    /// the ifaddrs type
,   TB_SINGLETON_TYPE_IFADDRS               = 4

    /// the timer type
,   TB_SINGLETON_TYPE_TIMER                 = 5

    /// the ltimer type
,   TB_SINGLETON_TYPE_LTIMER                = 6

    /// the aicp type
,   TB_SINGLETON_TYPE_AICP                  = 7

    /// the openssl library type
,   TB_SINGLETON_TYPE_LIBRARY_OPENSSL       = 8

    /// the mysql library type
,   TB_SINGLETON_TYPE_LIBRARY_MYSQL         = 9

    /// the sqlite3 library type
,   TB_SINGLETON_TYPE_LIBRARY_SQLITE3       = 10

    /// the thread pool type
,   TB_SINGLETON_TYPE_THREAD_POOL           = 11

    /// the transfer pool type
,   TB_SINGLETON_TYPE_TRANSFER_POOL         = 12

    /// the cookies type
,   TB_SINGLETON_TYPE_COOKIES               = 13

    /// the user defined type
,   TB_SINGLETON_TYPE_USER                  = 14

    /// the max count of the singleton type
#ifdef __tb_small__
,   TB_SINGLETON_TYPE_MAXN                  = 32
#else
,   TB_SINGLETON_TYPE_MAXN                  = 128
#endif

}tb_singleton_type_e;

/// the singleton init func type
typedef tb_handle_t (*tb_singleton_init_func_t)(tb_cpointer_t* ppriv);

/// the singleton exit func type
typedef tb_void_t   (*tb_singleton_exit_func_t)(tb_handle_t instance, tb_cpointer_t priv);

/// the singleton kill func type
typedef tb_void_t   (*tb_singleton_kill_func_t)(tb_handle_t instance, tb_cpointer_t priv);

/// the singleton static init func type
typedef tb_bool_t   (*tb_singleton_static_init_func_t)(tb_handle_t instance, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init singleton
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_singleton_init(tb_noarg_t);

/*! kill singleton
 */
tb_void_t           tb_singleton_kill(tb_noarg_t);

/*! exit singleton
 */
tb_void_t           tb_singleton_exit(tb_noarg_t);

/*! the singleton instance
 *
 * @param type      the singleton type
 * @param init      the singleton init func 
 * @param exit      the singleton exit func 
 * @param kill      the singleton kill func 
 * @param priv      the private data
 *
 * @return          the singleton instance handle
 */
tb_handle_t         tb_singleton_instance(tb_size_t type, tb_singleton_init_func_t init, tb_singleton_exit_func_t exit, tb_singleton_kill_func_t kill, tb_cpointer_t priv);

/*! the singleton static instance
 *
 * @code
    static tb_bool_t tb_xxxx_instance_init(tb_handle_t instance, tb_cpointer_t priv)
    {
        // init 
        // ...

        // ok
        return tb_true;
    }
    tb_xxxx_t* tb_xxxx()
    {
        // init
        static tb_atomic_t      s_binited = 0;
        static tb_xxxx_t        s_xxxx = {0};

        // init the static instance
        tb_bool_t ok = tb_singleton_static_init(&s_binited, &s_xxxx, tb_xxxx_instance_init, tb_null);
        tb_assert(ok);

        // ok
        return &s_xxxx;
    }
 * @endcode
 *
 * @param binited   the singleton static instance is inited?
 * @param instance  the singleton static instance
 * @param init      the singleton static init func 
 * @param priv      the private data
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_singleton_static_init(tb_atomic_t* binited, tb_handle_t instance, tb_singleton_static_init_func_t init, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

