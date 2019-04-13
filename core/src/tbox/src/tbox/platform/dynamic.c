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
 * @file        dynamic.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "dynamic.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_CONFIG_OS_WINDOWS
#   include "windows/dynamic.c"
#elif defined(TB_CONFIG_POSIX_HAVE_DLOPEN)
#   include "posix/dynamic.c"
#else
tb_dynamic_ref_t tb_dynamic_init(tb_char_t const* name)
{
    tb_trace_noimpl();
    return tb_null;
}
tb_void_t tb_dynamic_exit(tb_dynamic_ref_t dynamic)
{
    tb_trace_noimpl();
}
tb_pointer_t tb_dynamic_func(tb_dynamic_ref_t dynamic, tb_char_t const* name)
{
    tb_trace_noimpl();
    return tb_null;
}
tb_pointer_t tb_dynamic_pvar(tb_dynamic_ref_t dynamic, tb_char_t const* name)
{
    tb_trace_noimpl();
    return tb_null;
}
#endif

