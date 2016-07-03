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
 * @file        printf_object.h
 * @ingroup     libc
 *
 */
#ifndef TB_LIBC_STDIO_PRINTF_OBJECT_H
#define TB_LIBC_STDIO_PRINTF_OBJECT_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the printf object name maxn
#define TB_PRINTF_OBJECT_NAME_MAXN      (16)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/*! the printf object func type
 *
 * @param object        the printf object
 * @param cstr          the string buffer
 * @param maxn          the string buffer maxn
 *
 * @return              the real string size
 */
typedef tb_long_t       (*tb_printf_object_func_t)(tb_cpointer_t object, tb_char_t* cstr, tb_size_t maxn);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! register the printf object func
 *
 * @note non thread-safe
 *
 * @param name          the format name
 * @param func          the format func
 *
 * @code
    static tb_long_t tb_printf_object_ipv4(tb_cpointer_t object, tb_char_t* cstr, tb_size_t maxn)
    {
        // check
        tb_assert_and_check_return_val(object && cstr && maxn, -1);

        // the ipv4
        tb_ipv4_ref_t ipv4 = (tb_ipv4_ref_t)object;

        // format
        tb_long_t size = tb_snprintf(cstr, maxn - 1, "%u.%u.%u.%u", ipv4->u8[0], ipv4->u8[1], ipv4->u8[2], ipv4->u8[3]);
        if (size >= 0) cstr[size] = '\0';

        // ok?
        return size;
    }
    
    // register the "ipv4" printf object func
    tb_printf_object_register("ipv4", tb_printf_object_ipv4);

    // init ipv4
    tb_ipv4_t ipv4;
    tb_ipv4_cstr_set(&ipv4, "127.0.0.1");

    // trace ipv4, output: "ipv4: 127.0.0.1"
    tb_trace_i("ipv4: %{ipv4}", &ipv4);

 * @endcode
 */
tb_void_t               tb_printf_object_register(tb_char_t const* name, tb_printf_object_func_t func);

/*! find the printf object func from the given format name
 *
 * @param name          the format name
 *
 * @return              the format func
 */
tb_printf_object_func_t tb_printf_object_find(tb_char_t const* name);

/*! exit the printf object
 */
tb_void_t               tb_printf_object_exit(tb_noarg_t);

#ifdef __tb_debug__
/*! dump the printf object
 */
tb_void_t               tb_printf_object_dump(tb_noarg_t);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
