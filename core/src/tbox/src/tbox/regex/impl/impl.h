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
 * @file        prefix.h
 *
 */
#ifndef TB_REGEX_IMPL_H
#define TB_REGEX_IMPL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t tb_regex_match_exit(tb_element_ref_t element, tb_pointer_t buff)
{
    // check
    tb_regex_match_ref_t match = (tb_regex_match_ref_t)buff;
    tb_assert_and_check_return(match);

    // exit it
    if (match->cstr) tb_free(match->cstr);
    match->cstr = tb_null;
    match->size = 0;
}

#endif
