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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        sha.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "sha"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_hash_sha(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get mode
    tb_size_t mode = (tb_size_t)lua_tointeger(lua, 1);

    // is bytes? get data and size
    if (xm_lua_isinteger(lua, 2) && xm_lua_isinteger(lua, 3))
    {
        tb_byte_t const* data = (tb_byte_t const*)(tb_size_t)(tb_long_t)lua_tointeger(lua, 2);
        tb_size_t size = (tb_size_t)lua_tointeger(lua, 3);
        if (!data || !size)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "invalid data(%p) and size(%d)!", data, (tb_int_t)size);
            return 2;
        }
        tb_assert_static(sizeof(lua_Integer) >= sizeof(tb_pointer_t));

        // compute sha
        tb_sha_t sha;
        tb_byte_t buffer[32];
        tb_sha_init(&sha, mode);
        tb_sha_spak(&sha, data, size);
        tb_sha_exit(&sha, buffer, sizeof(buffer));

        // make sha string
        tb_size_t i = 0;
        tb_size_t n = sha.digest_len << 2;
        tb_char_t s[256] = {0};
        for (i = 0; i < n; ++i) tb_snprintf(s + (i << 1), 3, "%02x", buffer[i]);

        // save result
        lua_pushstring(lua, s);
        return 1;
    }

    // get the filename
    tb_char_t const* filename = luaL_checkstring(lua, 2);
    tb_check_return_val(filename, 0);

    // load data from file
    tb_bool_t ok = tb_false;
    tb_stream_ref_t stream = tb_stream_init_from_file(filename, TB_FILE_MODE_RO);
    if (stream)
    {
        // open stream
        if (tb_stream_open(stream))
        {
            // init sha
            tb_sha_t sha;
            tb_sha_init(&sha, mode);

            // read data and update sha
            tb_byte_t data[TB_STREAM_BLOCK_MAXN];
            while (!tb_stream_beof(stream))
            {
                // read data
                tb_long_t real = tb_stream_read(stream, data, sizeof(data));

                // ok?
                if (real > 0) tb_sha_spak(&sha, data, real);
                // no data? continue it
                else if (!real)
                {
                    // wait
                    real = tb_stream_wait(stream, TB_STREAM_WAIT_READ, tb_stream_timeout(stream));
                    tb_check_break(real > 0);

                    // has read?
                    tb_assert_and_check_break(real & TB_STREAM_WAIT_READ);
                }
                // failed or end?
                else break;
            }

            // exit sha
            tb_byte_t buffer[32];
            tb_sha_exit(&sha, buffer, sizeof(buffer));

            // make sha string
            tb_size_t i = 0;
            tb_size_t n = sha.digest_len << 2;
            tb_char_t s[256] = {0};
            for (i = 0; i < n; ++i) tb_snprintf(s + (i << 1), 3, "%02x", buffer[i]);

            // save result
	        lua_pushstring(lua, s);

            // ok
            ok = tb_true;
        }

        // exit stream
        tb_stream_exit(stream);
    }
    if (!ok) lua_pushnil(lua);
    return 1;
}
