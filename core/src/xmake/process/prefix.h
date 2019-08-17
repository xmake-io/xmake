/*!A cross-platform build utility based on Lua
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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        prefix.h
 *
 */
#ifndef XM_PROCESS_PREFIX_H
#define XM_PROCESS_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the subprocess type
typedef struct __xm_subprocess_t
{
    /// the stdout redirect type
    tb_uint16_t             outtype;

    /// the stderr redirect type
    tb_uint16_t             errtype;

    union
    {
        /// the stdout pipe
        tb_pipe_file_ref_t  outpipe;

        /// the stdout file 
        tb_file_ref_t       outfile;
    };

    union 
    {
        /// the strerr pipe
        tb_pipe_file_ref_t  errpipe;

        /// the stderr file
        tb_file_ref_t       errfile;
    };

    // vs unicode output environment variable
    tb_string_t             vs_unicode_output;

}xm_subprocess_t;


#endif


