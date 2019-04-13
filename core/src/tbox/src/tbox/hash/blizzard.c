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
 * @file        blizzard.c
 * @ingroup     hash
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "blizzard.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_blizzard_make(tb_byte_t const* data, tb_size_t size, tb_size_t seed)
{
    // check
    tb_assert_and_check_return_val(data && size, 0);

    // init value
    tb_size_t value = seed;

    // generate it
    while (size--) value = (*data++) + (value << 6) + (value << 16) - value;
    return value;

    // make table
    static tb_size_t s_make = 0;
    static tb_size_t s_table[1280];
    if (!s_make)
    {
        tb_size_t i = 0;  
        tb_size_t index1 = 0;
        tb_size_t index2 = 0;
        tb_size_t seed0 = 0x00100001;
        for (index1 = 0; index1 < 0x100; index1++)  
        {   
            for (index2 = index1, i = 0; i < 5; i++, index2 += 0x100)  
            {   
                seed0 = (seed0 * 125 + 3) % 0x2aaaab; tb_size_t temp1 = (seed0 & 0xffff) << 0x10;  
                seed0 = (seed0 * 125 + 3) % 0x2aaaab; tb_size_t temp2 = (seed0 & 0xffff);
                s_table[index2] = (temp1 | temp2);   
            }   
        }

        // ok
        s_make = 1;
    }

    // init value
    tb_size_t seed1 = 0x7fed7fed;  
    tb_size_t seed2 = 0Xeeeeeeee;  
    if (seed)
    {
        seed1 = s_table[(1 << 8) + seed] ^ (seed1 + seed2);  
        seed2 = seed + seed1 + seed2 + (seed2 << 5) + 3;  
    }

    // done
    tb_size_t byte = 0;  
    while (size--)
    {
        // get one byte
        byte = *data++;  

        // 0 << 8: hash type: 0
        // 1 << 8: hash type: 1
        // 2 << 8: hash type: 2
        seed1 = s_table[(1 << 8) + byte] ^ (seed1 + seed2);  
        seed2 = byte + seed1 + seed2 + (seed2 << 5) + 3;  
    }

    // ok
    return seed1;  
}
tb_size_t tb_blizzard_make_from_cstr(tb_char_t const* cstr, tb_size_t seed)
{
    // check
    tb_assert_and_check_return_val(cstr, 0);

    // make it
    return tb_blizzard_make((tb_byte_t const*)cstr, tb_strlen(cstr) + 1, seed);
}
