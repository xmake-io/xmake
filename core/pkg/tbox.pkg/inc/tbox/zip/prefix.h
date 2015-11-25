/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
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
#include "vlc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the zip action type
typedef enum __tb_zip_action_t
{
    TB_ZIP_ACTION_NULL      = 0
,   TB_ZIP_ACTION_INFLATE   = 1
,   TB_ZIP_ACTION_DEFLATE   = 2

}tb_zip_action_t;

// the zip algorithm type
typedef enum __tb_zip_algo_t
{
    TB_ZIP_ALGO_NONE        = 0     //!< null
,   TB_ZIP_ALGO_RLC         = 1     //!< run length coding
,   TB_ZIP_ALGO_HUFFMAN     = 2     //!< adaptive huffman
,   TB_ZIP_ALGO_LZSW        = 3     //!< sliding window .e.g lz77 lzss ...
,   TB_ZIP_ALGO_LZPD        = 4     //!< phrase dictionary .e.g lzw lz78 ...
,   TB_ZIP_ALGO_ZLIBRAW     = 5     //!< zlib: raw inflate & deflate
,   TB_ZIP_ALGO_ZLIB        = 6     //!< zlib
,   TB_ZIP_ALGO_GZIP        = 7     //!< gnu zip
,   TB_ZIP_ALGO_ARITHMETIC  = 8     //!< arithmetic coding

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

    // the vlc 
    union __tb_zip_vlc_union_t
    {
        tb_zip_vlc_fixed_t  fixed;
        tb_zip_vlc_golomb_t golomb;
        tb_zip_vlc_gamma_t  gamma;

    }vlc;

}tb_zip_t;

/// the zip ref type
typedef tb_zip_t*           tb_zip_ref_t;           


#endif
