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
 * @file        bloom_filter.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "bloom_filter"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "bloom_filter.h"
#include "../libc/libc.h"
#include "../libm/libm.h"
#include "../math/math.h"
#include "../utils/utils.h"
#include "../memory/memory.h"
#include "../stream/stream.h"
#include "../platform/platform.h"
#include "../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the data size maxn
#ifdef __tb_small__
#   define TB_BLOOM_FILTER_DATA_MAXN            (1 << 28)
#else
#   define TB_BLOOM_FILTER_DATA_MAXN            (1 << 30)
#endif

// the item default maxn
#ifdef __tb_small__
#   define TB_BLOOM_FILTER_ITEM_MAXN_DEFAULT    TB_BLOOM_FILTER_ITEM_MAXN_MICRO
#else
#   define TB_BLOOM_FILTER_ITEM_MAXN_DEFAULT    TB_BLOOM_FILTER_ITEM_MAXN_SMALL
#endif

// the bit sets
#define tb_bloom_filter_set1(data, i)           do {(data)[(i) >> 3] |= (0x1 << ((i) & 7));} while (0)
#define tb_bloom_filter_set0(data, i)           do {(data)[(i) >> 3] &= ~(0x1 << ((i) & 7));} while (0)
#define tb_bloom_filter_bset(data, i)           ((data)[(i) >> 3] & (0x1 << ((i) & 7)))

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the bloom filter type
typedef struct __tb_bloom_filter_t
{
    // the probability
    tb_size_t           probability;

    // the hash count
    tb_size_t           hash_count;

    // the maxn
    tb_size_t           maxn;

    // the element
    tb_element_t        element;

    // the size
    tb_size_t           size;

    // the data
    tb_byte_t*          data;

    // the hash mask
    tb_size_t           mask;

}tb_bloom_filter_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bloom_filter_ref_t tb_bloom_filter_init(tb_size_t probability, tb_size_t hash_count, tb_size_t item_maxn, tb_element_t element)
{
    // check
    tb_assert_and_check_return_val(element.hash, tb_null);

    // done
    tb_bool_t           ok = tb_false;
    tb_bloom_filter_t*  filter = tb_null;
    do
    {
        // check 
        tb_assert_and_check_break(probability && probability < 32);
#ifdef __tb_small__
        tb_assert_and_check_break(hash_count && hash_count < 4);
#else
        tb_assert_and_check_break(hash_count && hash_count < 16);
#endif

        // check item maxn
        if (!item_maxn) item_maxn = TB_BLOOM_FILTER_ITEM_MAXN_DEFAULT;
        tb_assert_and_check_break(item_maxn < TB_MAXU32);

        // make filter
        filter = tb_malloc0_type(tb_bloom_filter_t);
        tb_assert_and_check_break(filter);
    
        // init filter
        filter->element     = element;
        filter->maxn        = item_maxn;
        filter->hash_count  = hash_count;
        filter->probability = probability;

        /* compute the storage space
         *
         * c = p^(1/k)
         * s = m / n = 2k / (2c + c * c)
         */
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
        tb_double_t k = (tb_double_t)hash_count;
        tb_double_t p = 1. / (tb_double_t)(1 << probability);
        tb_double_t c = tb_pow(p, 1 / k);
        tb_double_t s = (k + k) / (c + c + c * c);
        tb_size_t   n = item_maxn;
        tb_size_t   m = tb_round(s * n);
        tb_trace_d("k: %lf, p: %lf, c: %lf, s: %lf => p: %lf, m: %lu, n: %lu", k, p, c, s, tb_pow((1 - tb_exp(-k / s)), k), m, n);
#else

#if 0
        // make scale table
        tb_size_t i = 0;
        for (i = 1; i < 16; i++)
        {
            tb_printf(",\t{ ");
            tb_size_t j = 0;
            for (j = 0; j < 31; j++)
            {
                tb_double_t k = (tb_double_t)i;
                tb_double_t p = 1. / (tb_double_t)(1 << j);
                tb_double_t c = tb_pow(p, 1 / k);
                tb_double_t s = (k + k) / (c + c + c * c);
                if (j != 30) tb_printf("%#010x, ", tb_float_to_fixed(s));
                else tb_printf("%#010x }\n", tb_float_to_fixed(s));
            }
        }
#endif
        // the scale
        static tb_size_t s_scale[15][31] =
        {
            { 0x0000aaaa, 0x00019999, 0x00038e38, 0x00078787, 0x000f83e0, 0x001f81f8, 0x003f80fe, 0x007f807f, 0x00ff803f, 0x01ff801f, 0x03ff800f, 0x07ff8007, 0x0fff8003, 0x1fff8001, 0x3fff8000, 0x7fff8000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000 }
        ,   { 0x00015555, 0x000216f2, 0x00033333, 0x0004ce9c, 0x00071c71, 0x000a6519, 0x000f0f0f, 0x0015ab74, 0x001f07c1, 0x002c46c5, 0x003f03f0, 0x00598545, 0x007f01fc, 0x00b4065b, 0x00ff00ff, 0x01690a9a, 0x01ff007f, 0x02d31427, 0x03ff003f, 0x05a727c6, 0x07ff001f, 0x0b4f4f49, 0x0fff000f, 0x169f9e71, 0x1fff0007, 0x2d403cd2, 0x3fff0003, 0x5a81799c, 0x7fff0001, 0x80000000, 0x80000000 }
        ,   { 0x00020000, 0x0002b4b7, 0x00039f1a, 0x0004cccc, 0x00064ed1, 0x00083a7e, 0x000aaaaa, 0x000dc122, 0x0011a886, 0x00169696, 0x001ccf1a, 0x0024a789, 0x002e8ba2, 0x003b0334, 0x004ab965, 0x005e85e8, 0x00777886, 0x0096e7b6, 0x00be82fa, 0x00f06a01, 0x012f49d1, 0x017e817e, 0x01e25077, 0x026010d0, 0x02fe80bf, 0x03c61f26, 0x04c1a037, 0x05fe805f, 0x078dbd69, 0x0984bfba, 0x0bfe802f }
        ,   { 0x0002aaaa, 0x0003594c, 0x00042de4, 0x00052f7d, 0x00066666, 0x0007dc6f, 0x00099d38, 0x000bb692, 0x000e38e3, 0x001137b0, 0x0014ca32, 0x00190c0b, 0x001e1e1e, 0x0024278c, 0x002b56e8, 0x0033e397, 0x003e0f83, 0x004a2914, 0x00588d8b, 0x0069abd5, 0x007e07e0, 0x00963e94, 0x00b30a8b, 0x00d549b3, 0x00fe03f8, 0x012e7338, 0x01680cb6, 0x01ac8c57, 0x01fe01fe, 0x025ee16e, 0x02d21535 }
        ,   { 0x00035555, 0x0004006d, 0x0004c8d7, 0x0005b2de, 0x0006c365, 0x00080000, 0x00096f0f, 0x000b17e2, 0x000d02d9, 0x000f3993, 0x0011c71c, 0x0014b825, 0x00181b43, 0x001c013a, 0x00207d4e, 0x0025a5a5, 0x002b93b2, 0x003264b4, 0x003a3a48, 0x00433b0d, 0x004d9364, 0x0059764a, 0x00671e54, 0x0076cecd, 0x0088d509, 0x009d89d8, 0x00b55345, 0x00d0a688, 0x00f00a47, 0x01141931, 0x013d84f6 }
        ,   { 0x00040000, 0x0004a8c7, 0x0005696e, 0x000644d6, 0x00073e35, 0x00085921, 0x00099999, 0x000b0419, 0x000c9da2, 0x000e6bd5, 0x001074fd, 0x0012c02d, 0x00155555, 0x00183d5c, 0x001b8245, 0x001f2f4c, 0x0023510d, 0x0027f5b5, 0x002d2d2d, 0x00330952, 0x00399e34, 0x0041025c, 0x00494f13, 0x0052a0c0, 0x005d1745, 0x0068d66e, 0x00760668, 0x0084d450, 0x009572cb, 0x00a81ab0, 0x00bd0bd0 }
        ,   { 0x0004aaaa, 0x000551d0, 0x00060d16, 0x0006de8d, 0x0007c87b, 0x0008cd5c, 0x0009efee, 0x000b3333, 0x000c9a7b, 0x000e296d, 0x000fe410, 0x0011ced6, 0x0013eea3, 0x001648e3, 0x0018e38e, 0x001bc53c, 0x001ef538, 0x00227b8e, 0x00266121, 0x002aafc2, 0x002f724a, 0x0034b4b4, 0x003a843a, 0x0040ef7a, 0x00480696, 0x004fdb60, 0x00588189, 0x00620eca, 0x006c9b26, 0x0078411d, 0x00851df4 }
        ,   { 0x00055555, 0x0005fb45, 0x0006b298, 0x00077cdf, 0x00085bc8, 0x00095128, 0x000a5efb, 0x000b8769, 0x000ccccc, 0x000e31b1, 0x000fb8de, 0x0011655a, 0x00133a71, 0x00153bbc, 0x00176d24, 0x0019d2ef, 0x001c71c7, 0x001f4ebe, 0x00226f61, 0x0025d9bb, 0x00299465, 0x002da690, 0x00321817, 0x0036f188, 0x003c3c3c, 0x00420262, 0x00484f19, 0x004f2e80, 0x0056add0, 0x005edb76, 0x0067c72f }
        ,   { 0x00060000, 0x0006a500, 0x0007594f, 0x00081e25, 0x0008f4ce, 0x0009deb1, 0x000add50, 0x000bf249, 0x000d1f5a, 0x000e6666, 0x000fc972, 0x00114aad, 0x0012ec74, 0x0014b150, 0x00169c01, 0x0018af7c, 0x001aeef6, 0x001d5de3, 0x00200000, 0x0022d953, 0x0025ee3a, 0x00294368, 0x002cddf5, 0x0030c35e, 0x0034f994, 0x00398700, 0x003e7291, 0x0043c3c3, 0x004982ad, 0x004fb80b, 0x00566d4f }
        ,   { 0x0006aaaa, 0x00074eec, 0x000800da, 0x0008c16d, 0x000991af, 0x000a72ba, 0x000b65bd, 0x000c6bfa, 0x000d86ca, 0x000eb79e, 0x00100000, 0x00116194, 0x0012de1e, 0x00147782, 0x00162fc4, 0x0018090e, 0x001a05b2, 0x001c282d, 0x001e7327, 0x0020e97b, 0x00238e38, 0x002664a7, 0x0029704a, 0x002cb4e6, 0x00303686, 0x0033f97e, 0x00380274, 0x003c5662, 0x0040fa9d, 0x0045f4df, 0x004b4b4b }
        ,   { 0x00075555, 0x0007f8fb, 0x0008a8fc, 0x00096622, 0x000a3147, 0x000b0b4e, 0x000bf52c, 0x000cefe2, 0x000dfc83, 0x000f1c30, 0x0010501f, 0x00119999, 0x0012f9fb, 0x001472b9, 0x0016055f, 0x0017b390, 0x00197f0d, 0x001b69b3, 0x001d757e, 0x001fa48a, 0x0021f917, 0x0024758a, 0x00271c71, 0x0029f084, 0x002cf4a7, 0x00302bf1, 0x003399ab, 0x00374154, 0x003b26a9, 0x003f4da1, 0x0043ba79 }
        ,   { 0x00080000, 0x0008a325, 0x0009518e, 0x000a0be5, 0x000ad2dc, 0x000ba731, 0x000c89ac, 0x000d7b1f, 0x000e7c6a, 0x000f8e78, 0x0010b242, 0x0011e8ce, 0x00133333, 0x00149297, 0x00160832, 0x0017954d, 0x00193b45, 0x001afb8d, 0x001cd7aa, 0x001ed13d, 0x0020e9fb, 0x002323b6, 0x0025805b, 0x002801f4, 0x002aaaaa, 0x002d7cc8, 0x00307ab9, 0x0033a712, 0x0037048b, 0x003a9608, 0x003e5e98 }
        ,   { 0x0008aaaa, 0x00094d63, 0x0009fa76, 0x000ab273, 0x000b75f0, 0x000c458d, 0x000d21f2, 0x000e0bcc, 0x000f03d6, 0x00100ad2, 0x0011218b, 0x001248da, 0x001381a0, 0x0014cccc, 0x00162b5a, 0x00179e52, 0x001926cc, 0x001ac5ed, 0x001c7cec, 0x001e4d0f, 0x002037af, 0x00223e37, 0x00246228, 0x0026a515, 0x002908a8, 0x002b8ea4, 0x002e38e3, 0x0031095a, 0x00340218, 0x0037254b, 0x003a753f }
        ,   { 0x00095555, 0x0009f7b1, 0x000aa3a1, 0x000b599e, 0x000c1a2c, 0x000ce5d1, 0x000dbd1b, 0x000ea09e, 0x000f90f6, 0x00108ec6, 0x00119ab9, 0x0012b582, 0x0013dfdc, 0x00151a8e, 0x00166666, 0x0017c43d, 0x001934f6, 0x001ab982, 0x001c52db, 0x001e0209, 0x001fc821, 0x0021a647, 0x00239dac, 0x0025af91, 0x0027dd47, 0x002a2832, 0x002c91c7, 0x002f1b8b, 0x0031c71c, 0x00349629, 0x00378a79 }
        ,   { 0x000a0000, 0x000aa20c, 0x000b4d00, 0x000c0147, 0x000cbf51, 0x000d8793, 0x000e5a86, 0x000f38aa, 0x00102283, 0x0011189b, 0x00121b85, 0x00132bd7, 0x00144a30, 0x00157735, 0x0016b393, 0x00180000, 0x00195d38, 0x001acc02, 0x001c4d2d, 0x001de193, 0x001f8a17, 0x002147a6, 0x00231b39, 0x002505d5, 0x0027088c, 0x0029247a, 0x002b5acc, 0x002dacba, 0x00301b8e, 0x0032a89f, 0x00355555 }
        };

        // m = (s * n) >> 16
        tb_size_t m = tb_fixed_mul(s_scale[hash_count - 1][probability], item_maxn);
#endif
        
        // init size
        filter->size = tb_align8(m) >> 3;
        tb_assert_and_check_break(filter->size);
        if (filter->size > TB_BLOOM_FILTER_DATA_MAXN)
        {
            tb_trace_e("the need space too large, size: %lu, please decrease hash count and probability!", filter->size);
            break;
        }
        tb_trace_d("size: %lu", filter->size);

        // init data
        filter->data = tb_malloc0_bytes(filter->size);
        tb_assert_and_check_break(filter->data);

        // init hash mask
        filter->mask = tb_align_pow2((filter->size << 3)) - 1;
        tb_assert_and_check_break(filter->mask);

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (filter) tb_bloom_filter_exit((tb_bloom_filter_ref_t)filter);
        filter = tb_null;
    }

    // ok?
    return (tb_bloom_filter_ref_t)filter;
}
tb_void_t tb_bloom_filter_exit(tb_bloom_filter_ref_t self)
{
    // check
    tb_bloom_filter_t* filter = (tb_bloom_filter_t*)self;
    tb_assert_and_check_return(filter);

    // exit data
    if (filter->data) tb_free(filter->data);
    filter->data = tb_null;

    // exit it
    tb_free(filter);
}
tb_void_t tb_bloom_filter_clear(tb_bloom_filter_ref_t self)
{
    // check
    tb_bloom_filter_t* filter = (tb_bloom_filter_t*)self;
    tb_assert_and_check_return(filter);

    // clear it
    if (filter->data && filter->size) tb_memset(filter->data, 0, filter->size);
}
tb_bool_t tb_bloom_filter_set(tb_bloom_filter_ref_t self, tb_cpointer_t data)
{
    // check
    tb_bloom_filter_t* filter = (tb_bloom_filter_t*)self;
    tb_assert_and_check_return_val(filter, tb_false);

    // walk
    tb_size_t i = 0;
    tb_size_t n = filter->hash_count;
    tb_bool_t ok = tb_false;
    for (i = 0; i < n; i++)
    {
        // compute the bit index
        tb_size_t index = filter->element.hash(&filter->element, data, filter->mask, i);
        if (index >= (filter->size << 3)) index %= (filter->size << 3);

        // not exists? 
        if (!tb_bloom_filter_bset(filter->data, index)) 
        {
            // set it
            tb_bloom_filter_set1(filter->data, index);

            // ok
            ok = tb_true;
        }
    }

    // ok?
    return ok;
}
tb_bool_t tb_bloom_filter_get(tb_bloom_filter_ref_t self, tb_cpointer_t data)
{
    // check
    tb_bloom_filter_t* filter = (tb_bloom_filter_t*)self;
    tb_assert_and_check_return_val(filter, tb_false);

    // walk
    tb_size_t i = 0;
    tb_size_t n = filter->hash_count;
    for (i = 0; i < n; i++)
    {
        // compute the bit index
        tb_size_t index = filter->element.hash(&filter->element, data, filter->mask, i);
        if (index >= (filter->size << 3)) index %= (filter->size << 3);

        // not exists? break it
        if (!tb_bloom_filter_bset(filter->data, index)) break;
    }

    // ok?
    return (i == n)? tb_true : tb_false;
}

