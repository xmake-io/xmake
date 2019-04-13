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
 * @file        writer.c
 * @ingroup     object
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "writer.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the object writer
static tb_oc_writer_t*  g_writer[TB_OBJECT_FORMAT_MAXN] = {tb_null};

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_oc_writer_set(tb_size_t format, tb_oc_writer_t* writer)
{
    // check
    format &= 0x00ff;
    tb_assert_and_check_return_val(writer && (format < tb_arrayn(g_writer)), tb_false);

    // exit the older writer if exists
    tb_oc_writer_remove(format);

    // set
    g_writer[format] = writer;

    // ok
    return tb_true;
}
tb_void_t tb_oc_writer_remove(tb_size_t format)
{
    // check
    format &= 0x00ff;
    tb_assert_and_check_return((format < tb_arrayn(g_writer)));

    // exit it
    if (g_writer[format])
    {
        // exit hooker
        if (g_writer[format]->hooker) tb_hash_map_exit(g_writer[format]->hooker);
        g_writer[format]->hooker = tb_null;
        
        // clear it
        g_writer[format] = tb_null;
    }
}
tb_oc_writer_t* tb_oc_writer_get(tb_size_t format)
{
    // check
    format &= 0x00ff;
    tb_assert_and_check_return_val((format < tb_arrayn(g_writer)), tb_null);

    // ok
    return g_writer[format];
}
tb_long_t tb_oc_writer_done(tb_object_ref_t object, tb_stream_ref_t stream, tb_size_t format)
{
    // check
    tb_assert_and_check_return_val(object && stream, -1);

    // the writer
    tb_oc_writer_t* writer = tb_oc_writer_get(format);
    tb_assert_and_check_return_val(writer && writer->writ, -1);

    // writ it
    return writer->writ(stream, object, (format & TB_OBJECT_FORMAT_DEFLATE)? tb_true : tb_false);
}
