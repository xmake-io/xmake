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
 * @file        type.h
 *
 */
#ifndef TB_LIBC_MISC_TIME_TYPE_H
#define TB_LIBC_MISC_TIME_TYPE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the tm type
typedef struct __tb_tm_t
{
    tb_long_t   second;
    tb_long_t   minute;
    tb_long_t   hour;
    tb_long_t   mday;
    tb_long_t   month;
    tb_long_t   year;
    tb_long_t   week;
    tb_long_t   yday;
    tb_long_t   isdst;

}tb_tm_t;

#endif
