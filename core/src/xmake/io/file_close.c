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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      OpportunityLiu, ruki
 * @file        file_close.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME    "file_close"
#define TB_TRACE_MODULE_DEBUG   (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// io.file_close(file)
tb_int_t xm_io_file_close(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // is user data?
    if (!lua_isuserdata(lua, 1))
        xm_io_return_error(lua, "close(invalid file)!");

    // get file
    xm_io_file_t* file = (xm_io_file_t*)lua_touserdata(lua, 1);
    tb_check_return_val(file, 0);

    // close file
    if (xm_io_file_is_file(file))
    {
        // check
        tb_assert(file->file_ref);

#ifdef TB_CONFIG_OS_WINDOWS
        // write cached data first
        tb_byte_t const* odata = tb_buffer_data(&file->wcache);
        tb_size_t        osize = tb_buffer_size(&file->wcache);
        if (odata && osize)
        {
            if (!tb_stream_bwrit(file->file_ref, odata, osize)) return tb_false;
            tb_buffer_clear(&file->wcache);
        }
#endif

        // close file
        tb_stream_clos(file->file_ref);
        file->file_ref = tb_null;

        // exit fstream
        if (file->fstream) tb_stream_exit(file->fstream);
        file->fstream = tb_null;

        // exit stream
        if (file->stream) tb_stream_exit(file->stream);
        file->stream = tb_null;

        // exit the line cache buffer
        tb_buffer_exit(&file->rcache);
        tb_buffer_exit(&file->wcache);

        // gc will free it if no any refs for lua_newuserdata()
        // ...

        // ok
        lua_pushboolean(lua, tb_true);
        return 1;
    }
    else // for stdfile (gc/close)
    {
        // exit the line cache buffer
        tb_buffer_exit(&file->rcache);
        tb_buffer_exit(&file->wcache);

        // gc will free it if no any refs for lua_newuserdata()
        // ...

        // ok
        lua_pushboolean(lua, tb_true);
        return 1;
    }
}

