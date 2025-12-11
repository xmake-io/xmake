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
 * @file        readsyms.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "mslib_readsyms"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * forward declarations
 */
extern tb_bool_t xm_binutils_coff_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_elf_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_macho_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* read symbols from MSVC lib archive
 *
 * @param istream     the input stream
 * @param base_offset the base offset
 * @param lua         the lua state
 * @return            tb_true on success, tb_false on failure
 */
tb_bool_t xm_binutils_mslib_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State* lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // check magic (!<arch>\n)
    if (!xm_binutils_mslib_check_magic(istream)) {
        return tb_false;
    }

    tb_bool_t ok = tb_true;
    tb_size_t object_count = 0;
    tb_char_t* longnames = tb_null;
    tb_size_t  longnames_size = 0;

    // iterate through members
    while (ok) {
        // read header
        xm_mslib_header_t header;
        if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
            // end of file
            break;
        }

        // parse member size
        tb_int64_t member_size = xm_binutils_mslib_parse_decimal(header.size, 10);
        if (member_size < 0) {
            ok = tb_false;
            break;
        }

        // parse member name
        tb_char_t member_name[256] = {0};
        tb_bool_t is_longname_table = tb_false;

        if (header.name[0] == '/') {
            if (header.name[1] == '/') {
                // long name table (//)
                is_longname_table = tb_true;
            } else if (tb_isdigit(header.name[1])) {
                // offset into long name table (/123)
                tb_int64_t offset = xm_binutils_mslib_parse_decimal(header.name + 1, 15);
                if (offset >= 0 && (tb_size_t)offset < longnames_size) {
                    // copy from longnames
                    // names in longnames are null-terminated
                    tb_strlcpy(member_name, longnames + offset, sizeof(member_name));
                }
            } else {
                 // symbol table or other special member (/)
                 // usually symbol table is just "/"
                 tb_strlcpy(member_name, "/", sizeof(member_name));
            }
        } else {
             // short name, ends with /
             tb_size_t i = 0;
             for (i = 0; i < 16 && header.name[i] != '/'; i++) {
                 member_name[i] = header.name[i];
             }
             member_name[i] = '\0';
        }

        if (is_longname_table) {
            if (longnames) tb_free(longnames);
            longnames = (tb_char_t*)tb_malloc_bytes((tb_size_t)member_size + 1);
            if (!longnames || !tb_stream_bread(istream, (tb_byte_t*)longnames, (tb_size_t)member_size)) {
                ok = tb_false;
                break;
            }
            longnames[member_size] = '\0';
            longnames_size = (tb_size_t)member_size;

            // align
            if (member_size % 2) {
                 if (!tb_stream_skip(istream, 1)) {
                    ok = tb_false;
                    break;
                }
            }
            continue;
        }

        // check if we should process
        // skip empty names, symbol tables (/), long name table (//) - handled above,
        // and __.SYMDEF (SysV/BSD style symbol table, just in case)
        if (member_name[0] == '\0' || tb_strcmp(member_name, "/") == 0 || tb_strcmp(member_name, "//") == 0 ||
            tb_strncmp(member_name, "__.SYMDEF", 9) == 0) {

            // skip member data
            if (!tb_stream_skip(istream, member_size)) {
                ok = tb_false;
                break;
            }
             // align
            if (member_size % 2) {
                 if (!tb_stream_skip(istream, 1)) {
                    ok = tb_false;
                    break;
                }
            }
            continue;
        }

        // save current position
        tb_hize_t current_pos = tb_stream_offset(istream);
        
        // detect format
        tb_int_t format = xm_binutils_detect_format(istream);
        if (format != XM_BINUTILS_FORMAT_UNKNOWN && format != XM_BINUTILS_FORMAT_AR) {
            // create entry table
            lua_newtable(lua);

            // object name
            lua_pushstring(lua, "objectfile");
            lua_pushstring(lua, member_name);
            lua_settable(lua, -3);

            // symbols
            lua_pushstring(lua, "symbols");
            tb_bool_t read_ok = tb_false;
            if (format == XM_BINUTILS_FORMAT_COFF) {
                read_ok = xm_binutils_coff_read_symbols(istream, current_pos, lua);
            } else if (format == XM_BINUTILS_FORMAT_ELF) {
                read_ok = xm_binutils_elf_read_symbols(istream, current_pos, lua);
            } else if (format == XM_BINUTILS_FORMAT_MACHO) {
                read_ok = xm_binutils_macho_read_symbols(istream, current_pos, lua);
            }

            if (read_ok) {
                lua_settable(lua, -3);
                lua_rawseti(lua, -2, (int)(++object_count));
            } else {
                lua_pop(lua, 2); // pop symbols key and entry table
            }
        }

        // skip to next member
        tb_hize_t member_data_read = tb_stream_offset(istream) - current_pos;
        tb_hize_t remaining_size = (tb_hize_t)member_size - member_data_read;

        if (remaining_size > 0) {
            if (!tb_stream_skip(istream, remaining_size)) {
                ok = tb_false;
                break;
            }
        } else if (remaining_size < 0) {
             if (!tb_stream_seek(istream, current_pos + (tb_hize_t)member_size)) {
                ok = tb_false;
                break;
             }
        }
        
        // align to 2-byte boundary
        if (member_size % 2) {
             if (!tb_stream_skip(istream, 1)) {
                ok = tb_false;
                break;
            }
        }
    }

    if (longnames) tb_free(longnames);
    return ok;
}
