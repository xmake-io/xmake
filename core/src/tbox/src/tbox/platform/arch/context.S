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
 * @file        context.S
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../../prefix/prefix.S"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

#if defined(TB_ARCH_x86)
#   include "x86/context.S"
#elif defined(TB_ARCH_x64)
#   include "x64/context.S"
#elif defined(TB_ARCH_ARM64)
#   include "arm64/context.S"
#elif defined(TB_ARCH_ARM)
#   include "arm/context.S"
#elif defined(TB_ARCH_MIPS)
#   include "mips/context.S"
#endif
