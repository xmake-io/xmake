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

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#if defined(TB_ASSEMBLER_IS_GAS) && !defined(TB_ARCH_ARM_THUMB) && !defined(TB_ARCH_ARM64)
#   define TB_LIBC_STRING_IMPL_MEMSET_U8
#   define TB_LIBC_STRING_IMPL_MEMSET_U16
#   define TB_LIBC_STRING_IMPL_MEMSET_U32
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

#ifdef TB_LIBC_STRING_IMPL_MEMSET_U8
static __tb_inline__ tb_void_t tb_memset_impl_u8_opt_v1(tb_byte_t* s, tb_byte_t c, tb_size_t n)
{
    // cache line: 16-bytes
    __tb_asm__ __tb_volatile__
    (
        "   tst     %2, #3\n"                   //!<  align by 4-bytes, if (s & 0x3) *s = c, s++, n-- 
        "   strneb  %1, [%2], #1\n"
        "   subne   %0, %0, #1\n"
        "   tst     %2, #3\n"                   //!<  align by 4-bytes, if (s & 0x3) *s = c, s++, n-- 
        "   strneb  %1, [%2], #1\n"
        "   subne   %0, %0, #1\n"
        "   tst     %2, #3\n"                   //!<  align by 4-bytes, if (s & 0x3) *s = c, s++, n-- 
        "   strneb  %1, [%2], #1\n"
        "   subne   %0, %0, #1\n"
        "   orr     %1, %1, %1, lsl #8\n"       //!<  c |= c << 8, expand to 16-bits 
        "   orr     %1, %1, %1, lsl #16\n"      //!<  c |= c << 16, expand to 32-bits 
        "   mov     r3, %1\n"                   //!<  for storing data by 4x32bits 
        "   mov     r4, %1\n"
        "   mov     r5, %1\n"
        "1:\n"                                  //!<  fill data by cache line n 
        "   subs    %0, %0, #16\n"              //!<  n -= 16[x8bits] and update cpsr, assume 16-bytes cache lines 
        "   stmhsia %2!, {%1, r3, r4, r5}\n"    //!<  storing data by 4x32bits = 16[x8bits], cond: hs (if >= 0), ia: s++ 
        "   bhs     1b\n"                       //!<  goto 1b if hs (>= 0) 
        "   add     %0, %0, #16\n"              //!<  fill the left data, n = left n (< 16[x8bits]) 
        "   movs    %0, %0, lsl #29\n"          //!<  1, 11100000000000000000000000000000 
        "   stmcsia %2!, {r4, r5}\n"            //!<  store 2x32bits, cond: cs (if carry bit == 1, >= 8[x8bits]) 
        "   strmi   r3, [%2], #4\n"             //!<  store 32bits, cond: mi (if negative bit == 1, >=4[x8bits]) 
        "   movs    %0, %0, lsl #2\n"           //!<  1, 10000000000000000000000000000000 
        "   strcsh  %1, [%2], #2\n"             //!<  store 16bits, cond: cs (if carry bit == 1, >= 2[x8bits]) 
        "   strmib  r3, [%2]\n"                 //!<  store 8bits, cond: cs (if negative bit == 1, >= 1[x8bits]) 

        : : "r" (n), "r" (c), "r" (s)
        : "r3", "r4", "r5"
    );
}
#endif

#ifdef TB_LIBC_STRING_IMPL_MEMSET_U8
static tb_pointer_t tb_memset_impl(tb_pointer_t s, tb_byte_t c, tb_size_t n)
{
    tb_assert_and_check_return_val(s, tb_null);
    if (!n) return s;

    // align: 3 + cache: 16
    if (n > 19) tb_memset_impl_u8_opt_v1(s, c, n);
    else
    {
        __tb_register__ tb_byte_t*  p = s;
        __tb_register__ tb_byte_t   b = c;
        while (n--) *p++ = b;
    }

    return s;
}
#endif


