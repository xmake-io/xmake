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
 * @file        compiler.h
 *
 */
#ifndef TB_PREFIX_COMPILER_H
#define TB_PREFIX_COMPILER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// intel c++
#if defined(__INTEL_COMPILER)
#   define TB_COMPILER_IS_INTEL
#   define TB_COMPILER_VERSION_BT(major, minor)     (__INTEL_COMPILER > ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_BE(major, minor)     (__INTEL_COMPILER >= ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_EQ(major, minor)     (__INTEL_COMPILER == ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LT(major, minor)     (__INTEL_COMPILER < ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LE(major, minor)     (__INTEL_COMPILER <= ((major) * 100 + (minor)))
#   define TB_COMPILER_STRING                       "intel c/c++"
#   if (__INTEL_COMPILER == 600)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 6.0"
#   elif (__INTEL_COMPILER == 700)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 7.0"
#   elif (__INTEL_COMPILER == 800)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 8.0"
#   elif (__INTEL_COMPILER == 900)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 9.0"
#   elif (__INTEL_COMPILER == 1000)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 10.0"
#   elif (__INTEL_COMPILER == 1100)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 11.0"
#   elif (__INTEL_COMPILER == 1110)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 11.1"
#   elif (__INTEL_COMPILER == 1200)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 12.0"
#   elif (__INTEL_COMPILER == 1210)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 12.1"
#   elif (__INTEL_COMPILER == 1300)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 13.0"
#   elif (__INTEL_COMPILER == 1310)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 13.1"
#   elif (__INTEL_COMPILER == 1400)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 14.0"
#   elif (__INTEL_COMPILER == 1410)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ 14.1"
#   elif (__INTEL_COMPILER == 9999)
#       define TB_COMPILER_VERSION_STRING           "intel c/c++ mainline"
#   else
#       error Unknown Intel C++ Compiler Version
#   endif

// borland c++
#elif defined(__BORLANDC__)
#   define TB_COMPILER_IS_BORLAND
#   define TB_COMPILER_VERSION_BT(major, minor)     (__BORLANDC__ > ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_BE(major, minor)     (__BORLANDC__ >= ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_EQ(major, minor)     (__BORLANDC__ == ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LT(major, minor)     (__BORLANDC__ < ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LE(major, minor)     (__BORLANDC__ <= ((major) * 100 + (minor)))
#   define TB_COMPILER_STRING                       "borland c/c++"
#   if 0
#       define TB_COMPILER_VERSION_STRING           "borland c++ 4.52"
#   elif 0
#       define TB_COMPILER_VERSION_STRING           "borland c++ 5.5"
#   elif (__BORLANDC__ == 0x0551)
#       define TB_COMPILER_VERSION_STRING           "borland c++ 5.51"
#   elif (__BORLANDC__ == 0x0560)
#       define TB_COMPILER_VERSION_STRING           "borland c++ 5.6"
#   elif (__BORLANDC__ == 0x0564)
#       define TB_COMPILER_VERSION_STRING           "borland c++ 5.6.4 (c++ builderx)"
#   elif (__BORLANDC__ == 0x0582)
#       define TB_COMPILER_VERSION_STRING           "borland c++ 5.82 (turbo c++)"
#   else
#       error Unknown borland c++ Compiler Version
#   endif

// gnu c/c++ 
#elif defined(__GNUC__)
#   define TB_COMPILER_IS_GCC
#   define TB_COMPILER_VERSION_BT(major, minor)     ((__GNUC__ * 100 + __GNUC_MINOR__) > ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_BE(major, minor)     ((__GNUC__ * 100 + __GNUC_MINOR__) >= ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_EQ(major, minor)     ((__GNUC__ * 100 + __GNUC_MINOR__) == ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LT(major, minor)     ((__GNUC__ * 100 + __GNUC_MINOR__) < ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LE(major, minor)     ((__GNUC__ * 100 + __GNUC_MINOR__) <= ((major) * 100 + (minor)))
#   define TB_COMPILER_STRING                       "gnu c/c++"
#   if  __GNUC__ == 2
#       if __GNUC_MINOR__ < 95
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ <2.95"
#       elif __GNUC_MINOR__ == 95
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 2.95"
#       elif __GNUC_MINOR__ == 96
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 2.96"
#       else
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ > 2.96 && < 3.0"
#       endif
#   elif __GNUC__ == 3
#       if __GNUC_MINOR__ == 2
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 3.2"
#       elif __GNUC_MINOR__ == 3
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 3.3"
#       elif __GNUC_MINOR__ == 4
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 3.4"
#       else
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ > 3.4 && < 4.0"
#       endif
#   elif __GNUC__ == 4
#       if __GNUC_MINOR__ == 1
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 4.1"
#       elif __GNUC_MINOR__ == 2
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 4.2"
#       elif __GNUC_MINOR__ == 3
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 4.3"
#       elif __GNUC_MINOR__ == 4
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 4.4"
#       elif __GNUC_MINOR__ == 5
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 4.5"
#       elif __GNUC_MINOR__ == 6
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 4.6"
#       elif __GNUC_MINOR__ == 7
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 4.7"
#       elif __GNUC_MINOR__ == 8
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 4.8"
#       elif __GNUC_MINOR__ == 9
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 4.9"
#       endif
#   elif __GNUC__ == 5
#       if __GNUC_MINOR__ == 1
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 5.1"
#       elif __GNUC_MINOR__ == 2
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 5.2"
#       elif __GNUC_MINOR__ == 3
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 5.3"
#       elif __GNUC_MINOR__ == 4
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 5.4"
#       elif __GNUC_MINOR__ == 5
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 5.5"
#       elif __GNUC_MINOR__ == 6
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 5.6"
#       elif __GNUC_MINOR__ == 7
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 5.7"
#       elif __GNUC_MINOR__ == 8
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 5.8"
#       elif __GNUC_MINOR__ == 9
#           define TB_COMPILER_VERSION_STRING       "gnu c/c++ 5.9"
#       endif
#   else
#       error Unknown gnu c/c++ Compiler Version
#   endif

    // clang
