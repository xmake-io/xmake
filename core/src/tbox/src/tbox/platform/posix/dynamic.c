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
#include "prefix.h"
#include "../dynamic.h"
#include <dlfcn.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_dynamic_ref_t tb_dynamic_init(tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(name, tb_null);

    // clear error
    dlerror();

    // open
    tb_handle_t dynamic = dlopen(name, RTLD_LAZY);

    // error?
    if (dlerror()) 
    {
        if (dynamic) dlclose(dynamic);
        dynamic = tb_null;
    }

    // ok?
    return (tb_dynamic_ref_t)dynamic;
}
tb_void_t tb_dynamic_exit(tb_dynamic_ref_t dynamic)
{
    // check
    tb_assert_and_check_return(dynamic);

    // close it
    dlclose((tb_handle_t)dynamic);
    tb_assert(!dlerror());
}
tb_pointer_t tb_dynamic_func(tb_dynamic_ref_t dynamic, tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(dynamic && name, tb_null);

    // the func
    return (tb_pointer_t)dlsym((tb_handle_t)dynamic, name);
}
tb_pointer_t tb_dynamic_pvar(tb_dynamic_ref_t dynamic, tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(dynamic && name, tb_null);

    // the variable address
    return (tb_pointer_t)dlsym((tb_handle_t)dynamic, name);
}
