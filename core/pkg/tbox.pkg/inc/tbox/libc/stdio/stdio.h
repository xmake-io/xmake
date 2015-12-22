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
 * @file        stdio.h
 * @ingroup     libc
 *
 */
#ifndef TB_LIBC_STDIO_H
#define TB_LIBC_STDIO_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "printf_object.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// vsnprintf format
#define tb_vsnprintf_format(s, n, format, r) \
do \
{ \
    tb_long_t __tb_ret = 0; \
    tb_va_list_t __tb_varg_list; \
    tb_va_start(__tb_varg_list, format); \
    __tb_ret = tb_vsnprintf(s, (n), format, __tb_varg_list); \
    tb_va_end(__tb_varg_list); \
    if (__tb_ret >= 0) s[__tb_ret] = '\0'; \
    *r = __tb_ret > 0? __tb_ret : 0; \
 \
} while (0) 

// vswprintf format
#define tb_vswprintf_format(s, n, format, r) \
do \
{ \
    tb_long_t __tb_ret = 0; \
    tb_va_list_t __tb_varg_list; \
    tb_va_start(__tb_varg_list, format); \
    __tb_ret = tb_vswprintf(s, (n), format, __tb_varg_list); \
    tb_va_end(__tb_varg_list); \
    if (__tb_ret >= 0) s[__tb_ret] = L'\0'; \
    *r = __tb_ret > 0? __tb_ret : 0; \
 \
} while (0) 

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! puts
 *
 * @param string    the string
 * 
 * @return          the real size
 */
tb_long_t           tb_puts(tb_char_t const* string);

/*! wputs
 *
 * @param string    the string
 * 
 * @return          the real size
 */
tb_long_t           tb_wputs(tb_wchar_t const* string);