#   if defined(__clang__)
#       define TB_COMPILER_IS_CLANG
#       undef TB_COMPILER_STRING
#       define TB_COMPILER_STRING                   "clang c/c++"
#       if defined(__VERSION__)
#           undef TB_COMPILER_VERSION_STRING
#           define TB_COMPILER_VERSION_STRING       __VERSION__
#       elif defined(__clang_version__)
#           undef TB_COMPILER_VERSION_STRING
#           define TB_COMPILER_VERSION_STRING       __clang_version__
#       endif
        // ignore warning: empty struct has size 0 in C, size 1 in C++
#       ifdef __cplusplus
#           pragma clang diagnostic ignored         "-Wextern-c-compat"
#       endif
#   endif

// watcom c/c++ 
#elif defined(__WATCOMC__)
#   define TB_COMPILER_IS_WATCOM
#   define TB_COMPILER_VERSION_BT(major, minor)     (__WATCOMC__ > ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_BE(major, minor)     (__WATCOMC__ >= ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_EQ(major, minor)     (__WATCOMC__ == ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LT(major, minor)     (__WATCOMC__ < ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LE(major, minor)     (__WATCOMC__ <= ((major) * 100 + (minor)))
#   define TB_COMPILER_STRING                       "watcom c/c++"
#   if (__WATCOMC__ == 1100)
#       define TB_COMPILER_VERSION_STRING           "watcom c/c++ 11.0"
#   elif (__WATCOMC__ == 1200)
#       define TB_COMPILER_VERSION_STRING           "open watcom c/c++ 1.0 (watcom 12.0)"
#   elif (__WATCOMC__ == 1210)
#       define TB_COMPILER_VERSION_STRING           "open watcom c/c++ 1.1 (watcom 12.1)"
#   elif (__WATCOMC__ == 1220)
#       define TB_COMPILER_VERSION_STRING           "open watcom c/c++ 1.2 (watcom 12.2)"
#   elif (__WATCOMC__ == 1230)
#       define TB_COMPILER_VERSION_STRING           "open watcom c/c++ 1.3 (watcom 12.3)"
#   elif (__WATCOMC__ == 1240)
#       define TB_COMPILER_VERSION_STRING           "open watcom c/c++ 1.4 (watcom 12.4)"
#   elif (__WATCOMC__ == 1250)
#       define TB_COMPILER_VERSION_STRING           "open watcom c/c++ 1.5"
#   elif (__WATCOMC__ == 1260)
#       define TB_COMPILER_VERSION_STRING           "open watcom c/c++ 1.6"
#   elif (__WATCOMC__ == 1270)
#       define TB_COMPILER_VERSION_STRING           "open watcom c/c++ 1.7"
#   else
#       error Unknown watcom c/c++ Compiler Version
#   endif

