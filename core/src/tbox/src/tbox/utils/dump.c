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
 * @file        dump.c
 * @ingroup     utils
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "dump.h"
#include "../stream/stream.h"
#include "../platform/platform.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_dump_data(tb_byte_t const* data, tb_size_t size)
{
    // check
    tb_assert_and_check_return(data && size);

    // dump head
    tb_trace_i("");

    // walk
    tb_size_t           i = 0;
    tb_size_t           n = 147;
    tb_byte_t const*    p = data;
    tb_byte_t const*    e = data + size;
    tb_char_t           info[8192];
    while (p < e)
    {
        // full line?
        tb_char_t* q = info;
        tb_char_t* d = info + sizeof(info);
        if (p + 0x20 <= e)
        {
            // dump offset
            if (q < d) q += tb_snprintf(q, d - q, "%08X ", p - data);

            // dump data
            for (i = 0; i < 0x20; i++)
            {
                if (!(i & 3) && q < d) q += tb_snprintf(q, d - q, " ");
                if (q < d) q += tb_snprintf(q, d - q, " %02X", p[i]);
            }

            // dump spaces
            if (q < d) q += tb_snprintf(q, d - q, "  ");

            // dump characters
            for (i = 0; i < 0x20; i++)
            {
                if (q < d) q += tb_snprintf(q, d - q, "%c", tb_isgraph(p[i])? p[i] : '.');
            }

            // dump it
            if (q < d)
            {
                // end
                *q = '\0';

                // trace
                tb_trace_i("%s", info);
            }

            // update p
            p += 0x20;
        }
        // has left?
        else if (p < e)
        {
            // init padding
            tb_size_t padding = n - 0x20;

            // dump offset
            if (q < d) q += tb_snprintf(q, d - q, "%08X ", p - data); 
            if (padding >= 9) padding -= 9;

            // dump data
            tb_size_t left = e - p;
            for (i = 0; i < left; i++)
            {
                if (!(i & 3)) 
                {
                    if (q < d) q += tb_snprintf(q, d - q, " ");
                    if (padding) padding--;
                }

                if (q < d) q += tb_snprintf(q, d - q, " %02X", p[i]);
                if (padding >= 3) padding -= 3;
            }

            // dump spaces
            while (padding--) if (q < d) q += tb_snprintf(q, d - q, " ");
                
            // dump characters
            for (i = 0; i < left; i++)
            {
                if (q < d) q += tb_snprintf(q, d - q, "%c", tb_isgraph(p[i])? p[i] : '.');
            }

            // dump it
            if (q < d)
            {
                // end
                *q = '\0';

                // trace
                tb_trace_i("%s", info);
            }

            // update p
            p += left;
        }
        // end
        else break;
    }
}
