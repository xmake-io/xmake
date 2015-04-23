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
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        number.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_NUMBER_H
#define TB_OBJECT_NUMBER_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

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

/*! init number from uint8
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_uint8(tb_uint8_t value);

/*! init number from sint8
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_sint8(tb_sint8_t value);

/*! init number from uint16
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_uint16(tb_uint16_t value);

/*! init number from sint16
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_sint16(tb_sint16_t value);

/*! init number from uint32
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_uint32(tb_uint32_t value);

/*! init number from sint32
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_sint32(tb_sint32_t value);

/*! init number from uint64
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_uint64(tb_uint64_t value);

/*! init number from sint64
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_sint64(tb_sint64_t value);

#ifdef TB_CONFIG_TYPE_FLOAT
/*! init number from float
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_float(tb_float_t value);

/*! init number from double
 *
 * @param value     the value
 *
 * @return          the number object
 */
tb_object_ref_t     tb_object_number_init_from_double(tb_double_t value);
#endif

/*! the number type
 *
 * @param object    the object pointer
 *
 * @return          the number type
 */
tb_size_t           tb_object_number_type(tb_object_ref_t number);

/*! the uint8 value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_uint8_t          tb_object_number_uint8(tb_object_ref_t number);

/*! the sint8 value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_sint8_t          tb_object_number_sint8(tb_object_ref_t number);

/*! the uint16 value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_uint16_t         tb_object_number_uint16(tb_object_ref_t number);

/*! the sint16 value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_sint16_t         tb_object_number_sint16(tb_object_ref_t number);

/*! the uint32 value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_uint32_t         tb_object_number_uint32(tb_object_ref_t number);

/*! the sint32 value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_sint32_t         tb_object_number_sint32(tb_object_ref_t number);

/*! the uint64 value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_uint64_t         tb_object_number_uint64(tb_object_ref_t number);

/*! the sint64 value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_sint64_t         tb_object_number_sint64(tb_object_ref_t number);

#ifdef TB_CONFIG_TYPE_FLOAT
/*! the float value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_float_t          tb_object_number_float(tb_object_ref_t number);

/*! the double value of the number
 *
 * @param object    the object pointer
 *
 * @return          the number value
 */
tb_double_t         tb_object_number_double(tb_object_ref_t number);
#endif

/*! set the uint8 value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_uint8_set(tb_object_ref_t number, tb_uint8_t value);

/*! set the sint8 value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_sint8_set(tb_object_ref_t number, tb_sint8_t value);

/*! set the uint16 value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_uint16_set(tb_object_ref_t number, tb_uint16_t value);

/*! set the sint16 value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_sint16_set(tb_object_ref_t number, tb_sint16_t value);

/*! set the uint32 value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_uint32_set(tb_object_ref_t number, tb_uint32_t value);

/*! set the sint32 value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_sint32_set(tb_object_ref_t number, tb_sint32_t value);

/*! set the uint64 value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_uint64_set(tb_object_ref_t number, tb_uint64_t value);

/*! set the sint64 value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_sint64_set(tb_object_ref_t number, tb_sint64_t value);

#ifdef TB_CONFIG_TYPE_FLOAT
/*! set the float value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_float_set(tb_object_ref_t number, tb_float_t value);

/*! set the double value 
 *
 * @param object    the object pointer
 * @param value     the number value
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_object_number_double_set(tb_object_ref_t number, tb_double_t value);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

