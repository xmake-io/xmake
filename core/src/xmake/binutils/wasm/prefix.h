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
 * @file        prefix.h
 *
 */
#ifndef XM_BINUTILS_WASM_PREFIX_H
#define XM_BINUTILS_WASM_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// wasm file magic: \0asm
#define XM_WASM_MAGIC0         0x00
#define XM_WASM_MAGIC1         0x61
#define XM_WASM_MAGIC2         0x73
#define XM_WASM_MAGIC3         0x6d

// wasm header size: magic(4) + version(4)
#define XM_WASM_HEADER_SIZE    8

// wasm section ids
#define XM_WASM_SECTION_IMPORT 2
#define XM_WASM_SECTION_EXPORT 7

// wasm custom section names
#define XM_WASM_CUSTOM_LINKING "linking"
#define XM_WASM_CUSTOM_NAME    "name"

// wasm import/export kinds
#define XM_WASM_KIND_FUNC      0
#define XM_WASM_KIND_TABLE     1
#define XM_WASM_KIND_MEMORY    2
#define XM_WASM_KIND_GLOBAL    3
#define XM_WASM_KIND_TAG       4

// wasm limits flags
#define XM_WASM_LIMITS_HAS_MAX 0x01
#define XM_WASM_LIMITS_MEM64   0x04

// leb128 max bytes
#define XM_WASM_U32_LEB_MAX    5
#define XM_WASM_U64_LEB_MAX    10

// linking custom section
#define XM_WASM_LINKING_VERSION_2         2
#define XM_WASM_LINKING_SUBSEC_SYMTAB     8

// symbol table kinds (linking section)
#define XM_WASM_SYMTAB_KIND_FUNCTION      0
#define XM_WASM_SYMTAB_KIND_DATA          1
#define XM_WASM_SYMTAB_KIND_GLOBAL        2
#define XM_WASM_SYMTAB_KIND_SECTION       3
#define XM_WASM_SYMTAB_KIND_EVENT         4
#define XM_WASM_SYMTAB_KIND_TABLE         5
#define XM_WASM_SYMTAB_KIND_TAG           6

// symbol table flags (linking section)
#define XM_WASM_SYMTAB_FLAG_UNDEFINED     0x10

// symbol types for binutils.readsyms
#define XM_WASM_SYM_UNDEF      "U"
#define XM_WASM_SYM_TEXT       "T"
#define XM_WASM_SYM_DATA       "D"

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline implementation
 */

// decode unsigned leb128 (u32) from current stream offset
static __tb_inline__ tb_bool_t xm_binutils_wasm_read_u32_leb(tb_stream_ref_t istream, tb_uint32_t* out) {
    tb_uint32_t result = 0;
    tb_uint32_t shift = 0;
    tb_byte_t byte = 0;
    for (tb_size_t i = 0; i < XM_WASM_U32_LEB_MAX; i++) {
        if (!tb_stream_bread(istream, &byte, 1)) {
            return tb_false;
        }
        result |= ((tb_uint32_t)(byte & 0x7f)) << shift;
        if (!(byte & 0x80)) {
            *out = result;
            return tb_true;
        }
        shift += 7;
    }
    return tb_false;
}

// decode unsigned leb128 (u64) from current stream offset
static __tb_inline__ tb_bool_t xm_binutils_wasm_read_u64_leb(tb_stream_ref_t istream, tb_uint64_t* out) {
    tb_uint64_t result = 0;
    tb_uint32_t shift = 0;
    tb_byte_t byte = 0;
    for (tb_size_t i = 0; i < XM_WASM_U64_LEB_MAX; i++) {
        if (!tb_stream_bread(istream, &byte, 1)) {
            return tb_false;
        }
        result |= ((tb_uint64_t)(byte & 0x7f)) << shift;
        if (!(byte & 0x80)) {
            *out = result;
            return tb_true;
        }
        shift += 7;
    }
    return tb_false;
}

// read wasm "name" (u32 leb length + bytes), truncate to fit buffer and skip remaining bytes
static __tb_inline__ tb_bool_t xm_binutils_wasm_read_name(tb_stream_ref_t istream, tb_char_t* name, tb_size_t name_size) {
    tb_uint32_t len = 0;
    if (!xm_binutils_wasm_read_u32_leb(istream, &len)) {
        return tb_false;
    }
    tb_size_t readn = (tb_size_t)tb_min((tb_uint32_t)(name_size > 0 ? name_size - 1 : 0), len);
    if (readn && !tb_stream_bread(istream, (tb_byte_t*)name, readn)) {
        return tb_false;
    }
    if (name_size) {
        name[readn] = '\0';
    }
    if (len > readn) {
        if (!tb_stream_skip(istream, (tb_hize_t)(len - readn))) {
            return tb_false;
        }
    }
    return tb_true;
}

// skip wasm limits used by table/memory types, supports wasm32 and wasm64(memory64)
static __tb_inline__ tb_bool_t xm_binutils_wasm_skip_limits(tb_stream_ref_t istream) {
    tb_uint32_t flags = 0;
    if (!xm_binutils_wasm_read_u32_leb(istream, &flags)) {
        return tb_false;
    }
    if (flags & XM_WASM_LIMITS_MEM64) {
        tb_uint64_t tmp64 = 0;
        if (!xm_binutils_wasm_read_u64_leb(istream, &tmp64)) {
            return tb_false;
        }
        if (flags & XM_WASM_LIMITS_HAS_MAX) {
            if (!xm_binutils_wasm_read_u64_leb(istream, &tmp64)) {
                return tb_false;
            }
        }
    } else {
        tb_uint32_t tmp32 = 0;
        if (!xm_binutils_wasm_read_u32_leb(istream, &tmp32)) {
            return tb_false;
        }
        if (flags & XM_WASM_LIMITS_HAS_MAX) {
            if (!xm_binutils_wasm_read_u32_leb(istream, &tmp32)) {
                return tb_false;
            }
        }
    }
    return tb_true;
}

// add one symbol table entry: {name=..., type=...}
static __tb_inline__ tb_void_t xm_binutils_wasm_add_symbol(lua_State* lua, tb_size_t* result_count, tb_char_t const* name, tb_char_t const* type) {
    lua_pushinteger(lua, (lua_Integer)(*result_count + 1));
    lua_newtable(lua);

    lua_pushstring(lua, "name");
    lua_pushstring(lua, name);
    lua_settable(lua, -3);

    lua_pushstring(lua, "type");
    lua_pushstring(lua, type);
    lua_settable(lua, -3);

    lua_settable(lua, -3);
    (*result_count)++;
}

// seek and validate wasm header at base_offset, leave stream offset after header
static __tb_inline__ tb_bool_t xm_binutils_wasm_check_header(tb_stream_ref_t istream, tb_hize_t base_offset) {
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }

    tb_uint8_t header[XM_WASM_HEADER_SIZE];
    if (!tb_stream_bread(istream, header, XM_WASM_HEADER_SIZE)) {
        return tb_false;
    }
    if (header[0] != XM_WASM_MAGIC0 || header[1] != XM_WASM_MAGIC1 || header[2] != XM_WASM_MAGIC2 || header[3] != XM_WASM_MAGIC3) {
        return tb_false;
    }
    return tb_true;
}

#endif
