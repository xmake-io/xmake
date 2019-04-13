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
 * @file        packed_e.h
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "compiler.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/* packed
 *
 * // #define TB_PACKED_ALIGN 4
 * #include "tbox/prefix/packed.h"
 * typedef struct __tb_xxxxx_t
 * {
 *      tb_byte_t   a;
 *      tb_uint32_t b;
 *
 * } __tb_packed__ tb_xxxxx_t;
 *
 * #include "tbox/prefix/packed.h"
 *
 * sizeof(tb_xxxxx_t) == 5
 *
 */
#ifdef TB_COMPILER_IS_MSVC
#   ifndef TB_PACKED_ENTER
#       ifdef TB_PACKED_ALIGN
#           pragma pack(push, TB_PACKED_ALIGN)
#       else
#           pragma pack(push, 1)
#       endif
#       define TB_PACKED_ENTER
#   else
#       pragma pack(pop)
#       undef TB_PACKED_ENTER
#       undef TB_PACKED_ALIGN
#   endif
#endif
