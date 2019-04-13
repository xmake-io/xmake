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
#ifdef TB_ARCH_SSE2
#   include <emmintrin.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#if (defined(TB_ASSEMBLER_IS_GAS) && TB_CPU_BIT32) || \
        defined(TB_ARCH_SSE2)
#   define TB_LIBC_STRING_IMPL_MEMSET_U8
#   define TB_LIBC_STRING_IMPL_MEMSET_U16
#   define TB_LIBC_STRING_IMPL_MEMSET_U32
#endif
/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

#if defined(TB_ASSEMBLER_IS_GAS) && TB_CPU_BIT32
static __tb_inline__ tb_void_t tb_memset_impl_u8_opt_v1(tb_byte_t* s, tb_byte_t c, tb_size_t n)
{
    tb_size_t edi;
    __tb_asm__ __tb_volatile__
    (
        // note: the address not align by 4-bytes, but it is also fast.
        "   cld\n"
        "   mov     %2,     %%ecx\n"
        "   shr     $2,     %%ecx\n"        //!< n >>= 2
        "   jz      1f\n"                   //!< goto fill the left bytes if n < 4
        "   movzx   %%al,   %%eax\n"        //!< 3 bytes, or: and $0xff, %%eax - 5 bytes
        "   imul    $0x01010101, %%eax\n"   //!< 6 bytes
        "   rep;    stosl\n"                //!< fill 4-bytes
        "1: and     $3,     %2\n"           //!< left = n & 0x3
        "   jz      9f\n"                   //!< goto end if left == 0
        "2:\n"
        "   mov     %2,     %%ecx\n"
        "   rep     stosb\n"                //!< fill the left bytes (3-bytes)
        "9:\n"

        : "=&D" (edi)
        : "a" (c), "r" (n), "0" (s)
        : "memory", "ecx"
    );
}
#endif

#ifdef TB_ARCH_SSE2
static __tb_inline__ tb_void_t tb_memset_impl_u8_opt_v2(tb_byte_t* s, tb_byte_t c, tb_size_t n)
{
    if (n >= 64) 
    {
        // aligned by 16-bytes
        for (; ((tb_size_t)s) & 0x0f; --n) *s++ = c;

        // l = n % 64
        tb_size_t l = n & 0x3f; n = (n - l) >> 6;

        // fill 4 x 16 bytes
        __m128i*    d = (__m128i*)(s);
        __m128i     v = _mm_set1_epi8(c);
        while (n) 
        {
            _mm_store_si128(d++, v);
            _mm_store_si128(d++, v);
            _mm_store_si128(d++, v);
            _mm_store_si128(d++, v);
            --n;
        }
        s = (tb_byte_t*)(d);
        n = l;
    }
    while (n--) *s++ = c;
}
#endif

#ifdef TB_LIBC_STRING_IMPL_MEMSET_U8
static tb_pointer_t tb_memset_impl(tb_pointer_t s, tb_byte_t c, tb_size_t n)
{
    tb_assert_and_check_return_val(s, tb_null);
    if (!n) return s;

#   if defined(TB_ASSEMBLER_IS_GAS) && TB_CPU_BIT32
    tb_memset_impl_u8_opt_v1(s, c, n);
#   elif defined(TB_ARCH_SSE2)
    tb_memset_impl_u8_opt_v2(s, c, n);
#   else
#       error
#   endif

    return s;
}
#endif


#if defined(TB_ASSEMBLER_IS_GAS) && TB_CPU_BIT32
static __tb_inline__ tb_void_t tb_memset_u16_impl_opt_v1(tb_uint16_t* s, tb_uint16_t c, tb_size_t n)
{
    // align by 4-bytes 
    if (((tb_size_t)s) & 0x3)
    {
        *s++ = c;
        --n;
    }

    __tb_asm__ __tb_volatile__
    (
        "cld\n\t"                           // clear the direction bit, s++, not s--
        "rep stosw"                         // *s++ = ax
        :                                   // no output registers
        : "c" (n), "a" (c), "D" (s)         // ecx = n, eax = c, edi = s
    );
}
#endif

