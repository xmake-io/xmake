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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        environment.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "environment.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the separator
#ifdef TB_CONFIG_OS_WINDOWS 
#   define TM_ENVIRONMENT_SEP       ';'
#else
#   define TM_ENVIRONMENT_SEP       ':'
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#ifdef TB_CONFIG_OS_WINDOWS
#   include "windows/environment.c"
#else
#   include "libc/environment.c"
#endif
tb_environment_ref_t tb_environment_init()
{
    // init environment
    return tb_vector_init(8, tb_element_str(tb_true));
}
tb_void_t tb_environment_exit(tb_environment_ref_t environment)
{
    // exit environment
    if (environment) tb_vector_exit(environment);
}
tb_size_t tb_environment_size(tb_environment_ref_t environment)
{
    return tb_vector_size(environment);
}
tb_char_t const* tb_environment_at(tb_environment_ref_t environment, tb_size_t index)
{
    // check
    tb_assert_and_check_return_val(environment, tb_null);

    // get the value
    return (index < tb_vector_size(environment))? (tb_char_t const*)tb_iterator_item(environment, index) : tb_null;
}
tb_bool_t tb_environment_replace(tb_environment_ref_t environment, tb_char_t const* value)
{
    // check
    tb_assert_and_check_return_val(environment, tb_false);

    // clear it first
    tb_vector_clear(environment);

    // insert value
    if (value) tb_vector_insert_tail(environment, value);

    // ok
    return tb_true;
}
tb_bool_t tb_environment_insert(tb_environment_ref_t environment, tb_char_t const* value, tb_bool_t to_head)
{
    // check
    tb_assert_and_check_return_val(environment && value, tb_false);

    // insert value into the head
    if (to_head) tb_vector_insert_head(environment, value);
    // insert value into the tail
    else tb_vector_insert_tail(environment, value);

    // ok
    return tb_true;
}
tb_size_t tb_environment_get(tb_char_t const* name, tb_char_t* values, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(name && values && maxn, 0);

    // init values
    tb_string_t valuestrs;
    if (!tb_string_init(&valuestrs)) return 0;

    // init environment
    tb_environment_ref_t environment = tb_environment_init();
    if (environment)
    {
        // load variable
        if (tb_environment_load(environment, name))
        {
            // make values
            tb_bool_t is_first = tb_true;
            tb_for_all_if (tb_char_t const*, value, environment, value)
            {
                // append separator
                if (!is_first) tb_string_chrcat(&valuestrs, TM_ENVIRONMENT_SEP);
                else is_first = tb_false;

                // append value
                tb_string_cstrcat(&valuestrs, value);
            }
        }

        // exit environment
        tb_environment_exit(environment);
    }

    // save result
    tb_size_t           size = tb_string_size(&valuestrs);
    tb_char_t const*    cstr = tb_string_cstr(&valuestrs);
    if (size && cstr) 
    {
        // copy it
        size = tb_strlcpy(values, cstr, maxn);
        tb_assert(size < maxn);
    }

    // exit values
    tb_string_exit(&valuestrs);

    // ok?
    return size;
}
tb_bool_t tb_environment_set(tb_char_t const* name, tb_char_t const* values)
{
    // check
    tb_assert_and_check_return_val(name && values, tb_false);

    // find the first separator position
    tb_bool_t ok = tb_false;
    tb_char_t const* p = values? tb_strchr(values, TM_ENVIRONMENT_SEP) : tb_null;
    if (p)
    {
        // init filter
        tb_hash_set_ref_t filter = tb_hash_set_init(8, tb_element_str(tb_true));

        // init environment 
        tb_char_t               data[TB_PATH_MAXN];
        tb_environment_ref_t    environment = tb_environment_init();
        if (environment)
        {
            // make environment
            tb_char_t const* b = values;
            tb_char_t const* e = b + tb_strlen(values);
            do
            {
                // not empty?
                if (b < p)
                {
                    // the size
                    tb_size_t size = tb_min(p - b, sizeof(data) - 1);

                    // copy it
                    tb_strncpy(data, b, size);
                    data[size] = '\0';

                    // have been not inserted?
                    if (!filter || !tb_hash_set_get(filter, data)) 
                    {
                        // append the environment 
                        tb_environment_insert(environment, data, tb_false);

                        // save it to the filter
                        tb_hash_set_insert(filter, data);
                    }
                }

                // end?
                tb_check_break(p + 1 < e);

                // find the next separator position
                b = p + 1;
                p = tb_strchr(b, TM_ENVIRONMENT_SEP);
                if (!p) p = e;

            } while (1);

            // set environment variables
            ok = tb_environment_save(environment, name);

            // exit environment
            tb_environment_exit(environment);
        }

        // exit filter
        if (filter) tb_hash_set_exit(filter);
        filter = tb_null;
    }
    // only one?
    else
    {
        // set environment variables
        tb_environment_ref_t environment = tb_environment_init();
        if (environment)
        {
            // append the environment 
            tb_environment_insert(environment, values, tb_false);

            // set environment variables
            ok = tb_environment_save(environment, name);

            // exit environment
            tb_environment_exit(environment);
        }
    }

    // ok?
    return ok;
}
tb_bool_t tb_environment_add(tb_char_t const* name, tb_char_t const* values, tb_bool_t to_head)
{
    // check
    tb_assert_and_check_return_val(name && values, tb_false);

    // find the first separator position
    tb_bool_t ok = tb_false;
    tb_char_t const* p = values? tb_strchr(values, TM_ENVIRONMENT_SEP) : tb_null;
    if (p)
    {
        // init filter
        tb_hash_set_ref_t filter = tb_hash_set_init(8, tb_element_str(tb_true));

        // init environment 
        tb_char_t               data[TB_PATH_MAXN];
        tb_environment_ref_t    environment = tb_environment_init();
        if (environment)
        {
            // load the previous values
            tb_environment_load(environment, name);

            // make environment
            tb_char_t const* b = values;
            tb_char_t const* e = b + tb_strlen(values);
            do
            {
                // not empty?
                if (b < p)
                {
                    // the size
                    tb_size_t size = tb_min(p - b, sizeof(data) - 1);

                    // copy it
                    tb_strncpy(data, b, size);
                    data[size] = '\0';

                    // have been not inserted?
                    if (!filter || !tb_hash_set_get(filter, data)) 
                    {
                        // append the environment 
                        tb_environment_insert(environment, data, to_head);

                        // save it to the filter
                        tb_hash_set_insert(filter, data);
                    }
                }

                // end?
                tb_check_break(p + 1 < e);

                // find the next separator position
                b = p + 1;
                p = tb_strchr(b, TM_ENVIRONMENT_SEP);
                if (!p) p = e;

            } while (1);

            // set environment variables
            ok = tb_environment_save(environment, name);

            // exit environment
            tb_environment_exit(environment);
        }

        // exit filter
        if (filter) tb_hash_set_exit(filter);
        filter = tb_null;
    }
    // only one?
    else
    {
        // set environment variables
        tb_environment_ref_t environment = tb_environment_init();
        if (environment)
        {
            // load the previous values
            tb_environment_load(environment, name);

            // append the environment 
            tb_environment_insert(environment, values, to_head);

            // set environment variables
            ok = tb_environment_save(environment, name);

            // exit environment
            tb_environment_exit(environment);
        }
    }

    // ok?
    return ok;
}
#ifdef __tb_debug__
tb_void_t tb_environment_dump(tb_environment_ref_t environment, tb_char_t const* name)
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
#endif
