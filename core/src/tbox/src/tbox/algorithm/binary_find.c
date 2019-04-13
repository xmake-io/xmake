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
 * @file        binary_find.c
 * @ingroup     algorithm
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "binary_find.h"
#include "binary_find_if.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_binary_find(tb_iterator_ref_t iterator, tb_size_t head, tb_size_t tail, tb_cpointer_t item)
{
    return tb_binary_find_if(iterator, head, tail, tb_iterator_comp, item);
}
tb_size_t tb_binary_find_all(tb_iterator_ref_t iterator, tb_cpointer_t item)
{
    return tb_binary_find_all_if(iterator, tb_iterator_comp, item);
}

