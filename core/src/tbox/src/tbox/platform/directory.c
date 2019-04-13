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
 * @file        directory.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "directory.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_CONFIG_OS_WINDOWS
#   include "windows/directory.c"
#elif defined(TB_CONFIG_POSIX_HAVE_OPENDIR)
#   include "posix/directory.c"
#else
tb_bool_t tb_directory_create(tb_char_t const* path)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_bool_t tb_directory_remove(tb_char_t const* path)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_size_t tb_directory_home(tb_char_t* path, tb_size_t maxn)
{
    tb_trace_noimpl();
    return 0;
}
tb_size_t tb_directory_current(tb_char_t* path, tb_size_t maxn)
{
    tb_trace_noimpl();
    return 0;
}
tb_bool_t tb_directory_current_set(tb_char_t const* path)
{
    tb_trace_noimpl();
    return tb_false;
}
tb_size_t tb_directory_temporary(tb_char_t* path, tb_size_t maxn)
{
    tb_trace_noimpl();
    return 0;
}
tb_void_t tb_directory_walk(tb_char_t const* path, tb_long_t recursion, tb_bool_t prefix, tb_directory_walk_func_t func, tb_cpointer_t priv)
{
    tb_trace_noimpl();
}
tb_bool_t tb_directory_copy(tb_char_t const* path, tb_char_t const* dest)
{
    tb_trace_noimpl();
    return tb_false;
}
#endif
