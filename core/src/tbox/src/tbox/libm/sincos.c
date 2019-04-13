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
 * @file        sincos.c
 * @ingroup     libm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "math.h"
#include <math.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */
#ifdef TB_CONFIG_LIBM_HAVE_SINCOS
extern tb_void_t sincos(tb_double_t x, tb_double_t* s, tb_double_t* c);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_sincos(tb_double_t x, tb_double_t* s, tb_double_t* c)
{
#ifdef TB_CONFIG_LIBM_HAVE_SINCOS
    sincos(x, s, c);
#else
    if (s) *s = tb_sin(x);
    if (c) *c = tb_cos(x);
#endif
}
