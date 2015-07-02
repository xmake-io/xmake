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
 * @file        string.h
 * @ingroup     libc
 *
 */
#ifndef TB_LIBC_STRING_H
#define TB_LIBC_STRING_H

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

// memset_ptr
#if TB_CPU_BIT64
#   define      tb_memset_ptr(s, p, n)      tb_memset_u64(s, (tb_uint64_t)(p), n)
#else 
#   define      tb_memset_ptr(s, p, n)      tb_memset_u32(s, (tb_uint32_t)(p), n)
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// memset
tb_pointer_t        tb_memset(tb_pointer_t s, tb_byte_t c, tb_size_t n);
tb_pointer_t        tb_memset_(tb_pointer_t s, tb_byte_t c, tb_size_t n);
tb_pointer_t        tb_memset_u16(tb_pointer_t s, tb_uint16_t c, tb_size_t n);
tb_pointer_t        tb_memset_u24(tb_pointer_t s, tb_uint32_t c, tb_size_t n);
tb_pointer_t        tb_memset_u32(tb_pointer_t s, tb_uint32_t c, tb_size_t n);
tb_pointer_t        tb_memset_u64(tb_pointer_t s, tb_uint64_t c, tb_size_t n);

// memdup
tb_pointer_t        tb_memdup(tb_cpointer_t s, tb_size_t n);
tb_pointer_t        tb_memdup_(tb_cpointer_t s, tb_size_t n);

// memcpy
tb_pointer_t        tb_memcpy(tb_pointer_t s1, tb_cpointer_t s2, tb_size_t n);
tb_pointer_t        tb_memcpy_(tb_pointer_t s1, tb_cpointer_t s2, tb_size_t n);

// memmov
tb_pointer_t        tb_memmov(tb_pointer_t s1, tb_cpointer_t s2, tb_size_t n);
tb_pointer_t        tb_memmov_(tb_pointer_t s1, tb_cpointer_t s2, tb_size_t n);

// memcmp
tb_long_t           tb_memcmp(tb_cpointer_t s1, tb_cpointer_t s2, tb_size_t n);
tb_long_t           tb_memcmp_(tb_cpointer_t s1, tb_cpointer_t s2, tb_size_t n);

// strlen
tb_size_t           tb_strlen(tb_char_t const* s);
tb_size_t           tb_strnlen(tb_char_t const* s, tb_size_t n);

// strdup
tb_char_t*          tb_strdup(tb_char_t const* s);
tb_char_t*          tb_strndup(tb_char_t const* s, tb_size_t n);

// strcat
tb_char_t*          tb_strcat(tb_char_t* s1, tb_char_t const* s2);
tb_char_t*          tb_strncat(tb_char_t* s1, tb_char_t const* s2, tb_size_t n);

// strcpy
tb_char_t*          tb_strcpy(tb_char_t* s1, tb_char_t const* s2);
tb_char_t*          tb_strncpy(tb_char_t* s1, tb_char_t const* s2, tb_size_t n);
tb_size_t           tb_strlcpy(tb_char_t* s1, tb_char_t const* s2, tb_size_t n);

// strcmp
tb_long_t           tb_strcmp(tb_char_t const* s1, tb_char_t const* s2);
tb_long_t           tb_strncmp(tb_char_t const* s1, tb_char_t const* s2, tb_size_t n);

tb_long_t           tb_stricmp(tb_char_t const* s1, tb_char_t const* s2);
tb_long_t           tb_strnicmp(tb_char_t const* s1, tb_char_t const* s2, tb_size_t n);

// strchr
tb_char_t*          tb_strchr(tb_char_t const* s, tb_char_t c);
tb_char_t*          tb_strichr(tb_char_t const* s, tb_char_t c);

// strrchr
tb_char_t*          tb_strrchr(tb_char_t const* s, tb_char_t c);
tb_char_t*          tb_strirchr(tb_char_t const* s, tb_char_t c);

tb_char_t*          tb_strnrchr(tb_char_t const* s, tb_size_t n, tb_char_t c);
tb_char_t*          tb_strnirchr(tb_char_t const* s, tb_size_t n, tb_char_t c);

