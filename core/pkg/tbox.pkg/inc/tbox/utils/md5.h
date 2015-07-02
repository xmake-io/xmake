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
 * @file        md5.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_MD5_H
#define TB_UTILS_MD5_H

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

/*! encode md5 
 *
 * @param ib            the input data
 * @param in            the input size
 * @param ob            the output data
 * @param on            the output size
 *
 * @return              the real size
 */
tb_size_t               tb_md5_encode(tb_byte_t const* ib, tb_size_t in, tb_byte_t* ob, tb_size_t on);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

