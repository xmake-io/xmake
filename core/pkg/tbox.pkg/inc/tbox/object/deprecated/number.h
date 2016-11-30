/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
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

