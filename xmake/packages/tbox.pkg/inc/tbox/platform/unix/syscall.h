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
 * @file        syscall.h
 * @ingroup     platform
 */
#ifndef TB_PLATFORM_UNIX_SYSCALL_H
#define TB_PLATFORM_UNIX_SYSCALL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <sys/syscall.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#ifdef TB_ASSEMBLER_IS_GAS

// x64
#   if defined(TB_ARCH_x64)
#       define tb_syscall1(code, name, type1, arg1) \
        static __tb_inline__ tb_long_t name(type1 arg1) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("syscall" : "=a" (__ret) : \
                "0" (code), "D" (arg1)); \
            return __ret; \
        }

#       define tb_syscall2(code, name, type1, arg1, type2, arg2) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("syscall" : "=a" (__ret) : \
                "0" (code), "D" (arg1), "S" (arg2)); \
            return __ret; \
        }

#       define tb_syscall3(code, name, type1, arg1, type2, arg2, type3, arg3)   \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2, type3 arg3) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("syscall" : "=a" (__ret) : \
                "0" (code), "D" (arg1), "S" (arg2), \
                "d" (arg3) \
                ); \
            return __ret; \
        }

#       define tb_syscall4(code, name, type1, arg1, type2, arg2, type3, arg3, type4, arg4) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2, type3 arg3, type4 arg4) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("movq %5,%%r10 ; syscall" : "=a" (__ret) : \
                "0" (code), "D" (arg1), "S" (arg2), \
                "d" (arg3), "g" (arg4) \
                ); \
            return __ret; \
        }

#       define tb_syscall5(code, name, type1, arg1, type2, arg2, type3, arg3, type4, arg4, type5, arg5) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("movq %5,%%r10 ; movq %6,%%r8 ; syscall" : "=a" (__ret) : \
                "0" (code), "D" (arg1), "S" (arg2), \
                "d" (arg3), "g" (arg4), "g" (arg5) \
                ); \
            return __ret; \
        }

// x86
#   elif defined(TB_ARCH_x86)
#       define tb_syscall1(code, name, type1, arg1) \
        static __tb_inline__ tb_long_t name(type1 arg1) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("int $0x80" : "=a" (__ret) : \
                "0" (code), "b" (arg1)); \
            return __ret; \
        }

#       define tb_syscall2(code, name, type1, arg1, type2, arg2) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("int $0x80" : "=a" (__ret) : \
                "0" (code), "b" (arg1), "c" (arg2)); \
            return __ret; \
        }

#       define tb_syscall3(code, name, type1, arg1, type2, arg2, type3, arg3) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2, type3 arg3) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("int $0x80" : "=a" (__ret) : \
                "0" (code), "b" (arg1), "c" (arg2), \
                "d" (arg3) \
                ); \
            return __ret; \
        }

#       define tb_syscall4(code, name, type1, arg1, type2, arg2, type3, arg3, type4, arg4) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2, type3 arg3, type4 arg4) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("int $0x80" : "=a" (__ret) : \
                "0" (code), "b" (arg1), "c" (arg2), \
                "d" (arg3), "S" (arg4) \
                ); \
            return __ret; \
        }

#       define tb_syscall5(code, name, type1, arg1, type2, arg2, type3, arg3, type4, arg4, type5, arg5) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5) \
        { \
            tb_long_t __ret; \
            __asm__ __volatile__("int $0x80" : "=a" (__ret) : \
                "0" (code), "b" (arg1), "c" (arg2), \
                "d" (arg3), "S" (arg4), "D" (arg5) \
                ); \
            return __ret; \
        }

#   endif
#endif

#ifndef tb_syscall1
#       define tb_syscall1(code, name, type1, arg1) \
        static __tb_inline__ tb_long_t name(type1 arg1) \
        { \
            return syscall(code, arg1); \
        }
#endif

#ifndef tb_syscall2
#       define tb_syscall2(code, name, type1, arg1, type2, arg2) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2) \
        { \
            return syscall(code, arg1, arg2); \
        }
#endif

#ifndef tb_syscall3
#       define tb_syscall3(code, name, type1, arg1, type2, arg2, type3, arg3) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2, type3 arg3) \
        { \
            return syscall(code, arg1, arg2, arg3); \
        }
#endif

#ifndef tb_syscall4
#       define tb_syscall4(code, name, type1, arg1, type2, arg2, type3, arg3, type4, arg4) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2, type3 arg3, type4 arg4) \
        { \
            return syscall(code, arg1, arg2, arg3, arg4); \
        }
#endif

#ifndef tb_syscall5
#       define tb_syscall5(code, name, type1, arg1, type2, arg2, type3, arg3, type4, arg4, type5, arg5) \
        static __tb_inline__ tb_long_t name(type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5) \
        { \
            return syscall(code, arg1, arg2, arg3, arg4, arg5); \
        }
#endif
#endif
