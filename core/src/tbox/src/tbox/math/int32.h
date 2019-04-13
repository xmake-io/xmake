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

