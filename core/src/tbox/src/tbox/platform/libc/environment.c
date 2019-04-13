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
 * @file        environment.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../../libc/libc.h"
#include "../../string/string.h"
#include "../../algorithm/algorithm.h"
#include <stdlib.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_environment_load(tb_environment_ref_t environment, tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(environment && name, 0);

    // clear environment first
    tb_vector_clear(environment);

    // get values
    tb_char_t const* values = getenv(name);
    tb_check_return_val(values, 0);

    // init value string
    tb_string_t value;
    if (!tb_string_init(&value)) return 0;

    // done
    tb_char_t const*    p = values;
    tb_char_t           c = '\0';
    while (1)
    {
        // the character
        c = *p++;

        // make value
        if (c != ':' && c) tb_string_chrcat(&value, c);
        else 
        {
            // save value to environment
            if (tb_string_size(&value)) 
                tb_vector_insert_tail(environment, tb_string_cstr(&value));

            // clear value 
            tb_string_clear(&value);

            // end?
            tb_check_break(c);
        }
    }

    // exit value string
    tb_string_exit(&value);

    // ok?
    return tb_vector_size(environment);
}
tb_bool_t tb_environment_save(tb_environment_ref_t environment, tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(environment && name, tb_false);

    // empty? remove this environment variable
    if (!tb_vector_size(environment)) return !unsetenv(name);

    // init values string
    tb_string_t values;
    if (!tb_string_init(&values)) return tb_false;

    // make values string
    tb_for_all_if (tb_char_t const*, value, environment, value)
    {
        // the single value cannot exist ':'
        tb_assertf(!tb_strchr(value, ':'), "invalid value: %s", value);

        // append value
        tb_string_cstrcat(&values, value);
        tb_string_chrcat(&values, ':');
    }

    // strip the last ':'
    tb_string_strip(&values, tb_string_size(&values) - 1);

    // save variable
    tb_bool_t ok;
    tb_char_t const* value_cstr = tb_string_cstr(&values);
    if (value_cstr) ok = !setenv(name, value_cstr, 1);
    else ok = !unsetenv(name);

    // exit values string
    tb_string_exit(&values);

    // ok?
    return ok;
}
tb_size_t tb_environment_first(tb_char_t const* name, tb_char_t* value, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(name && value && maxn, 0);

    // get it
    tb_char_t const* data = getenv(name);
    tb_check_return_val(data, 0);

    // the value size
    tb_size_t size = tb_strlen(data);
    tb_check_return_val(size, 0);

    // the space is not enough
    tb_assert_and_check_return_val(size < maxn, 0);

    // copy it
    tb_strlcpy(value, data, maxn);
    value[size] = '\0';

    // only get the first one if exists multiple values
    tb_char_t* p = tb_strchr(value, ':');
    if (p)
    {
        // strip it
        *p = '\0';

        // update size
        size = p - value;
    }

    // ok
    return size;
}
tb_bool_t tb_environment_remove(tb_char_t const* name)
{
    // check
    tb_assert_and_check_return_val(name, tb_false);

    // remove it
    return !unsetenv(name);
}
