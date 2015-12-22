/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        exception.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_EXCEPTION_H
#define TB_PLATFORM_WINDOWS_EXCEPTION_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */ 

#if defined(tb_setjmp) && defined(tb_longjmp)

#   if defined(TB_COMPILER_IS_MSVC)
#       define __tb_try                 __try
#       define __tb_except(x)           __except(!!(x))
#       define __tb_leave               __leave
#       define __tb_end                 
#   elif defined(TB_ASSEMBLER_IS_GAS) && !TB_CPU_BIT64

        // try
#       define __tb_try \
        do \
        { \
            /* init */ \
            tb_exception_handler_t __h = {{0}}; \
            tb_exception_registration_t __r = {0}; \
            \
            /* init handler */ \
            __r.handler = (tb_exception_func_t)tb_exception_func_impl; \
            __r.exception_handler = &__h; \
            /* push seh */ \
            __tb_asm__ __tb_volatile__ ("movl %%fs:0, %0" : "=r" (__r.prev)); \
            __tb_asm__ __tb_volatile__ ("movl %0, %%fs:0" : : "r" (&__r)); \
            \
            /* save jmpbuf */ \
            __tb_volatile__ tb_int_t __j = tb_setjmp(__h.jmpbuf); \
            if (!__j) \
            {

        // except
#       define __tb_except(x) \
            } \
            \
            /* check */ \
            tb_assert(x >= 0); \
            /* do not this catch? goto the top exception stack */ \
            if (__j && !(x)) \
            { \
                if (__r.prev && __r.prev->exception_handler) tb_longjmp(__r.prev->exception_handler->jmpbuf, 1); \
                else \
                { \
                    /* no exception handler */ \
                    tb_assert_and_check_break(0); \
                } \
            } \
            /* pop seh */ \
            __tb_asm__ __tb_volatile__ ("movl %0, %%fs:0" : : "r" (__r.prev)); \
            if (__j)

        // end
#       define __tb_end \
        } while (0);

        // leave
#       define __tb_leave   break

#   endif
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */ 

// for mingw
#if defined(tb_setjmp) \
    && defined(tb_longjmp) \
    && !defined(TB_COMPILER_IS_MSVC) \
    && defined(TB_ASSEMBLER_IS_GAS) \
    && !TB_CPU_BIT64

#include "../../prefix/packed.h"

// the seh expception handler func type
typedef tb_int_t (*tb_exception_func_t)(tb_pointer_t, tb_pointer_t, tb_pointer_t, tb_pointer_t);

// the expception float context type
typedef struct __tb_exception_context_float_t 
{
    tb_uint32_t                         controlword;
    tb_uint32_t                         statusword;
    tb_uint32_t                         tagword;
    tb_uint32_t                         erroroffset;
    tb_uint32_t                         errorselector;
    tb_uint32_t                         dataoffset;
    tb_uint32_t                         dataselector;
    tb_byte_t                           registerarea[80];
    tb_uint32_t                         cr0npxstate;

}__tb_packed__ tb_exception_context_float_t ;

// the expception context type
typedef struct __tb_exception_context_t
{
    tb_uint32_t                         contextflags;
    tb_uint32_t                         dr0;
    tb_uint32_t                         dr1;
    tb_uint32_t                         dr2;
    tb_uint32_t                         dr3;
    tb_uint32_t                         dr6;
    tb_uint32_t                         dr7;
    tb_exception_context_float_t        floatsave;
    tb_uint32_t                         seggs;
    tb_uint32_t                         segfs;
    tb_uint32_t                         seges;
    tb_uint32_t                         segds;
    tb_uint32_t                         edi;
    tb_uint32_t                         esi;
    tb_uint32_t                         ebx;
    tb_uint32_t                         edx;
    tb_uint32_t                         ecx;
    tb_uint32_t                         eax;
    tb_uint32_t                         ebp;
    tb_uint32_t                         eip;
    tb_uint32_t                         segcs;
    tb_uint32_t                         eflags;
    tb_uint32_t                         esp;
    tb_uint32_t                         segss;
    tb_byte_t                           extendedregisters[512];

}__tb_packed__ tb_exception_context_t;

// the expception record type
typedef struct __tb_exception_record_t
{
    // the expception code
    tb_uint32_t                         exception_code;

    // the expception flags
    tb_uint32_t                         exception_flags;

    // the expception record
    struct __tb_exception_record_t*     exception_record;

    // the expception address
    tb_pointer_t                        exception_address;

    // the parameters number
    tb_uint32_t                         number_parameters;

    // the expception information
    tb_pointer_t                        exception_information[15];

}__tb_packed__ tb_exception_record_t;

// the expception registration type
struct __tb_exception_handler_t;
typedef struct __tb_exception_registration_t
{
    // the previous seh exception registration
    struct __tb_exception_registration_t*   prev;

    // the exception handler
    tb_exception_func_t                     handler;

    // the seh handler
    struct __tb_exception_handler_t*        exception_handler;

}tb_exception_registration_t;

// the exception handler type
typedef struct __tb_exception_handler_t
{
    // the jmpbuf
    tb_jmpbuf_t                             jmpbuf;

    // the exception record
    tb_exception_record_t                   record;

    // the context
    tb_exception_context_t                  context;    

}tb_exception_handler_t;

#include "../../prefix/packed.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * handler
 */
static __tb_inline__ tb_int_t tb_exception_func_impl(tb_pointer_t record, tb_exception_registration_t* reg, tb_pointer_t context, tb_pointer_t record2)
{
    tb_assert(reg && reg->exception_handler && context && record);
    if (context) tb_memcpy(&reg->exception_handler->context, context, sizeof(tb_exception_context_t));
    if (record) tb_memcpy(&reg->exception_handler->record, record, sizeof(tb_exception_record_t));
    tb_longjmp(reg->exception_handler->jmpbuf, 1);
}

#endif /* for mingw */

#endif


