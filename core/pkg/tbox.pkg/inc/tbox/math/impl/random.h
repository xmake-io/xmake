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
 * @file        random.h
 *
 */
#ifndef TB_MATH_IMPL_RANDOM_H
#define TB_MATH_IMPL_RANDOM_H

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

// the random type enum
typedef enum __tb_random_type_e
{
    TB_RANDOM_TYPE_NONE       = 0
,   TB_RANDOM_TYPE_LINEAR     = 1

}tb_random_type_e;

// the random impl type
typedef struct __tb_random_impl_t
{
    // the type
    tb_size_t           type;

    // exit 
    tb_void_t           (*exit)(struct __tb_random_impl_t* random);

    // seed
    tb_void_t           (*seed)(struct __tb_random_impl_t* random, tb_size_t seed);

    // clear
    tb_void_t           (*clear)(struct __tb_random_impl_t* random);

    // range
    tb_long_t           (*range)(struct __tb_random_impl_t* random, tb_long_t beg, tb_long_t end);

}tb_random_impl_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */

/* init the linear random
 *
 * @param seed          the seed
 *
 * @return              the random
 */
tb_random_impl_t*       tb_random_linear_init(tb_size_t seed);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