#ifdef TB_LIBC_STRING_IMPL_MEMSET_U16
static __tb_inline__ tb_void_t tb_memset_u16_impl_opt_v1(tb_uint16_t* s, tb_uint16_t c, tb_size_t n)
{
    // cache line: 16-bytes
    __tb_asm__ __tb_volatile__
    (
        "   tst     %2, #3\n"                   //!<  align by 4-bytes, if (s & 0x3) *((tb_uint16_t*)s) = c, s += 2, n-- 
        "   strneh  %1, [%2], #2\n"
        "   subne   %0, %0, #1\n"
        "   orr     %1, %1, %1, lsl #16\n"      //!<  c |= c << 16, expand to 32-bits 
        "   mov     r3, %1\n"                   //!<  for storing data by 4x32bits 
        "   mov     r4, %1\n"
        "   mov     r5, %1\n"
        "1:\n"                                  //!<  fill data by cache line n 
        "   subs    %0, %0, #8\n"               //!<  n -= 4x2[x16bits] and update cpsr, assume 16-bytes cache lines 
        "   stmhsia %2!, {%1, r3, r4, r5}\n"    //!<  storing data by 4x32bits = 8[x16bits], cond: hs (if >= 0), ia: s++ 
        "   bhs     1b\n"                       //!<  goto 1b if hs (>= 0) 
        "   add     %0, %0, #8\n"               //!<  fill the left data, n = left n (< 8[x16bits]) 
        "   movs    %0, %0, lsl #30\n"          //!<  1, 11000000000000000000000000000000 
        "   stmcsia %2!, {r4, r5}\n"            //!<  store 2x32bits, cond: cs (if carry bit == 1, >= 4[x16bits]) 
        "   strmi   r3, [%2], #4\n"             //!<  store 32bits, cond: mi (if negative bit == 1, >=2[x16bits]) 
        "   movs    %0, %0, lsl #2\n"           //!<  1, 00000000000000000000000000000000 
        "   strcsh  %1, [%2]\n"                 //!<  store 16bits, cond: cs (if carry bit == 1, >= [x16bits]) 

        : : "r" (n), "r" (c), "r" (s)
        : "r3", "r4", "r5"
    );
}
static __tb_inline__ tb_void_t tb_memset_u16_impl_opt_v2(tb_uint16_t* s, tb_uint16_t c, tb_size_t n)
{
    // cache line: 32-bytes
    __tb_asm__ __tb_volatile__
    (
        "   tst     %2, #3\n"                   //!<  align by 4-bytes, if (s & 0x3) *((tb_uint16_t*)s) = c, s += 2, n--
        "   strneh  %1, [%2], #2\n"
        "   subne   %0, %0, #1\n"
        "   orr     %1, %1, %1, lsl #16\n"      //!<  c |= c << 16, expand to 32-bits 
        "   mov     r3, %1\n"                   //!<  for storing data by 8x32bits 
        "   mov     r4, %1\n"
        "   mov     r5, %1\n"
        "1:\n"                                  //!<  fill data by cache line n 
        "   subs    %0, %0, #16\n"              //!<  n -= 8x2[x16bits] and update cpsr, assume 32-bytes cache lines 
        "   stmhsia %2!, {%1, r3, r4, r5}\n"    //!<  storing data by 8x32bits = 16[x16bits], cond: hs (if >= 0), ia: s++ 
        "   stmhsia %2!, {%1, r3, r4, r5}\n"    
        "   bhs     1b\n"                       //!<  goto 1b if hs (>= 0) 
        "   add     %0, %0, #16\n"              //!<  fill the left data, n = left n (< 16[x16bits]) 
        "   movs    %0, %0, lsl #29\n"          //!<  1, 11100000000000000000000000000000 
        "   stmcsia %2!, {%1, r3, r4, r5}\n"    //!<  store 4x32bits, cond: cs (if carry bit == 1, >= 8[x16bits]) 
        "   stmmiia %2!, {r4, r5}\n"            //!<  store 2x32bits, cond: mi (if negative bit == 1, >=4[x16bits]) 
        "   movs    %0, %0, lsl #2\n"           //!<  1, 10000000000000000000000000000000 
        "   strcs   %1, [%2], #4\n"             //!<  store 32bits, cond: cs (if carry bit == 1, >= 2[x16bits]) 
        "   strmih  r3, [%2]\n"                 //!<  store 16bits, cond: cs (if negative bit == 1, >= [x16bits]) 

        : : "r" (n), "r" (c), "r" (s)
        : "r3", "r4", "r5"
    );
}
#endif

