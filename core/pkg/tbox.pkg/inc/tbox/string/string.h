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
 * @ingroup     string
 *
 */
#ifndef TB_STRING_H
#define TB_STRING_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "static_string.h"
#include "../memory/memory.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the string type
typedef tb_buffer_t         tb_string_t;

/// the string ref type
typedef tb_buffer_ref_t     tb_string_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init string
 *
 * @param string        the string
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_string_init(tb_string_ref_t string);

/*! exit string
 *
 * @param string        the string
 */
tb_void_t               tb_string_exit(tb_string_ref_t string);

/*! the c-string pointer
 *
 * @param string        the string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_cstr(tb_string_ref_t string);

/*! the string size
 *
 * @param string        the string
 *
 * @return              the string size
 */
tb_size_t               tb_string_size(tb_string_ref_t string);

/*! clear the string
 *
 * @param string        the string
 */
tb_void_t               tb_string_clear(tb_string_ref_t string);

/*! strip the string
 *
 * @param string        the string
 * @param n             the striped size
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_strip(tb_string_ref_t string, tb_size_t n);

/*! trim the left spaces for string
 *
 * @param string        the string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_ltrim(tb_string_ref_t string);

/*! trim the right spaces for string
 *
 * @param string        the string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_rtrim(tb_string_ref_t string);

/*! get the charactor at the given position
 *
 * @param string        the string
 * @param p             the position
 *
 * @return              the c-string
 */
tb_char_t               tb_string_charat(tb_string_ref_t string, tb_size_t p);

/*! find charactor position
 *
 * @param string        the string
 * @param p             the start position
 * @param c             the finded charactor
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_strchr(tb_string_ref_t string, tb_size_t p, tb_char_t c);

/*! find charactor position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param c             the finded charactor
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_strichr(tb_string_ref_t string, tb_size_t p, tb_char_t c);

/*! reverse to find charactor position
 *
 * @param string        the string
 * @param p             the start position
 * @param c             the finded charactor
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_strrchr(tb_string_ref_t string, tb_size_t p, tb_char_t c);

/*! reverse to find charactor position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param c             the finded charactor
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_strirchr(tb_string_ref_t string, tb_size_t p, tb_char_t c);

/*! find string position 
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_strstr(tb_string_ref_t string, tb_size_t p, tb_string_ref_t s);

/*! find string position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_stristr(tb_string_ref_t string, tb_size_t p, tb_string_ref_t s);

/*! find c-string position 
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded c-string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_cstrstr(tb_string_ref_t string, tb_size_t p, tb_char_t const* s);

/*! find c-string position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded c-string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_cstristr(tb_string_ref_t string, tb_size_t p, tb_char_t const* s);

/*! reverse to find string position 
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_strrstr(tb_string_ref_t string, tb_size_t p, tb_string_ref_t s);

/*! reverse to find string position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_strirstr(tb_string_ref_t string, tb_size_t p, tb_string_ref_t s);

/*! reverse to find c-string position 
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded c-string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_cstrrstr(tb_string_ref_t string, tb_size_t p, tb_char_t const* s);

/*! reverse to find c-string position and ignore case
 *
 * @param string        the string
 * @param p             the start position
 * @param s             the finded c-string
 *
 * @return              the real position, no find: -1
 */
tb_long_t               tb_string_cstrirstr(tb_string_ref_t string, tb_size_t p, tb_char_t const* s);

/*! copy string
 *
 * @param string        the string
 * @param s             the copied string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_strcpy(tb_string_ref_t string, tb_string_ref_t s);

/*! copy c-string
 *
 * @param string        the string
 * @param s             the copied c-string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_cstrcpy(tb_string_ref_t string, tb_char_t const* s);

/*! copy c-string with the given size
 *
 * @param string        the string
 * @param s             the copied c-string
 * @param n             the copied c-string size
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_cstrncpy(tb_string_ref_t string, tb_char_t const* s, tb_size_t n);

/*! copy format c-string
 *
 * @param string        the string
 * @param fmt           the copied format c-string 
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_cstrfcpy(tb_string_ref_t string, tb_char_t const* fmt, ...);

/*! append charactor
 *
 * @param string        the string
 * @param c             the appended charactor
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_chrcat(tb_string_ref_t string, tb_char_t c);

/*! append charactor with the given size
 *
 * @param string        the string
 * @param c             the appended charactor
 * @param n             the appended size
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_chrncat(tb_string_ref_t string, tb_char_t c, tb_size_t n);

/*! append string
 *
 * @param string        the string
 * @param s             the appended string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_strcat(tb_string_ref_t string, tb_string_ref_t s);

/*! append c-string
 *
 * @param string        the string
 * @param s             the appended c-string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_cstrcat(tb_string_ref_t string, tb_char_t const* s);

/*! append c-string with the given size
 *
 * @param string        the string
 * @param s             the appended c-string
 * @param n             the appended c-string size
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_cstrncat(tb_string_ref_t string, tb_char_t const* s, tb_size_t n);

/*! append format c-string 
 *
 * @param string        the string
 * @param fmt           the appended format c-string
 *
 * @return              the c-string
 */
tb_char_t const*        tb_string_cstrfcat(tb_string_ref_t string, tb_char_t const* fmt, ...);

/*! compare string
 *
 * @param string        the string
 * @param s             the compared string
 *
 * @return              equal: 0
 */
tb_long_t               tb_string_strcmp(tb_string_ref_t string, tb_string_ref_t s);

/*! compare string and ignore case
 *
 * @param string        the string
 * @param s             the compared string
 *
 * @return              equal: 0
 */
tb_long_t               tb_string_strimp(tb_string_ref_t string, tb_string_ref_t s);

/*! compare c-string
 *
 * @param string        the string
 * @param s             the compared c-string
 *
 * @return              equal: 0
 */
tb_long_t               tb_string_cstrcmp(tb_string_ref_t string, tb_char_t const* s);

/*! compare c-string and ignore case
 *
 * @param string        the string
 * @param s             the compared c-string
 *
 * @return              equal: 0
 */
tb_long_t               tb_string_cstricmp(tb_string_ref_t string, tb_char_t const* s);

/*! compare c-string with given size
 *
 * @param string        the string
 * @param s             the compared c-string
 * #param n             the compared c-string size
 *
 * @return              equal: 0
 */
tb_long_t               tb_string_cstrncmp(tb_string_ref_t string, tb_char_t const* s, tb_size_t n);

/*! compare c-string with given size and ignore case
 *
 * @param string        the string
 * @param s             the compared c-string
 * #param n             the compared c-string size
 *
 * @return              equal: 0
 */
tb_long_t               tb_string_cstrnicmp(tb_string_ref_t string, tb_char_t const* s, tb_size_t n);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

