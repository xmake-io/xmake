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
 * @file        string.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_STRING_H
#define TB_OBJECT_STRING_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init string from c-string
 *
 * @param cstr      the c-string
 *
 * @return          the string object
 */
tb_object_ref_t     tb_oc_string_init_from_cstr(tb_char_t const* cstr);

/*! init string from string
 *
 * @param str       the string
 *
 * @return          the string object
 */
tb_object_ref_t     tb_oc_string_init_from_str(tb_string_ref_t str);

/*! the c-string
 *
 * @param string    the string object
 *
 * @return          the c-string
 */
tb_char_t const*    tb_oc_string_cstr(tb_object_ref_t string);

/*! set the c-string
 *
 * @param string    the string object
 * @param cstr      the c-string
 *
 * @return          the string size
 */
tb_size_t           tb_oc_string_cstr_set(tb_object_ref_t string, tb_char_t const* cstr);

/*! the string size
 *
 * @param string    the string object
 *
 * @return          the string size
 */
tb_size_t           tb_oc_string_size(tb_object_ref_t string);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

