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
#define TB_TRACE_MODULE_NAME "readsyms_coff"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

tb_bool_t xm_binutils_coff_read_symbols(tb_stream_ref_t istream, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // read COFF header
    xm_coff_header_t header;
    if (!tb_stream_seek(istream, 0)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
        return tb_false;
    }

    // check if there are symbols
    if (header.nsyms == 0 || header.symtabofs == 0) {
        lua_newtable(lua);
        return tb_true;
    }

    // create result table
    lua_newtable(lua);

    // read string table offset (after symbol table)
    tb_uint32_t strtab_offset = header.symtabofs + header.nsyms * 18; // each symbol is 18 bytes

    // read section headers to determine section types
    xm_coff_section_t *sections = tb_null;
    if (header.nsects > 0) {
        sections = (xm_coff_section_t*)tb_malloc(header.nsects * sizeof(xm_coff_section_t));
        if (sections) {
            tb_hize_t saved_pos = tb_stream_offset(istream);
            // section headers are after COFF header and optional header
            tb_uint32_t section_offset = sizeof(xm_coff_header_t) + (header.opthdr > 0 ? header.opthdr : 0);
            if (tb_stream_seek(istream, section_offset)) {
                for (tb_uint16_t i = 0; i < header.nsects; i++) {
                    if (!tb_stream_bread(istream, (tb_byte_t*)&sections[i], sizeof(xm_coff_section_t))) {
                        break;
                    }
                }
            }
            tb_stream_seek(istream, saved_pos);
        }
    }

    // read symbols
    if (!tb_stream_seek(istream, header.symtabofs)) {
        if (sections) {
            tb_free(sections);
        }
        return tb_false;
    }

    tb_uint32_t sym_index = 0;
    tb_uint32_t sym_count = 0;
    while (sym_index < header.nsyms) {
        // read symbol
        xm_coff_symbol_t sym;
        if (!tb_stream_bread(istream, (tb_byte_t*)&sym, sizeof(sym))) {
            if (sections) tb_free(sections);
            return tb_false;
        }

        tb_bool_t skip = tb_false;
        tb_char_t name[256] = {0};
        if (!xm_binutils_coff_get_symbol_name(istream, &sym, strtab_offset, name, sizeof(name)) || !name[0]) {
            skip = tb_true;
        } else if (name[0] == '.') {
            skip = tb_true;
        } else if (tb_strchr(name, '$') != tb_null ||
                   tb_strstr(name, ".constprop") != tb_null ||
                   tb_strstr(name, ".startup") != tb_null ||
                   tb_strstr(name, "ta$") != tb_null) {
            skip = tb_true;
        }

        if (!skip) {
            // create symbol table entry
            lua_pushinteger(lua, sym_count + 1);
            lua_newtable(lua);

            // name
            lua_pushstring(lua, "name");
            lua_pushstring(lua, name);
            lua_settable(lua, -3);

            // type (nm-style: T/t/D/d/B/b/U)
            tb_char_t type_char = xm_binutils_coff_get_symbol_type_char(sym.scl, sym.sect, sections, header.nsects);
            tb_char_t type_str[2] = {type_char, '\0'};
            lua_pushstring(lua, "type");
            lua_pushstring(lua, type_str);
            lua_settable(lua, -3);

            lua_settable(lua, -3);
            sym_count++;
        }

        // skip to the next symbol, including auxiliary entries
        sym_index++;
        if (sym.naux > 0) {
            sym_index += sym.naux;
            if (!tb_stream_seek(istream, tb_stream_offset(istream) + sym.naux * 18)) {
                if (sections) tb_free(sections);
                return tb_false;
            }
        }
    }

    if (sections) {
        tb_free(sections);
    }

    return tb_true;
}
