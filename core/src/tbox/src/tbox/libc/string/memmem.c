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
 * @file        memmem.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "string.h"
#include "../../memory/impl/prefix.h"
#ifdef TB_CONFIG_LIBC_HAVE_MEMMEM
#   include <string.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation 
 */
#if defined(TB_CONFIG_LIBC_HAVE_MEMMEM)
static tb_pointer_t tb_memmem_impl(tb_cpointer_t s1, tb_size_t n1, tb_cpointer_t s2, tb_size_t n2)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    // done
    return memmem(s1, n1, s2, n2);
}
#elif !defined(TB_LIBC_STRING_IMPL_MEMMEM)
static tb_pointer_t tb_memmem_impl(tb_cpointer_t s1, tb_size_t n1, tb_cpointer_t s2, tb_size_t n2)
{
    // check
    tb_assert_and_check_return_val(s1 && s2, tb_null);

    // find empty data?
	if (!n2) return (tb_pointer_t)s1;

    // done
	if (n1 >= n2) 
    {
        tb_size_t           n = 0;
		tb_byte_t const*    ph = (tb_byte_t const*)s1;
		tb_byte_t const*    pn = (tb_byte_t const*)s2;
		tb_byte_t const*    plast = ph + (n1 - n2);
		do 
        {
			n = 0;
			while (ph[n] == pn[n]) 
            {
                // found?
				if (++n == n2) return (tb_pointer_t)ph;
			}

		} while (++ph <= plast);
	}

    // not found?
	return tb_null;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces 
 */
tb_pointer_t tb_memmem_(tb_cpointer_t s1, tb_size_t n1, tb_cpointer_t s2, tb_size_t n2)
{
    // done
    return tb_memmem_impl(s1, n1, s2, n2);
}
tb_pointer_t tb_memmem(tb_cpointer_t s1, tb_size_t n1, tb_cpointer_t s2, tb_size_t n2)
{
    // check
#ifdef __tb_debug__
    // TODO
#endif

    // done
    return tb_memmem_impl(s1, n1, s2, n2);
}
