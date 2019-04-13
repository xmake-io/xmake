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
 * @file        reader.c
 * @ingroup     object
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "reader.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the object reader
static tb_oc_reader_t*  g_reader[TB_OBJECT_FORMAT_MAXN] = {tb_null};

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_oc_reader_set(tb_size_t format, tb_oc_reader_t* reader)
{
    // check
    format &= 0x00ff;
    tb_assert_and_check_return_val(reader && (format < tb_arrayn(g_reader)), tb_false);

    // exit the older reader if exists
    tb_oc_reader_remove(format);

    // set
    g_reader[format] = reader;

    // ok
    return tb_true;
}
tb_void_t tb_oc_reader_remove(tb_size_t format)
{
    // check
    format &= 0x00ff;
    tb_assert_and_check_return((format < tb_arrayn(g_reader)));

    // exit it
    if (g_reader[format])
    {
        // exit hooker
        if (g_reader[format]->hooker) tb_hash_map_exit(g_reader[format]->hooker);
        g_reader[format]->hooker = tb_null;
        
        // clear it
        g_reader[format] = tb_null;
    }
}
tb_oc_reader_t* tb_oc_reader_get(tb_size_t format)
{
    // check
    format &= 0x00ff;
    tb_assert_and_check_return_val((format < tb_arrayn(g_reader)), tb_null);

    // ok
    return g_reader[format];
}
tb_object_ref_t tb_oc_reader_done(tb_stream_ref_t stream)
{
    // check
    tb_assert_and_check_return_val(stream, tb_null);

    // probe it
    tb_size_t i = 0;
    tb_size_t n = tb_arrayn(g_reader);
    tb_size_t m = 0;
    tb_size_t f = 0;
    for (i = 0; i < n && m < 100; i++)
    {
        // the reader
        tb_oc_reader_t* reader = g_reader[i];
        if (reader && reader->probe)
        {
            // the probe score
            tb_size_t score = reader->probe(stream);
            if (score > m) 
            {
                m = score;
                f = i;
            }
        }
    }

    // ok? read it
    return (m && g_reader[f] && g_reader[f]->read)? g_reader[f]->read(stream) : tb_null;
}