/*! printf
 *
 * @param format    the format string
 * 
 * @return          the real size
 *
 * - format: %[flags][width][.precision][qualifier]type
 *
 * - flags:
 *   - default: right-justified, left-pad the output with spaces until the required length of output is attained. 
 *              If combined with '0' (see below), 
 *              it will cause the sign to become a space when positive, 
 *              but the remaining characters will be zero-padded
 *   - -:       left-justified, e.g. %-d
 *   - +:       denote the sign '+' or '-' of a number
 *   - 0:       use 0 instead of spaces to left-fill a fixed-length field
 *   - #:       add prefix or suffix    
 *     - %#o => add prefix: 0...
 *     - %#x => add prefix: 0x...
 *     - %#X => add prefix: 0X...
 *     - %#b => add prefix: 0b...
 *     - %#B => add prefix: 0B...
 *     - %#f => add prefix: 0f...
 *     - %#F => add prefix: 0F...
 *
 * - width:
 *   - n:       n = 1, 2, 3, ..., fill spaces
 *   - 0n:      n = 1, 2, 3, ..., fill 0
 *   - *:       causes printf to pad the output until it is n characters wide, 
 *              where n is an integer value stored in the a function argument just preceding 
 *              that represented by the modified type. 
 *              e.g. printf("%*d", 5, 10) will result in "10" being printed with a width of 5.
 *
 * - .precision:
 *   - .n:      for non-integral numeric types, causes the decimal portion of the output to be expressed in at least number digits. 
 *              for the string type, causes the output to be truncated at number characters. 
 *              if the precision is zero, nothing is printed for the corresponding argument.
 *   - *:       same as the above, but uses an integer value in the intaken argument to 
 *              determine the number of decimal places or maximum string length. 
 *              e.g. printf("%.*s", 3, "abcdef") will result in "abc" being printed.
 *
 * - qualifier:
 *   - h:       short integer or single double-point
 *   - l:       long integer or double double-point
 *   - I8:      8-bit integer
 *   - I16:     16-bit integer
 *   - I32:     32-bit integer
 *   - I64/ll:  64-bit integer
 *
 * @note support h, l, I8, I16, I32, I64, ll
 *
 * - type(e.g. %d %x %u %% ...):
 *   - d, i:    print an int as a signed decimal number. 
 *              '%d' and '%i' are synonymous for output, but are different when used with scanf() for input.
 *   - u:       print decimal unsigned int.
 *   - o:       print an unsigned int in octal.
 *   - x/X:     print an unsigned int as a hexadecimal number. 'x' uses lower-case letters and 'X' uses upper-case.
 *   - b/B:     print an unsigned binary interger
 *   - e/E:     print a double value in standard form ([-]d.ddd e[+/-]ddd).
 *              An E conversion uses the letter E (rather than e) to introduce the exponent. 
 *              The exponent always contains at least two digits; if the value is zero, the exponent is 00.
 *              e.g. 3.141593e+00
 *   - f/F:     Print a double in normal (fixed-point) notation. 
 *              'f' and 'F' only differs in how the strings for an infinite number or NaN are printed 
 *              ('inf', 'infinity' and 'nan' for 'f', 'INF', 'INFINITY' and 'NAN' for 'F').
 *   - g/G:     print a double in either normal or exponential notation, whichever is more appropriate for its magnitude. 
 *              'g' uses lower-case letters, 'G' uses upper-case letters. 
 *              This type differs slightly from fixed-point notation in 
 *              that insignificant zeroes to the right of the decimal point are not included. 
 *              Also, the decimal point is not included on whole numbers.
 *   - c:       print a char (character).
 *   - s:       print a character string
 *   - p:       print a void * (pointer to void) in an implementation-defined format.
 *   - n:       print nothing, but write number of characters successfully written so far into an integer pointer parameter.
 *   - %:       %
 *
 * @note support        d, i, u, o, u, x/X, b/B, f/F, c, s
 * @note not support    e/E, g/G, p, n
 *
 * @code
 * tb_printf("|hello world|\n");
 * tb_printf("|%-10s|%%|%10s|\n", "hello", "world");
 * tb_printf("|%#2c|%2.5c|%*c|\n", 'A', 'B', 5, 'C');
 * tb_printf("|%#2d|%#8.3o|%*.*d|\n", -56, 56, 10, 5, 56);
 * tb_printf("|%#-8.5x|%#2.9X|\n", 0x1f, 0x1f);
 * tb_printf("|%#-8.5b|%#2.9B|\n", 0x1f, 0x1f);
 * tb_printf("|%-6Id|%5I8u|%#I64x|%#llx|\n", 256, 255, (tb_int64_t)0x8fffffffffff, (tb_int64_t)0x8fffffffffff);
 * tb_printf("|%lf|\n", -3.1415926535897932384626433832795);
 * tb_printf("|%lf|%lf|%lf|\n", 3.14, 0, -0);
 * tb_printf("|%0.9f|\n", 3.1415926535897932384626433832795);
 * tb_printf("|%16.9f|\n", 3.1415926535897932384626433832795);
 * tb_printf("|%016.9f|\n", 3.14159);
 * tb_printf("|%lf|\n", 1.0 / 6.0);
 * tb_printf("|%lf|\n", 0.0003141596);
 * tb_printf("|%F|\n", tb_float_to_fixed(3.1415));
 * tb_printf("|%{object_name}|\n", object);
 * @endcode
 */
tb_long_t           tb_printf(tb_char_t const* format, ...);

/*! wprintf
 *
 * @param format    the format string
 * 
 * @return          the real size
 */
tb_long_t           tb_wprintf(tb_wchar_t const* format, ...);

/*! sprintf
 *
 * @param s         the string data
 * @param format    the format string
 * 
 * @return          the real size
 */
tb_long_t           tb_sprintf(tb_char_t* s, tb_char_t const* format, ...);

/*! snprintf
 *
 * @param s         the string data
 * @param n         the string size
 * @param format    the format string
 * 
 * @return          the real size
 */
tb_long_t           tb_snprintf(tb_char_t* s, tb_size_t n, tb_char_t const* format, ...);

/*! vsnprintf
 *
 * @param s         the string data
 * @param n         the string size
 * @param format    the format string
 * @param args      the arguments
 * 
 * @return          the real size
 */
tb_long_t           tb_vsnprintf(tb_char_t* s, tb_size_t n, tb_char_t const* format, tb_va_list_t args);

/*! swprintf
 *
 * @param s         the string data
 * @param n         the string size
 * @param format    the format string
 * 
 * @return          the real size
 */
tb_long_t           tb_swprintf(tb_wchar_t* s, tb_size_t n, tb_wchar_t const* format, ...);

/*! vswprintf
 *
 * @param s         the string data
 * @param n         the string size
 * @param format    the format string
 * @param args      the arguments
 * 
 * @return          the real size
 */
tb_long_t           tb_vswprintf(tb_wchar_t* s, tb_size_t n, tb_wchar_t const* format, tb_va_list_t args);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
