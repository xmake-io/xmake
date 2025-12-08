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
#define TB_TRACE_MODULE_NAME "readsyms_macho"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

tb_bool_t xm_binutils_macho_read_symbols_32(tb_stream_ref_t istream, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);
    
    // read Mach-O header
    xm_macho_header_t header;
    if (!tb_stream_seek(istream, 0)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
        return tb_false;
    }
    
    // find LC_SYMTAB command
    xm_macho_symtab_command_t symtab_cmd;
    tb_bool_t found_symtab = tb_false;
    
    tb_uint32_t offset = sizeof(header);
    for (tb_uint32_t i = 0; i < header.ncmds; i++) {
        tb_uint32_t cmd;
        tb_uint32_t cmdsize;
        
        if (!tb_stream_seek(istream, offset)) {
            return tb_false;
        }
        if (!tb_stream_bread(istream, (tb_byte_t*)&cmd, 4)) {
            return tb_false;
        }
        if (!tb_stream_bread(istream, (tb_byte_t*)&cmdsize, 4)) {
            return tb_false;
        }
        
        if (cmd == XM_MACHO_LC_SYMTAB) {
            if (!tb_stream_seek(istream, offset)) {
                return tb_false;
            }
            if (!tb_stream_bread(istream, (tb_byte_t*)&symtab_cmd, sizeof(symtab_cmd))) {
                return tb_false;
            }
            found_symtab = tb_true;
            break;
        }
        
        offset += cmdsize;
    }
    
    if (!found_symtab) {
        lua_newtable(lua);
        return tb_true;
    }
    
    // create result table
    lua_newtable(lua);
    
    // read symbols
    if (!tb_stream_seek(istream, symtab_cmd.symoff)) {
        return tb_false;
    }
    
    tb_uint32_t result_count = 0;
    for (tb_uint32_t i = 0; i < symtab_cmd.nsyms; i++) {
        xm_macho_nlist_t nlist;
        if (!tb_stream_bread(istream, (tb_byte_t*)&nlist, sizeof(nlist))) {
            return tb_false;
        }
        
        // skip NULL symbols
        if (nlist.strx == 0) {
            continue;
        }
        
        // get symbol name
        tb_char_t name[256];
        if (!xm_binutils_macho_read_string(istream, symtab_cmd.stroff, nlist.strx, name, sizeof(name)) || !name[0]) {
            continue;
        }
        
        // skip internal symbols (starting with .)
        if (name[0] == '.') {
            continue;
        }
        
        // create symbol table entry
        lua_pushinteger(lua, result_count + 1);
        lua_newtable(lua);
        
        // name
        lua_pushstring(lua, "name");
        lua_pushstring(lua, name);
        lua_settable(lua, -3);
        
        // value
        lua_pushstring(lua, "value");
        lua_pushinteger(lua, nlist.value);
        lua_settable(lua, -3);
        
        // section
        lua_pushstring(lua, "section");
        lua_pushinteger(lua, nlist.sect);
        lua_settable(lua, -3);
        
        // type (nm-style: T/t/D/d/B/b/U)
        tb_char_t type_char = xm_binutils_macho_get_symbol_type_char(nlist.type, nlist.sect);
        tb_char_t type_str[2] = {type_char, '\0'};
        lua_pushstring(lua, "type");
        lua_pushstring(lua, type_str);
        lua_settable(lua, -3);
        
        // bind
        lua_pushstring(lua, "bind");
        lua_pushstring(lua, xm_binutils_macho_get_symbol_bind(nlist.type));
        lua_settable(lua, -3);
        
        lua_settable(lua, -3);
        result_count++;
    }
    
    return tb_true;
}

