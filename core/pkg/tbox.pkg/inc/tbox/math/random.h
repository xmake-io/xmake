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
 * @ingroup     math
 *
 */
#ifndef TB_MATH_RANDOM_H
#define TB_MATH_RANDOM_H

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

/// the random ref type
typedef struct{}*   tb_random_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init random
 * 
 * @param type      the random type
 * @param seed      the random seed
 *
 * @return          the random
 */
tb_random_ref_t     tb_random_init(tb_size_t type, tb_size_t seed);

/*! exit random
 *
 * @param random    the random
 */
tb_void_t           tb_random_exit(tb_random_ref_t random);

/*! update random seed
 *
 * @param random    the random, using the default random if be null
 * @param seed      the random seed
 */
tb_void_t           tb_random_seed(tb_random_ref_t random, tb_size_t seed);

/*! clear cache value and reset to the initial value
 *
 * @param random    the random, using the default random if be null
 */
tb_void_t           tb_random_clear(tb_random_ref_t random);

/*! generate the random with range: [beg, end)
 *
 * @param random    the random, using the default random if be null
 * @param beg       the begin value
 * @param end       the end value
 *
 * @return          the random value
 */
tb_long_t           tb_random_range(tb_random_ref_t random, tb_long_t beg, tb_long_t end);

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
/*! generate the float random with range: [beg, end)
 *
 * @param random    the random, using the default random if be null
 * @param beg       the begin value
 * @param end       the end value
 *
 * @return          the random value
 */
tb_float_t          tb_random_rangef(tb_random_ref_t random, tb_float_t beg, tb_float_t end);
#endif

/*! generate the random with range: [0, max)
 *
 * @param random    the random, using the default random if be null
 *
 * @return          the random value
 */
tb_long_t           tb_random_value(tb_random_ref_t random);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

