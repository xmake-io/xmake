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
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        extractlib.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "mslib_extract"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* extract MSVC lib archive to directory (placeholder, not yet implemented)
 *
 * @param istream    the input stream
 * @param outputdir  the output directory
 * @return           tb_true on success, tb_false on failure
 */
tb_bool_t xm_binutils_mslib_extract(tb_stream_ref_t istream, tb_char_t const *outputdir) {
    tb_assert_and_check_return_val(istream && outputdir, tb_false);
    
    // TODO: implement MSVC lib extraction
    // MSVC lib format extraction is not yet implemented
    (void)istream;
    (void)outputdir;
    return tb_false;
}

