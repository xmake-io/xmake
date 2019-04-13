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
 * @file        mutex.h
 * @ingroup     dynamic
 *
 */
#ifndef TB_PLATFORM_DYNAMIC_H
#define TB_PLATFORM_DYNAMIC_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the dynamic ref type
typedef __tb_typeref__(dynamic);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init dynamic library
 * 
 * @param name      the library name
 *
 * @return          the dynamic library 
 */
tb_dynamic_ref_t    tb_dynamic_init(tb_char_t const* name);

/*! exit dynamic library
 * 
 * @param dynamic   the dynamic library 
 */
tb_void_t           tb_dynamic_exit(tb_dynamic_ref_t dynamic);

/*! the dynamic library function
 * 
 * @param dynamic   the dynamic library 
 * @param name      the function name
 *
 * @return          the function address
 */
tb_pointer_t        tb_dynamic_func(tb_dynamic_ref_t dynamic, tb_char_t const* name);

/*! the dynamic library variable
 * 
 * @param dynamic   the dynamic library 
 * @param name      the variable name
 *
 * @return          the variable address
 */
tb_pointer_t        tb_dynamic_pvar(tb_dynamic_ref_t dynamic, tb_char_t const* name);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
