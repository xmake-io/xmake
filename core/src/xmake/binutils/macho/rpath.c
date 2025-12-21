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
 * @file        rpath.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "rpath_macho"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t xm_binutils_macho_rpath_list(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    tb_bool_t ok = tb_false;
    do {
        // init Mach-O context
        xm_macho_context_t context;
        if (!xm_binutils_macho_context_init(istream, base_offset, &context)) break;

        // skip header to reach load commands
        tb_size_t header_size = context.is64 ? sizeof(xm_macho_header_64_t) : sizeof(xm_macho_header_32_t);
        if (!tb_stream_seek(istream, base_offset + header_size)) break;

        tb_size_t result_count = 0;

        // iterate load commands
        tb_uint32_t i = 0;
        for (i = 0; i < context.ncmds; i++) {
            xm_macho_load_command_t lc;
            tb_hize_t current_cmd_offset = tb_stream_offset(istream);

            if (!tb_stream_bread(istream, (tb_byte_t*)&lc, sizeof(lc))) break;
            xm_binutils_macho_swap_load_command(&lc, context.swap);

            // check for LC_RPATH
            if (lc.cmd == XM_MACHO_LC_RPATH) {

                xm_macho_rpath_command_t rc;
                if (tb_stream_seek(istream, current_cmd_offset)) {
                     if (tb_stream_bread(istream, (tb_byte_t*)&rc, sizeof(rc))) {
                         xm_binutils_macho_swap_rpath_command(&rc, context.swap);

                         tb_uint32_t name_offset = rc.path_offset;
                         if (name_offset < lc.cmdsize) {
                             // name is at current_cmd_offset + name_offset
                             tb_char_t rpath[TB_PATH_MAXN];
                             if (xm_binutils_read_string(istream, current_cmd_offset + name_offset, rpath, sizeof(rpath))) {
                                 if (tb_strlen(rpath) > 0) {
                                     lua_pushinteger(lua, result_count + 1);
                                     lua_pushstring(lua, rpath);
                                     lua_settable(lua, -3);
                                     result_count++;
                                 }
                             }
                         }
                     }
                }
            }

            // move to next command
            if (!tb_stream_seek(istream, current_cmd_offset + lc.cmdsize)) break;
        }
        if (i < context.ncmds) break;

        ok = tb_true;
    } while (0);

    return ok;
}

tb_bool_t xm_binutils_macho_rpath_clean(tb_stream_ref_t istream, tb_hize_t base_offset) {
    tb_assert_and_check_return_val(istream, tb_false);

    tb_bool_t ok = tb_false;
    tb_byte_t* buffer = tb_null;
    do {
        // init Mach-O context
        xm_macho_context_t context;
        if (!xm_binutils_macho_context_init(istream, base_offset, &context)) break;

        tb_size_t header_size = context.is64 ? sizeof(xm_macho_header_64_t) : sizeof(xm_macho_header_32_t);
        if (!tb_stream_seek(istream, base_offset + header_size)) break;

        tb_hize_t read_offset = base_offset + header_size;
        tb_hize_t write_offset = read_offset;
        tb_uint32_t new_ncmds = 0;
        tb_uint32_t new_sizeofcmds = 0;
        tb_bool_t found = tb_false;

        buffer = (tb_byte_t*)tb_malloc(64 * 1024); // 64KB should be enough for any load command
        if (!buffer) break;

        tb_uint32_t i = 0;
        for (i = 0; i < context.ncmds; i++) {
            xm_macho_load_command_t lc;
            if (!tb_stream_seek(istream, read_offset)) break;
            if (!tb_stream_bread(istream, (tb_byte_t*)&lc, sizeof(lc))) break;
            xm_binutils_macho_swap_load_command(&lc, context.swap);

            tb_bool_t remove = tb_false;
            if (lc.cmd == XM_MACHO_LC_RPATH) {
                remove = tb_true;
                found = tb_true;
            }

            if (!remove) {
                // copy command to write_offset
                if (read_offset != write_offset) {
                    if (lc.cmdsize > 64 * 1024) break;

                    if (!tb_stream_seek(istream, read_offset)) break;
                    if (!tb_stream_bread(istream, buffer, lc.cmdsize)) break;
                    if (!tb_stream_seek(istream, write_offset)) break;
                    if (!tb_stream_bwrit(istream, buffer, lc.cmdsize)) break;
                }
                write_offset += lc.cmdsize;
                new_ncmds++;
                new_sizeofcmds += lc.cmdsize;
            }

            read_offset += lc.cmdsize;
        }
        if (i < context.ncmds) break;

        if (found) {
            // zero out the remaining space
            if (read_offset > write_offset) {
                tb_size_t diff = read_offset - write_offset;
                if (!tb_stream_seek(istream, write_offset)) break;
                
                tb_byte_t zero = 0;
                tb_bool_t write_ok = tb_true;
                for (tb_size_t k = 0; k < diff; k++) {
                     if (!tb_stream_bwrit(istream, &zero, 1)) {
                         write_ok = tb_false;
                         break;
                     }
                }
                if (!write_ok) break;
            }

            // update header
            if (context.is64) {
                context.header.header64.ncmds = new_ncmds;
                context.header.header64.sizeofcmds = new_sizeofcmds;
                xm_binutils_macho_swap_header_64(&context.header.header64, context.swap);
                if (!tb_stream_seek(istream, base_offset)) break;
                if (!tb_stream_bwrit(istream, (tb_byte_t const*)&context.header.header64, sizeof(xm_macho_header_64_t))) break;
            } else {
                context.header.header32.ncmds = new_ncmds;
                context.header.header32.sizeofcmds = new_sizeofcmds;
                xm_binutils_macho_swap_header_32(&context.header.header32, context.swap);
                if (!tb_stream_seek(istream, base_offset)) break;
                if (!tb_stream_bwrit(istream, (tb_byte_t const*)&context.header.header32, sizeof(xm_macho_header_32_t))) break;
            }
        }

        ok = tb_true;
    } while (0);

    if (buffer) tb_free(buffer);
    return ok;
}
