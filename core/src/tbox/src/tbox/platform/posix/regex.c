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
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <regex.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the regex type
typedef struct __tb_regex_t
{
    // the code
    regex_t             code;

    // the results 
    tb_vector_ref_t     results;

    // the mode
    tb_size_t           mode;

    // the match data
    regmatch_t*         match_data;

    // the match maxn
    tb_size_t           match_maxn;

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
        tb_int_t options = REG_EXTENDED;
        if (mode & TB_REGEX_MODE_CASELESS) options |= REG_ICASE;
        if (mode & TB_REGEX_MODE_MULTILINE) options |= REG_NEWLINE;
#ifdef REG_ENHANCED
        options |= REG_ENHANCED;
#endif

        // init code
        tb_int_t error = regcomp(&regex->code, pattern, options);
        if (error)
        {
#ifdef __tb_debug__
            tb_char_t info[256] = {0};
            regerror(error, &regex->code, info, sizeof(info));

            // trace
            tb_trace_d("compile failed: %s\n", info);
#endif

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

    // exit match data
    if (regex->match_data) tb_free(regex->match_data);
    regex->match_data = tb_null;
    regex->match_maxn = 0;

    // exit results
    if (regex->results) tb_vector_exit(regex->results);
    regex->results = tb_null;

    // exit code
    regfree(&regex->code);

    // exit it
    tb_free(regex);
}
tb_long_t tb_regex_match(tb_regex_ref_t self, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults)
{
    // check
    tb_regex_t* regex = (tb_regex_t*)self;
    tb_assert_and_check_return_val(regex && cstr, -1);

    // done
    tb_long_t ok = -1;
    do
    {
        // clear length first
        if (plength) *plength = 0;

        // end?
        tb_check_break(start < size);

        // init match data
        if (!regex->match_data)
        {
            regex->match_maxn = 16;
            regex->match_data = (regmatch_t*)tb_malloc_bytes(sizeof(regmatch_t) * regex->match_maxn);
        }
        tb_assert_and_check_break(regex->match_data);

        // check
        tb_assert(size <= tb_strlen(cstr));

        // match it
        tb_long_t error = -1;
        while (REG_ESPACE == (error = regexec(&regex->code, cstr + start, regex->match_maxn, regex->match_data, 0)))
        {
            // grow match data
            regex->match_maxn <<= 1;
            regex->match_data = (regmatch_t*)tb_ralloc_bytes(regex->match_data, sizeof(regmatch_t) * regex->match_maxn);
            tb_assert_and_check_break(regex->match_data);
        }
        if (error)
        {
            // no match?
            tb_check_break(error != REG_NOMATCH);

#ifdef __tb_debug__
            // get error info
            tb_char_t info[256] = {0};
            regerror(error, &regex->code, info, sizeof(info));

            // trace
            tb_trace_d("match failed at offset %lu: error: %s\n", start, info);
#endif

            // end
            break;
        }

        // get the match offset and length
        regmatch_t const*   match = regex->match_data;
        tb_size_t           count = 1 + regex->code.re_nsub;
        tb_size_t           offset = start + (tb_size_t)match[0].rm_so;
        tb_size_t           length = (tb_size_t)match[0].rm_eo - match[0].rm_so;
        tb_check_break(offset + length <= size);

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
                tb_size_t substr_offset = start + match[i].rm_so;
                tb_size_t substr_length = match[i].rm_eo - match[i].rm_so;
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
