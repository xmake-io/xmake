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
 * @file        memcpy.c
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
#   define TB_LIBC_STRING_IMPL_MEMCPY
#endif


/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_ASSEMBLER_IS_GAS
static tb_pointer_t tb_memcpy_impl(tb_pointer_t s1, tb_cpointer_t s2, tb_size_t n)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    tb_long_t d0, d1, d2;
    __tb_asm__ __tb_volatile__
    (
        "   rep;    movsl\n"
        "   movl    %4, %%ecx\n"
        "   andl    $3, %%ecx\n"
        /* jz is optional. avoids "rep; movsb" with ecx == 0,
        * but adds a branch, which is currently (2008) faster */
        "   jz      1f\n"
        "   rep;    movsb\n"
        "1:\n"

        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" ((tb_size_t)s1), "2" ((tb_size_t)s2)
        : "memory"
    );
    return s1;
}
#endif
