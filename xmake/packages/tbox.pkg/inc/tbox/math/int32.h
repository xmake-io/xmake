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
 * @file        int32.h
 * @ingroup     math
 *
 */
#ifndef TB_MATH_INT32_H
#define TB_MATH_INT32_H

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

// sign
#define tb_int32_get_sign(x)            tb_int32_get_sign_inline(x)
#define tb_int32_set_sign(x, s)         tb_int32_set_sign_inline(x, s)

// bool: is true?
#define tb_int32_nz(x)                  tb_int32_nz_inline(x)

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// div
tb_int32_t  tb_int32_div(tb_int32_t x, tb_int32_t y, tb_int_t nbits);

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline
 */

// return -1 if x < 0, else return 0
static __tb_inline__ tb_int32_t tb_int32_get_sign_inline(tb_int32_t x)
{
    tb_int32_t s = ((tb_int32_t)(x) >> 31);
    tb_assert((x < 0 && s == -1) || (x >= 0 && !s));
    return s;
}
// if s == -1, return -x, else s must be 0, and return x.
static __tb_inline__ tb_int32_t tb_int32_set_sign_inline(tb_int32_t x, tb_int32_t s)
{
    tb_assert(s == 0 || s == -1);
    return (x ^ s) - s;
}
// non zero, return 1 if x != 0, else return 0
static __tb_inline__ tb_long_t tb_int32_nz_inline(tb_uint32_t x)
{
    //return (x? 1 : 0);
    return ((x | (0 - x)) >> 31);
}


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

