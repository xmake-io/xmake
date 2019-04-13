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
 * @file        memset.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <string.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define TB_LIBC_STRING_IMPL_MEMSET_U8

#if defined(TB_ASSEMBLER_IS_GAS)
#   define TB_LIBC_STRING_IMPL_MEMSET_U16
#   define TB_LIBC_STRING_IMPL_MEMSET_U32
#endif
/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

#ifdef TB_ASSEMBLER_IS_GAS
static __tb_inline__ tb_void_t tb_memset_impl_u8_opt_v1(tb_byte_t* s, tb_byte_t c, tb_size_t n)
{

}
#endif

#ifdef TB_LIBC_STRING_IMPL_MEMSET_U8
static tb_pointer_t tb_memset_impl(tb_pointer_t s, tb_byte_t c, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);
    if (!n) return s;

#   if 1
    memset(s, c, n);
#   elif defined(TB_ASSEMBLER_IS_GAS)
    tb_memset_impl_u8_opt_v1(s, (tb_byte_t)c, n);
#   else
#       error
#   endif

    return s;
}
#endif


#ifdef TB_ASSEMBLER_IS_GAS
static __tb_inline__ tb_void_t tb_memset_u16_impl_opt_v1(tb_uint16_t* s, tb_uint16_t c, tb_size_t n)
{
    /* align by 4-bytes */
    if (((tb_size_t)s) & 0x3)
    {
        *((tb_uint16_t*)s) = c;
        s += 2;
        n--;
    }
    tb_size_t l = n & 0x3;
    s += (n << 1);
    if (!l)
    {
        n >>= 2;
        __tb_asm__ __tb_volatile__
        (
            "1:\n\t"
            "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
            "mov.w %1,@-%2\n\t" /* *--s = c */
            "mov.w %1,@-%2\n\t" /* *--s = c */
            "mov.w %1,@-%2\n\t" /* *--s = c */
            "mov.w %1,@-%2\n\t" /* *--s = c */
            "bf 1b\n\t"         /* if T == 0 goto label 1: */
            :                   /* no output registers */ 
            : "r" (n), "r" (c), "r" (s) /* constraint: register */
        );
    }
    else if (n >= 4)
    {
        n >>= 2;
        __tb_asm__ __tb_volatile__
        (
            "1:\n\t"            /* fill left data */
            "dt %3\n\t"
            "mov.w %1,@-%2\n\t"
            "bf 1b\n\t"
            "2:\n\t"            /* fill aligned data by 4 */
            "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
            "mov.w %1,@-%2\n\t" /* *--s = c */
            "mov.w %1,@-%2\n\t" /* *--s = c */
            "mov.w %1,@-%2\n\t" /* *--s = c */
            "mov.w %1,@-%2\n\t" /* *--s = c */
            "bf 2b\n\t"         /* if T == 0 goto label 1: */
            :                   /* no output registers */ 
            : "r" (n), "r" (c), "r" (s), "r" (l) /* constraint: register */
        ); 
    }
    else
    {
        __tb_asm__ __tb_volatile__
        (
            "1:\n\t"
            "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
            "mov.w %1,@-%2\n\t" /* *--s = c */
            "bf 1b\n\t"         /* if T == 0 goto label 1: */
            :                   /* no output registers */
            : "r" (n), "r" (c), "r" (s) /* constraint: register */
        );
    }
}
static __tb_inline__ tb_void_t tb_memset_u16_impl_opt_v2(tb_uint16_t* s, tb_uint16_t c, tb_size_t n)
{
    /* align by 4-bytes */
    if (((tb_size_t)s) & 0x3)
    {
        *((tb_uint16_t*)s) = c;
        s += 2;
        n--;
    }
    s += n << 1;
    __tb_asm__ __tb_volatile__
    (
        "1:\n\t"
        "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
        "mov.w %1,@-%2\n\t" /* *--s = c */
        "bf 1b\n\t"         /* if T == 0 goto label 1: */
        :                   /* no output registers */
        : "r" (n), "r" (c), "r" (s) /* constraint: register */
    );
}
#endif

