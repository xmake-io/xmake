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
 * @file        strcpy.c
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
//#     define TB_LIBC_STRING_IMPL_STRCPY
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if 0//def TB_ASSEMBLER_IS_GAS
static tb_char_t* tb_strcpy_impl(tb_char_t* s1, tb_char_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    tb_size_t edi, esi, eax;
    __tb_asm__ __tb_volatile__
    (
        // align?
        "1:\n"
        "   movl (%%esi), %%eax\n" // lodsl is too slower, why?
        "   add $4, %%esi\n"
        "   movl %%eax, %%edx\n"
        "   testb %%dl, %%dl\n"
        "   je 2f\n"
        "   shr $8, %%edx\n"
        "   testb %%dl, %%dl\n"
        "   je 2f\n"
        "   shr $8, %%edx\n"
        "   testb %%dl, %%dl\n"
        "   je 2f\n"
        "   shr $8, %%edx\n"
        "   testb %%dl, %%dl\n"
        "   je 2f\n"
        "   stosl\n"
        "   jmp 1b\n"
        "2:\n"
        "   stosb\n"
        "   testb %%al, %%al\n"
        "   je 3f\n"
        "   shr $8, %%eax\n"
        "   jmp 2b\n"
        "3:\n"


        : "=&S" (esi), "=&D" (edi)
        : "0" (s2), "1" (s1) 
        : "memory", "eax", "edx"
    );
    return s1;
}
#endif
