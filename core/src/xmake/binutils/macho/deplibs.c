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
 * @file        deplibs.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "deplibs_macho"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t xm_binutils_macho_deplibs(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // init Mach-O context
    xm_macho_context_t context;
    if (!xm_binutils_macho_context_init(istream, base_offset, &context)) {
        return tb_false;
    }

    // skip header to reach load commands
    tb_size_t header_size = context.is64 ? sizeof(xm_macho_header_64_t) : sizeof(xm_macho_header_t);
    if (!tb_stream_seek(istream, base_offset + header_size)) {
        return tb_false;
    }

    lua_newtable(lua);
    tb_size_t result_count = 0;

    // iterate load commands
    for (tb_uint32_t i = 0; i < context.ncmds; i++) {
        xm_macho_load_command_t lc;
        tb_hize_t current_cmd_offset = tb_stream_offset(istream);
        
        if (!tb_stream_bread(istream, (tb_byte_t*)&lc, sizeof(lc))) {
            return tb_false;
        }
        xm_binutils_macho_swap_load_command(&lc, context.swap);

        // check for LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB, LC_ID_DYLIB
        if (lc.cmd == XM_MACHO_LC_LOAD_DYLIB || lc.cmd == XM_MACHO_LC_ID_DYLIB || 
            lc.cmd == XM_MACHO_LC_LOAD_WEAK_DYLIB || lc.cmd == XM_MACHO_LC_REEXPORT_DYLIB) {
            
            xm_macho_dylib_command_t dc;
            if (tb_stream_seek(istream, current_cmd_offset)) {
                 if (tb_stream_bread(istream, (tb_byte_t*)&dc, sizeof(dc))) {
                     xm_binutils_macho_swap_dylib_command(&dc, context.swap);
                     
                     tb_uint32_t name_offset = dc.dylib.offset;
                     if (name_offset < lc.cmdsize) {
                         // name is at current_cmd_offset + name_offset
                         if (tb_stream_seek(istream, current_cmd_offset + name_offset)) {
                             tb_char_t dylib_path[1024];
                             tb_size_t max_len = lc.cmdsize - name_offset;
                             if (max_len > sizeof(dylib_path) - 1) max_len = sizeof(dylib_path) - 1;
                             
                             tb_size_t pos = 0;
                             tb_byte_t c;
                             while (pos < max_len) {
                                 if (!tb_stream_bread(istream, &c, 1)) break;
                                 if (c == 0) break;
                                 dylib_path[pos++] = (tb_char_t)c;
                             }
                             dylib_path[pos] = '\0';
                             
                             if (pos > 0) {
                                 lua_pushinteger(lua, result_count + 1);
                                 lua_pushstring(lua, dylib_path);
                                 lua_settable(lua, -3);
                                 result_count++;
                             }
                         }
                     }
                 }
            }
        }

        // move to next command
        if (!tb_stream_seek(istream, current_cmd_offset + lc.cmdsize)) {
            break;
        }
    }

    return tb_true;
}
