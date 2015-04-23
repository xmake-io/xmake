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
 * @file        stdlib.h
 * @ingroup     libc
 *
 */
#ifndef TB_LIBC_STDLIB_H
#define TB_LIBC_STDLIB_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// for uint32
#define tb_s2tou32(s)               ((tb_uint32_t)tb_s2tou64(s))
#define tb_s8tou32(s)               ((tb_uint32_t)tb_s8tou64(s))
#define tb_s10tou32(s)              ((tb_uint32_t)tb_s10tou64(s))
#define tb_s16tou32(s)              ((tb_uint32_t)tb_s16tou64(s))
#define tb_stou32(s)                ((tb_uint32_t)tb_stou64(s))
#define tb_sbtou32(s, b)            ((tb_uint32_t)tb_sbtou64(s, b))

// for int32
#define tb_s2toi32(s)               ((tb_int32_t)tb_s2tou64(s))
#define tb_s8toi32(s)               ((tb_int32_t)tb_s8tou64(s))
#define tb_s10toi32(s)              ((tb_int32_t)tb_s10tou64(s))
#define tb_s16toi32(s)              ((tb_int32_t)tb_s16tou64(s))
#define tb_stoi32(s)                ((tb_int32_t)tb_stou64(s))
#define tb_sbtoi32(s, b)            ((tb_int32_t)tb_sbtou64(s, b))

// for int64
#define tb_s2toi64(s)               ((tb_int64_t)tb_s2tou64(s))
#define tb_s8toi64(s)               ((tb_int64_t)tb_s8tou64(s))
#define tb_s10toi64(s)              ((tb_int64_t)tb_s10tou64(s))
#define tb_s16toi64(s)              ((tb_int64_t)tb_s16tou64(s))
#define tb_stoi64(s)                ((tb_int64_t)tb_stou64(s))
#define tb_sbtoi64(s, b)            ((tb_int64_t)tb_sbtou64(s, b))

// for float
#ifdef TB_CONFIG_TYPE_FLOAT
#   define tb_s2tof(s)              ((tb_float_t)tb_s2tod(s))
#   define tb_s8tof(s)              ((tb_float_t)tb_s8tod(s))
#   define tb_s10tof(s)             ((tb_float_t)tb_s10tod(s))
#   define tb_s16tof(s)             ((tb_float_t)tb_s16tod(s))
#   define tb_stof(s)               ((tb_float_t)tb_stod(s))
#   define tb_sbtof(s, b)           ((tb_float_t)tb_sbtod(s, b))
#endif

// for porting libc
#define tb_atoi(s)                  tb_s10toi32(s)
#define tb_atoll(s)                 tb_s10toi64(s)
#define tb_strtol(s, e, b)          tb_sbtoi32(s, b)
#define tb_strtoll(s, e, b)         tb_sbtoi64(s, b)
#ifdef TB_CONFIG_TYPE_FLOAT
#   define tb_atof(s)               tb_s10tod(s)
#   define tb_strtof(s, e)          tb_s10tof(s)
#   define tb_strtod(s, e)          tb_s10tod(s)
#endif

// atow
#define tb_atow(s1, s2, n)          tb_mbstowcs(s1, s2, n)

// wtoa
#define tb_wtoa(s1, s2, n)          tb_wcstombs(s1, s2, n)

// rand
#define tb_rand()                   (tb_int_t)tb_random()
#define tb_srand(seed)              tb_srandom(seed)

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! convert the binary string to uint64
 *
 * <pre>
 * .e.g 
 *
 * "1001" => 9
 * "0b1001" => 9
 * </pre>
 *
 * @param s         the string
 *
 * @return          the uint64 number
 */
tb_uint64_t         tb_s2tou64(tb_char_t const* s);

/*! convert the octal string to uint64
 *
 * <pre>
 * .e.g 
 *
 * "11" => 9
 * "011" => 9
 * </pre>
 *
 * @param s         the string
 *
 * @return          the uint64 number
 */
tb_uint64_t         tb_s8tou64(tb_char_t const* s);

/*! convert the decimal string to uint64
 *
 * .e.g "9" => 9
 *
 * @param s         the string
 *
 * @return          the uint64 number
 */
tb_uint64_t         tb_s10tou64(tb_char_t const* s);

/*! convert the hex string to uint64
 *
 * <pre>
 * .e.g
 * 
 * "9" => 9
 * "0x9" => 9
 * </pre>
 *
 * @param s         the string
 *
 * @return          the uint64 number
 */
tb_uint64_t         tb_s16tou64(tb_char_t const* s);

/*! auto convert string to uint64
 *
 * <pre>
 * .e.g 
 *
 * "0b1001" => 9
 * "011"    => 9
 * "9"      => 9
 * "0x9"    => 9
 * </pre>
 *
 * @param s         the string
 *
 * @return          the uint64 number
 */
tb_uint64_t         tb_stou64(tb_char_t const* s);

/*! convert string to uint64 using the given base number
 *
 * @param s         the string
 *
 * @return          the uint64 number
 */
tb_uint64_t         tb_sbtou64(tb_char_t const* s, tb_int_t base);

#ifdef TB_CONFIG_TYPE_FLOAT

/*! convert the binary string to double
 *
 * <pre>
 * .e.g 
 *
 * "1001" => 9
 * "0b1001" => 9
 * </pre>
 *
 * @param s         the string
 *
 * @return          the double number
 */
tb_double_t         tb_s2tod(tb_char_t const* s);

/*! convert the binary string to double
 *
 * <pre>
 * .e.g 
 *
 * "11" => 9
 * "011" => 9
 * </pre>
 *
 * @param s         the string
 *
 * @return          the double number
 */
tb_double_t         tb_s8tod(tb_char_t const* s);

/*! convert the decimal string to double
 *
 * .e.g "9" => 9
 *
 * @param s         the string
 *
 * @return          the double number
 */
tb_double_t         tb_s10tod(tb_char_t const* s);

/*! convert the hex string to double
 *
 * <pre>
 * .e.g
 * 
 * "9" => 9
 * "0x9" => 9
 * </pre>
 *
 * @param s         the string
 *
 * @return          the double number
 */
tb_double_t         tb_s16tod(tb_char_t const* s);

/*! auto convert string to double
 *
 * <pre>
 * .e.g 
 *
 * "0b1001" => 9
 * "011"    => 9
 * "9"      => 9
 * "0x9"    => 9
 * </pre>
 *
 * @param s         the string
 *
 * @return          the double number
 */
tb_double_t         tb_stod(tb_char_t const* s);

/*! convert string to double using the given base number
 *
 * @param s         the string
 *
 * @return          the double number
 */
tb_double_t         tb_sbtod(tb_char_t const* s, tb_int_t base);

#endif

/*! mbstowcs, convert string to wstring
 *
 * @param s1        the wstring data
 * @param s2        the string data
 * @param n         the string length
 *
 * @return          the wstring length
 */
tb_size_t           tb_mbstowcs(tb_wchar_t* s1, tb_char_t const* s2, tb_size_t n);

/*! wcstombs, convert wstring to string
 *
 * @param s1        the string data
 * @param s2        the wstring data
 * @param n         the wstring length
 *
 * @return          the string length
 */
tb_size_t           tb_wcstombs(tb_char_t* s1, tb_wchar_t const* s2, tb_size_t n);

/*! update random seed
 *
 * @param seed      the random seed
 */
tb_void_t           tb_srandom(tb_size_t seed);

/*! generate the random with range: [0, max)
 *
 * @return          the random value
 */
tb_long_t           tb_random(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
