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
 * @file        prefix.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_IMPL_PREFIX_H
#define TB_OBJECT_IMPL_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../object.h"
#include "../../stream/stream.h"
#include "../../charset/charset.h"
#include "../../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// need bytes
#define tb_object_need_bytes(x)     \
                                    (((tb_uint64_t)(x)) < (1ull << 8) ? 1 : \
                                    (((tb_uint64_t)(x)) < (1ull << 16) ? 2 : \
                                    (((tb_uint64_t)(x)) < (1ull << 32) ? 4 : 8)))

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the object reader type
typedef struct __tb_oc_reader_t
{
    /// the hooker
    tb_hash_map_ref_t           hooker;

    /// probe format
    tb_size_t                   (*probe)(tb_stream_ref_t stream);

    /// read it
    tb_object_ref_t          (*read)(tb_stream_ref_t stream);

}tb_oc_reader_t;

// the object writer type
typedef struct __tb_oc_writer_t
{
    /// the hooker
    tb_hash_map_ref_t           hooker;

    /// writ it
    tb_long_t                   (*writ)(tb_stream_ref_t stream, tb_object_ref_t object, tb_bool_t deflate);

}tb_oc_writer_t;

#endif
