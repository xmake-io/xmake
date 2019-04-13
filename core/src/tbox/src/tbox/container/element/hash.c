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
 * @file        hash.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "hash.h"
#include "../../hash/hash.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * data hash implementation
 */
static tb_size_t tb_element_hash_data_func_0(tb_byte_t const* data, tb_size_t size)
{
    return tb_bkdr_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_1(tb_byte_t const* data, tb_size_t size)
{
    return tb_adler32_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_2(tb_byte_t const* data, tb_size_t size)
{
    return tb_fnv32_1a_make(data, size, 0);
}
#if !defined(__tb_small__) && defined(TB_CONFIG_MODULE_HAVE_HASH)
static tb_size_t tb_element_hash_data_func_3(tb_byte_t const* data, tb_size_t size)
{
    return tb_ap_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_4(tb_byte_t const* data, tb_size_t size)
{
    return tb_murmur_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_5(tb_byte_t const* data, tb_size_t size)
{
    return tb_crc32_le_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_6(tb_byte_t const* data, tb_size_t size)
{
    return tb_fnv32_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_7(tb_byte_t const* data, tb_size_t size)
{
    return tb_djb2_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_8(tb_byte_t const* data, tb_size_t size)
{
    return tb_blizzard_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_9(tb_byte_t const* data, tb_size_t size)
{
    return tb_rs_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_10(tb_byte_t const* data, tb_size_t size)
{
    return tb_sdbm_make(data, size, 0);
}
static tb_size_t tb_element_hash_data_func_11(tb_byte_t const* data, tb_size_t size)
{
    // using md5, better but too slower
    tb_byte_t b[16] = {0};
    tb_md5_make(data, size, b, 16);
    return tb_bits_get_u32_ne(b);
}
static tb_size_t tb_element_hash_data_func_12(tb_byte_t const* data, tb_size_t size)
{
    // using sha, better but too slower
    tb_byte_t b[32] = {0};
    tb_sha_make(TB_SHA_MODE_SHA1_160, data, size, b, 32);
    return tb_bits_get_u32_ne(b);
}
static tb_size_t tb_element_hash_data_func_13(tb_byte_t const* data, tb_size_t size)
{
    tb_trace_noimpl();
    return 0;
}
static tb_size_t tb_element_hash_data_func_14(tb_byte_t const* data, tb_size_t size)
{
    tb_trace_noimpl();
    return 0;
}
static tb_size_t tb_element_hash_data_func_15(tb_byte_t const* data, tb_size_t size)
{
    tb_trace_noimpl();
    return 0;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * cstr hash implementation
 */
static tb_size_t tb_element_hash_cstr_func_0(tb_char_t const* data)
{
    return tb_bkdr_make_from_cstr(data, 0);
}
static tb_size_t tb_element_hash_cstr_func_1(tb_char_t const* data)
{
    return tb_fnv32_1a_make_from_cstr(data, 0);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * uint8 hash implementation
 */
static tb_size_t tb_element_hash_uint8_func_0(tb_uint8_t value)
{
    return (tb_size_t)value;
}
static tb_size_t tb_element_hash_uint8_func_1(tb_uint8_t value)
{
    return (tb_size_t)(((tb_uint64_t)(value) * 2654435761ul) >> 16);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * uint16 hash implementation
 */
static tb_size_t tb_element_hash_uint16_func_0(tb_uint16_t value)
{
    return (tb_size_t)(((tb_uint64_t)(value) * 2654435761ul) >> 16);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * uint32 hash implementation
 */
static tb_size_t tb_element_hash_uint32_func_0(tb_uint32_t value)
{
    return (tb_size_t)(((tb_uint64_t)(value) * 2654435761ul) >> 16);
}
static tb_size_t tb_element_hash_uint32_func_1(tb_uint32_t value)
{
    // Bob Jenkins' 32 bit integer hash function
    value = (value + 0x7ed55d16) + (value << 12); 
    value = (value ^ 0xc761c23c) ^ (value >> 19); 
    value = (value + 0x165667b1) + (value << 5); 
    value = (value + 0xd3a2646c) ^ (value << 9); 
    value = (value + 0xfd7046c5) + (value << 3);
    value = (value ^ 0xb55a4f09) ^ (value >> 16);  
    return value;
}
static tb_size_t tb_element_hash_uint32_func_2(tb_uint32_t value)
{
    // Tomas Wang
    value = ~value + (value << 15);
    value = value ^ (value >> 12); 
    value = value + (value << 2); 
    value = value ^ (value >> 4); 
    value = value * 2057;
    value = value ^ (value >> 16); 
    return value;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * uint64 hash implementation
 */
static tb_size_t tb_element_hash_uint64_func_0(tb_uint64_t value)
{
    return (tb_size_t)((value * 2654435761ul) >> 16);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_element_hash_uint8(tb_uint8_t value, tb_size_t mask, tb_size_t index)
{
    // check
    tb_assert_and_check_return_val(mask, 0);

    // for optimization
    if (index < 2)
    {
        // the func
        static tb_size_t (*s_func[])(tb_uint8_t) = 
        {
            tb_element_hash_uint8_func_0
        ,   tb_element_hash_uint8_func_1
        };
        tb_assert_and_check_return_val(index < tb_arrayn(s_func), 0);

        // done
        return s_func[index](value) & mask;
    }

    // using uint32 hash
    tb_uint32_t v = (tb_uint32_t)value;
    return tb_element_hash_uint32(v | (v << 8) | (v << 16) | (v << 24), mask, index - 1);
}
tb_size_t tb_element_hash_uint16(tb_uint16_t value, tb_size_t mask, tb_size_t index)
{
    // check
    tb_assert_and_check_return_val(mask, 0);

    // for optimization
    if (index < 1)
    {
        // the func
        static tb_size_t (*s_func[])(tb_uint16_t) = 
        {
            tb_element_hash_uint16_func_0
        };
        tb_assert_and_check_return_val(index < tb_arrayn(s_func), 0);

        // done
        return s_func[index](value) & mask;
    }

    // using uint32 hash
    tb_uint32_t v = (tb_uint32_t)value;
    return tb_element_hash_uint32(v | (v << 16), mask, index);
}
tb_size_t tb_element_hash_uint32(tb_uint32_t value, tb_size_t mask, tb_size_t index)
{
    // check
    tb_assert_and_check_return_val(mask, 0);

    // for optimization
    if (index < 3)
    {
        // the func
        static tb_size_t (*s_func[])(tb_uint32_t) = 
        {
            tb_element_hash_uint32_func_0
        ,   tb_element_hash_uint32_func_1
        ,   tb_element_hash_uint32_func_2
        };
        tb_assert_and_check_return_val(index < tb_arrayn(s_func), 0);

        // done
        return s_func[index](value) & mask;
    }

    // done
    return tb_element_hash_data((tb_byte_t const*)&value, sizeof(tb_uint32_t), mask, index - 3);
}
tb_size_t tb_element_hash_uint64(tb_uint64_t value, tb_size_t mask, tb_size_t index)
{
    // for optimization
    if (index < 1)
    {
        // the func
        static tb_size_t (*s_func[])(tb_uint64_t) = 
        {
            tb_element_hash_uint64_func_0
        };
        tb_assert_and_check_return_val(index < tb_arrayn(s_func), 0);

        // done
        return s_func[index](value) & mask;
    }

    // using the uint32 hash
    tb_size_t hash0 = tb_element_hash_uint32((tb_uint32_t)value, mask, index);
    tb_size_t hash1 = tb_element_hash_uint32((tb_uint32_t)(value >> 32), mask, index);
    return ((hash0 ^ hash1) & mask);
}
tb_size_t tb_element_hash_data(tb_byte_t const* data, tb_size_t size, tb_size_t mask, tb_size_t index)
{
    // check
    tb_assert_and_check_return_val(data && size && mask, 0);

    // the func
    static tb_size_t (*s_func[])(tb_byte_t const* , tb_size_t) = 
    {
        tb_element_hash_data_func_0
    ,   tb_element_hash_data_func_1
    ,   tb_element_hash_data_func_2
#if !defined(__tb_small__) && defined(TB_CONFIG_MODULE_HAVE_HASH)
    ,   tb_element_hash_data_func_3
    ,   tb_element_hash_data_func_4
    ,   tb_element_hash_data_func_5
    ,   tb_element_hash_data_func_6
    ,   tb_element_hash_data_func_7
    ,   tb_element_hash_data_func_8
    ,   tb_element_hash_data_func_9
    ,   tb_element_hash_data_func_10
    ,   tb_element_hash_data_func_11
    ,   tb_element_hash_data_func_12
    ,   tb_element_hash_data_func_13
    ,   tb_element_hash_data_func_14
    ,   tb_element_hash_data_func_15
#endif
    };
    tb_assert_and_check_return_val(index < tb_arrayn(s_func), 0);

    // done
    return s_func[index](data, size) & mask;
}
tb_size_t tb_element_hash_cstr(tb_char_t const* cstr, tb_size_t mask, tb_size_t index)
{
    // check
    tb_assert_and_check_return_val(cstr && mask, 0);

    // for optimization
    if (index < 2)
    {
        // the func
        static tb_size_t (*s_func[])(tb_char_t const*) = 
        {
            tb_element_hash_cstr_func_0
        ,   tb_element_hash_cstr_func_1
        };
        tb_assert_and_check_return_val(index < tb_arrayn(s_func), 0);

        // done
        return s_func[index](cstr) & mask;
    }

    // using the data hash
    return tb_element_hash_data((tb_byte_t const*)cstr, tb_strlen(cstr), mask, index);
}
