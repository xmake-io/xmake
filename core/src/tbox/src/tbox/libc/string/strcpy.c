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
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../memory/impl/prefix.h"
#ifndef TB_CONFIG_LIBC_HAVE_STRCPY
#   if defined(TB_ARCH_x86)
#       include "impl/x86/strcpy.c"
#   elif defined(TB_ARCH_ARM)
#       include "impl/arm/strcpy.c"
#   elif defined(TB_ARCH_SH4)
#       include "impl/sh4/strcpy.c"
#   endif
#else
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#if defined(TB_CONFIG_LIBC_HAVE_STRCPY)
static tb_char_t* tb_strcpy_impl(tb_char_t* s1, tb_char_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);
    return strcpy(s1, s2);
}
#elif !defined(TB_LIBC_STRING_IMPL_STRCPY)
static tb_char_t* tb_strcpy_impl(tb_char_t* s1, tb_char_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    __tb_register__ tb_char_t* s = s1;
    if (s1 == s2) return s;

#if 1
    tb_memcpy(s1, s2, tb_strlen(s2) + 1);
#elif defined(__tb_small__)
    while ((*s++ = *s2++)) ;
#else
    while (1) 
    {
        if (!(s1[0] = s2[0])) break;
        if (!(s1[1] = s2[1])) break;
        if (!(s1[2] = s2[2])) break;
        if (!(s1[3] = s2[3])) break;
        s1 += 4;
        s2 += 4;
    }
#endif

    return s;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_char_t* tb_strcpy(tb_char_t* s1, tb_char_t const* s2)
{
    // check
#ifdef __tb_debug__
    {
        // overflow dst? 
        tb_size_t n2 = tb_strlen(s2);

        // strcpy overflow? 
        tb_size_t n1 = tb_pool_data_size(s1);
        if (n1 && n2 + 1 > n1)
        {
            tb_trace_i("[strcpy]: [overflow]: [%p, %lu] => [%p, %lu]", s2, n2, s1, n1);
            tb_backtrace_dump("[strcpy]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s2, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    return tb_strcpy_impl(s1, s2);
}
