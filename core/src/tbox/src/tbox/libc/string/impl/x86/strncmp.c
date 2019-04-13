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
 * @file        strncmp.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#if 0//def TB_ASSEMBLER_IS_GAS
#   define TB_LIBC_STRING_IMPL_STRNCMP
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if 0//def TB_ASSEMBLER_IS_GAS
static tb_long_t tb_strncmp_impl(tb_char_t const* s1, tb_char_t const* s2, tb_size_t n)
{
    tb_assert_and_check_return_val(s1 && s2, 0);
    if (s1 == s2 || !n) return 0;

    tb_size_t r;
    tb_size_t d0, d1, d2;
    __tb_asm__ __tb_volatile__
    (
        "1:\n"
        "   decl %3\n"
        "   js 2f\n"
        "   lodsb\n"
        "   scasb\n"
        "   jne 3f\n"
        "   testb %%al,%%al\n"
        "   jne 1b\n"
        "2:\n"
        "   xorl %%eax,%%eax\n"
        "   jmp 4f\n"
        "3:\n"
        "   sbbl %%eax,%%eax\n"
        "   orb $1,%%al\n"
        "4:"

        : "=a" (r), "=&S" (d0), "=&D" (d1), "=&c" (d2)
        : "1" (s1), "2" (s2), "3" (n)
        : "memory"
    );

    return r;
}
#endif
