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
