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
 * @file        assembler.h
 *
 */
#ifndef TB_PREFIX_ASSEMBLER_H
#define TB_PREFIX_ASSEMBLER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "keyword.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#if defined(TB_COMPILER_IS_MSVC)
#   define TB_ASSEMBLER_IS_MASM
#elif defined(TB_COMPILER_IS_GCC) \
    || defined(TB_COMPILER_IS_CLANG) \
    || defined(TB_COMPILER_IS_INTEL)
#   define TB_ASSEMBLER_IS_GAS
#endif

#endif


