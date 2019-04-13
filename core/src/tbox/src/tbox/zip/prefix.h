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
 *
 */
#ifndef TB_ZIP_PREFIX_H
#define TB_ZIP_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../stream/static_stream.h"
#include "../memory/memory.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the zip action type
typedef enum __tb_zip_action_t
{
    TB_ZIP_ACTION_NONE      = 0
,   TB_ZIP_ACTION_INFLATE   = 1
,   TB_ZIP_ACTION_DEFLATE   = 2

}tb_zip_action_t;

// the zip algorithm type
typedef enum __tb_zip_algo_t
{
    TB_ZIP_ALGO_NONE        = 0     //!< none
,   TB_ZIP_ALGO_ZLIBRAW     = 1     //!< zlib: raw inflate & deflate
,   TB_ZIP_ALGO_ZLIB        = 2     //!< zlib
,   TB_ZIP_ALGO_GZIP        = 3     //!< gnu zip

}tb_zip_algo_t;

// the zip type
typedef struct __tb_zip_t
{
    // the algorithm
    tb_uint16_t             algo;

    // the action
    tb_uint16_t             action;

    // spak
    tb_long_t               (*spak)(struct __tb_zip_t* zip, tb_static_stream_ref_t ist, tb_static_stream_ref_t ost, tb_long_t sync);

}tb_zip_t;

/// the zip ref type
typedef tb_zip_t*           tb_zip_ref_t;           


#endif
