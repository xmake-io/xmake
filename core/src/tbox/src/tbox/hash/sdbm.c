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
 * @file        sdbm.c
 * @ingroup     hash
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "sdbm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_sdbm_make(tb_byte_t const* data, tb_size_t size, tb_size_t seed)
{
    // check
    tb_assert_and_check_return_val(data && size, 0);

    // init value
    tb_size_t value = seed;

    // generate it
    while (size--) value = (*data++) + (value << 6) + (value << 16) - value;
    return value;
}
tb_size_t tb_sdbm_make_from_cstr(tb_char_t const* cstr, tb_size_t seed)
{
    // check
    tb_assert_and_check_return_val(cstr, 0);

    // make it
    return tb_sdbm_make((tb_byte_t const*)cstr, tb_strlen(cstr) + 1, seed);
}