#ifdef TB_ARCH_SSE2
static __tb_inline__ tb_void_t tb_memset_u16_impl_opt_v2(tb_uint16_t* s, tb_uint16_t c, tb_size_t n)
{
    if (n >= 32) 
    {
        // aligned by 16-bytes
        for (; ((tb_size_t)s) & 0x0f; --n) *s++ = c;

        // l = n % 32
        tb_size_t l = n & 0x1f; n = (n - l) >> 5;

        // fill 4 x 16 bytes
        __m128i*    d = (__m128i*)(s);
        __m128i     v = _mm_set1_epi16(c);
        while (n) 
        {
            _mm_store_si128(d++, v);
            _mm_store_si128(d++, v);
            _mm_store_si128(d++, v);
            _mm_store_si128(d++, v);
            --n;
        }
        s = (tb_uint16_t*)(d);
        n = l;
    }
    while (n--) *s++ = c;
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

#   if (defined(TB_ASSEMBLER_IS_GAS) && TB_CPU_BIT32) && \
        defined(TB_ARCH_SSE2)
    if (n < 2049) tb_memset_u16_impl_opt_v2(s, c, n);
    else tb_memset_u16_impl_opt_v1(s, c, n);
#   elif defined(TB_ASSEMBLER_IS_GAS) && TB_CPU_BIT32
    tb_memset_u16_impl_opt_v1(s, c, n);
#   elif defined(TB_ARCH_SSE2)
    tb_memset_u16_impl_opt_v2(s, c, n);
#   else
#       error
#   endif

    return s;
}
#endif

#if defined(TB_ASSEMBLER_IS_GAS) && TB_CPU_BIT32
static __tb_inline__ tb_void_t tb_memset_u32_impl_opt_v1(tb_uint32_t* s, tb_uint32_t c, tb_size_t n)
{
    __tb_asm__ __tb_volatile__
    (
        "cld\n\t"                           // clear the direction bit, s++, not s--
        "rep stosl"                         // *s++ = eax
        :                                   // no output registers
        : "c" (n), "a" (c), "D" (s)         // ecx = n, eax = c, edi = s
    );
}
#endif

#ifdef TB_ARCH_SSE2
static __tb_inline__ tb_void_t tb_memset_u32_impl_opt_v2(tb_uint32_t* s, tb_uint32_t c, tb_size_t n)
{
    if (n >= 16) 
    {
        // aligned by 16-bytes
        for (; ((tb_size_t)s) & 0x0f; --n) *s++ = c;

        // l = n % 16
        tb_size_t l = n & 0x0f; n = (n - l) >> 4;

        // fill 4 x 16 bytes
        __m128i*    d = (__m128i*)(s);
        __m128i     v = _mm_set1_epi32(c);
        while (n) 
        {
            _mm_store_si128(d++, v);
            _mm_store_si128(d++, v);
            _mm_store_si128(d++, v);
            _mm_store_si128(d++, v);
            --n;
        }
        s = (tb_uint32_t*)(d);
        n = l;
    }
    while (n--) *s++ = c;
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

#   if (defined(TB_ASSEMBLER_IS_GAS) && TB_CPU_BIT32) && \
    defined(TB_ARCH_SSE2)
    if (n < 2049) tb_memset_u32_impl_opt_v2(s, c, n);
    else tb_memset_u32_impl_opt_v1(s, c, n);
#   elif defined(TB_ASSEMBLER_IS_GAS) && TB_CPU_BIT32
    tb_memset_u32_impl_opt_v1(s, c, n);
#   elif defined(TB_ARCH_SSE2)
    tb_memset_u32_impl_opt_v2(s, c, n);
#   else
#       error
#   endif

    return s;
}
#endif


