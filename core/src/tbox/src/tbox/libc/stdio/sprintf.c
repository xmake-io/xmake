/*!The Treasure Arch Library
 * 
 * TArch is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * TArch is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with TArch; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2019, ruki All rights reserved.
 *
 * @author      ruki
 * @file        sprintf.c
 * @ingroup     libc
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "stdio.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

tb_long_t tb_sprintf(tb_char_t* s, tb_char_t const* fmt, ...)
{
    tb_long_t ret = 0;
    tb_vsnprintf_format(s, TB_MAXU16, fmt, &ret);
    return ret;
}
