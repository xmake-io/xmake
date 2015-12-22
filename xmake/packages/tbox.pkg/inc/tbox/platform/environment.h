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
 * @file        environment.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_ENVIRONMENT_H
#define TB_PLATFORM_ENVIRONMENT_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../container/iterator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the environment variable ref type
typedef tb_iterator_ref_t tb_environment_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the environment variable
 *
 * @return              the environment variable 
 */
tb_environment_ref_t    tb_environment_init(tb_noarg_t);

/*! exit the environment variable
 *
 * @param environment   the environment variable
 */
tb_void_t               tb_environment_exit(tb_environment_ref_t environment);

/*! the environment variable count
 *
 * @param environment   the environment variable
 *
 * @return              the environment variable count
 */
tb_size_t               tb_environment_size(tb_environment_ref_t environment);

/*! load the environment variable from the given name
 *
 * @code
 *
    // init environment
    tb_environment_ref_t environment = tb_environment_init();
    if (environment)
    {
        // load variable
        if (tb_environment_load(environment, "PATH"))
        {
            // trace
            tb_trace_i("%s:", name);

            // dump values
            tb_for_all_if (tb_char_t const*, value, environment, value)
            {
                // trace
                tb_trace_i("    %s", value);
            }
        }

        // exit environment
        tb_environment_exit(environment);
    }
 * @endcode
 *
 * @param environment   the environment variable
 * @param name          the variable name
 *
 * @return              the count of the variable value 
 */
tb_size_t               tb_environment_load(tb_environment_ref_t environment, tb_char_t const* name);

/*! save the environment variable and will overwrite it
 *
 * we will remove this environment variable if environment is null or empty
 *
 * @code
 *
    // init environment
    tb_environment_ref_t environment = tb_environment_init();
    if (environment)
    {
        // insert values
        tb_environment_insert(environment, "/xxx/0", tb_false);
        tb_environment_insert(environment, "/xxx/1", tb_false);
        tb_environment_insert(environment, "/xxx/2", tb_false);
        tb_environment_insert(environment, "/xxx/3", tb_false);

        // save variable
        tb_environment_save(environment, "PATH");

        // exit environment
        tb_environment_exit(environment);
    }

 * @endcode
 *
 * @param environment   the environment variable
 * @param name          the variable name
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_environment_save(tb_environment_ref_t environment, tb_char_t const* name);

/*! get the environment variable from the given index
 *
 * @code
 *
    // init environment
    tb_environment_ref_t environment = tb_environment_init();
    if (environment)
    {
        // load variable
        if (tb_environment_load(environment, "PATH"))
        {
            tb_char_t const* value = tb_environment_get(environment, 0);
            if (value)
            {
                // ...
            }
        }

        // exit environment
        tb_environment_exit(environment);
    }
 * @endcode
 *
 *
 * @param environment   the environment variable
 * @param index         the variable index
 *
 * @return              the variable value
 */
tb_char_t const*        tb_environment_get(tb_environment_ref_t environment, tb_size_t index);

/*! set the environment variable and will overwrite it
 *
 * we will clear environment and overwrite it
 *
 * @param environment   the environment variable
 * @param value         the variable value, will clear it if be null
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_environment_set(tb_environment_ref_t environment, tb_char_t const* value);

/*! set the environment variable 
 *
 * @param environment   the environment variable
 * @param value         the variable value
 * @param to_head       insert value into the head?
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_environment_insert(tb_environment_ref_t environment, tb_char_t const* value, tb_bool_t to_head);

#ifdef __tb_debug__
/*! dump the environment variable
 *
 * @param environment   the environment variable
 * @param name          the variable name
 */
tb_void_t               tb_environment_dump(tb_environment_ref_t environment, tb_char_t const* name);
#endif

/*! get the first environment variable value 
 *
 * @code
 
    tb_char_t value[TB_PATH_MAXN];
    if (tb_environment_get_one("HOME", value, sizeof(value)))
    {
        // ...
    }

 * @endcode
 *
 * @param name          the variable name
 * @param value         the variable value
 * @param maxn          the variable value maxn
 *
 * @return              the variable value size
 */
tb_size_t               tb_environment_get_one(tb_char_t const* name, tb_char_t* value, tb_size_t maxn);

/*! set the environment variable value
 *
 * we will set only one value and overwrite it,
 * and remove this environment variable if the value is null 
 *
 * @param name          the variable name
 * @param value         the variable value
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_environment_set_one(tb_char_t const* name, tb_char_t const* value);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
