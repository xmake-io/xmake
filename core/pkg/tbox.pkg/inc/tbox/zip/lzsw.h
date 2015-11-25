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
 * @file        lzsw.h
 * @ingroup     zip
 *
 */
#ifndef TB_STREAM_ZSTREAM_LZSW_H
#define TB_STREAM_ZSTREAM_LZSW_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// vlc 
#define TB_LZSW_VLC_TYPE_FIXED          (0)
#define TB_LZSW_VLC_TYPE_GAMMA          (1)
#define TB_LZSW_VLC_TYPE_GOLOMB         (0)

// window
//#define TB_LZSW_WINDOW_SIZE_MAX       (256)
//#define TB_LZSW_WINDOW_SIZE_MAX       (4096)
#define TB_LZSW_WINDOW_SIZE_MAX         (65536)
//#define TB_LZSW_WINDOW_SIZE_MAX       (8)

#define TB_LZSW_WINDOW_HASH_FIND        (1)
#define TB_LZSW_WINDOW_HASH_MAX         (768)   // (256 + 256 + 256)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

#if TB_LZSW_WINDOW_HASH_FIND
// the node type
typedef struct __tb_lzsw_node_t
{
    // the signature
    tb_byte_t                   sign[4];

    // the circle offset
    tb_size_t                   coff;

    // the global address
    tb_byte_t const*            addr;

    // the next & prev
    tb_size_t                   prev;
    tb_size_t                   next;

}tb_lzsw_node_t;
#endif

// the inflate window type
typedef struct __tb_lzsw_inflate_window_t
{
    // the window rage
    tb_byte_t const*            we;
    tb_size_t                   wn;

    // the window bits
    tb_size_t                   wb;
    tb_size_t                   mb;

}tb_lzsw_inflate_window_t;


// the deflate window type
typedef struct __tb_lzsw_deflate_window_t
{
    // the window rage
    tb_byte_t const*            we;
    tb_size_t                   wn;

    // the window bits
    tb_size_t                   wb;
    tb_size_t                   mb;

#if TB_LZSW_WINDOW_HASH_FIND
    // the circle base
    tb_size_t                   base;

    // the window hash
    tb_pointer_t                        pool;
    tb_size_t                   hash[TB_LZSW_WINDOW_HASH_MAX];
#endif

}tb_lzsw_deflate_window_t;


// the lzsw inflate zstream type
typedef struct __tb_lzsw_inflate_stream_filter_zip_t
{
    // the stream base
    tb_inflate_stream_filter_zip_t        base;

    // the reference to vlc
    tb_stream_filter_zip_vlc_t*           vlc;

    // the window 
    tb_lzsw_inflate_window_t    window;

}tb_lzsw_inflate_stream_filter_zip_t;

// the lzsw deflate zstream type
typedef struct __tb_lzsw_deflate_stream_filter_zip_t
{
    // the stream base
    tb_deflate_stream_filter_zip_t        base;

    // the reference to vlc
    tb_stream_filter_zip_vlc_t*           vlc;

    // the window 
    tb_lzsw_deflate_window_t    window;

}tb_lzsw_deflate_stream_filter_zip_t;


// the lzsw zstream type
typedef union __tb_lzsw_stream_filter_zip_t
{
    tb_lzsw_inflate_stream_filter_zip_t   infst;
    tb_lzsw_deflate_stream_filter_zip_t   defst;

}tb_lzsw_stream_filter_zip_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

tb_stream_filter_t*   tb_stream_filter_zip_open_lzsw_inflate(tb_lzsw_inflate_stream_filter_zip_t* zst);
tb_stream_filter_t*   tb_stream_filter_zip_open_lzsw_deflate(tb_lzsw_deflate_stream_filter_zip_t* zst);
tb_stream_filter_t*   tb_stream_filter_zip_open_lzsw(tb_lzsw_stream_filter_zip_t* zst, tb_size_t action);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

