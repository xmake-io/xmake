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
 * @file        dictionary.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_DEPRECATED_DICTIONARY_H
#define TB_OBJECT_DEPRECATED_DICTIONARY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define TB_OBJECT_DICTIONARY_SIZE_MICRO                (64)
#define TB_OBJECT_DICTIONARY_SIZE_SMALL                (256)
#define TB_OBJECT_DICTIONARY_SIZE_LARGE                (65536)

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the dictionary item type
typedef struct __tb_object_dictionary_item_t
{
    /// the key
    tb_char_t const*    key;

    /// the value
    tb_object_ref_t     val;

}tb_object_dictionary_item_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
#define tb_object_dictionary_init       tb_oc_dictionary_init
#define tb_object_dictionary_size       tb_oc_dictionary_size
#define tb_object_dictionary_incr       tb_oc_dictionary_incr
#define tb_object_dictionary_itor       tb_oc_dictionary_itor
#define tb_object_dictionary_value      tb_oc_dictionary_value
#define tb_object_dictionary_insert     tb_oc_dictionary_insert
#define tb_object_dictionary_remove     tb_oc_dictionary_remove

#endif

