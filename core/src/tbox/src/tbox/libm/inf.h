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
 * @file        inf.h
 * @ingroup     libm
 *
 */
#ifndef TB_LIBM_INF_H
#define TB_LIBM_INF_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "maf.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#if defined(TB_COMPILER_IS_GCC) \
        && TB_COMPILER_VERSION_BE(3, 3)
#   define TB_INF   (__builtin_inff ())
#else
#   define TB_INF   TB_MAF
#endif


#endif
