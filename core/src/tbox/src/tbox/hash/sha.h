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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        sha.h
 * @ingroup     hash
 *
 */
#ifndef TB_HASH_SHA_H
#define TB_HASH_SHA_H

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

/*! make sha 
 *
 * @param ib            the input data
 * @param in            the input size
 * @param ob            the output data
 * @param on            the output size
 *
 * @return              the real size
 */
tb_size_t               tb_sha_make(tb_size_t mode, tb_byte_t const* ib, tb_size_t ip, tb_byte_t* ob, tb_size_t on);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

