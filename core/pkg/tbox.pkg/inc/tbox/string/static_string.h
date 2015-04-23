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
 * @file        static_string.h
 * @ingroup     string
 *
 */
#ifndef TB_STRING_STATIC_STRING_H
#define TB_STRING_STATIC_STRING_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../memory/memory.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the static string type
typedef tb_static_buffer_t  tb_static_string_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init string
 *
 * @param string        the string
 * @param data          the data
 * @param maxn          the maxn
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_static_string_init(tb_static_string_t* string, tb_char_t* data, tb_size_t maxn);

/*! exit string
 *
 * @param string        the string
 */
tb_void_t               tb_static_string_exit(tb_static_string_t* string);

/*! the c-string pointer
 *
 * @param string        the string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_cstr(tb_static_string_t const* string);

/*! the string size
 *
 * @param string        the string
 *
 * @return              the string size
 */
tb_size_t               tb_static_string_size(tb_static_string_t const* string);

/*! clear the string
 *
 * @param string        the string
 */
tb_void_t               tb_static_string_clear(tb_static_string_t* string);

/*! strip the string
 *
 * @param string        the string
 * @param n             the striped size
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_strip(tb_static_string_t* string, tb_size_t n);

/*! trim the right spaces for string
 *
 * @param string        the string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_rtrim(tb_static_string_t* string);

/*! find charactor position
 *
 * @param string        the string
 * @param p             the start position
 * @param c             the finded charactor
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_strchr(tb_static_string_t const* string, tb_size_t p, tb_char_t c);

/*! find charactor position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param c             the finded charactor
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_strichr(tb_static_string_t const* string, tb_size_t p, tb_char_t c);

/*! reverse to find charactor position
 *
 * @param string        the string
 * @param p             the start position
 * @param c             the finded charactor
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_strrchr(tb_static_string_t const* string, tb_size_t p, tb_char_t c);

/*! reverse to find charactor position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param c             the finded charactor
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_strirchr(tb_static_string_t const* string, tb_size_t p, tb_char_t c);

/*! find string position 
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_strstr(tb_static_string_t const* string, tb_size_t p, tb_static_string_t const* s);

/*! find string position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_stristr(tb_static_string_t const* string, tb_size_t p, tb_static_string_t const* s);

/*! find c-string position 
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded c-string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_cstrstr(tb_static_string_t const* string, tb_size_t p, tb_char_t const* s);

/*! find c-string position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded c-string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_cstristr(tb_static_string_t const* string, tb_size_t p, tb_char_t const* s);

/*! reverse to find string position 
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_strrstr(tb_static_string_t const* string, tb_size_t p, tb_static_string_t const* s);

/*! reverse to find string position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_strirstr(tb_static_string_t const* string, tb_size_t p, tb_static_string_t const* s);

/*! reverse to find c-string position 
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded c-string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_cstrrstr(tb_static_string_t const* string, tb_size_t p, tb_char_t const* s);

/*! reverse to find c-string position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded c-string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_static_string_cstrirstr(tb_static_string_t const* string, tb_size_t p, tb_char_t const* s);

/*! copy string
 *
 * @param string        the string
 * @param s             the copied string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_strcpy(tb_static_string_t* string, tb_static_string_t const* s);

/*! copy c-string
 *
 * @param string        the string
 * @param s             the copied c-string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_cstrcpy(tb_static_string_t* string, tb_char_t const* s);

/*! copy c-string with the given size
 *
 * @param string        the string
 * @param s             the copied c-string
 * @param n             the copied c-string size
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_cstrncpy(tb_static_string_t* string, tb_char_t const* s, tb_size_t n);

/*! copy format c-string
 *
 * @param string        the string
 * @param fmt           the copied format c-string 
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_cstrfcpy(tb_static_string_t* string, tb_char_t const* fmt, ...);

/*! append charactor
 *
 * @param string        the string
 * @param c             the appended charactor
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_chrcat(tb_static_string_t* string, tb_char_t c);

/*! append charactor with the given size
 *
 * @param string        the string
 * @param c             the appended charactor
 * @param n             the appended size
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_chrncat(tb_static_string_t* string, tb_char_t c, tb_size_t n);

/*! append string
 *
 * @param string        the string
 * @param s             the appended string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_strcat(tb_static_string_t* string, tb_static_string_t const* s);

/*! append c-string
 *
 * @param string        the string
 * @param s             the appended c-string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_cstrcat(tb_static_string_t* string, tb_char_t const* s);

/*! append c-string with the given size
 *
 * @param string        the string
 * @param s             the appended c-string
 * @param n             the appended c-string size
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_cstrncat(tb_static_string_t* string, tb_char_t const* s, tb_size_t n);

/*! append format c-string 
 *
 * @param string        the string
 * @param fmt           the appended format c-string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_static_string_cstrfcat(tb_static_string_t* string, tb_char_t const* fmt, ...);

/*! compare string
 *
 * @param string        the string
 * @param s             the compared string
 *
 * @return              equal: 0
 */
tb_long_t               tb_static_string_strcmp(tb_static_string_t* string, tb_static_string_t const* s);

/*! compare string and ignore case
 *
 * @param string        the string
 * @param s             the compared string
 *
 * @return              equal: 0
 */
tb_long_t               tb_static_string_strimp(tb_static_string_t* string, tb_static_string_t const* s);

/*! compare c-string
 *
 * @param string        the string
 * @param s             the compared c-string
 *
 * @return              equal: 0
 */
tb_long_t               tb_static_string_cstrcmp(tb_static_string_t* string, tb_char_t const* s);

/*! compare c-string and ignore case
 *
 * @param string        the string
 * @param s             the compared c-string
 *
 * @return              equal: 0
 */
tb_long_t               tb_static_string_cstricmp(tb_static_string_t* string, tb_char_t const* s);

/*! compare c-string with given size
 *
 * @param string        the string
 * @param s             the compared c-string
 * #param n             the compared c-string size
 *
 * @return              equal: 0
 */
tb_long_t               tb_static_string_cstrncmp(tb_static_string_t* string, tb_char_t const* s, tb_size_t n);

/*! compare c-string with given size and ignore case
 *
 * @param string        the string
 * @param s             the compared c-string
 * #param n             the compared c-string size
 *
 * @return              equal: 0
 */
tb_long_t               tb_static_string_cstrnicmp(tb_static_string_t* string, tb_char_t const* s, tb_size_t n);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

