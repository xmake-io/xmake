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
 * @file        stricmp.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#ifdef TB_CONFIG_LIBC_HAVE_STRCASECMP
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#ifdef TB_CONFIG_LIBC_HAVE_STRCASECMP
static tb_long_t tb_stricmp_impl(tb_char_t const* s1, tb_char_t const* s2)
{
    tb_assert_and_check_return_val(s1 && s2, 0);
#ifdef TB_COMPILER_IS_MSVC
    return _stricmp(s1, s2);
#else
    return strcasecmp(s1, s2);
#endif
}
#else
static tb_long_t tb_stricmp_impl(tb_char_t const* s1, tb_char_t const* s2)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);
    tb_check_return_val(s1 != s2, 0);

    // done
    tb_long_t r = 0;
    while (((s1 == s2) || !(r = ((tb_long_t)(tb_tolower(*((tb_byte_t* )s1)))) - tb_tolower(*((tb_byte_t* )s2)))) && (++s2, *s1++));
    return r;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_long_t tb_stricmp(tb_char_t const* s1, tb_char_t const* s2)
{
    // check
#ifdef __tb_debug__
    {
        // check overflow? 
        tb_strlen(s1);
        tb_strlen(s2);
    }
#endif

    // done
    return tb_stricmp_impl(s1, s2);
}
