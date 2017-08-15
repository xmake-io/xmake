/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        mbstowcs.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "stdlib.h"
#ifdef TB_CONFIG_LIBC_HAVE_MBSTOWCS
#   include <stdlib.h>
#   ifdef TB_CONFIG_LIBC_HAVE_SETLOCALE
#       include <locale.h>
#   endif
#else
#   include "../../charset/charset.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */

#if defined(TB_CONFIG_LIBC_HAVE_MBSTOWCS)
tb_size_t tb_mbstowcs(tb_wchar_t* s1, tb_char_t const* s2, tb_size_t n)
{
    // set local locale
#ifdef TB_CONFIG_LIBC_HAVE_SETLOCALE
    setlocale(LC_ALL, "");
#endif

    // convert it
    n = mbstowcs(s1, s2, n);

    // set default locale
#ifdef TB_CONFIG_LIBC_HAVE_SETLOCALE
    setlocale(LC_ALL, "C");
#endif

    // ok
    return n;
}
#elif defined(TB_CONFIG_MODULE_HAVE_CHARSET)
tb_size_t tb_mbstowcs(tb_wchar_t* s1, tb_char_t const* s2, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, 0);

    // init
    tb_size_t e = (sizeof(tb_wchar_t) == 4)? TB_CHARSET_TYPE_UCS4 : TB_CHARSET_TYPE_UCS2;
    tb_long_t r = tb_charset_conv_cstr(TB_CHARSET_TYPE_UTF8, e | TB_CHARSET_TYPE_LE, s2, (tb_byte_t*)s1, n * sizeof(tb_wchar_t));
    if (r > 0) r /= sizeof(tb_wchar_t);
    
    // strip
    if (r >= 0) s1[r] = L'\0';

    // ok?
    return r >= 0? r : -1;
}
#else
tb_size_t tb_mbstowcs(tb_wchar_t* s1, tb_char_t const* s2, tb_size_t n)
{
    tb_trace_noimpl();
    return -1;
}
#endif
