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
#define TB_TRACE_MODULE_NAME "readsyms_elf"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

tb_bool_t xm_binutils_elf_read_symbols_32(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    xm_elf_context_t ctx;
    xm_binutils_elf_get_context_32(istream, base_offset, &ctx);

    if (!ctx.symtab_offset || !ctx.symstr_offset) {
        lua_newtable(lua);
        return tb_true;
    }

    lua_newtable(lua);

    tb_uint32_t sym_count = (tb_uint32_t)(ctx.symtab_size / sizeof(xm_elf32_symbol_t));
    if (!tb_stream_seek(istream, base_offset + ctx.symtab_offset)) {
        return tb_false;
    }

    tb_uint32_t result_count = 0;
    for (tb_uint32_t i = 0; i < sym_count; i++) {
        xm_elf32_symbol_t sym;
        if (!tb_stream_bread(istream, (tb_byte_t*)&sym, sizeof(sym))) {
            return tb_false;
        }

        if (sym.st_name == 0 && sym.st_value == 0 && sym.st_size == 0) {
            continue;
        }

        tb_uint8_t type = sym.st_info & 0xf;
        if (type == 3 || type == 4) {
            continue;
        }

        tb_char_t name[256];
        if (!xm_binutils_read_string(istream, base_offset + ctx.symstr_offset + sym.st_name, name, sizeof(name)) || !name[0]) {
            continue;
        }

        if (name[0] == '.' || name[0] == '$') {
            continue;
        }

        tb_uint8_t bind = (sym.st_info >> 4) & 0xf;
        if (bind == 0 && sym.st_shndx != 0) {
            continue;
        }

        lua_pushinteger(lua, result_count + 1);
        lua_newtable(lua);

        lua_pushstring(lua, "name");
        lua_pushstring(lua, name);
        lua_settable(lua, -3);

        tb_char_t type_char = xm_binutils_elf_get_symbol_type_char(sym.st_info, sym.st_shndx);
        tb_char_t type_str[2] = {type_char, '\0'};
        lua_pushstring(lua, "type");
        lua_pushstring(lua, type_str);
        lua_settable(lua, -3);

        lua_settable(lua, -3);
        result_count++;
    }

    return tb_true;
}

tb_bool_t xm_binutils_elf_read_symbols_64(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    xm_elf_context_t ctx;
    xm_binutils_elf_get_context_64(istream, base_offset, &ctx);

    if (!ctx.symtab_offset || !ctx.symstr_offset) {
        lua_newtable(lua);
        return tb_true;
    }

    lua_newtable(lua);

    tb_uint32_t sym_count = (tb_uint32_t)(ctx.symtab_size / sizeof(xm_elf64_symbol_t));
    if (!tb_stream_seek(istream, base_offset + ctx.symtab_offset)) {
        return tb_false;
    }

    tb_uint32_t result_count = 0;
    for (tb_uint32_t i = 0; i < sym_count; i++) {
        xm_elf64_symbol_t sym;
        if (!tb_stream_bread(istream, (tb_byte_t*)&sym, sizeof(sym))) {
            return tb_false;
        }

        if (sym.st_name == 0 && sym.st_value == 0 && sym.st_size == 0) {
            continue;
        }

        tb_uint8_t type = sym.st_info & 0xf;
        if (type == 3 || type == 4) {
            continue;
        }

        tb_char_t name[256];
        if (!xm_binutils_read_string(istream, base_offset + ctx.symstr_offset + sym.st_name, name, sizeof(name)) || !name[0]) {
            continue;
        }

        if (name[0] == '.' || name[0] == '$') {
            continue;
        }

        tb_uint8_t bind = (sym.st_info >> 4) & 0xf;
        if (bind == 0 && sym.st_shndx != 0) {
            continue;
        }

        lua_pushinteger(lua, result_count + 1);
        lua_newtable(lua);

        lua_pushstring(lua, "name");
        lua_pushstring(lua, name);
        lua_settable(lua, -3);

        tb_char_t type_char = xm_binutils_elf_get_symbol_type_char(sym.st_info, sym.st_shndx);
        tb_char_t type_str[2] = {type_char, '\0'};
        lua_pushstring(lua, "type");
        lua_pushstring(lua, type_str);
        lua_settable(lua, -3);

        lua_settable(lua, -3);
        result_count++;
    }

    return tb_true;
}

tb_bool_t xm_binutils_elf_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // read and check ELF magic
    tb_uint8_t magic[4];
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, magic, 4)) {
        return tb_false;
    }
    if (magic[0] != 0x7f || magic[1] != 'E' || magic[2] != 'L' || magic[3] != 'F') {
        return tb_false;
    }

    // check ELF class (32-bit or 64-bit)
    tb_uint8_t elf_class;
    if (!tb_stream_seek(istream, base_offset + 4)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&elf_class, 1)) {
        return tb_false;
    }

    if (elf_class == 1) {
        return xm_binutils_elf_read_symbols_32(istream, base_offset, lua);
    } else if (elf_class == 2) {
        return xm_binutils_elf_read_symbols_64(istream, base_offset, lua);
    }

    return tb_false;
}

