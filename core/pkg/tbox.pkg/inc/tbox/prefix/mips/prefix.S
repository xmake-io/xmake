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
 * @file        prefix.S
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/*! function
 * 
 * @code
    function func_xxxx, export=1
        ...
    endfunc
   @endcode
 */
.macro function name, export=0
    .macro endfunc
        .end \name
        .size \name, . - \name
        .purgem endfunc
    .endm

        .text
        .align TB_CPU_BITBYTE
    .if \export
        .global \name
        .type   \name, @function
        .hidden \name
        .ent \name
\name:
    .else
        .type   \name, @function
        .hidden \name
        .ent \name
\name:
    .endif
.endm


