/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        stream.h
 *
 */
#ifndef TB_STREAM_IMPL_STREAM_H
#define TB_STREAM_IMPL_STREAM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// cast stream
#define tb_stream_cast(stream)          ((stream)? &(((tb_stream_t*)(stream))[-1]) : tb_null)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the stream type
typedef struct __tb_stream_t
{   
    // the stream type
    tb_uint8_t          type;

    // is writed?
    tb_uint8_t          bwrited;

    // the url
    tb_url_t            url;

    /* the internal state for killing stream in the other thread
     *
     * <pre>
     * TB_STATE_CLOSED
     * TB_STATE_OPENED
     * TB_STATE_KILLED
     * TB_STATE_OPENING
     * TB_STATE_KILLING
     * </pre>
     */
    tb_atomic_t         istate;

    // the timeout
    tb_long_t           timeout;

    /* the stream state
     *
     * <pre>
     * TB_STATE_KILLED
     * TB_STATE_WAIT_FAILED
     * </pre>
     */
    tb_size_t           state;

    // the offset
    tb_hize_t           offset;

    // the cache
    tb_queue_buffer_t   cache;

    // wait 
    tb_long_t           (*wait)(tb_stream_ref_t stream, tb_size_t wait, tb_long_t timeout);

    // open
    tb_bool_t           (*open)(tb_stream_ref_t stream);

    // clos
    tb_bool_t           (*clos)(tb_stream_ref_t stream);

    // read
    tb_long_t           (*read)(tb_stream_ref_t stream, tb_byte_t* data, tb_size_t size);

    // writ
    tb_long_t           (*writ)(tb_stream_ref_t stream, tb_byte_t const* data, tb_size_t size);

    // seek
    tb_bool_t           (*seek)(tb_stream_ref_t stream, tb_hize_t offset);

    // sync
    tb_bool_t           (*sync)(tb_stream_ref_t stream, tb_bool_t bclosing);

    // ctrl 
    tb_bool_t           (*ctrl)(tb_stream_ref_t stream, tb_size_t ctrl, tb_va_list_t args);

    // exit
    tb_void_t           (*exit)(tb_stream_ref_t stream);

    // kill
    tb_void_t           (*kill)(tb_stream_ref_t stream);

}tb_stream_t;


#endif
