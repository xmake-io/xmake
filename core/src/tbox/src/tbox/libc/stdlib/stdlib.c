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
 * @file        stdlib.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "stdlib.h"
#include "../../libm/libm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_uint64_t tb_s2tou64(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    while (tb_isspace(*s)) s++;

    // has sign?
    tb_int_t sign = 0;
    if (*s == '-') 
    {
        sign = 1;
        s++;
    }
    // skip '+'
    else if (*s == '+') s++;

    // skip "0b"
    if (s[0] == '0' && (s[1] == 'b' || s[1] == 'B'))
        s += 2;

    // skip '0'
    while ((*s) == '0') s++;

    // compute number
    tb_uint64_t val = 0;
    while (*s)
    {
        tb_char_t ch = *s;
        if (tb_isdigit2(ch))
            val = (val << 1) + (ch - '0');
        else break;
    
        s++;
    }

    // is negative number?
    if (sign) val = ~val + 1;

    // the value
    return val;
}
tb_uint64_t tb_s8tou64(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    while (tb_isspace(*s)) s++;

    // has sign?
    tb_int_t sign = 0;
    if (*s == '-') 
    {
        sign = 1;
        s++;
    }
    // skip '+'
    else if (*s == '+') s++;

    // skip '0'
    while ((*s) == '0') s++;

    // compute number
    tb_uint64_t val = 0;
    while (*s)
    {
        tb_char_t ch = *s;
        if (tb_isdigit8(ch))
            val = (val << 3) + (ch - '0');
        else break;
    
        s++;
    }

    // is negative number?
    if (sign) val = ~val + 1;

    // the value
    return val;
}
tb_uint64_t tb_s10tou64(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    while (tb_isspace(*s)) s++;

    // has sign?
    tb_int_t sign = 0;
    if (*s == '-') 
    {
        sign = 1;
        s++;
    }
    // skip '+'
    else if (*s == '+') s++;

    // skip '0'
    while ((*s) == '0') s++;

    // compute number
    tb_uint64_t val = 0;
    while (*s)
    {
        tb_char_t ch = *s;
        if (tb_isdigit10(ch))
            val = val * 10 + (ch - '0');
        else break;
    
        s++;
    }

    // is negative number?
    if (sign) val = ~val + 1;

    // the value
    return val;
}
tb_uint64_t tb_s16tou64(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    while (tb_isspace(*s)) s++;

    // has sign?
    tb_int_t sign = 0;
    if (*s == '-') 
    {
        sign = 1;
        s++;
    }
    // skip '+'
    else if (*s == '+') s++;

    // skip "0x"
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X'))
        s += 2;

    // skip '0'
    while ((*s) == '0') s++;

    // compute number
    tb_uint64_t val = 0;
    while (*s)
    {
        tb_char_t ch = *s;
        if (tb_isdigit10(ch))
            val = (val << 4) + (ch - '0');
        else if (ch > ('a' - 1) && ch < ('f' + 1))
            val = (val << 4) + (ch - 'a') + 10;
        else if (ch > ('A' - 1) && ch < ('F' + 1))
            val = (val << 4) + (ch - 'A') + 10;
        else break;
    
        s++;
    }

    // is negative number?
    if (sign) val = ~val + 1;

    // the value
    return val;
}
tb_uint64_t tb_stou64(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    tb_char_t const* p = s;
    while (tb_isspace(*p)) p++;

    // has sign?
    if (*p == '-' || *p == '+') p++;

    // is hex?
    if (*p++ == '0')
    {
        if (*p == 'x' || *p == 'X')
            return tb_s16tou64(s);
        else if (*p == 'b' || *p == 'B')
            return tb_s2tou64(s);
        else return tb_s8tou64(s);
    }
    else return tb_s10tou64(s);
}
tb_uint64_t tb_sbtou64(tb_char_t const* s, tb_int_t base)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // the convect functions
    static tb_uint64_t (*s_conv[])(tb_char_t const*) =
    {
        tb_null
    ,   tb_null
    ,   tb_s2tou64
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_s8tou64
    ,   tb_null
    ,   tb_s10tou64
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_s16tou64
    };
    tb_assert_and_check_return_val(base < tb_arrayn(s_conv) && s_conv[base], 0);

    // convect it
    return s_conv[base](s);
}
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
tb_double_t tb_s2tod(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    while (tb_isspace(*s)) s++;

    // has sign?
    tb_int_t sign = 0;
    if (*s == '-') 
    {
        sign = 1;
        s++;
    }
    // skip '+'
    else if (*s == '+') s++;

    // nan?
    if (s[0] == 'n' && s[1] == 'a' && s[2] == 'n')
        return TB_NAN;

    // inf or -inf?
    if (s[0] == 'i' && s[1] == 'n' && s[2] == 'f')
        return sign? -TB_INF : TB_INF;

    // skip "0b"
    if (s[0] == '0' && (s[1] == 'b' || s[1] == 'B'))
        s += 2;

    // compute double: lhs.rhs
    tb_int_t    dec = 0;
    tb_uint64_t lhs = 0;
    tb_double_t rhs = 0.;
    tb_int_t    zeros = 0;
    tb_int8_t   decimals[256];
    tb_int8_t*  d = decimals;
    tb_int8_t*  e = decimals + 256;
    while (*s)
    {
        tb_char_t ch = *s;

        // is the part of decimal?
        if (ch == '.')
        {
            if (!dec) 
            {
                dec = 1;
                s++;
                continue ;
            }
            else break;
        }

        // parse integer & decimal
        if (tb_isdigit2(ch))
        {
            // save decimals
            if (dec) 
            {
                if (d < e)
                {
                    if (ch != '0')
                    {
                        // fill '0'
                        while (zeros--) *d++ = 0;
                        zeros = 0;

                        // save decimal
                        *d++ = ch - '0';
                    }
                    else zeros++;
                }
            }
            else lhs = (lhs << 1) + (ch - '0');
        }
        else break;
    
        s++;
    }

    tb_assert(d <= decimals + 256);

    // compute decimal
    while (d-- > decimals) rhs = (rhs + *d) / 2;

    // merge 
    return (sign? ((tb_double_t)lhs + rhs) * -1. : ((tb_double_t)lhs + rhs));
}
tb_double_t tb_s8tod(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    while (tb_isspace(*s)) s++;

    // has sign?
    tb_int_t sign = 0;
    if (*s == '-') 
    {
        sign = 1;
        s++;
    }
    // skip '+'
    else if (*s == '+') s++;

    // nan?
    if (s[0] == 'n' && s[1] == 'a' && s[2] == 'n')
        return TB_NAN;

    // inf or -inf?
    if (s[0] == 'i' && s[1] == 'n' && s[2] == 'f')
        return sign? -TB_INF : TB_INF;

    // skip '0'
    while ((*s) == '0') s++;

    // compute double: lhs.rhs
    tb_int_t    dec = 0;
    tb_uint64_t lhs = 0;
    tb_double_t rhs = 0.;
    tb_int_t    zeros = 0;
    tb_int8_t   decimals[256];
    tb_int8_t*  d = decimals;
    tb_int8_t*  e = decimals + 256;
    while (*s)
    {
        tb_char_t ch = *s;

        // is the part of decimal?
        if (ch == '.')
        {
            if (!dec) 
            {
                dec = 1;
                s++;
                continue ;
            }
            else break;
        }

        // parse integer & decimal
        if (tb_isdigit8(ch))
        {
            // save decimals
            if (dec) 
            {
                if (d < e)
                {
                    if (ch != '0')
                    {
                        // fill '0'
                        while (zeros--) *d++ = 0;
                        zeros = 0;

                        // save decimal
                        *d++ = ch - '0';
                    }
                    else zeros++;
                }
            }
            else lhs = (lhs << 3) + (ch - '0');
        }
        else break;
    
        s++;
    }

    // check
    tb_assert_and_check_return_val(d <= decimals + 256, 0);

    // compute decimal
    while (d-- > decimals) rhs = (rhs + *d) / 8;

    // merge 
    return (sign? ((tb_double_t)lhs + rhs) * -1. : ((tb_double_t)lhs + rhs));
}
tb_double_t tb_s10tod(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    while (tb_isspace(*s)) s++;

    // has sign?
    tb_int_t sign = 0;
    if (*s == '-') 
    {
        sign = 1;
        s++;
    }
    // skip '+'
    else if (*s == '+') s++;

    // nan?
    if (s[0] == 'n' && s[1] == 'a' && s[2] == 'n')
        return TB_NAN;

    // inf or -inf?
    if (s[0] == 'i' && s[1] == 'n' && s[2] == 'f')
        return sign? -TB_INF : TB_INF;

    // skip '0'
    while ((*s) == '0') s++;

    // compute double: lhs.rhs
    tb_int_t    dec = 0;
    tb_uint64_t lhs = 0;
    tb_double_t rhs = 0.;
    tb_int_t    zeros = 0;
    tb_int8_t   decimals[256];
    tb_int8_t*  d = decimals;
    tb_int8_t*  e = decimals + 256;
    while (*s)
    {
        tb_char_t ch = *s;

        // is the part of decimal?
        if (ch == '.')
        {
            if (!dec) 
            {
                dec = 1;
                s++;
                continue ;
            }
            else break;
        }

        // parse integer & decimal
        if (tb_isdigit10(ch))
        {
            // save decimals
            if (dec) 
            {
                if (d < e)
                {
                    if (ch != '0')
                    {
                        // fill '0'
                        while (zeros--) *d++ = 0;
                        zeros = 0;

                        // save decimal
                        *d++ = ch - '0';
                    }
                    else zeros++;
                }
            }
            else lhs = lhs * 10 + (ch - '0');
        }
        else break;
    
        s++;
    }

    // check
    tb_assert_and_check_return_val(d <= decimals + 256, 0);

    // compute decimal
    while (d-- > decimals) rhs = (rhs + *d) / 10;

    // merge 
    return (sign? ((tb_double_t)lhs + rhs) * -1. : ((tb_double_t)lhs + rhs));
}
tb_double_t tb_s16tod(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    while (tb_isspace(*s)) s++;

    // has sign?
    tb_int_t sign = 0;
    if (*s == '-') 
    {
        sign = 1;
        s++;
    }
    // skip '+'
    else if (*s == '+') s++;

    // nan?
    if (s[0] == 'n' && s[1] == 'a' && s[2] == 'n')
        return TB_NAN;

    // inf or -inf?
    if (s[0] == 'i' && s[1] == 'n' && s[2] == 'f')
        return sign? -TB_INF : TB_INF;

    // skip "0x"
    if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X'))
        s += 2;

    // compute double: lhs.rhs
    tb_int_t    dec = 0;
    tb_uint64_t lhs = 0;
    tb_double_t rhs = 0.;
    tb_int_t    zeros = 0;
    tb_int8_t   decimals[256];
    tb_int8_t*  d = decimals;
    tb_int8_t*  e = decimals + 256;
    while (*s)
    {
        tb_char_t ch = *s;

        // is the part of decimal?
        if (ch == '.')
        {
            if (!dec) 
            {
                dec = 1;
                s++;
                continue ;
            }
            else break;
        }

        // parse integer & decimal
        if (tb_isdigit10(ch))
        {
            // save decimals
            if (dec) 
            {
                if (d < e)
                {
                    if (ch != '0')
                    {
                        // fill '0'
                        while (zeros--) *d++ = 0;
                        zeros = 0;

                        // save decimal
                        *d++ = ch - '0';
                    }
                    else zeros++;
                }
            }
            else lhs = (lhs << 4) + (ch - '0');
        }
        else if (ch > ('a' - 1) && ch < ('f' + 1))
        {
            // save decimals
            if (dec) 
            {
                if (d < e)
                {
                    if (ch != '0')
                    {
                        // fill '0'
                        while (zeros--) *d++ = 0;
                        zeros = 0;

                        // save decimal
                        *d++ = (ch - 'a') + 10;
                    }
                    else zeros++;
                }
            }
            else lhs = (lhs << 4) + (ch - 'a') + 10;
        }
        else if (ch > ('A' - 1) && ch < ('F' + 1))
        {
            // save decimals
            if (dec) 
            {
                if (d < e)
                {
                    if (ch != '0')
                    {
                        // fill '0'
                        while (zeros--) *d++ = 0;
                        zeros = 0;

                        // save decimal
                        *d++ = (ch - 'A') + 10;
                    }
                    else zeros++;
                }
            }
            else lhs = (lhs << 4) + (ch - 'A') + 10;
        }
        else break;
    
        s++;
    }

    // check
    tb_assert_and_check_return_val(d <= decimals + 256, 0);

    // compute decimal
    while (d-- > decimals) rhs = (rhs + *d) / 16;

    // merge 
    return (sign? ((tb_double_t)lhs + rhs) * -1. : ((tb_double_t)lhs + rhs));
}
tb_double_t tb_stod(tb_char_t const* s)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // skip space
    tb_char_t const* p = s;
    while (tb_isspace(*p)) p++;

    // has sign?
    if (*p == '-' || *p == '+') p++;

    // is hex?
    if (*p++ == '0')
    {
        if (*p == 'x' || *p == 'X')
            return tb_s16tod(s);
        else if (*p == 'b' || *p == 'B')
            return tb_s2tod(s);
        else return tb_s8tod(s);
    }
    else return tb_s10tod(s);
}
tb_double_t tb_sbtod(tb_char_t const* s, tb_int_t base)
{
    // check
    tb_assert_and_check_return_val(s, 0);

    // the convect functions
    static tb_double_t (*s_conv[])(tb_char_t const*) =
    {
        tb_null
    ,   tb_null
    ,   tb_s2tod
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_s8tod
    ,   tb_null
    ,   tb_s10tod
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_null
    ,   tb_s16tod
    };
    tb_assert_and_check_return_val(base < tb_arrayn(s_conv) && s_conv[base], 0);

    // convect it
    return s_conv[base](s);
}
#endif

