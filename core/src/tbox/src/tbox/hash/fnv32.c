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
 * @author      alexyer, ruki
 * @file        fnv32.c
 * @ingroup     hash
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "fnv32.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the pnv32 prime and offset basis
#define TB_FNV32_PRIME          (16777619)
#define TB_FNV32_OFFSET_BASIS   (2166136261)

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_uint32_t tb_fnv32_make(tb_byte_t const* data, tb_size_t size, tb_uint32_t seed)
{
    // check
    tb_assert_and_check_return_val(data && size, 0);

    // init value
    tb_uint32_t value = TB_FNV32_OFFSET_BASIS;
    if (seed) value = (value * TB_FNV32_PRIME) ^ seed;

    // generate it
    while (size)
    {
        value *= TB_FNV32_PRIME;
        value ^= (tb_uint32_t)*data++;
        size--;
    }
    return value;
}
tb_uint32_t tb_fnv32_make_from_cstr(tb_char_t const* cstr, tb_uint32_t seed)
{
    // check
    tb_assert_and_check_return_val(cstr, 0);

    // make it
    return tb_fnv32_make((tb_byte_t const*)cstr, tb_strlen(cstr) + 1, seed);
}
tb_uint32_t tb_fnv32_1a_make(tb_byte_t const* data, tb_size_t size, tb_uint32_t seed)
{
    // check
    tb_assert_and_check_return_val(data && size, 0);

    // init value
    tb_uint32_t value = TB_FNV32_OFFSET_BASIS;
    if (seed) value = (value * TB_FNV32_PRIME) ^ seed;

    // generate it
    while (size)
    {
        value ^= (tb_uint32_t)*data++;
        value *= TB_FNV32_PRIME;
        size--;
    }
    return value;
}
tb_uint32_t tb_fnv32_1a_make_from_cstr(tb_char_t const* cstr, tb_uint32_t seed)
{
    // check
    tb_assert_and_check_return_val(cstr, 0);

    // make it
    return tb_fnv32_1a_make((tb_byte_t const*)cstr, tb_strlen(cstr) + 1, seed);
}
