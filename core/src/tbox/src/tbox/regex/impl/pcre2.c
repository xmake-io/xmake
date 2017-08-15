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
 * @file        pcre2.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <pcre2.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the regex type
typedef struct __tb_regex_t
{
    // the code
    pcre2_code*         code;

    // the match data
    pcre2_match_data*   match_data;

    // the results 
    tb_vector_ref_t     results;

    // the mode
    tb_size_t           mode;

    // the buffer data
    PCRE2_UCHAR*        buffer_data;

    // the buffer maxn
    tb_size_t           buffer_maxn;

}tb_regex_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_regex_ref_t tb_regex_init(tb_char_t const* pattern, tb_size_t mode)
{
    // check
    tb_assert_and_check_return_val(pattern, tb_null);

    // done
    tb_bool_t   ok = tb_false;
    tb_regex_t* regex = tb_null;
    do
    {
        // make regex
        regex = (tb_regex_t*)tb_malloc0_type(tb_regex_t);
        tb_assert_and_check_break(regex);

        // init options
        tb_uint32_t options = PCRE2_UTF;
        if (mode & TB_REGEX_MODE_CASELESS) options |= PCRE2_CASELESS;
        if (mode & TB_REGEX_MODE_MULTILINE) options |= PCRE2_MULTILINE;
#ifndef __tb_debug__
        options |= PCRE2_NO_UTF_CHECK;
#endif

        // init code
        tb_int_t    errornumber;
        PCRE2_SIZE  erroroffset;
        regex->code = pcre2_compile((PCRE2_SPTR)pattern, PCRE2_ZERO_TERMINATED, options, &errornumber, &erroroffset, tb_null);
        if (!regex->code)
        {
#if defined(__tb_debug__) && !defined(TB_CONFIG_OS_WINDOWS) // FIXME: _sprintf undefined link error for vs2015 on windows
            // get error info
            PCRE2_UCHAR info[256];
            pcre2_get_error_message(errornumber, info, sizeof(info));

            // trace
            tb_trace_d("compile failed at offset %ld: %s\n", (tb_long_t)erroroffset, info);
#endif

            // end
            break;
        }

        // init match data
        regex->match_data = pcre2_match_data_create_from_pattern(regex->code, tb_null);
        tb_assert_and_check_break(regex->match_data);

        // save mode
        regex->mode = mode;

        // ok 
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (regex) tb_regex_exit((tb_regex_ref_t)regex);
        regex = tb_null;
    }

    // ok?
    return (tb_regex_ref_t)regex;
}
tb_void_t tb_regex_exit(tb_regex_ref_t self)
{
    // check
    tb_regex_t* regex = (tb_regex_t*)self;
    tb_assert_and_check_return(regex);

    // exit buffer
    if (regex->buffer_data) tb_free(regex->buffer_data);
    regex->buffer_data = tb_null;
    regex->buffer_maxn = 0;

    // exit results
    if (regex->results) tb_vector_exit(regex->results);
    regex->results = tb_null;

    // exit match data
    if (regex->match_data) pcre2_match_data_free(regex->match_data);
    regex->match_data = tb_null;

    // exit code
    if (regex->code) pcre2_code_free(regex->code);
    regex->code = tb_null;

    // exit it
    tb_free(regex);
}
tb_long_t tb_regex_match(tb_regex_ref_t self, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults)
{
    // check
    tb_regex_t* regex = (tb_regex_t*)self;
    tb_assert_and_check_return_val(regex && regex->code && regex->match_data && cstr, -1);

    // done
    tb_long_t ok = -1;
    do
    {
        // clear length first
        if (plength) *plength = 0;

        // end?
        tb_check_break(start < size);

        // init options
#ifdef __tb_debug__
        tb_uint32_t options = 0;
#else
        tb_uint32_t options = PCRE2_NO_UTF_CHECK;
#endif

        // match it
        tb_long_t count = pcre2_match(regex->code, (PCRE2_SPTR)cstr, (PCRE2_SIZE)size, (PCRE2_SIZE)start, options, regex->match_data, tb_null);
        if (count < 0)
        {
            // no match?
            tb_check_break(count != PCRE2_ERROR_NOMATCH);

#if defined(__tb_debug__) && !defined(TB_CONFIG_OS_WINDOWS)
            // get error info
            PCRE2_UCHAR info[256];
            pcre2_get_error_message(count, info, sizeof(info));

            // trace
            tb_trace_d("match failed at offset %lu: error: %ld, %s\n", start, count, info);
#endif

            // end
            break;
        }

        // check
        tb_assertf_and_check_break(count, "ovector has not enough space!");

        // get output vector
        PCRE2_SIZE* ovector = pcre2_get_ovector_pointer(regex->match_data);
        tb_assert_and_check_break(ovector);

        // get the match offset and length
        tb_size_t offset = (tb_size_t)ovector[0];
        tb_size_t length = (tb_size_t)ovector[1] - ovector[0];
        tb_assert_and_check_break(offset + length <= size);

        // trace
        tb_trace_d("matched count: %lu, offset: %lu, length: %lu", count, offset, length);

        // save results
        if (presults)
        {
            // init results if not exists
            tb_vector_ref_t results = *presults;
            if (!results)
            {
                // init it
                if (!regex->results) regex->results = tb_vector_init(16, tb_element_mem(sizeof(tb_regex_match_t), tb_regex_match_exit, tb_null));

                // save it
                *presults = results = regex->results;
            }
            tb_assert_and_check_break(results);

            // clear it first
            tb_vector_clear(results);

            // done
            tb_long_t           i = 0;
            tb_regex_match_t    entry;
            for (i = 0; i < count; i++)
            {
                // get substring offset and length
                tb_size_t substr_offset = ovector[i << 1];
                tb_size_t substr_length = ovector[(i << 1) + 1] - ovector[i << 1];
                tb_assert_and_check_break(substr_offset + substr_length <= size);

                // make match entry
                entry.cstr  = tb_strndup(cstr + substr_offset, substr_length);
                entry.size  = substr_length;
                entry.start = substr_offset;
                tb_assert_and_check_break(entry.cstr);
                
                // trace
                tb_trace_d("    matched: [%lu, %lu]: %s", entry.start, entry.size, entry.cstr);

                // append it
                tb_vector_insert_tail(results, &entry);
            }
            tb_assert_and_check_break(i == count);
        }

        // save length 
        if (plength) *plength = length;

        // ok
        ok = offset;

    } while (0);

    // ok?
    return ok;
}
tb_char_t const* tb_regex_replace(tb_regex_ref_t self, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_char_t const* replace_cstr, tb_size_t replace_size, tb_size_t* plength)
{
    // check
    tb_regex_t* regex = (tb_regex_t*)self;
    tb_assert_and_check_return_val(regex && regex->code && cstr && replace_cstr, tb_null);

    // done
    tb_char_t const* result = tb_null;
    do
    {
        // clear length first
        if (plength) *plength = 0;

        // end?
        tb_check_break(start < size);

        // init options
#ifdef __tb_debug__
        tb_uint32_t options = 0;
#else
        tb_uint32_t options = PCRE2_NO_UTF_CHECK;
#endif
        if (regex->mode & TB_REGEX_MODE_GLOBAL) options |= PCRE2_SUBSTITUTE_GLOBAL;

        // init buffer
        if (!regex->buffer_data)
        {
            regex->buffer_maxn = tb_max(size + replace_size + 64, 256);
            regex->buffer_data = (PCRE2_UCHAR*)tb_malloc_bytes(regex->buffer_maxn);
        }
        tb_assert_and_check_break(regex->buffer_data);

        // done
        tb_long_t   ok = -1;
        PCRE2_SIZE  length = 0;
        while (1)
        {
            // replace it
            length = (PCRE2_SIZE)regex->buffer_maxn;
            ok = pcre2_substitute(regex->code, (PCRE2_SPTR)cstr, (PCRE2_SIZE)size, (PCRE2_SIZE)start, options, tb_null, tb_null, (PCRE2_SPTR)replace_cstr, (PCRE2_SIZE)replace_size, regex->buffer_data, &length);

            // no space?
            if (ok == PCRE2_ERROR_NOMEMORY)
            {
                // grow buffer
                regex->buffer_maxn <<= 1;
                regex->buffer_data = (PCRE2_UCHAR*)tb_ralloc_bytes(regex->buffer_data, regex->buffer_maxn);
                tb_assert_and_check_break(regex->buffer_data);
            }
            // failed
            else if (ok < 0)
            {
#if defined(__tb_debug__) && !defined(TB_CONFIG_OS_WINDOWS)
                // get error info
                PCRE2_UCHAR info[256];
                pcre2_get_error_message(ok, info, sizeof(info));

                // trace
                tb_trace_d("replace failed at offset %lu: error: %ld, %s\n", start, ok, info);
#endif

                // end
                break;
            }
            else break;
        }

        // check
        tb_check_break(ok > 0);
        tb_assert_and_check_break(length < regex->buffer_maxn);

        // end
        regex->buffer_data[length] = '\0';

        // trace
        tb_trace_d("    replace: [%lu]: %s", length, regex->buffer_data);

        // save length 
        if (plength) *plength = (tb_size_t)length;

        // ok
        result = (tb_char_t const*)regex->buffer_data;

    } while (0);

    // ok?
    return result;
}
