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
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
 *
 * @author      ruki
 * @file        random.h
 *
 */
#ifndef TB_MATH_RANDOM_H
#define TB_MATH_RANDOM_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "linear.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! set the random seed
 *
 * @param seed      the random seed
 */
tb_void_t           tb_random_seed(tb_size_t seed);

/*! reset value using the initial seed
 *
 * @param pseudo    reset to the pseudo random?
 */
tb_void_t           tb_random_reset(tb_bool_t pseudo);

/*! generate the random value
 *
 * it will generate a pseudo-random sequence if the seed is not modified manually.
 *
 * @return          the random value
 */
tb_long_t           tb_random_value(tb_noarg_t);

/*! generate the random with range: [begin, end)
 *
 * @param begin     the begin value
 * @param end       the end value
 *
 * @return          the random value
 */
tb_long_t           tb_random_range(tb_long_t begin, tb_long_t end);

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
/*! generate the float random with range: [begin, end)
 *
 * @param begin     the begin value
 * @param end       the end value
 *
 * @return          the random value
 */
tb_float_t          tb_random_rangef(tb_float_t begin, tb_float_t end);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