// digital mars c/c++
#elif defined(__DMC__)
#   define TB_COMPILER_IS_DMC
#   define TB_COMPILER_VERSION_BT(major, minor)     (__DMC__ > ((major) * 256 + (minor)))
#   define TB_COMPILER_VERSION_BE(major, minor)     (__DMC__ >= ((major) * 256 + (minor)))
#   define TB_COMPILER_VERSION_EQ(major, minor)     (__DMC__ == ((major) * 256 + (minor)))
#   define TB_COMPILER_VERSION_LT(major, minor)     (__DMC__ < ((major) * 256 + (minor)))
#   define TB_COMPILER_VERSION_LE(major, minor)     (__DMC__ <= ((major) * 256 + (minor)))
#   define TB_COMPILER_STRING                       "digital mars c/c++"
#   if (__DMC__ < 0x0826)
#       error Only versions 8.26 and later of the digital mars c/c++ compilers are supported by the EXTL libraries
#   else
#       if __DMC__ >= 0x0832
#           define TB_COMPILER_VERSION_STRING       __DMC_VERSION_STRING__
#       elif (__DMC__ == 0x0826)
#           define TB_COMPILER_VERSION_STRING       "digital mars c/c++ 8.26"
#       elif (__DMC__ == 0x0827)
#           define TB_COMPILER_VERSION_STRING       "digital mars c/c++ 8.27"
#       elif (__DMC__ == 0x0828)
#           define TB_COMPILER_VERSION_STRING       "digital mars c/c++ 8.28"
#       elif (__DMC__ == 0x0829)
#           define TB_COMPILER_VERSION_STRING       "digital mars c/c++ 8.29"
#       elif (__DMC__ == 0x0830)
#           define TB_COMPILER_VERSION_STRING       "digital mars c/c++ 8.30"
#       elif (__DMC__ == 0x0831)
#           define TB_COMPILER_VERSION_STRING       "digital mars c/c++ 8.31"
#       else
#           error Unknown digital mars c/c++ Compiler Version
#       endif
#   endif

// codeplay vector c/c++
#elif defined(__VECTORC)
#   define TB_COMPILER_IS_VECTORC
#   define TB_COMPILER_VERSION_BT(major, minor)     (__VECTORC > (major))
#   define TB_COMPILER_VERSION_BE(major, minor)     (__VECTORC >= (major))
#   define TB_COMPILER_VERSION_EQ(major, minor)     (__VECTORC == (major))
#   define TB_COMPILER_VERSION_LT(major, minor)     (__VECTORC < (major))
#   define TB_COMPILER_VERSION_LE(major, minor)     (__VECTORC <= (major))
#   define TB_COMPILER_VERSION_STRING               "codeplay vector c/c++"
#   if (__VECTORC == 1)
#       define TB_COMPILER_VERSION_STRING           "codeplay vector c/c++"
#   else
#       error Unknown CodePlay VectorC C++ Compiler Version
#   endif

// visual c++
#elif defined(_MSC_VER)
#   define TB_COMPILER_IS_MSVC
#   define TB_COMPILER_VERSION_BT(major, minor)     (_MSC_VER > ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_BE(major, minor)     (_MSC_VER >= ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_EQ(major, minor)     (_MSC_VER == ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LT(major, minor)     (_MSC_VER < ((major) * 100 + (minor)))
#   define TB_COMPILER_VERSION_LE(major, minor)     (_MSC_VER <= ((major) * 100 + (minor)))
#       define TB_COMPILER_STRING                   "visual c++"
#   if defined(TB_FORCE_MSVC_4_2) && (_MSC_VER == 1020)
#       define TB_COMPILER_VERSION_STRING           "visual c++ 4.2"
#   elif (_MSC_VER == 1100)
#       define TB_COMPILER_VERSION_STRING           "visual c++ 5.0"
#   elif (_MSC_VER == 1200)
#       define TB_COMPILER_VERSION_STRING           "visual c++ 6.0"
#   elif (_MSC_VER == 1300)
#       define TB_COMPILER_VERSION_STRING           "visual c++ .net (7.0)"
#   elif (_MSC_VER == 1310)
#       define TB_COMPILER_VERSION_STRING           "visual c++ .net 2003 (7.1)" 
#   elif (_MSC_VER == 1400)
#       define TB_COMPILER_VERSION_STRING           "visual c++ .net 2005 (8.0)"
#   elif (_MSC_VER == 1500)
#       define TB_COMPILER_VERSION_STRING           "visual c++ .net 2008 (9.0)"
#   elif (_MSC_VER == 1600)
#       define TB_COMPILER_VERSION_STRING           "visual c++ .net 2010 (10.0)"
#   elif (_MSC_VER == 1700)
#       define TB_COMPILER_VERSION_STRING           "visual c++ .net 2012 (11.0)"
#   elif (_MSC_VER == 1800)
#       define TB_COMPILER_VERSION_STRING           "visual c++ .net 2013 (12.0)"
#   elif (_MSC_VER == 1900)
#       define TB_COMPILER_VERSION_STRING           "visual c++ .net 2015 (14.0)"
#   else
#       error Unknown visual c++ Compiler Version
#   endif

// suppress warning
#   pragma warning(disable:4018)
#   pragma warning(disable:4197)
#   pragma warning(disable:4141)
#   pragma warning(disable:4996)

#else
#   define TB_COMPILER_STRING                       "unknown compiler"
#   define TB_COMPILER_VERSION_STRING               "unknown compiler version"
#   define TB_COMPILER_IS_UNKNOWN
#endif


#endif


