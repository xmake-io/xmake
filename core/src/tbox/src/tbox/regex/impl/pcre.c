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
 * @file        pcre.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#define PCRE_STATIC
#include <pcre.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the regex type
typedef struct __tb_regex_t
{
    // the code
    pcre*               code;

    // the results 
    tb_vector_ref_t     results;

    // the mode
    tb_size_t           mode;

    // the ovector data
    tb_int_t*           ovector_data;

    // the ovector maxn
    tb_size_t           ovector_maxn;

    // the buffer data
    tb_char_t*          buffer_data;

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
        tb_int_t options = 0;//PCRE_UTF8;
        if (mode & TB_REGEX_MODE_CASELESS) options |= PCRE_CASELESS;
        if (mode & TB_REGEX_MODE_MULTILINE) options |= PCRE_MULTILINE;
#ifndef __tb_debug__
        options |= 0;//PCRE_NO_UTF_CHECK;
#endif

        // init code
        tb_char_t const*    errorstring = tb_null;
        tb_int_t            erroroffset = 0;
        regex->code = pcre_compile(pattern, options, &errorstring, &erroroffset, tb_null);
        if (!regex->code)
        {
            // trace
            tb_trace_d("compile failed at offset %ld: %s\n", (tb_long_t)erroroffset, errorstring);

            // end
            break;
        }

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

    // exit buffer data
    if (regex->buffer_data) tb_free(regex->buffer_data);
    regex->buffer_data = tb_null;
    regex->buffer_maxn = 0;

    // exit ovector
    if (regex->ovector_data) tb_free(regex->ovector_data);
    regex->ovector_data = tb_null;
    regex->ovector_maxn = 0;

    // exit results
    if (regex->results) tb_vector_exit(regex->results);
    regex->results = tb_null;

    // exit code
    if (regex->code) pcre_free(regex->code);
    regex->code = tb_null;

    // exit it
    tb_free(regex);
}
tb_long_t tb_regex_match(tb_regex_ref_t self, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults)
{
    // check
    tb_regex_t* regex = (tb_regex_t*)self;
    tb_assert_and_check_return_val(regex && regex->code && cstr, -1);

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
        tb_uint32_t options = 0;//PCRE_NO_UTF_CHECK;
#endif

        // init ovector
        if (!regex->ovector_data)
        {
            regex->ovector_maxn = 3 * 16;
            regex->ovector_data = (tb_int_t*)tb_malloc_bytes(sizeof(tb_int_t) * regex->ovector_maxn);
        }
        tb_assert_and_check_break(regex->ovector_data);

        // match it
        tb_long_t count = -1;
        while (!(count = pcre_exec(regex->code, tb_null, cstr, (tb_int_t)size, (tb_int_t)start, (tb_int_t)options, regex->ovector_data, (tb_int_t)regex->ovector_maxn)))
        {
            // grow ovector
            regex->ovector_maxn <<= 1;
            regex->ovector_data = (tb_int_t*)tb_ralloc_bytes(regex->ovector_data, sizeof(tb_int_t) * regex->ovector_maxn);
            tb_assert_and_check_break(regex->ovector_data);
        }
        if (count < 0)
        {
            // no match?
            tb_check_break(count != PCRE_ERROR_NOMATCH);

            // trace
            tb_trace_d("match failed at offset %lu: error: %ld\n", start, count);

            // end
            break;
        }

        // check
        tb_assertf_and_check_break(count, "ovector has not enough space!");

        // get the match offset and length
        tb_int_t const* ovector = regex->ovector_data;
        tb_size_t       offset = (tb_size_t)ovector[0];
        tb_size_t       length = (tb_size_t)ovector[1] - ovector[0];
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
    tb_assert_and_check_return_val(regex && cstr && replace_cstr, tb_null);

    // done
    tb_char_t const* result = tb_null;
    do
    {
        // clear length first
        if (plength) *plength = 0;

        // end?
        tb_check_break(start < size);

        // init buffer
        if (!regex->buffer_data)
        {
            regex->buffer_maxn = tb_max(size + replace_size + 64, 256);
            regex->buffer_data = tb_malloc_cstr(regex->buffer_maxn);
        }
        tb_assert_and_check_break(regex->buffer_data);

        // copy cstr
        tb_memcpy(regex->buffer_data, cstr, size);
        regex->buffer_data[size] = '\0';

        // done
        tb_size_t       count = 0;
        tb_long_t       suboffset = start;
        tb_size_t       sublength = 0;
        tb_size_t       length = 0;
        tb_vector_ref_t results = tb_null;
        while ((suboffset = tb_regex_match(self, regex->buffer_data, size, suboffset + sublength, &sublength, &results)) >= 0 && results)
        {
            // trace
            tb_trace_d("replace: match: [%lu, %lu]", suboffset, sublength);

            // calculate substring end
            tb_size_t subend = suboffset + sublength;
            tb_assert_and_check_break(subend <= size);

            // update length
            length = size - sublength + replace_size;

            // grow buffer
            if (regex->buffer_maxn < length)
            {
                regex->buffer_maxn = tb_max(regex->buffer_maxn << 1, length);
                regex->buffer_data = tb_ralloc_cstr(regex->buffer_data, regex->buffer_maxn + 1);
            }
            tb_assert_and_check_break(regex->buffer_data);

            // replace this match
            if (subend < size) tb_memmov(regex->buffer_data + suboffset + replace_size, regex->buffer_data + subend, size - subend);
            tb_memcpy(regex->buffer_data + suboffset, replace_cstr, replace_size);
            regex->buffer_data[length] = '\0';
           
            // trace
            tb_trace_d("replace: => %s", regex->buffer_data);

            // update matched count
            count++;

            // global replace?
            tb_check_break(regex->mode & TB_REGEX_MODE_GLOBAL);

            // update size
            size        = length;
            sublength   = replace_size;
        }

        // check
        tb_check_break(count);
        tb_assert_and_check_break(length < regex->buffer_maxn);

        // end
        regex->buffer_data[length] = '\0';

        // trace
        tb_trace_d("    replace: [%lu]: %s", length, regex->buffer_data);

        // save length 
        if (plength) *plength = length;

        // ok
        result = (tb_char_t const*)regex->buffer_data;

    } while (0);

    // ok?
    return result;
}