// strstr
tb_char_t*          tb_strstr(tb_char_t const* s1, tb_char_t const* s2);
tb_char_t*          tb_stristr(tb_char_t const* s1, tb_char_t const* s2);

tb_char_t*          tb_strnstr(tb_char_t const* s1, tb_size_t n1, tb_char_t const* s2);
tb_char_t*          tb_strnistr(tb_char_t const* s1, tb_size_t n1, tb_char_t const* s2);

// strrstr
tb_char_t*          tb_strrstr(tb_char_t const* s1, tb_char_t const* s2);
tb_char_t*          tb_strirstr(tb_char_t const* s1, tb_char_t const* s2);

tb_char_t*          tb_strnrstr(tb_char_t const* s1, tb_size_t n1, tb_char_t const* s2);
tb_char_t*          tb_strnirstr(tb_char_t const* s1, tb_size_t n1, tb_char_t const* s2);

// wcslen
tb_size_t           tb_wcslen(tb_wchar_t const* s);
tb_size_t           tb_wcsnlen(tb_wchar_t const* s, tb_size_t n);

// wcsdup
tb_wchar_t*         tb_wcsdup(tb_wchar_t const* s);
tb_wchar_t*         tb_wcsndup(tb_wchar_t const* s, tb_size_t n);

// wcscat
tb_wchar_t*         tb_wcscat(tb_wchar_t* s1, tb_wchar_t const* s2);
tb_wchar_t*         tb_wcsncat(tb_wchar_t* s1, tb_wchar_t const* s2, tb_size_t n);

// wcscpy
tb_wchar_t*         tb_wcscpy(tb_wchar_t* s1, tb_wchar_t const* s2);
tb_wchar_t*         tb_wcsncpy(tb_wchar_t* s1, tb_wchar_t const* s2, tb_size_t n);
tb_size_t           tb_wcslcpy(tb_wchar_t* s1, tb_wchar_t const* s2, tb_size_t n);

// wcscmp
tb_long_t           tb_wcscmp(tb_wchar_t const* s1, tb_wchar_t const* s2);
tb_long_t           tb_wcsncmp(tb_wchar_t const* s1, tb_wchar_t const* s2, tb_size_t n);

tb_long_t           tb_wcsicmp(tb_wchar_t const* s1, tb_wchar_t const* s2);
tb_long_t           tb_wcsnicmp(tb_wchar_t const* s1, tb_wchar_t const* s2, tb_size_t n);

// wcschr
tb_wchar_t*         tb_wcschr(tb_wchar_t const* s, tb_wchar_t c);
tb_wchar_t*         tb_wcsichr(tb_wchar_t const* s, tb_wchar_t c);

// wcsrchr
tb_wchar_t*         tb_wcsrchr(tb_wchar_t const* s, tb_wchar_t c);
tb_wchar_t*         tb_wcsirchr(tb_wchar_t const* s, tb_wchar_t c);

tb_wchar_t*         tb_wcsnrchr(tb_wchar_t const* s, tb_size_t n, tb_wchar_t c);
tb_wchar_t*         tb_wcsnirchr(tb_wchar_t const* s, tb_size_t n, tb_wchar_t c);

// wcsstr
tb_wchar_t*         tb_wcsstr(tb_wchar_t const* s1, tb_wchar_t const* s2);
tb_wchar_t*         tb_wcsistr(tb_wchar_t const* s1, tb_wchar_t const* s2);

// wcsrstr
tb_wchar_t*         tb_wcsrstr(tb_wchar_t const* s1, tb_wchar_t const* s2);
tb_wchar_t*         tb_wcsirstr(tb_wchar_t const* s1, tb_wchar_t const* s2);

tb_wchar_t*         tb_wcsnrstr(tb_wchar_t const* s1, tb_size_t n, tb_wchar_t const* s2);
tb_wchar_t*         tb_wcsnirstr(tb_wchar_t const* s1, tb_size_t n, tb_wchar_t const* s2);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
