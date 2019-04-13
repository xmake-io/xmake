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
 * @file        memdup.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../memory/impl/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_pointer_t tb_memdup_(tb_cpointer_t s, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // done
    __tb_register__ tb_pointer_t p = tb_malloc(n);
    if (p) tb_memcpy_(p, s, n);
    return p;
}
tb_pointer_t tb_memdup(tb_cpointer_t s, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);
    
    // check
#ifdef __tb_debug__
    {
        // overflow?
        tb_size_t size = tb_pool_data_size(s);
        if (size && n > size)
        {
            tb_trace_i("[memdup]: [overflow]: [%p, %lu] from [%p, %lu]", s, n, s, size);
            tb_backtrace_dump("[memdup]: [overflow]: ", tb_null, 10);
            tb_pool_data_dump(s, tb_true, "\t[malloc]: [from]: ");
            tb_abort();
        }
    }
#endif

    // done
    __tb_register__ tb_pointer_t p = tb_malloc(n);
    if (p) tb_memcpy(p, s, n);
    return p;
}
