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
 * @file        uuid.h
 * @ingroup     hash
 *
 */
#ifndef TB_HASH_UUID_H
#define TB_HASH_UUID_H

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

/*! make an uuid
 *
 * @param uuid      the uuid output buffer
 * @param name      we only generate it using a simple hashing function for speed if name is supplied 
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_uuid_make(tb_byte_t uuid[16], tb_char_t const* name);

/*! make an uuid string
 *
 * @param uuid_cstr the uuid output c-string
 * @param name      we only generate it using a simple hashing function for speed if name is supplied 
 *
 * @return          the uuid c-string or tb_null
 */
tb_char_t const*    tb_uuid_make_cstr(tb_char_t uuid_cstr[37], tb_char_t const* name);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