#ifdef TB_LIBC_STRING_IMPL_MEMSET_U16
static tb_pointer_t tb_memset_u16_impl(tb_pointer_t s, tb_uint16_t c, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // align by 2-bytes 
    tb_assert(!(((tb_size_t)s) & 0x1));
    if (!n) return s;

#   if defined(TB_ASSEMBLER_IS_GAS)
    tb_memset_u16_impl_opt_v1(s, c, n);
#   else
#       error
#   endif

    return s;
}
#endif

#ifdef TB_ASSEMBLER_IS_GAS
static __tb_inline__ tb_void_t tb_memset_u32_impl_opt_v1(tb_uint32_t* s, tb_uint32_t c, tb_size_t n)
{
    tb_size_t l = n & 0x3;
    s += (n << 2);
    if (!l)
    {
        n >>= 2;
        __tb_asm__ __tb_volatile__
        (
            "1:\n\t" 
            "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "bf 1b\n\t"         /* if T == 0 goto label 1: */
            :                   /* no output registers */ 
            : "r" (n), "r" (c), "r" (s) /* constraint: register */
        ); 
    }
    else
    {
        __tb_asm__ __tb_volatile__
        (
            "1:\n\t" 
            "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "bf 1b\n\t"         /* if T == 0 goto label 1: */
            :                   /* no output registers */ 
            : "r" (n), "r" (c), "r" (s) /* constraint: register */
        ); 
    }
}
static __tb_inline__ tb_void_t tb_memset_u32_impl_opt_v2(tb_uint32_t* s, tb_uint32_t c, tb_size_t n)
{
    tb_size_t l = n & 0x3;
    s += (n << 2);
    if (!l)
    {
        n >>= 2;
        __tb_asm__ __tb_volatile__
        (
            "1:\n\t" 
            "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "bf 1b\n\t"         /* if T == 0 goto label 1: */
            :                   /* no output registers */ 
            : "r" (n), "r" (c), "r" (s) /* constraint: register */
        ); 
    }
    else if (n >= 4) /* fixme */
    {
        n >>= 2;
        __tb_asm__ __tb_volatile__
        (
            "1:\n\t"            /* fill the left data */
            "dt %3\n\t"
            "mov.l %1,@-%2\n\t"
            "bf 1b\n\t"
            "2:\n\t"            /* fill aligned data by 4 */
            "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "bf 2b\n\t"         /* if T == 0 goto label 1: */
            :                   /* no output registers */ 
            : "r" (n), "r" (c), "r" (s), "r" (l) /* constraint: register */
        ); 
    }
    else
    {
        __tb_asm__ __tb_volatile__
        (
            "1:\n\t" 
            "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
            "mov.l %1,@-%2\n\t" /* *--s = c */
            "bf 1b\n\t"         /* if T == 0 goto label 1: */
            :                   /* no output registers */ 
            : "r" (n), "r" (c), "r" (s) /* constraint: register */
        ); 
    }
}
static __tb_inline__ tb_void_t tb_memset_u32_impl_opt_v3(tb_uint32_t* s, tb_uint32_t c, tb_size_t n)
{   
    s += n << 2;
    __tb_asm__ __tb_volatile__
    (
        "1:\n\t"
        "dt %0\n\t"         /* i--, i > 0? T = 0 : 1 */
        "mov.l %1,@-%2\n\t" /* *--s = c */
        "bf 1b\n\t"         /* if T == 0 goto label 1: */
        :                   /* no output registers */ 
        : "r" (n), "r" (c), "r" (s) /* constraint: register */
    );
}
#endif

#ifdef TB_LIBC_STRING_IMPL_MEMSET_U32
static tb_pointer_t tb_memset_u32_impl(tb_pointer_t s, tb_uint32_t c, tb_size_t n)
{
    // check
    tb_assert_and_check_return_val(s, tb_null);

    // align by 4-bytes 
    tb_assert(!(((tb_size_t)s) & 0x3));
    if (!n) return s;

#   if defined(TB_ASSEMBLER_IS_GAS)
    tb_memset_u32_impl_opt_v1(s, c, n);
#   else
#       error
#   endif

    return s;
}
#endif


