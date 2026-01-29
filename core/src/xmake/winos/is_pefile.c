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
 * @file        is_pefile.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "is_pefile"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* is pe file?
 *
 * local is_pe = winos.is_pefile(filepath)
 */
tb_int_t xm_winos_is_pefile(lua_State *lua) {
    
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the arguments
    tb_char_t const *filepath = luaL_checkstring(lua, 1);
    tb_check_return_val(filepath, 0);

    // check pe file
    tb_bool_t ok = tb_false;
    tb_stream_ref_t stream = tb_stream_init_from_file(filepath, TB_FILE_MODE_RO);
    if (stream) {
        
        // open stream
        if (tb_stream_open(stream)) {
            
            // check mz signature
            tb_byte_t data[4];
            if (tb_stream_read(stream, data, 2) == 2 && data[0] == 'M' && data[1] == 'Z') {
                
                // seek to pe header offset (0x3c)
                if (tb_stream_seek(stream, 0x3c)) {
                    
                    // read the pe header offset
                    if (tb_stream_read(stream, data, 4) == 4) {
                        
                        // get the pe header offset
                        tb_uint32_t offset = data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24);
                        if (offset) {
                            
                            // seek to the pe header
                            if (tb_stream_seek(stream, offset)) {
                                
                                // check pe signature
                                if (tb_stream_read(stream, data, 4) == 4 && 
                                    data[0] == 'P' && data[1] == 'E' && data[2] == 0 && data[3] == 0) {
                                    ok = tb_true;
                                }
                            }
                        }
                    }
                }
            }
        }

        // exit stream
        tb_stream_exit(stream);
    }

    // return result
    lua_pushboolean(lua, ok);
    return 1;
}
