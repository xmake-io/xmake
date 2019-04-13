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
 * @file        hwaddr.c 
 * @ingroup     network
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "hwaddr"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "hwaddr.h"
#include "../libc/libc.h"
#include "../math/math.h"
#include "../utils/utils.h"
#include "../string/string.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_void_t tb_hwaddr_clear(tb_hwaddr_ref_t hwaddr)
{
    // check
    tb_assert_and_check_return(hwaddr);

    // clear it
    tb_memset(hwaddr->u8, 0, sizeof(hwaddr->u8));
}
tb_void_t tb_hwaddr_copy(tb_hwaddr_ref_t hwaddr, tb_hwaddr_ref_t copied)
{
    // check
    tb_assert_and_check_return(hwaddr && copied);

    // copy it
    hwaddr->u8[0] = copied->u8[0];
    hwaddr->u8[1] = copied->u8[1];
    hwaddr->u8[2] = copied->u8[2];
    hwaddr->u8[3] = copied->u8[3];
    hwaddr->u8[4] = copied->u8[4];
    hwaddr->u8[5] = copied->u8[5];
}
tb_bool_t tb_hwaddr_is_equal(tb_hwaddr_ref_t hwaddr, tb_hwaddr_ref_t other)
{
    // check
    tb_assert_and_check_return_val(hwaddr && other, tb_false);

    // is equal?
    return !tb_memcmp(hwaddr->u8, other->u8, sizeof(hwaddr->u8));
}
tb_char_t const* tb_hwaddr_cstr(tb_hwaddr_ref_t hwaddr, tb_char_t* data, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(hwaddr && data && maxn >= TB_HWADDR_CSTR_MAXN, tb_null);

    // make it
    tb_long_t size = tb_snprintf(data, maxn - 1, "%02x:%02x:%02x:%02x:%02x:%02x", hwaddr->u8[0], hwaddr->u8[1], hwaddr->u8[2], hwaddr->u8[3], hwaddr->u8[4], hwaddr->u8[5]);
    if (size >= 0) data[size] = '\0';

    // ok
    return data;
}
tb_bool_t tb_hwaddr_cstr_set(tb_hwaddr_ref_t hwaddr, tb_char_t const* cstr)
{
    // check
    tb_assert_and_check_return_val(cstr, tb_false);

    // done
    tb_uint32_t         v = 0;
    tb_char_t           c = '\0';
    tb_size_t           i = 0;
    tb_char_t const*    p = cstr;
    tb_bool_t           ok = tb_true;
    tb_hwaddr_t         temp;
    do
    {
        // the character
        c = *p++;

        // digit?
        if (tb_isdigit16(c) && v <= 0xff)
        {
            // update value
            if (tb_isdigit10(c))
                v = (v << 4) + (c - '0');
            else if (c > ('a' - 1) && c < ('f' + 1))
                v = (v << 4) + (c - 'a') + 10;
            else if (c > ('A' - 1) && c < ('F' + 1))
                v = (v << 4) + (c - 'A') + 10;
            else 
            {
                // abort
                tb_assert(0);

                // failed
                ok = tb_false;
                break;
            }
        }
        // ':' or "-" or '\0'?
        else if (i < 6 && (c == ':' || c == '-' || !c) && v <= 0xff)
        {
            // save value
            temp.u8[i++] = v;

            // clear value
            v = 0;
        }
        // failed?
        else 
        {
            ok = tb_false;
            break;
        }

    } while (c);

    // failed
    if (i != 6) ok = tb_false;

    // save it if ok
    if (ok && hwaddr) *hwaddr = temp;

    // trace
//    tb_assertf(ok, "invalid hwaddr: %s", cstr);

    // ok?
    return ok;
}

