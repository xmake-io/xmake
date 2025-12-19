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
        tb_size_t header_size = context.is64 ? sizeof(xm_macho_header_64_t) : sizeof(xm_macho_header_t);
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

static tb_hize_t xm_binutils_macho_find_low_fileoff(tb_stream_ref_t istream, tb_hize_t base_offset, tb_uint32_t ncmds, tb_bool_t swap, tb_bool_t is64) {
    tb_hize_t low_off = -1; // Max value

    do {
        tb_size_t header_size = is64 ? sizeof(xm_macho_header_64_t) : sizeof(xm_macho_header_t);
        if (!tb_stream_seek(istream, base_offset + header_size)) {
            low_off = 0;
            break;
        }

        tb_uint32_t i = 0;
        for (i = 0; i < ncmds; i++) {
            xm_macho_load_command_t lc;
            tb_hize_t current_cmd_offset = tb_stream_offset(istream);
            if (!tb_stream_bread(istream, (tb_byte_t*)&lc, sizeof(lc))) break;
            xm_binutils_macho_swap_load_command(&lc, swap);

            if (lc.cmd == XM_MACHO_LC_SEGMENT) {
                xm_macho_segment_command_t seg;
                if (tb_stream_seek(istream, current_cmd_offset) && tb_stream_bread(istream, (tb_byte_t*)&seg, sizeof(seg))) {
                    if (swap) {
                        seg.nsects = tb_bits_swap_u32(seg.nsects);
                    }
                    
                    // iterate sections
                    if (seg.nsects > 0) {
                        for (tb_uint32_t j = 0; j < seg.nsects; j++) {
                            xm_macho_section_t sect;
                            if (tb_stream_bread(istream, (tb_byte_t*)&sect, sizeof(sect))) {
                                if (swap) sect.offset = tb_bits_swap_u32(sect.offset);
                                if (sect.offset > 0 && (low_off == -1 || sect.offset < low_off)) {
                                    low_off = sect.offset;
                                }
                            }
                        }
                    }
                }
            } else if (lc.cmd == XM_MACHO_LC_SEGMENT_64) {
                xm_macho_segment_command_64_t seg;
                if (tb_stream_seek(istream, current_cmd_offset) && tb_stream_bread(istream, (tb_byte_t*)&seg, sizeof(seg))) {
                    if (swap) {
                        seg.nsects = tb_bits_swap_u32(seg.nsects);
                    }

                    // iterate sections
                    if (seg.nsects > 0) {
                        for (tb_uint32_t j = 0; j < seg.nsects; j++) {
                            xm_macho_section_64_t sect;
                            if (tb_stream_bread(istream, (tb_byte_t*)&sect, sizeof(sect))) {
                                if (swap) sect.offset = tb_bits_swap_u32(sect.offset);
                                if (sect.offset > 0 && (low_off == -1 || sect.offset < low_off)) {
                                    low_off = sect.offset;
                                }
                            }
                        }
                    }
                }
            }

            if (!tb_stream_seek(istream, current_cmd_offset + lc.cmdsize)) {
                break;
            }
        }

        if (i < ncmds) {
            low_off = 0;
            break;
        }
    } while (0);

    return low_off;
}

tb_bool_t xm_binutils_macho_rpath_insert(tb_stream_ref_t istream, tb_hize_t base_offset, tb_char_t const* rpath) {
    tb_assert_and_check_return_val(istream && rpath, tb_false);

    tb_bool_t ok = tb_false;
    do {
        // init Mach-O context
        xm_macho_context_t context;
        if (!xm_binutils_macho_context_init(istream, base_offset, &context)) break;

        tb_size_t header_size = context.is64 ? sizeof(xm_macho_header_64_t) : sizeof(xm_macho_header_t);

        // check if rpath already exists
        if (!tb_stream_seek(istream, base_offset + header_size)) break;

        tb_uint32_t i = 0;
        for (i = 0; i < context.ncmds; i++) {
            xm_macho_load_command_t lc;
            tb_hize_t current_cmd_offset = tb_stream_offset(istream);
            if (!tb_stream_bread(istream, (tb_byte_t*)&lc, sizeof(lc))) break;
            xm_binutils_macho_swap_load_command(&lc, context.swap);

            if (lc.cmd == XM_MACHO_LC_RPATH) {
                xm_macho_rpath_command_t rc;
                if (tb_stream_seek(istream, current_cmd_offset) && tb_stream_bread(istream, (tb_byte_t*)&rc, sizeof(rc))) {
                    xm_binutils_macho_swap_rpath_command(&rc, context.swap);
                    tb_uint32_t name_offset = rc.path_offset;
                    if (name_offset < lc.cmdsize) {
                        tb_char_t current_rpath[TB_PATH_MAXN];
                        if (xm_binutils_read_string(istream, current_cmd_offset + name_offset, current_rpath, sizeof(current_rpath))) {
                            if (tb_strcmp(current_rpath, rpath) == 0) {
                                ok = tb_true; // already exists
                                break;
                            }
                        }
                    }
                }
            }
            if (!tb_stream_seek(istream, current_cmd_offset + lc.cmdsize)) break;
        }
        if (ok) break;
        if (i < context.ncmds) break;

        // check if we have space for new command
        // LC_RPATH size: sizeof(xm_macho_rpath_command_t) + rpath_len + padding
        tb_size_t rpath_len = tb_strlen(rpath);
        tb_size_t cmd_size = sizeof(xm_macho_rpath_command_t) + rpath_len + 1;
        cmd_size = tb_align4(cmd_size);

        tb_hize_t low_off = xm_binutils_macho_find_low_fileoff(istream, base_offset, context.ncmds, context.swap, context.is64);
        if (low_off == -1 || low_off == 0) break;

        if (base_offset + header_size + context.sizeofcmds + cmd_size > low_off) break;

        // write new command
        xm_macho_rpath_command_t rc;
        rc.cmd = XM_MACHO_LC_RPATH;
        rc.cmdsize = (tb_uint32_t)cmd_size;
        rc.path_offset = sizeof(xm_macho_rpath_command_t);
        xm_binutils_macho_swap_rpath_command(&rc, context.swap);

        if (!tb_stream_seek(istream, base_offset + header_size + context.sizeofcmds)) break;
        if (!tb_stream_bwrit(istream, (tb_byte_t const*)&rc, sizeof(rc))) break;
        if (!tb_stream_bwrit(istream, (tb_byte_t const*)rpath, rpath_len + 1)) break;

        // write padding
        tb_size_t padding = cmd_size - (sizeof(xm_macho_rpath_command_t) + rpath_len + 1);
        if (padding > 0) {
            tb_byte_t pad[4] = {0};
            if (!tb_stream_bwrit(istream, pad, padding)) break;
        }

        // update header
        if (context.is64) {
            context.header.header64.ncmds++;
            context.header.header64.sizeofcmds += (tb_uint32_t)cmd_size;
            xm_binutils_macho_swap_header_64(&context.header.header64, context.swap); // swap back to write
            if (!tb_stream_seek(istream, base_offset)) break;
            if (!tb_stream_bwrit(istream, (tb_byte_t const*)&context.header.header64, sizeof(xm_macho_header_64_t))) break;
        } else {
            context.header.header32.ncmds++;
            context.header.header32.sizeofcmds += (tb_uint32_t)cmd_size;
            xm_binutils_macho_swap_header_32(&context.header.header32, context.swap); // swap back to write
            if (!tb_stream_seek(istream, base_offset)) break;
            if (!tb_stream_bwrit(istream, (tb_byte_t const*)&context.header.header32, sizeof(xm_macho_header_t))) break;
        }

        ok = tb_true;
    } while (0);

    return ok;
}

