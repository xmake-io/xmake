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

