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
 * @file        regex.h
 * @defgroup    regex
 */
#ifndef TB_REGEX_H
#define TB_REGEX_H

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

/// the regex ref type
typedef __tb_typeref__(regex);

/// the regex match type
typedef struct _tb_regex_match_t
{
    /// the c-string data
    tb_char_t const*        cstr;

    /// the c-string size
    tb_size_t               size;

    /// the matched start position
    tb_size_t               start;

}tb_regex_match_t, *tb_regex_match_ref_t;

/// the regex mode enum
typedef enum __tb_regex_mode_e
{
    TB_REGEX_MODE_NONE              = 0     //!< the default mode
,   TB_REGEX_MODE_CASELESS          = 1     //!< do caseless matching
,   TB_REGEX_MODE_MULTILINE         = 2     //!< ^ and $ match newlines within data
,   TB_REGEX_MODE_GLOBAL            = 4     //!< global replace all

}tb_regex_mode_e;


/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init regex
 *
 * @param pattern       the regex pattern
 * @param mode          the regex mode, uses the default mode if be zero
 *
 * @return              the regex
 */
tb_regex_ref_t          tb_regex_init(tb_char_t const* pattern, tb_size_t mode);

/*! exit regex
 *
 * @param regex         the regex
 */
tb_void_t               tb_regex_exit(tb_regex_ref_t regex);

/*! match the given c-string and size by regex
 *
 * @param regex         the regex
 * @param cstr          the c-string data
 * @param size          the c-string size
 * @param start         the start position
 * @param plength       the matched length pointer, do not get it if be null
 * @param presults      the results pointer, only match it if be null
 *
 * @return              the matched position, not match: -1
 */
tb_long_t               tb_regex_match(tb_regex_ref_t regex, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults);

/*! match the given c-string by regex
 *
 * @code
    
    // init regex
    tb_regex_ref_t regex = tb_regex_init("\\w+", 0);
    if (regex)
    {
        // match single 
        //
        // results: "hello"
        //
        tb_vector_ref_t results = tb_null;
        if (tb_regex_match_cstr(regex, "hello world", 0, tb_null, &results) >= 0 && results)
        {
            // show results
            tb_for_all_if (tb_regex_match_ref_t, entry, results, entry)
            {
                // trace
                tb_trace_i("cstr: %s, size: %lu, start: %lu", entry->cstr, entry->size, entry->start);
            }
        }

        // match global 
        //
        // results: "hello"
        // results: "world"
        //
        tb_long_t       start = 0;
        tb_size_t       length = 0;
        tb_vector_ref_t results = tb_null;
        while ((start = tb_regex_match_cstr(regex, "hello world", start + length, &length, &results)) >= 0 && results)
        {
            // show results
            tb_for_all_if (tb_regex_match_ref_t, entry, results, entry)
            {
                // trace
                tb_trace_i("cstr: %s, size: %lu, start: %lu", entry->cstr, entry->size, entry->start);
            }
        }

        // exit regex
        tb_regex_exit(regex);
    }
 * @endcode
 *
 * @param regex         the regex
 * @param cstr          the c-string 
 * @param start         the start position
 * @param plength       the matched length pointer, do not get it if be null
 * @param presults      the results pointer, only match it if be null
 *
 * @return              the matched position, not match: -1
 */
tb_long_t               tb_regex_match_cstr(tb_regex_ref_t regex, tb_char_t const* cstr, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults);

/*! simply match the given c-string by regex
 *
 * @note only supports single match
 *
 * @code
    
    // init regex
    tb_regex_ref_t regex = tb_regex_init("\\w+", 0);
    if (regex)
    {
        // match single 
        //
        // results: "hello"
        //
        tb_vector_ref_t results = tb_regex_match_simple(regex, "hello world");
        if (results)
        {
            // show results
            tb_for_all_if (tb_regex_match_ref_t, entry, results, entry)
            {
                // trace
                tb_trace_i("cstr: %s, size: %lu, start: %lu", entry->cstr, entry->size, entry->start);
            }
        }

        // exit regex
        tb_regex_exit(regex);
    }
 * @endcode
 *
 * @param regex         the regex
 * @param cstr          the c-string 
 *
 * @return              the matched results
 */
tb_vector_ref_t         tb_regex_match_simple(tb_regex_ref_t regex, tb_char_t const* cstr);

/*! replace the given c-string and size by regex
 *
 * @param regex         the regex
 * @param cstr          the c-string data
 * @param size          the c-string size
 * @param start         the start position
 * @param replace_cstr  the replacement c-string data
 * @param replace_size  the replacement c-string size
 * @param plength       the result c-string length pointer, do not get it if be null
 *
 * @return              the result c-string
 */
tb_char_t const*        tb_regex_replace(tb_regex_ref_t regex, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_char_t const* replace_cstr, tb_size_t replace_size, tb_size_t* plength);

/*! replace the given c-string by regex
 *
 * @param regex         the regex
 * @param cstr          the c-string data
 * @param start         the start position
 * @param replace_cstr  the replacement c-string data
 * @param plength       the result c-string length pointer, do not get it if be null
 *
 * @return              the result c-string
 */
tb_char_t const*        tb_regex_replace_cstr(tb_regex_ref_t regex, tb_char_t const* cstr, tb_size_t start, tb_char_t const* replace_cstr, tb_size_t* plength);

