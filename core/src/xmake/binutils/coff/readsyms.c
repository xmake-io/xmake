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

    // read symbols
    if (!tb_stream_seek(istream, header.symtabofs)) {
        return tb_false;
    }

    tb_uint32_t sym_index = 0;
    tb_uint32_t sym_count = 0;
    while (sym_index < header.nsyms) {
        // read symbol
        xm_coff_symbol_t sym;
        if (!tb_stream_bread(istream, (tb_byte_t*)&sym, sizeof(sym))) {
            return tb_false;
        }

        // get symbol name
        tb_char_t name[256];
        if (!xm_binutils_coff_get_symbol_name(istream, &sym, strtab_offset, name, sizeof(name)) || !name[0]) {
            // skip empty names
            sym_index++;
            if (sym.naux > 0) {
                sym_index += sym.naux; // skip auxiliary entries
                // skip auxiliary data
                tb_stream_seek(istream, tb_stream_offset(istream) + sym.naux * 18);
            }
            continue;
        }

        // create symbol table entry
        lua_pushinteger(lua, sym_count + 1);
        lua_newtable(lua);

        // name
        lua_pushstring(lua, "name");
        lua_pushstring(lua, name);
        lua_settable(lua, -3);

        // value
        lua_pushstring(lua, "value");
        lua_pushinteger(lua, sym.value);
        lua_settable(lua, -3);

        // section
        lua_pushstring(lua, "section");
        lua_pushinteger(lua, sym.sect);
        lua_settable(lua, -3);

        // type
        lua_pushstring(lua, "type");
        lua_pushstring(lua, xm_binutils_coff_get_symbol_type(sym.scl));
        lua_settable(lua, -3);

        // storage class
        lua_pushstring(lua, "storage_class");
        lua_pushinteger(lua, sym.scl);
        lua_settable(lua, -3);

        lua_settable(lua, -3);

        sym_count++;
        sym_index++;

        // skip auxiliary entries
        if (sym.naux > 0) {
            sym_index += sym.naux;
            // skip auxiliary data
            if (!tb_stream_seek(istream, tb_stream_offset(istream) + sym.naux * 18)) {
                return tb_false;
            }
        }
    }

    return tb_true;
}
