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
 * @file        hash_set.c
 * @ingroup     container
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "hash_set"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "hash_set.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
// the hash map itor item func type
typedef tb_pointer_t (*gb_hash_map_item_func_t)(tb_iterator_ref_t, tb_size_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_pointer_t tb_hash_set_itor_item(tb_iterator_ref_t iterator, tb_size_t itor)
{
    // check
    tb_assert(iterator && iterator->priv);

    // the item func for the hash map
    gb_hash_map_item_func_t func = (gb_hash_map_item_func_t)iterator->priv;

    // get the item of the hash map
    tb_hash_map_item_ref_t item = (tb_hash_map_item_ref_t)func(iterator, itor);
    
    // get the item of the hash set
    return item? item->name : tb_null;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_hash_set_ref_t tb_hash_set_init(tb_size_t bucket_size, tb_element_t element)
{
    // init hash set
    tb_iterator_ref_t hash_set = (tb_iterator_ref_t)tb_hash_map_init(bucket_size, element, tb_element_true());
    tb_assert_and_check_return_val(hash_set, tb_null);

    // @note the private data of the hash map iterator cannot be used
    tb_assert(!hash_set->priv);

    // init operation
    static tb_iterator_op_t op = {0};
    if (op.item != tb_hash_set_itor_item)
    {
        op = *hash_set->op;
        op.item = tb_hash_set_itor_item;
    }

    // hacking hash_map and hook the item
    hash_set->priv = (tb_pointer_t)hash_set->op->item;
    hash_set->op = &op;

    // ok?
    return (tb_hash_set_ref_t)hash_set;
}
tb_void_t tb_hash_set_exit(tb_hash_set_ref_t self)
{
    tb_hash_map_exit((tb_hash_map_ref_t)self);
}
tb_void_t tb_hash_set_clear(tb_hash_set_ref_t self)
{
    tb_hash_map_clear((tb_hash_map_ref_t)self);
}
tb_bool_t tb_hash_set_get(tb_hash_set_ref_t self, tb_cpointer_t data)
{
    return tb_p2b(tb_hash_map_get((tb_hash_map_ref_t)self, data));
}
tb_size_t tb_hash_set_find(tb_hash_set_ref_t self, tb_cpointer_t data)
{
    return tb_hash_map_find((tb_hash_map_ref_t)self, data);
}
tb_size_t tb_hash_set_insert(tb_hash_set_ref_t self, tb_cpointer_t data)
{
    return tb_hash_map_insert((tb_hash_map_ref_t)self, data, tb_b2p(tb_true));
}
tb_void_t tb_hash_set_remove(tb_hash_set_ref_t self, tb_cpointer_t data)
{
    tb_hash_map_remove((tb_hash_map_ref_t)self, data);
}
tb_size_t tb_hash_set_size(tb_hash_set_ref_t self)
{
    return tb_hash_map_size((tb_hash_map_ref_t)self);
}
tb_size_t tb_hash_set_maxn(tb_hash_set_ref_t self)
{
    return tb_hash_map_maxn((tb_hash_map_ref_t)self);
}
#ifdef __tb_debug__
tb_void_t tb_hash_set_dump(tb_hash_set_ref_t self)
{
    tb_hash_map_dump((tb_hash_map_ref_t)self);
}
#endif