/*! simply replace the given c-string by regex
 * 
 * @code
    
    // init regex
    tb_regex_ref_t regex = tb_regex_init("\\w+", 0);
    if (regex)
    {
        // match single 
        //
        // results: "hi world"
        //
        tb_char_t const* results = tb_regex_replace_simple(regex, "hello world", "hi");
        if (results)
        {
            // trace
            tb_trace_i("results: %s", results);
        }

        // exit regex
        tb_regex_exit(regex);
    }
 * @endcode
 *
 * @param regex         the regex
 * @param cstr          the c-string data
 * @param replace_cstr  the replacement c-string data
 *
 * @return              the result c-string
 */
tb_char_t const*        tb_regex_replace_simple(tb_regex_ref_t regex, tb_char_t const* cstr, tb_char_t const* replace_cstr);

/*! match the given c-string and size by the given regex pattern
 *
 * @param pattern       the regex pattern
 * @param mode          the regex mode, uses the default mode if be zero
 * @param cstr          the c-string data
 * @param size          the c-string size
 * @param start         the start position
 * @param plength       the matched length pointer, do not get it if be null
 * @param presults      the results pointer, only match it if be null
 *                      @note we need exit it manually
 *
 * @return              the matched position, not match: -1
 */
tb_long_t               tb_regex_match_done(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults);

/*! match the given c-string by the given regex pattern
 * 
 * @code

    // match single 
    //
    // results: "hello"
    //
    tb_vector_ref_t results = tb_null;
    if (tb_regex_match_done_cstr("\\w+", 0, "hello world", 0, tb_null, &results) >= 0 && results)
    {
        // show results
        tb_for_all_if (tb_regex_match_ref_t, entry, results, entry)
        {
            // trace
            tb_trace_i("cstr: %s, size: %lu, start: %lu", entry->cstr, entry->size, entry->start);
        }
        
        // exit results
        tb_vector_exit(results);
    }

    // match global 
    //
    // results: "hello"
    // results: "world"
    //
    tb_long_t       start = 0;
    tb_size_t       length = 0;
    tb_vector_ref_t results = tb_null;
    while ((start = tb_regex_match_done_cstr("\\w+", 0, "hello world", start + length, &length, &results)) >= 0 && results)
    {
        // show results
        tb_for_all_if (tb_regex_match_ref_t, entry, results, entry)
        {
            // trace
            tb_trace_i("cstr: %s, size: %lu, start: %lu", entry->cstr, entry->size, entry->start);
        }
 
        // exit results
        tb_vector_exit(results);
    }

 * @endcode
 *
 * @param pattern       the regex pattern
 * @param mode          the regex mode, uses the default mode if be zero
 * @param cstr          the c-string data
 * @param start         the start position
 * @param plength       the matched length pointer, do not get it if be null
 * @param presults      the results pointer, only match it if be null
 *                      @note we need exit it manually
 *
 * @return              the matched position, not match: -1
 */
tb_long_t               tb_regex_match_done_cstr(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_size_t start, tb_size_t* plength, tb_vector_ref_t* presults);

/*! simply match the given c-string by the given regex pattern 
 *
 * @note only supports single match
 * 
 * @code

    // match single 
    //
    // results: "hello"
    //
    tb_vector_ref_t results = tb_regex_match_done_simple("\\w+", 0, "hello world");
    if (results)
    {
        // show results
        tb_for_all_if (tb_regex_match_ref_t, entry, results, entry)
        {
            // trace
            tb_trace_i("cstr: %s, size: %lu, start: %lu", entry->cstr, entry->size, entry->start);
        }
        
        // exit results
        tb_vector_exit(results);
    }

 * @endcode
 *
 * @param pattern       the regex pattern
 * @param mode          the regex mode, uses the default mode if be zero
 * @param cstr          the c-string data
 *
 * @return              the matched results, we need exit it manually
 */
tb_vector_ref_t         tb_regex_match_done_simple(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr);

/*! replace the given c-string and size by the given regex pattern 
 *
 * @param pattern       the regex pattern
 * @param mode          the regex mode, uses the default mode if be zero
 * @param cstr          the c-string data
 * @param size          the c-string size
 * @param start         the start position
 * @param replace_cstr  the replacement c-string data
 * @param replace_size  the replacement c-string size
 * @param plength       the result c-string length pointer, do not get it if be null
 *
 * @return              the result c-string
 */
tb_char_t const*        tb_regex_replace_done(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_size_t size, tb_size_t start, tb_char_t const* replace_cstr, tb_size_t replace_size, tb_size_t* plength);

/*! replace the given c-string by the given regex pattern 
 *
 * @param pattern       the regex pattern
 * @param mode          the regex mode, uses the default mode if be zero
 * @param cstr          the c-string data
 * @param start         the start position
 * @param replace_cstr  the replacement c-string data
 * @param plength       the result c-string length pointer, do not get it if be null
 *
 * @return              the result c-string
 */
tb_char_t const*        tb_regex_replace_done_cstr(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_size_t start, tb_char_t const* replace_cstr, tb_size_t* plength);

/*! simply replace the given c-string by the given regex pattern 
 * 
 * @code
    
    // replace single 
    //
    // results: "hi world"
    //
    tb_char_t const* results = tb_regex_replace_done_simple("\\w+", 0, "hello world", "hi");
    if (results)
    {
        // trace
        tb_trace_i("results: %s", results);

        // exit results
        tb_free(results);
    }

 * @endcode
 *
 * @param pattern       the regex pattern
 * @param mode          the regex mode, uses the default mode if be zero
 * @param cstr          the c-string data
 * @param replace_cstr  the replacement c-string data
 *
 * @return              the result c-string, @note we need free it manually
 */
tb_char_t const*        tb_regex_replace_done_simple(tb_char_t const* pattern, tb_size_t mode, tb_char_t const* cstr, tb_char_t const* replace_cstr);


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
