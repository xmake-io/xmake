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
 * @file        strcmp.c
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
//#     define TB_LIBC_STRING_IMPL_STRCMP
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if 0//def TB_ASSEMBLER_IS_GAS
static tb_long_t tb_strcmp_impl(tb_char_t const* s1, tb_char_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, 0);

    // FIXME: return is -1, 0, 1
    tb_size_t d0, d1;
    tb_size_t r;
    __tb_asm__ __tb_volatile__
    (
        "1:\n"
        "   lodsb\n"
        "   scasb\n"
        "   jne 2f\n"
        "   testb %%al, %%al\n"
        "   jne 1b\n"
        "   xorl %%eax, %%eax\n"
        "   jmp 3f\n"
        "2:\n"
        "   sbbl %%eax, %%eax\n"
        "   orb $1, %%al\n"
        "3:"

        : "=a" (r), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory"
    );

    return r;
}
#endif