tb_bool_t xm_binutils_macho_read_symbols_64(tb_stream_ref_t istream, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);
    
    // read Mach-O header
    xm_macho_header_64_t header;
    if (!tb_stream_seek(istream, 0)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
        return tb_false;
    }
    
    // find LC_SYMTAB command
    xm_macho_symtab_command_t symtab_cmd;
    tb_bool_t found_symtab = tb_false;
    
    tb_uint32_t offset = sizeof(header);
    for (tb_uint32_t i = 0; i < header.ncmds; i++) {
        tb_uint32_t cmd;
        tb_uint32_t cmdsize;
        
        if (!tb_stream_seek(istream, offset)) {
            return tb_false;
        }
        if (!tb_stream_bread(istream, (tb_byte_t*)&cmd, 4)) {
            return tb_false;
        }
        if (!tb_stream_bread(istream, (tb_byte_t*)&cmdsize, 4)) {
            return tb_false;
        }
        
        if (cmd == XM_MACHO_LC_SYMTAB) {
            if (!tb_stream_seek(istream, offset)) {
                return tb_false;
            }
            if (!tb_stream_bread(istream, (tb_byte_t*)&symtab_cmd, sizeof(symtab_cmd))) {
                return tb_false;
            }
            found_symtab = tb_true;
            break;
        }
        
        offset += cmdsize;
    }
    
    if (!found_symtab) {
        lua_newtable(lua);
        return tb_true;
    }
    
    // create result table
    lua_newtable(lua);
    
    // read symbols
    if (!tb_stream_seek(istream, symtab_cmd.symoff)) {
        return tb_false;
    }
    
    tb_uint32_t result_count = 0;
    for (tb_uint32_t i = 0; i < symtab_cmd.nsyms; i++) {
        xm_macho_nlist_64_t nlist;
        if (!tb_stream_bread(istream, (tb_byte_t*)&nlist, sizeof(nlist))) {
            return tb_false;
        }
        
        // skip NULL symbols
        if (nlist.strx == 0) {
            continue;
        }
        
        // get symbol name
        tb_char_t name[256];
        if (!xm_binutils_macho_read_string(istream, symtab_cmd.stroff, nlist.strx, name, sizeof(name)) || !name[0]) {
            continue;
        }
        
        // skip internal symbols (starting with .)
        if (name[0] == '.') {
            continue;
        }
        
        // create symbol table entry
        lua_pushinteger(lua, result_count + 1);
        lua_newtable(lua);
        
        // name
        lua_pushstring(lua, "name");
        lua_pushstring(lua, name);
        lua_settable(lua, -3);
        
        // value
        lua_pushstring(lua, "value");
        lua_pushinteger(lua, nlist.value);
        lua_settable(lua, -3);
        
        // section
        lua_pushstring(lua, "section");
        lua_pushinteger(lua, nlist.sect);
        lua_settable(lua, -3);
        
        // type (nm-style: T/t/D/d/B/b/U)
        tb_char_t type_char = xm_binutils_macho_get_symbol_type_char(nlist.type, nlist.sect);
        tb_char_t type_str[2] = {type_char, '\0'};
        lua_pushstring(lua, "type");
        lua_pushstring(lua, type_str);
        lua_settable(lua, -3);
        
        // bind
        lua_pushstring(lua, "bind");
        lua_pushstring(lua, xm_binutils_macho_get_symbol_bind(nlist.type));
        lua_settable(lua, -3);
        
        lua_settable(lua, -3);
        result_count++;
    }
    
    return tb_true;
}

tb_bool_t xm_binutils_macho_read_symbols(tb_stream_ref_t istream, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);
    
    // read and check magic
    tb_uint8_t magic_bytes[4];
    if (!xm_binutils_read_magic(istream, magic_bytes, 4)) {
        return tb_false;
    }
    
    // convert to uint32_t (little endian, Mach-O uses native endian)
    tb_uint32_t magic = (tb_uint32_t)magic_bytes[0] | 
                        ((tb_uint32_t)magic_bytes[1] << 8) |
                        ((tb_uint32_t)magic_bytes[2] << 16) |
                        ((tb_uint32_t)magic_bytes[3] << 24);
    
    if (magic == XM_MACHO_MAGIC_32) {
        return xm_binutils_macho_read_symbols_32(istream, lua);
    } else if (magic == XM_MACHO_MAGIC_64) {
        return xm_binutils_macho_read_symbols_64(istream, lua);
    }
    
    return tb_false;
}


