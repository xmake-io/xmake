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
 * @file        md5.h
 * @ingroup     hash
 *
 */
#ifndef TB_HASH_MD5_H
#define TB_HASH_MD5_H

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

// data structure for md5 (message data) computation 
typedef struct __tb_md5_t
{
    tb_uint32_t     i[2];       //!< number of _bits_ handled mod 2^64 
    tb_uint32_t     sp[4];      //!< scratch buffer 
    tb_byte_t       ip[64];     //!< input buffer 
    tb_byte_t       data[16];   //!< actual data after tb_md5_exit call 

}tb_md5_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init md5 
 *
 * @param md5           the md5
 * @param pseudo_rand   the pseudo rand
 */
tb_void_t               tb_md5_init(tb_md5_t* md5, tb_uint32_t pseudo_rand);

/*! exit md5 
 *
 * @param md5           the md5
 * @param data          the data
 * @param size          the size
 */
tb_void_t               tb_md5_exit(tb_md5_t* md5, tb_byte_t* data, tb_size_t size);

/*! spak md5 
 *
 * @param md5           the md5
 * @param data          the data
 * @param size          the size
 */
tb_void_t               tb_md5_spak(tb_md5_t* md5, tb_byte_t const* data, tb_size_t size);

/*! make md5 
 *
 * @param ib            the input data
 * @param in            the input size
 * @param ob            the output data
 * @param on            the output size
 *
 * @return              the real size
 */
tb_size_t               tb_md5_make(tb_byte_t const* ib, tb_size_t in, tb_byte_t* ob, tb_size_t on);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

