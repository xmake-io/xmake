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
 * @file        type.h
 *
 */
#ifndef TB_PREFIX_TYPE_H
#define TB_PREFIX_TYPE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "keyword.h"
#include "compiler.h"
#include "cpu.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// bool values
#define tb_true                     ((tb_bool_t)1)
#define tb_false                    ((tb_bool_t)0)

// null
#ifdef __cplusplus
#   define tb_null                  (0)
#else
#   define tb_null                  ((tb_pointer_t)0)
#endif

// check config
#if !defined(TB_CONFIG_TYPE_SCALAR_IS_FIXED) \
    && !defined(TB_CONFIG_TYPE_HAVE_FLOAT)
#   define TB_CONFIG_TYPE_SCALAR_IS_FIXED
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// basic
typedef signed int                  tb_int_t;
typedef unsigned int                tb_uint_t;
typedef signed short                tb_short_t;
typedef unsigned short              tb_ushort_t;
typedef tb_int_t                    tb_bool_t;
typedef signed char                 tb_int8_t;
typedef tb_int8_t                   tb_sint8_t;
typedef unsigned char               tb_uint8_t;
typedef tb_short_t                  tb_int16_t;
typedef tb_int16_t                  tb_sint16_t;
typedef tb_ushort_t                 tb_uint16_t;
typedef tb_int_t                    tb_int32_t;
typedef tb_int32_t                  tb_sint32_t;
typedef tb_uint_t                   tb_uint32_t;
typedef char                        tb_char_t;
typedef tb_int32_t                  tb_uchar_t;
typedef tb_uint8_t                  tb_byte_t;
typedef void                        tb_void_t;
typedef tb_void_t*                  tb_pointer_t;
typedef tb_void_t const*            tb_cpointer_t;
typedef tb_pointer_t                tb_handle_t;

// no argument
#ifdef __cplusplus
#   define tb_noarg_t               
#else
#   define tb_noarg_t               tb_void_t
#endif

// wchar
#ifdef TB_CONFIG_TYPE_HAVE_WCHAR
    typedef wchar_t                 tb_wchar_t;
#elif defined(TB_CONFIG_OS_WINDOWS)
#   if defined(_WCHAR_T_DEFINED) || defined(_NATIVE_WCHAR_T_DEFINED)
    typedef wchar_t                 tb_wchar_t;
#   else
    typedef tb_uint16_t             tb_wchar_t;
#   endif
#elif defined(__WCHAR_TYPE__)
typedef __WCHAR_TYPE__              tb_wchar_t;
#elif defined(__WCHAR_WIDTH__) && (__WCHAR_WIDTH__ == 2)
typedef tb_int16_t                  tb_wchar_t;
#elif defined(__WCHAR_WIDTH__) && (__WCHAR_WIDTH__ == 4)
typedef tb_int16_t                  tb_wchar_t;
#else
typedef tb_int32_t                  tb_wchar_t;
#endif

// int64
#if defined(TB_COMPILER_IS_MSVC)
typedef __int64                     tb_int64_t;
typedef unsigned __int64            tb_uint64_t;
#elif (TB_CPU_BITSIZE == 64)
typedef signed long                 tb_int64_t;
typedef unsigned long               tb_uint64_t;
#else
typedef signed long long            tb_int64_t;
typedef unsigned long long          tb_uint64_t;
#endif
typedef tb_int64_t                  tb_sint64_t;

// hong and hize
typedef tb_sint64_t                 tb_hong_t;
typedef tb_uint64_t                 tb_hize_t;

// long and size
#if defined(TB_CONFIG_OS_WINDOWS) && TB_CPU_BIT64
typedef tb_int64_t                  tb_long_t;
typedef tb_uint64_t                 tb_ulong_t;
#else
typedef signed long                 tb_long_t;
typedef unsigned long               tb_ulong_t;
#endif
typedef tb_ulong_t                  tb_size_t;

// double
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
typedef float                       tb_float_t;
typedef double                      tb_double_t;
#endif

