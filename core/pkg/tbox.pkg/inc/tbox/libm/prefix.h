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

#ifdef TB_CONFIG_TYPE_FLOAT

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
