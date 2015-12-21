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
 * @file        barrier.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_BARRIER_H
#define TB_PLATFORM_BARRIER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#if defined(TB_CONFIG_OS_MACOSX) || defined(TB_CONFIG_OS_IOS)
#   include "mach/barrier.h"
#elif defined(TB_COMPILER_IS_GCC) \
    &&  TB_COMPILER_VERSION_BE(4, 1)
#   include "compiler/gcc/barrier.h"
#elif defined(TB_CONFIG_OS_WINDOWS)
#   include "windows/barrier.h"
#endif
#include "arch/barrier.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifndef tb_barrier
#   define tb_barrier()         
#endif


#endif
