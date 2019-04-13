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
 * @file        strlen.c
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
//#     define TB_LIBC_STRING_IMPL_STRLEN
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if 0//def TB_ASSEMBLER_IS_GAS
static tb_size_t tb_strlen_impl(tb_char_t const* s)
{
    tb_assert_and_check_return_val(s, 0);

#if 0
    __tb_register__ tb_size_t r = 0;
    __tb_asm__ __tb_volatile__
    (
        "repne\n"
        "scasb\n"
        "notl   %0\n"
        "decl   %0"

        : "=c" (r)
        : "D" (s), "a" (0), "0" (0xffffffffu)
        : "memory"
    );
    return r;
#else
    __tb_register__ tb_size_t r = 0;
    __tb_asm__ __tb_volatile__
    (
        "   movl    %1, %0\n"
        "   decl    %0\n"
        "1:\n"  
        "   incl    %0\n"
        "   cmpb    $0, (%0)\n"
        "   jne     1b\n"
        "   subl    %1, %0"

        : "=a" (r)
        : "d" (s)
        : "memory"
    );
    return r;
#endif
}
#endif
