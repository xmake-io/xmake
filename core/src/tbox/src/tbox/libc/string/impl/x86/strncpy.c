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
 * @file        strncpy.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifdef TB_ASSEMBLER_IS_GAS
//#     define TB_LIBC_STRING_IMPL_STRNCPY
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if 0//def TB_ASSEMBLER_IS_GAS
static tb_char_t* tb_strncpy_impl(tb_char_t* s1, tb_char_t const* s2, tb_size_t n)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    tb_size_t d0, d1, d2, d3;
    __tb_asm__ __tb_volatile__
    (
        "1:\n"
        "   decl %2\n"
        "   js 2f\n"
        "   lodsb\n"
        "   stosb\n"
        "   testb %%al, %%al\n"
        "   jne 1b\n"
        "   rep\n"
        "   stosb\n"
        "2:"

        : "=&S" (d0), "=&D" (d1), "=&c" (d2), "=&a" (d3)
        : "0" (s2), "1" (s1), "2" (n) 
        : "memory"
    );
    return s1;
}
#endif