#ifdef TB_LIBC_STRING_IMPL_MEMSET_U16
static tb_pointer_t tb_memset_u16_impl(tb_pointer_t s, tb_uint16_t c, tb_size_t n)
{
    tb_assert_and_check_return_val(s, tb_null);

    // align by 2-bytes 
    tb_assert(!(((tb_size_t)s) & 0x1));
    if (!n) return s;

    if (n > 8) tb_memset_u16_impl_opt_v1(s, c, n);
    else
    {
        __tb_register__ tb_uint16_t*    p = s;
        __tb_register__ tb_uint16_t     b = c;
        while (n--) *p++ = b;
    }

    return s;
}
#endif

#ifdef TB_LIBC_STRING_IMPL_MEMSET_U32
static __tb_inline__ tb_void_t tb_memset_u32_impl_opt_v1(tb_uint32_t* s, tb_uint32_t c, tb_size_t n)
{
    // cache line: 16-bytes
    __tb_asm__ __tb_volatile__
    (
        "   mov r3, %1\n"                       //!<  for storing data by 4x32bits 
        "   mov r4, %1\n"
        "   mov r5, %1\n"
        "1:\n"                                  //!<  fill data by cache line n 
        "   subs %0, %0, #4\n"                  //!<  n -= 4[x32bits] and update cpsr, assume 16-bytes cache lines 
        "   stmhsia %2!, {%1, r3, r4, r5}\n"    //!<  storing data by 4x32bits, cond: hs (if >= 0), ia: s++ 
        "   bhs 1b\n"                           //!<  goto 1b if hs (>= 0) 
        "   add %0, %0, #4\n"                   //!<  fill the left data, n = left n (< 4[x32bits]) 
        "   movs %0, %0, lsl #31\n"             //!<  1, 1000000000000000000000000000000 
        "   stmcsia %2!, {r4, r5}\n"            //!<  store 2x32bits, cond: cs (if carry bit == 1, >= 2[x32bits]) 
        "   strmi r3, [%2]\n"                   //!<  store 32bits, cond: mi (if negative bit == 1, >= [x32bits]) 

        : : "r" (n), "r" (c), "r" (s)
        : "r3", "r4", "r5"
    );
}
static __tb_inline__ tb_void_t tb_memset_u32_impl_opt_v2(tb_uint32_t* s, tb_uint32_t c, tb_size_t n)
{
    // cache line: 32-bytes
    __tb_asm__ __tb_volatile__
    (
        "   mov r3, %1\n"                       //!<  for storing data by 4x32bits 
        "   mov r4, %1\n"
        "   mov r5, %1\n"
        "1:\n"                                  //!<  fill data by cache line n 
        "   subs %0, %0, #8\n"                  //!<  n -= 8[x16bits] and update cpsr, assume 32-bytes cache lines 
        "   stmhsia %2!, {%1, r3, r4, r5}\n"    //!<  storing data by 8x32bits, cond: hs (if >= 0), ia: s++ 
        "   stmhsia %2!, {%1, r3, r4, r5}\n"    
        "   bhs 1b\n"                           //!<  goto 1b if hs (>= 0) 
        "   add %0, %0, #8\n"                   //!<  fill the left data, n = left n (< 8[x32bits]) 
        "   movs %0, %0, lsl #30\n"             //!<  1, 1100000000000000000000000000000 
        "   stmcsia %2!, {%1, r3, r4, r5}\n"    //!<  store 4x32bits, cond: cs (if carry bit == 1, >= 4[x32bits]) 
        "   stmmiia %2!, {r4, r5}\n"            //!<  store 2x32bits, cond: mi (if negative bit == 1, >=2[x32bits]) 
        "   movs %0, %0, lsl #2\n"              //!<  1, 00000000000000000000000000000000 
        "   strcs %1, [%2]\n"                   //!<  store 32bits, cond: cs (if carry bit == 1, >= [x32bits]) 

        : : "r" (n), "r" (c), "r" (s)
        : "r3", "r4", "r5"
    );
}
#endif

#ifdef TB_LIBC_STRING_IMPL_MEMSET_U32
static tb_pointer_t tb_memset_u32_impl(tb_pointer_t s, tb_uint32_t c, tb_size_t n)
{
    tb_assert_and_check_return_val(s, tb_null);

    // align by 4-bytes 
    tb_assert(!(((tb_size_t)s) & 0x3));
    if (!n) return s;

    if (n > 4) tb_memset_u32_impl_opt_v1(s, c, n);
    else
    {
        __tb_register__ tb_uint32_t*    p = s;
        __tb_register__ tb_uint32_t     b = c;
        while (n--) *p++ = b;
    }

    return s;
}
#endif


