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
 * @file        number.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_DEPRECATED_NUMBER_H
#define TB_OBJECT_DEPRECATED_NUMBER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the number type enum
typedef enum __tb_object_number_type_e
{
    TB_NUMBER_TYPE_NONE     = 0
,   TB_NUMBER_TYPE_UINT8    = 1
,   TB_NUMBER_TYPE_SINT8    = 2
,   TB_NUMBER_TYPE_UINT16   = 3
,   TB_NUMBER_TYPE_SINT16   = 4
,   TB_NUMBER_TYPE_UINT32   = 5
,   TB_NUMBER_TYPE_SINT32   = 6
,   TB_NUMBER_TYPE_UINT64   = 7
,   TB_NUMBER_TYPE_SINT64   = 8
,   TB_NUMBER_TYPE_FLOAT    = 9
,   TB_NUMBER_TYPE_DOUBLE   = 10

}tb_object_number_type_e;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

#define tb_object_number_init_from_uint8        tb_oc_number_init_from_uint8
#define tb_object_number_init_from_sint8        tb_oc_number_init_from_sint8
#define tb_object_number_init_from_uint16       tb_oc_number_init_from_uint16
#define tb_object_number_init_from_sint16       tb_oc_number_init_from_sint16
#define tb_object_number_init_from_uint32       tb_oc_number_init_from_uint32
#define tb_object_number_init_from_sint32       tb_oc_number_init_from_sint32
#define tb_object_number_init_from_uint64       tb_oc_number_init_from_uint64
#define tb_object_number_init_from_sint64       tb_oc_number_init_from_sint64
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#   define tb_object_number_init_from_float     tb_oc_number_init_from_float
#   define tb_object_number_init_from_double    tb_oc_number_init_from_double
#endif

#define tb_object_number_type                   tb_oc_number_type
#define tb_object_number_uint8                  tb_oc_number_uint8
#define tb_object_number_sint8                  tb_oc_number_sint8
#define tb_object_number_uint16                 tb_oc_number_uint16
#define tb_object_number_sint16                 tb_oc_number_sint16
#define tb_object_number_uint32                 tb_oc_number_uint32
#define tb_object_number_sint32                 tb_oc_number_sint32
#define tb_object_number_uint64                 tb_oc_number_uint64
#define tb_object_number_sint64                 tb_oc_number_sint64
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#   define tb_object_number_float               tb_oc_number_float
#   define tb_object_number_double              tb_oc_number_double
#endif

#define tb_object_number_uint8_set              tb_oc_number_uint8_set
#define tb_object_number_sint8_set              tb_oc_number_sint8_set
#define tb_object_number_uint16_set             tb_oc_number_uint16_set
#define tb_object_number_sint16_set             tb_oc_number_sint16_set
#define tb_object_number_uint32_set             tb_oc_number_uint32_set
#define tb_object_number_sint32_set             tb_oc_number_sint32_set
#define tb_object_number_uint64_set             tb_oc_number_uint64_set
#define tb_object_number_sint64_set             tb_oc_number_sint64_set
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
#   define tb_object_number_floa_set            tb_oc_number_float_set
#   define tb_object_number_double_set          tb_oc_number_double_set
#endif

#endif

