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
 * @file        vlc.h
 * @ingroup     zip
 *
 */
#ifndef TB_ZIP_VLC_H
#define TB_ZIP_VLC_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// adaptive golomb coding
#define TB_ZIP_VLC_GOLOMB_ADAPTIVE

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the callback type
struct __tb_zip_vlc_t;
typedef tb_void_t       (*tb_zip_vlc_set_t)(struct __tb_zip_vlc_t* vlc, tb_uint32_t val, tb_static_stream_ref_t sstream);
typedef tb_uint32_t     (*tb_zip_vlc_get_t)(struct __tb_zip_vlc_t* vlc, tb_static_stream_ref_t sstream);
typedef tb_void_t       (*tb_zip_vlc_clos_t)(struct __tb_zip_vlc_t* vlc);

// the vlc type
typedef enum __tb_zip_vlc_type_t
{
    TB_ZIP_VLC_TYPE_FIXED   = 0
,   TB_ZIP_VLC_TYPE_GOLOMB  = 1
,   TB_ZIP_VLC_TYPE_GAMMA   = 2

}tb_zip_vlc_type_t;

// the variable length coding type
typedef struct __tb_zip_vlc_t
{
    // the vlc type
    tb_size_t           type;

    // set value to the bits stream
    tb_zip_vlc_set_t    set;

    // get value from the bits stream
    tb_zip_vlc_get_t    get;

    // close it
    tb_zip_vlc_clos_t   clos;

}tb_zip_vlc_t;


// the fixed length coding type
typedef struct __tb_zip_vlc_fixed_t
{
    // the base
    tb_zip_vlc_t        base;

    // the bits
    tb_byte_t           nbits;

}tb_zip_vlc_fixed_t;

// the gamma length coding type
typedef struct __tb_zip_vlc_gamma_t
{
    // the base
    tb_zip_vlc_t        base;

}tb_zip_vlc_gamma_t;

// the golomb length coding type
typedef struct __tb_zip_vlc_golomb_t
{
    // the base
    tb_zip_vlc_t        base;
    
    // the m value
    tb_size_t           defm;

#ifdef TB_ZIP_VLC_GOLOMB_ADAPTIVE
    // for computing the average value
    tb_size_t           total;
    tb_size_t           count;
#endif

}tb_zip_vlc_golomb_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

tb_zip_vlc_t* tb_zip_vlc_gamma_open(tb_zip_vlc_gamma_t* gamma);
tb_zip_vlc_t* tb_zip_vlc_golomb_open(tb_zip_vlc_golomb_t* golomb, tb_size_t defm);
tb_zip_vlc_t* tb_zip_vlc_fixed_open(tb_zip_vlc_fixed_t* fixed, tb_byte_t nbits);

#endif
