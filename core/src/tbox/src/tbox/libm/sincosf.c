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
 * @file        sincosf.c
 * @ingroup     libm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "math.h"
#include <math.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_sincosf(tb_float_t x, tb_float_t* s, tb_float_t* c)
{
#ifdef TB_CONFIG_LIBM_HAVE_SINCOSF
    sincosf(x, s, c);
#else
    if (s) *s = tb_sinf(x);
    if (c) *c = tb_cosf(x);
#endif
}
