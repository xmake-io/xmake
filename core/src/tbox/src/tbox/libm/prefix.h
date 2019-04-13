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
 * @file        prefix.h
 * @ingroup     libm
 *
 */
#ifndef TB_LIBM_PREFIX_H
#define TB_LIBM_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT

// the ieee float type
typedef union __tb_ieee_float_t
{
    tb_float_t  f;
    tb_uint32_t i;

}tb_ieee_float_t;

// the ieee double type
#   ifdef TB_FLOAT_BIGENDIAN
    typedef union __tb_ieee_double_t
    {
        tb_double_t d;
        struct
        {
            tb_uint32_t h;
            tb_uint32_t l;

        }i;

    }tb_ieee_double_t;
#   else
    typedef union __tb_ieee_double_t
    {
        tb_double_t d;
        struct
        {
            tb_uint32_t l;
            tb_uint32_t h;
        }i;

    }tb_ieee_double_t;
#   endif

#endif


#endif
