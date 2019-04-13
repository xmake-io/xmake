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
 * @file        static_allocator.c
 * @ingroup     memory
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "static_allocator.h"
#include "impl/impl.h"
#include "../utils/utils.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_handle_t tb_static_allocator_instance_init(tb_cpointer_t* ppriv)
{
    // check
    tb_check_return_val(ppriv, tb_null);

    // the data and size
    tb_value_ref_t  tuple = (tb_value_ref_t)*ppriv;
    tb_byte_t*      data = (tb_byte_t*)tuple[0].ptr;
    tb_size_t       size = tuple[1].ul;
    tb_assert_and_check_return_val(data && size, tb_null);
    
    // ok?
    return (tb_handle_t)tb_static_allocator_init(data, size);
}
static tb_void_t tb_static_allocator_instance_exit(tb_handle_t self, tb_cpointer_t priv)
{
    // check
    tb_allocator_ref_t allocator = (tb_allocator_ref_t)self;
    tb_assert_and_check_return(allocator);

    // dump allocator
#ifdef __tb_debug__
    if (allocator) tb_allocator_dump(allocator);
#endif

    // exit allocator
    if (allocator) tb_allocator_exit(allocator);
    allocator= tb_null;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_allocator_ref_t tb_static_allocator(tb_byte_t* data, tb_size_t size)
{
    /* init singleton first
     *
     * because this allocator may be called before tb_init()
     */
    if (!tb_singleton_init()) return tb_null;

    // init tuple
    tb_value_t tuple[2];
    tuple[0].ptr    = (tb_pointer_t)data;
    tuple[1].ul     = size;

    // get it
    return (tb_allocator_ref_t)tb_singleton_instance(TB_SINGLETON_TYPE_STATIC_ALLOCATOR, tb_static_allocator_instance_init, tb_static_allocator_instance_exit, tb_null, tuple);
}
tb_allocator_ref_t tb_static_allocator_init(tb_byte_t* data, tb_size_t size)
{
    // init it
    tb_allocator_ref_t allocator = tb_static_large_allocator_init(data, size, 8);
    tb_assert_and_check_return_val(allocator, tb_null);

    // init type
    allocator->type = TB_ALLOCATOR_TYPE_STATIC;

    // ok
    return allocator;
}

