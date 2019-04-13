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
 * @file        regex.c
 * @ingroup     regex
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "regex"
#define TB_TRACE_MODULE_DEBUG           (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "regex.h"
#include "impl/impl.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
#if defined(TB_CONFIG_PACKAGE_HAVE_PCRE2)
#   include "impl/pcre2.c"
#elif defined(TB_CONFIG_PACKAGE_HAVE_PCRE)
#   include "impl/pcre.c"
#elif defined(TB_CONFIG_POSIX_HAVE_REGCOMP) \
        && defined(TB_CONFIG_POSIX_HAVE_REGEXEC)
#   include "../platform/posix/regex.c"
#else
tb_regex_ref_t tb_regex_init(tb_char_t const* pattern, tb_size_t mode)
{
    tb_assert_noimpl();
    return tb_null;
}
tb_void_t tb_regex_exit(tb_regex_ref_t regex)
{
    tb_assert_noimpl();
}
tb_long_t tb_regex_match(tb_regex_ref_t regex, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults)
{
    tb_assert_noimpl();
    return -1;
}
tb_char_t const* tb_regex_replace(tb_regex_ref_t regex, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_char_t const* replace_cstr, tb_size_t replace_size, tb_size_t* plength)
{
    tb_assert_noimpl();
    return tb_null;
}
#endif
tb_long_t tb_regex_match_cstr(tb_regex_ref_t regex, tb_char_t const* cstr, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults)
{
    // check
    tb_assert_and_check_return_val(cstr, -1);

    // done
    return tb_regex_match(regex, cstr, tb_strlen(cstr), start, plength, presults);
}
tb_vector_ref_t tb_regex_match_simple(tb_regex_ref_t regex, tb_char_t const* cstr)
{
    // check
    tb_assert_and_check_return_val(cstr, tb_null);

    // done
    tb_vector_ref_t results = tb_null;
    return tb_regex_match(regex, cstr, tb_strlen(cstr), 0, tb_null, &results) >= 0? results : tb_null;
}
tb_char_t const* tb_regex_replace_cstr(tb_regex_ref_t regex, tb_char_t const* cstr, tb_size_t start, tb_char_t const* replace_cstr, tb_size_t* plength)
{
    // check
    tb_assert_and_check_return_val(cstr && replace_cstr, tb_null);

    // done
    return tb_regex_replace(regex, cstr, tb_strlen(cstr), start, replace_cstr, tb_strlen(replace_cstr), plength);
}
tb_char_t const* tb_regex_replace_simple(tb_regex_ref_t regex, tb_char_t const* cstr, tb_char_t const* replace_cstr)
{
    // check
    tb_assert_and_check_return_val(cstr && replace_cstr, tb_null);

    // done
    return tb_regex_replace(regex, cstr, tb_strlen(cstr), 0, replace_cstr, tb_strlen(replace_cstr), tb_null);
}
tb_long_t tb_regex_match_done(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults)
{
    // clear results first
    if (presults) *presults = tb_null;

    // init regex
    tb_long_t ok = -1;
    tb_regex_ref_t regex = tb_regex_init(pattern, mode);
    if (regex)
    {
        // init results
        tb_vector_ref_t results = tb_vector_init(16, tb_element_mem(sizeof(tb_regex_match_t), tb_regex_match_exit, tb_null));
        if (results)
        {
            // match regex
            ok = tb_regex_match(regex, cstr, size, start, plength, &results);

            // ok?
            if (ok >= 0)
            {
                // save results
                if (presults) 
                {
                    *presults = results;
                    results = tb_null;
                }
            }

            // exit results
            if (results) tb_vector_exit(results);
            results = tb_null;
        }

        // exit regex
        tb_regex_exit(regex);
    }

    // ok?
    return ok;
}
tb_long_t tb_regex_match_done_cstr(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults)
{
    // check
    tb_assert_and_check_return_val(cstr, -1);

    // done
    return tb_regex_match_done(pattern, mode, cstr, tb_strlen(cstr), start, plength, presults);
}
tb_vector_ref_t tb_regex_match_done_simple(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr)
{
    // check
    tb_assert_and_check_return_val(cstr, tb_null);

    // done
    tb_vector_ref_t results = tb_null;
    return tb_regex_match_done(pattern, mode, cstr, tb_strlen(cstr), 0, tb_null, &results) >= 0? results : tb_null;
}
tb_char_t const* tb_regex_replace_done(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_char_t const* replace_cstr, tb_size_t replace_size, tb_size_t* plength)
{
    // clear length first
    if (plength) *plength = 0;

    // init regex
    tb_char_t*      result = tb_null;
    tb_regex_ref_t  regex = tb_regex_init(pattern, mode);
    if (regex)
    {
        // replace regex
        tb_size_t           result_size = 0;
        tb_char_t const*    result_cstr = tb_regex_replace(regex, cstr, size, start, replace_cstr, replace_size, &result_size);
        if (result_cstr && result_size)
        {
            // save result
            result = tb_strndup(result_cstr, result_size);
            if (result)
            {
                // save length
                if (plength) *plength = result_size;
            }
        }

        // exit regex
        tb_regex_exit(regex);
    }

    // ok?
    return result;
}
tb_char_t const* tb_regex_replace_done_cstr(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_size_t start, tb_char_t const* replace_cstr, tb_size_t* plength)
{
    // check
    tb_assert_and_check_return_val(cstr && replace_cstr, tb_null);

    // done
    return tb_regex_replace_done(pattern, mode, cstr, tb_strlen(cstr), start, replace_cstr, tb_strlen(replace_cstr), tb_null);
}
tb_char_t const* tb_regex_replace_done_simple(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_char_t const* replace_cstr)
{
    // check
    tb_assert_and_check_return_val(cstr && replace_cstr, tb_null);

    // done
    return tb_regex_replace_done(pattern, mode, cstr, tb_strlen(cstr), 0, replace_cstr, tb_strlen(replace_cstr), tb_null);
}
