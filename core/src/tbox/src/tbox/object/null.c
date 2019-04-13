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
 * @file        null.c
 * @ingroup     object
 *
 */
 
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME        "oc_null"
#define TB_TRACE_MODULE_DEBUG       (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "object.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_object_ref_t tb_oc_null_copy(tb_object_ref_t object)
{
    return object;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// null
static tb_object_t const g_null = 
{
    TB_OBJECT_FLAG_READONLY | TB_OBJECT_FLAG_SINGLETON
,   TB_OBJECT_TYPE_NULL
,   1
,   tb_null
,   tb_oc_null_copy
,   tb_null
,   tb_null

};

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_object_ref_t tb_oc_null_init()
{
    return (tb_object_ref_t)&g_null;
}

