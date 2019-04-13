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
            tb_char_t const* value = tb_environment_at(environment, 0);
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
tb_char_t const*        tb_environment_at(tb_environment_ref_t environment, tb_size_t index);

/*! replace the environment variable and will overwrite it
 *
 * we will clear environment and overwrite it
 *
 * @param environment   the environment variable
 * @param value         the variable value, will clear it if be null
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_environment_replace(tb_environment_ref_t environment, tb_char_t const* value);

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
    if (tb_environment_first("HOME", value, sizeof(value)))
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
tb_size_t               tb_environment_first(tb_char_t const* name, tb_char_t* value, tb_size_t maxn);

/*! get the environment variable values 
 *
 * @code
 
    tb_char_t value[TB_PATH_MAXN];
    if (tb_environment_get("HOME", value, sizeof(value)))
    {
        // ...
    }

 * @endcode
 *
 * @param name          the variable name
 * @param values        the variable values, separator: windows(';') or other(';')
 * @param maxn          the variable values maxn
 *
 * @return              the variable values size
 */
tb_size_t               tb_environment_get(tb_char_t const* name, tb_char_t* values, tb_size_t maxn);

/*! set the environment variable values
 *
 * we will set all values and overwrite it
 *
 * @param name          the variable name
 * @param values        the variable values, separator: windows(';') or other(';')
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_environment_set(tb_char_t const* name, tb_char_t const* values);

/*! add the environment variable values and not overwrite it
 *
 * @param name          the variable name
 * @param values        the variable values, separator: windows(';') or other(';')
 * @param to_head       add value into the head?
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_environment_add(tb_char_t const* name, tb_char_t const* values, tb_bool_t to_head);

/*! remove the given environment variable 
 *
 * @param name          the variable name
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_environment_remove(tb_char_t const* name);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
