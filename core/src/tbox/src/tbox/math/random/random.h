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
