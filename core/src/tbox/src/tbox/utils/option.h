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
 * @file        option.h
 * @ingroup     utils
 *
 */
#ifndef TB_UTILS_OPTION_H
#define TB_UTILS_OPTION_H

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

/// the option mode enum
typedef enum __tb_option_mode_e
{
    TB_OPTION_MODE_END      = 0     //!< end
,   TB_OPTION_MODE_VAL      = 1     //!< value
,   TB_OPTION_MODE_KEY      = 2     //!< --key or -k
,   TB_OPTION_MODE_KEY_VAL  = 3     //!< --key=value or --key value or -k=value or -k value
,   TB_OPTION_MODE_MORE     = 4     //!< more and end

}tb_option_mode_e;

/// the option type enum
typedef enum __tb_option_type_e
{
    TB_OPTION_TYPE_NONE     = 0
,   TB_OPTION_TYPE_BOOL     = 1
,   TB_OPTION_TYPE_CSTR     = 2
,   TB_OPTION_TYPE_FLOAT    = 3
,   TB_OPTION_TYPE_INTEGER  = 4

}tb_option_type_e;

/// the option item type
typedef struct __tb_option_item_t
{
    /// the short name
    tb_char_t           sname;

    /// the long name
    tb_char_t const*    lname;

    /// the mode
    tb_uint16_t         mode;

    /// the type
    tb_uint16_t         type;

    /// the help
    tb_char_t const*    help;

}tb_option_item_t;

/// the option ref type
typedef __tb_typeref__(option);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init option
 *
 * @param name          the command name
 * @param help          the command help
 * @param opts          the option list
 *
 * @return              the option 
 */
tb_option_ref_t         tb_option_init(tb_char_t const* name, tb_char_t const* help, tb_option_item_t const* opts);

/*! exit option
 *
 * @param option        the option 
 */
tb_void_t               tb_option_exit(tb_option_ref_t option);

/*! find the option item 
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_option_find(tb_option_ref_t option, tb_char_t const* name);

/*! done option
 *
 * @param option        the option 
 * @param argc          the arguments count
 * @param argv          the arguments value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_option_done(tb_option_ref_t option, tb_size_t argc, tb_char_t** argv);

/*! dump option
 *
 * @param option        the option 
 */
tb_void_t               tb_option_dump(tb_option_ref_t option);

/*! help option
 *
 * @param option        the option 
 */
tb_void_t               tb_option_help(tb_option_ref_t option);

/*! the option item - cstr
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the c-string pointer
 */
tb_char_t const*        tb_option_item_cstr(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - bool
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_option_item_bool(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - uint8
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_uint8_t              tb_option_item_uint8(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - sint8
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_sint8_t              tb_option_item_sint8(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - uint16
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_uint16_t             tb_option_item_uint16(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - sint16
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_sint16_t             tb_option_item_sint16(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - uint32
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_uint32_t             tb_option_item_uint32(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - sint32
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_sint32_t             tb_option_item_sint32(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - uint64
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_uint64_t             tb_option_item_uint64(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - sint64
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_sint64_t             tb_option_item_sint64(tb_option_ref_t option, tb_char_t const* name);

#ifdef TB_CONFIG_TYPE_HAVE_FLOAT

/*! the option item - float
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_float_t              tb_option_item_float(tb_option_ref_t option, tb_char_t const* name);

/*! the option item - sint64
 *
 * @param option        the option 
 * @param name          the option name, long name or short name
 *
 * @return              the integer value
 */
tb_double_t             tb_option_item_double(tb_option_ref_t option, tb_char_t const* name);

#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

