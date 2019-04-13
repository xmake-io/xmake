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
 * @file        math.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "math.h"
#include "../math.h"
#include "../../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
#ifndef TB_CONFIG_MICRO_ENABLE
static tb_long_t tb_math_printf_format_fixed(tb_cpointer_t object, tb_char_t* cstr, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(cstr && maxn, -1);

    // the fixed
    tb_fixed_t fixed = (tb_fixed_t)tb_p2s32(object);

    // format
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
    tb_long_t size = tb_snprintf(cstr, maxn - 1, "%f", tb_fixed_to_float(fixed));
    if (size >= 0) cstr[size] = '\0';
#else
    tb_long_t size = tb_snprintf(cstr, maxn - 1, "%ld", tb_fixed_to_long(fixed));
    if (size >= 0) cstr[size] = '\0';
#endif

    // ok?
    return size;
}
#endif
    
/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_math_init_env()
{
#ifndef TB_CONFIG_MICRO_ENABLE
    // register printf("%{fixed}", fixed);
    tb_printf_object_register("fixed", tb_math_printf_format_fixed);
#endif

    // ok
    return tb_true;
}
tb_void_t tb_math_exit_env()
{
}

