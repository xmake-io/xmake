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
 * @file        prefix.S
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/*! function
 * 
 * @code
    function(func_xxxx)
        ...
    endfunc
   @endcode
 */
#ifdef TB_ARCH_ELF
#   define function(name) \
    .text ;\
    .align TB_CPU_BITBYTE ; \
    .global name ;\
    .type   name, %function; \
    .hidden name; \
name:
#else
#   define function(name) \
    .text ;\
    .align TB_CPU_BITBYTE ; \
    .global _##name ;\
_##name:
#endif

// end function
#define endfunc

