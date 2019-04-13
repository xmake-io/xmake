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
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#ifndef TB_CONFIG_LIBC_HAVE_STRNCMP
#   if defined(TB_ARCH_x86)
#       include "impl/x86/strncmp.c"
#   elif defined(TB_ARCH_ARM)
#       include "impl/arm/strncmp.c"
#   elif defined(TB_ARCH_SH4)
#       include "impl/sh4/strncmp.c"
#   endif
#else
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#if defined(TB_CONFIG_LIBC_HAVE_STRNCMP)
static tb_long_t tb_strncmp_impl(tb_char_t const* s1, tb_char_t const* s2, tb_size_t n)
{
    tb_assert_and_check_return_val(s1 && s2, 0);
    return strncmp(s1, s2, n);
}
#elif !defined(TB_LIBC_STRING_IMPL_STRNCMP)
static tb_long_t tb_strncmp_impl(tb_char_t const* s1, tb_char_t const* s2, tb_size_t n)
{
    tb_assert_and_check_return_val(s1 && s2, 0);
    if (s1 == s2 || !n) return 0;

    tb_long_t r = 0;
    while (n-- && ((r = ((tb_long_t)(*((tb_byte_t *)s1))) - *((tb_byte_t *)s2++)) == 0) && *s1++);
    return r;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_long_t tb_strncmp(tb_char_t const* s1, tb_char_t const* s2, tb_size_t n)
{
    // done
    return tb_strncmp_impl(s1, s2, n);
}
