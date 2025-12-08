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
#define TB_TRACE_MODULE_NAME "ar_readsyms"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* read symbols from AR archive
 *
 * @param istream the input stream
 * @param lua     the lua state
 * @return        tb_true on success, tb_false on failure
 */
tb_bool_t xm_binutils_ar_read_symbols(tb_stream_ref_t istream, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // create result table
    lua_newtable(lua);

    // skip AR magic (!<arch>\n or !<arch>\r\n)
    if (!tb_stream_seek(istream, 0)) {
        return tb_false;
    }
    tb_uint8_t magic[8];
    if (!tb_stream_bread(istream, magic, 8)) {
        return tb_false;
    }
    // check AR magic: !<arch>
    if (magic[0] != '!' || magic[1] != '<' || magic[2] != 'a' ||
        magic[3] != 'r' || magic[4] != 'c' || magic[5] != 'h' ||
        magic[6] != '>') {
        return tb_false;
    }
    // handle both \n and \r\n
    if (magic[7] == '\n') {
        // Standard format: !<arch>\n
        // already at position 8, ready to read first member
    } else if (magic[7] == '\r') {
        // Windows format: !<arch>\r\n, read one more byte
        tb_uint8_t next_byte;
        if (!tb_stream_bread(istream, &next_byte, 1) || next_byte != '\n') {
            return tb_false;
        }
    } else {
        return tb_false;
    }

    tb_uint32_t result_count = 0;
    tb_hize_t file_size = tb_stream_size(istream);

    // read archive members
    while (tb_stream_offset(istream) < file_size) {
        // read member header
        xm_ar_header_t header;
        if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
            break;
        }

        // check magic
        if (header.fmag[0] != '`' || header.fmag[1] != '\n') {
            break;
        }

        // parse file size
        tb_int64_t member_size = xm_binutils_ar_parse_decimal(header.size, 10);
        if (member_size < 0 || member_size == 0) {
            break;
        }

        // get member name (handle extended names)
        tb_char_t member_name[256] = {0};
        tb_size_t name_len = 0;
        if (header.name[0] == '/' && header.name[1] >= '0' && header.name[1] <= '9') {
            // extended name reference: /123 (offset in string table)
            // For simplicity, skip extended names for now
            // TODO: implement extended name support
        } else {
            // regular name
            for (tb_size_t i = 0; i < 16 && header.name[i] != ' ' && header.name[i] != '/' && header.name[i] != '\0'; i++) {
                member_name[name_len++] = header.name[i];
            }
            // remove trailing '/'
            if (name_len > 0 && member_name[name_len - 1] == '/') {
                name_len--;
            }
            member_name[name_len] = '\0';
        }

        // skip special members (symbol table, string table, etc.)
        if (member_name[0] == '/' || name_len == 0) {
            // skip to next member (align to 2 bytes)
            tb_hize_t current_pos = tb_stream_offset(istream);
            tb_hize_t next_pos = current_pos + member_size;
            if (next_pos & 1) {
                next_pos++; // align to 2 bytes
            }
            if (!tb_stream_seek(istream, next_pos)) {
                break;
            }
            continue;
        }

        // read member data
        tb_byte_t *member_data = (tb_byte_t*)tb_malloc((tb_size_t)member_size);
        if (!member_data) {
            break;
        }

        if (!tb_stream_bread(istream, member_data, (tb_size_t)member_size)) {
            tb_free(member_data);
            break;
        }

        // create stream from member data
        tb_stream_ref_t member_stream = tb_stream_init_from_data(member_data, (tb_size_t)member_size);
        if (!member_stream) {
            tb_free(member_data);
            break;
        }

        if (!tb_stream_open(member_stream)) {
            tb_free(member_data);
            tb_stream_exit(member_stream);
            break;
        }

        // detect member format and read symbols
        tb_int_t member_format = xm_binutils_detect_format(member_stream);
        if (member_format == XM_BINUTILS_FORMAT_COFF) {
            // create temporary table for member symbols
            lua_newtable(lua);
            if (xm_binutils_coff_read_symbols(member_stream, lua)) {
                // merge symbols into result table
                // Stack: result_table(-2), member_table(-1)
                tb_int_t member_sym_count = (tb_int_t)luaL_len(lua, -1);
                for (tb_int_t i = 1; i <= member_sym_count; i++) {
                    lua_pushinteger(lua, i);
                    lua_gettable(lua, -2); // get member_table[i]
                    // Stack: result_table(-3), member_table(-2), symbol(-1)
                    if (lua_istable(lua, -1)) {
                        lua_pushinteger(lua, result_count + 1);
                        lua_pushvalue(lua, -2); // copy symbol
                        // Stack: result_table(-5), member_table(-4), symbol(-3), index(-2), symbol(-1)
                        lua_settable(lua, -5); // result_table[index] = symbol
                        // Stack: result_table(-3), member_table(-2)
                        result_count++;
                    }
                    lua_pop(lua, 1); // remove symbol
                    // Stack: result_table(-2), member_table(-1)
                }
            }
            lua_pop(lua, 1); // remove temporary table
            // Stack: result_table(-1)
        } else if (member_format == XM_BINUTILS_FORMAT_ELF) {
            // create temporary table for member symbols
            lua_newtable(lua);
            if (xm_binutils_elf_read_symbols(member_stream, lua)) {
                // merge symbols into result table
                tb_int_t member_sym_count = (tb_int_t)luaL_len(lua, -1);
                for (tb_int_t i = 1; i <= member_sym_count; i++) {
                    lua_pushinteger(lua, i);
                    lua_gettable(lua, -2);
                    if (lua_istable(lua, -1)) {
                        lua_pushinteger(lua, result_count + 1);
                        lua_pushvalue(lua, -2);
                        lua_settable(lua, -5);
                        result_count++;
                    }
                    lua_pop(lua, 1);
                }
            }
            lua_pop(lua, 1); // remove temporary table
        } else if (member_format == XM_BINUTILS_FORMAT_MACHO) {
            // create temporary table for member symbols
            lua_newtable(lua);
            if (xm_binutils_macho_read_symbols(member_stream, lua)) {
                // merge symbols into result table
                tb_int_t member_sym_count = (tb_int_t)luaL_len(lua, -1);
                for (tb_int_t i = 1; i <= member_sym_count; i++) {
                    lua_pushinteger(lua, i);
                    lua_gettable(lua, -2);
                    if (lua_istable(lua, -1)) {
                        lua_pushinteger(lua, result_count + 1);
                        lua_pushvalue(lua, -2);
                        lua_settable(lua, -5);
                        result_count++;
                    }
                    lua_pop(lua, 1);
                }
            }
            lua_pop(lua, 1); // remove temporary table
        }

        // cleanup
        tb_stream_clos(member_stream);
        tb_stream_exit(member_stream);
        // Note: tb_stream_init_from_data sets bref=true, so it only references the data.
        // We need to free the data after the stream is closed.
        tb_free(member_data);

        // align to 2 bytes for next member
        tb_hize_t current_pos = tb_stream_offset(istream);
        if (current_pos & 1) {
            tb_byte_t padding;
            if (!tb_stream_bread(istream, &padding, 1)) {
                break;
            }
        }
    }

    return tb_true;
}