// fixed
typedef tb_int32_t                  tb_fixed6_t;
typedef tb_int32_t                  tb_fixed16_t;
typedef tb_int32_t                  tb_fixed30_t;
typedef tb_fixed16_t                tb_fixed_t;

/// the atomic type
#if TB_CPU_BIT64
typedef __tb_volatile__ __tb_aligned__(8) tb_long_t     tb_atomic_t;
#else
typedef __tb_volatile__ __tb_aligned__(4) tb_long_t     tb_atomic_t;
#endif

/// the atomic64 type, need be aligned for arm, ..
typedef __tb_volatile__  __tb_aligned__(8) tb_hong_t    tb_atomic64_t;

/// the spinlock type
typedef tb_atomic_t                 tb_spinlock_t;

/// the spinlock ref type
typedef tb_spinlock_t*              tb_spinlock_ref_t;

/// the pool ref type
typedef struct{}*                   tb_pool_ref_t;

/// the file ref type
typedef struct{}*                   tb_file_ref_t;

/// the socket ref type
typedef struct{}*                   tb_socket_ref_t;

/// the event ref type
typedef struct{}*                   tb_event_ref_t;

/// the mutex ref type
typedef struct{}*                   tb_mutex_ref_t;

/// the thread ref type
typedef struct{}*                   tb_thread_ref_t;

/// the semaphore ref type
typedef struct{}*                   tb_semaphore_ref_t;

/// the stream ref type
typedef struct{}*                   tb_stream_ref_t;

/// the async stream ref type
typedef struct{}*                   tb_async_stream_ref_t;

/// the time type
typedef tb_hong_t                   tb_time_t;

/// the suseconds type
typedef tb_long_t                   tb_suseconds_t;

/// the timeval type
typedef struct __tb_timeval_t
{
    /// the seconds
    tb_time_t                       tv_sec;

    // the useconds
    tb_suseconds_t                  tv_usec;

}tb_timeval_t;

/// the timezone type
typedef struct __tb_timezone_t
{
    /// the minutes west of greenwich
    tb_int_t                        tz_minuteswest;

    /// the type of dst correction
    tb_int_t                        tz_dsttime;

}tb_timezone_t;

/// the version type
typedef struct __tb_version_t
{
    /// the major
    tb_byte_t                       major;

    /// the minor 
    tb_byte_t                       minor;

    /// the alter
    tb_byte_t                       alter;

    /// the build
    tb_hize_t                       build;

}tb_version_t;

/// the value type
typedef union __tb_value_t
{
    /// uint8
    tb_uint8_t                      u8;

    /// sint8
    tb_sint8_t                      s8;

    /// char
    tb_char_t                       c;

    /// wchar
    tb_wchar_t                      wc;

    /// boolean
    tb_bool_t                       b;

    /// uint16
    tb_uint16_t                     u16;

    /// sint16
    tb_sint16_t                     s16;

    /// uint32
    tb_uint32_t                     u32;

    /// sint32
    tb_sint32_t                     s32;

    /// uint64
    tb_uint64_t                     u64;

    /// sint64
    tb_sint64_t                     s64;

    /// size
    tb_size_t                       ul;

    /// long
    tb_long_t                       l;

    /// time
    tb_time_t                       t;

    /// pointer
    tb_pointer_t                    ptr;

    /// const pointer
    tb_cpointer_t                   cptr;

    /// sock
    tb_socket_ref_t                 sock;

    /// file
    tb_file_ref_t                   file;

    /// handle
    tb_handle_t                     handle;

    /// string
    tb_char_t*                      str;

    /// const string
    tb_char_t const*                cstr;

    /// wstring
    tb_wchar_t*                     wstr;

    /// const wstring
    tb_wchar_t const*               wcstr;

    /// atomic
    tb_atomic_t                     a;

    /// atomic64
    tb_atomic_t                     a64;

    /// spinlock
    tb_spinlock_t                   lock;

    /// stream
    tb_stream_ref_t                 stream;

    /// async stream
    tb_async_stream_ref_t           astream;

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
    /// float
    tb_float_t                      f;

    /// double
    tb_double_t                     d;
#endif

}tb_value_t, *tb_value_ref_t;

#endif


