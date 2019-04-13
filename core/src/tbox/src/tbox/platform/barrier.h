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
