/*!The Treasure Box Library
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        str.c
 * @ingroup     container
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_long_t tb_iterator_str_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_assert(litem && ritem);

    // compare it
    return tb_strcmp((tb_char_t const*)litem, (tb_char_t const*)ritem);
}
static tb_long_t tb_iterator_istr_comp(tb_iterator_ref_t iterator, tb_cpointer_t litem, tb_cpointer_t ritem)
{
    // check
    tb_assert(litem && ritem);

    // compare it
    return tb_stricmp((tb_char_t const*)litem, (tb_char_t const*)ritem);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_iterator_ref_t tb_iterator_make_for_str(tb_array_iterator_ref_t iterator, tb_char_t** items, tb_size_t count)
{
    // make iterator for the pointer array
    if (!tb_iterator_make_for_ptr(iterator, (tb_pointer_t*)items, count)) return tb_null;

    // init
    iterator->base.comp = tb_iterator_str_comp;

    // ok
    return (tb_iterator_ref_t)iterator;
}
tb_iterator_ref_t tb_iterator_make_for_istr(tb_array_iterator_ref_t iterator, tb_char_t** items, tb_size_t count)
{
    // make iterator for the pointer array
    if (!tb_iterator_make_for_ptr(iterator, (tb_pointer_t*)items, count)) return tb_null;

    // init
    iterator->base.comp = tb_iterator_istr_comp;

    // ok
    return (tb_iterator_ref_t)iterator;
}
