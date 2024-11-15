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
 * @file        xxhash.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "xxhash"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#define XXH_NAMESPACE XM_
#define XXH_STATIC_LINKING_ONLY
#define XXH_IMPLEMENTATION
#include "xxhash/xxhash.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_hash_xxhash(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get mode
    tb_size_t mode = (tb_size_t)lua_tointeger(lua, 1);
    if (mode != 64 && mode != 128)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "invalid mode(%d)!", (tb_int_t)mode);
        return 2;
    }

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

        // compuate hash
        tb_byte_t const* buffer = tb_null;
        XXH64_hash_t value64;
        XXH128_hash_t value128;
        if (mode == 64)
        {
            value64 = XM_XXH3_64bits(data, size);
            buffer = (tb_byte_t const*)&value64;
        }
        else if (mode == 128)
        {
            value128 = XM_XXH3_128bits(data, size);
            buffer = (tb_byte_t const*)&value128;
        }
        if (!buffer)
        {
            lua_pushnil(lua);
            lua_pushfstring(lua, "empty buffer!");
            return 2;
        }

        // make xxhash string
        tb_size_t i = 0;
        tb_size_t n = mode >> 3;
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
        XXH3_state_t* state = XM_XXH3_createState();
        if (tb_stream_open(stream) && state)
        {
            // reset xxhash
            if (mode == 64) XM_XXH3_64bits_reset(state);
            else XM_XXH3_128bits_reset(state);

            // read data and update xxhash
            tb_byte_t data[TB_STREAM_BLOCK_MAXN];
            while (!tb_stream_beof(stream))
            {
                // read data
                tb_long_t real = tb_stream_read(stream, data, sizeof(data));

                // ok?
                if (real > 0)
                {
                    if (mode == 64) XM_XXH3_64bits_update(state, data, real);
                    else XM_XXH3_128bits_update(state, data, real);
                }
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

            // compuate hash
            tb_byte_t const* buffer;
            XXH64_hash_t value64;
            XXH128_hash_t value128;
            if (mode == 64)
            {
                value64 = XM_XXH3_64bits_digest(state);
                buffer = (tb_byte_t const*)&value64;
            }
            else
            {
                value128 = XM_XXH3_128bits_digest(state);
                buffer = (tb_byte_t const*)&value128;
            }

            // make xxhash string
            tb_size_t i = 0;
            tb_size_t n = mode >> 3;
            tb_char_t s[256] = {0};
            for (i = 0; i < n; ++i) tb_snprintf(s + (i << 1), 3, "%02x", buffer[i]);

            // save result
	        lua_pushstring(lua, s);
            ok = tb_true;
        }

        // exit stream
        tb_stream_exit(stream);

        // exit xxhash
        if (state) XM_XXH3_freeState(state);
    }
    if (!ok) lua_pushnil(lua);
    return 1;
}