tb_bool_t xm_binutils_macho_rpath_remove(tb_stream_ref_t istream, tb_hize_t base_offset, tb_char_t const* rpath) {
    tb_assert_and_check_return_val(istream && rpath, tb_false);

    tb_bool_t ok = tb_false;
    tb_byte_t* buffer = tb_null;
    do {
        // init Mach-O context
        xm_macho_context_t context;
        if (!xm_binutils_macho_context_init(istream, base_offset, &context)) break;

        tb_size_t header_size = context.is64 ? sizeof(xm_macho_header_64_t) : sizeof(xm_macho_header_t);
        if (!tb_stream_seek(istream, base_offset + header_size)) break;

        // iterate and find matching rpath
        tb_hize_t read_offset = base_offset + header_size;
        tb_hize_t write_offset = read_offset;
        tb_uint32_t new_ncmds = 0;
        tb_uint32_t new_sizeofcmds = 0;
        tb_bool_t found = tb_false;

        buffer = tb_malloc(64 * 1024); // 64KB should be enough for any load command
        if (!buffer) break;

        tb_uint32_t i = 0;
        for (i = 0; i < context.ncmds; i++) {
            xm_macho_load_command_t lc;
            if (!tb_stream_seek(istream, read_offset)) break;
            if (!tb_stream_bread(istream, (tb_byte_t*)&lc, sizeof(lc))) break;
            xm_binutils_macho_swap_load_command(&lc, context.swap);

            tb_bool_t remove = tb_false;
            if (lc.cmd == XM_MACHO_LC_RPATH) {
                 xm_macho_rpath_command_t rc;
                 if (tb_stream_seek(istream, read_offset) && tb_stream_bread(istream, (tb_byte_t*)&rc, sizeof(rc))) {
                     xm_binutils_macho_swap_rpath_command(&rc, context.swap);
                     tb_uint32_t name_offset = rc.path_offset;
                     if (name_offset < lc.cmdsize) {
                         tb_char_t current_rpath[TB_PATH_MAXN];
                         if (xm_binutils_read_string(istream, read_offset + name_offset, current_rpath, sizeof(current_rpath))) {
                             if (tb_strcmp(current_rpath, rpath) == 0) {
                                 remove = tb_true;
                                 found = tb_true;
                             }
                         }
                     }
                 }
            }

            if (!remove) {
                // copy command to write_offset
                if (read_offset != write_offset) {
                    // read the full command
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
                // we can just write zeros
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
                if (!tb_stream_bwrit(istream, (tb_byte_t const*)&context.header.header32, sizeof(xm_macho_header_t))) break;
            }
        }

        ok = tb_true;
    } while (0);

    if (buffer) tb_free(buffer);
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

        tb_size_t header_size = context.is64 ? sizeof(xm_macho_header_64_t) : sizeof(xm_macho_header_t);
        if (!tb_stream_seek(istream, base_offset + header_size)) break;

        tb_hize_t read_offset = base_offset + header_size;
        tb_hize_t write_offset = read_offset;
        tb_uint32_t new_ncmds = 0;
        tb_uint32_t new_sizeofcmds = 0;
        tb_bool_t found = tb_false;

        buffer = tb_malloc(64 * 1024); // 64KB should be enough for any load command
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
                if (!tb_stream_bwrit(istream, (tb_byte_t const*)&context.header.header32, sizeof(xm_macho_header_t))) break;
            }
        }

        ok = tb_true;
    } while (0);

    if (buffer) tb_free(buffer);
    return ok;
}
