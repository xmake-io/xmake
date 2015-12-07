/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed ip the hope that it will be useful,
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
 * @file        sha.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_SHA_H
#define TB_UTILS_SHA_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// data structure for sha (message data) computation 
typedef struct __tb_sha_t
{
    tb_uint8_t      digest_len;  //!< digest length in 32-bit words
    tb_hize_t       count;       //!< number of bytes in buffer
    tb_uint8_t      buffer[64];  //!< 512-bit buffer of input values used in hash updating
    tb_uint32_t     state[8];    //!< current hash value
    tb_void_t       (*transform)(tb_uint32_t *state, tb_uint8_t const buffer[64]);

}tb_sha_t;

// the sha mode type
typedef enum __tb_sha_mode_t
{
    TB_SHA_MODE_SHA1_160 = 160
,   TB_SHA_MODE_SHA2_224 = 224
,   TB_SHA_MODE_SHA2_256 = 256

}tb_sha_mode_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init sha 
 *
 * @param sha           the sha
 * @param mode          the mode
 */
tb_void_t               tb_sha_init(tb_sha_t* sha, tb_size_t mode);

/*! exit sha 
 *
 * @param sha           the sha
 * @param data          the data
 * @param size          the size
 */
tb_void_t               tb_sha_exit(tb_sha_t* sha, tb_byte_t* data, tb_size_t size);

/*! spak sha 
 *
 * @param sha           the sha
 * @param data          the data
 * @param size          the size
 */
tb_void_t               tb_sha_spak(tb_sha_t* sha, tb_byte_t const* data, tb_size_t size);

/*! encode sha 
 *
 * @param ib            the input data
 * @param in            the input size
 * @param ob            the output data
 * @param on            the output size
 *
 * @return              the real size
 */
tb_size_t               tb_sha_encode(tb_size_t mode, tb_byte_t const* ib, tb_size_t ip, tb_byte_t* ob, tb_size_t on);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

