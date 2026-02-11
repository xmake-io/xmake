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
#define TB_TRACE_MODULE_NAME "wasm_readsyms"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_bool_t xm_binutils_wasm_parse_linking_symtab(tb_stream_ref_t istream, tb_hize_t payload_end, lua_State* lua, tb_size_t* result_count) {
    tb_uint32_t symcount = 0;
    if (!xm_binutils_wasm_read_u32_leb(istream, &symcount)) {
        return tb_false;
    }

    for (tb_uint32_t i = 0; i < symcount; i++) {
        tb_byte_t kind = 0;
        if (!tb_stream_bread(istream, &kind, 1)) {
            return tb_false;
        }

        tb_uint32_t flags = 0;
        if (!xm_binutils_wasm_read_u32_leb(istream, &flags)) {
            return tb_false;
        }

        tb_bool_t is_undef = (flags & XM_WASM_SYMTAB_FLAG_UNDEFINED) != 0;
        tb_char_t name[256] = {0};

        if (kind == XM_WASM_SYMTAB_KIND_FUNCTION || kind == XM_WASM_SYMTAB_KIND_GLOBAL ||
            kind == XM_WASM_SYMTAB_KIND_EVENT || kind == XM_WASM_SYMTAB_KIND_TABLE ||
            kind == XM_WASM_SYMTAB_KIND_TAG) {

            if (!is_undef) {
                tb_uint32_t index = 0;
                if (!xm_binutils_wasm_read_u32_leb(istream, &index)) {
                    return tb_false;
                }
            }
            if (!xm_binutils_wasm_read_name(istream, name, sizeof(name))) {
                return tb_false;
            }
        } else if (kind == XM_WASM_SYMTAB_KIND_DATA) {
            if (!xm_binutils_wasm_read_name(istream, name, sizeof(name))) {
                return tb_false;
            }
            if (!is_undef) {
                tb_uint32_t tmp = 0;
                if (!xm_binutils_wasm_read_u32_leb(istream, &tmp)) { // segment
                    return tb_false;
                }
                if (!xm_binutils_wasm_read_u32_leb(istream, &tmp)) { // offset
                    return tb_false;
                }
                if (!xm_binutils_wasm_read_u32_leb(istream, &tmp)) { // size
                    return tb_false;
                }
            }
        } else if (kind == XM_WASM_SYMTAB_KIND_SECTION) {
            tb_uint32_t section_index = 0;
            if (!xm_binutils_wasm_read_u32_leb(istream, &section_index)) {
                return tb_false;
            }
            if (!xm_binutils_wasm_read_name(istream, name, sizeof(name))) {
                return tb_false;
            }
        } else {
            return tb_false;
        }

        if (name[0]) {
            tb_char_t const* type = XM_WASM_SYM_DATA;
            if (is_undef) {
                type = XM_WASM_SYM_UNDEF;
            } else if (kind == XM_WASM_SYMTAB_KIND_FUNCTION) {
                type = XM_WASM_SYM_TEXT;
            }
            xm_binutils_wasm_add_symbol(lua, result_count, name, type);
        }

        if (tb_stream_offset(istream) > payload_end) {
            return tb_false;
        }
    }
    return tb_true;
}

static tb_bool_t xm_binutils_wasm_parse_custom_linking(tb_stream_ref_t istream, tb_hize_t payload_end, lua_State* lua, tb_size_t* result_count) {
    tb_uint32_t version = 0;
    if (!xm_binutils_wasm_read_u32_leb(istream, &version)) {
        return tb_false;
    }

    while (tb_stream_offset(istream) < payload_end) {
        tb_byte_t subsec_type = 0;
        if (!tb_stream_bread(istream, &subsec_type, 1)) {
            return tb_false;
        }

        tb_uint32_t subsec_size = 0;
        if (!xm_binutils_wasm_read_u32_leb(istream, &subsec_size)) {
            return tb_false;
        }

        tb_hize_t subsec_end = tb_stream_offset(istream) + (tb_hize_t)subsec_size;
        if (subsec_end > payload_end) {
            return tb_false;
        }

        if (subsec_type == XM_WASM_LINKING_SUBSEC_SYMTAB) {
            if (!xm_binutils_wasm_parse_linking_symtab(istream, subsec_end, lua, result_count)) {
                return tb_false;
            }
        }

        if (tb_stream_offset(istream) < subsec_end) {
            if (!tb_stream_seek(istream, subsec_end)) {
                return tb_false;
            }
        }
    }

    return version > 0 ? tb_true : tb_false;
}

static tb_bool_t xm_binutils_wasm_parse_custom_name(tb_stream_ref_t istream, tb_hize_t payload_end, lua_State* lua, tb_size_t* result_count) {
    // only use the name section as a fallback when we have no symbols yet
    if (*result_count != 0) {
        return tb_true;
    }

    while (tb_stream_offset(istream) < payload_end) {
        tb_byte_t subsec_type = 0;
        if (!tb_stream_bread(istream, &subsec_type, 1)) {
            return tb_false;
        }
        tb_uint32_t subsec_size = 0;
        if (!xm_binutils_wasm_read_u32_leb(istream, &subsec_size)) {
            return tb_false;
        }
        tb_hize_t subsec_end = tb_stream_offset(istream) + (tb_hize_t)subsec_size;
        if (subsec_end > payload_end) {
            return tb_false;
        }

        if (subsec_type == 1) {
            tb_uint32_t count = 0;
            if (!xm_binutils_wasm_read_u32_leb(istream, &count)) {
                return tb_false;
            }
            for (tb_uint32_t i = 0; i < count; i++) {
                tb_uint32_t index = 0;
                if (!xm_binutils_wasm_read_u32_leb(istream, &index)) {
                    return tb_false;
                }
                tb_char_t name[256] = {0};
                if (!xm_binutils_wasm_read_name(istream, name, sizeof(name))) {
                    return tb_false;
                }
                if (name[0]) {
                    xm_binutils_wasm_add_symbol(lua, result_count, name, XM_WASM_SYM_TEXT);
                }
                if (tb_stream_offset(istream) > subsec_end) {
                    return tb_false;
                }
            }
        }

        if (tb_stream_offset(istream) < subsec_end) {
            if (!tb_stream_seek(istream, subsec_end)) {
                return tb_false;
            }
        }
    }
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */
tb_bool_t xm_binutils_wasm_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);
    if (!xm_binutils_wasm_check_header(istream, base_offset)) {
        return tb_false;
    }

    lua_newtable(lua);
    tb_size_t result_count = 0;

    // parse wasm sections until EOF, collect imports/exports as symbols
    for (;;) {
        tb_byte_t section_id = 0;
        if (!tb_stream_bread(istream, &section_id, 1)) {
            break;
        }

        tb_uint32_t payload_len = 0;
        if (!xm_binutils_wasm_read_u32_leb(istream, &payload_len)) {
            break;
        }

        tb_hize_t payload_start = tb_stream_offset(istream);
        tb_hize_t payload_end = payload_start + (tb_hize_t)payload_len;
        if (payload_len == 0) {
            continue;
        }

        if (section_id == 0) {
            // custom section: name + custom payload
            tb_char_t custom_name[64] = {0};
            if (!xm_binutils_wasm_read_name(istream, custom_name, sizeof(custom_name))) {
                break;
            }

            if (!tb_strcmp(custom_name, XM_WASM_CUSTOM_LINKING)) {
                if (!xm_binutils_wasm_parse_custom_linking(istream, payload_end, lua, &result_count)) {
                    break;
                }
            } else if (!tb_strcmp(custom_name, XM_WASM_CUSTOM_NAME)) {
                if (!xm_binutils_wasm_parse_custom_name(istream, payload_end, lua, &result_count)) {
                    break;
                }
            }
        } else if (section_id == XM_WASM_SECTION_IMPORT) {
            // import section: (vec import), each import => undefined symbol
            tb_uint32_t count = 0;
            if (xm_binutils_wasm_read_u32_leb(istream, &count)) {
                for (tb_uint32_t i = 0; i < count; i++) {
                    tb_char_t module[256] = {0};
                    tb_char_t field[256] = {0};
                    if (!xm_binutils_wasm_read_name(istream, module, sizeof(module))) {
                        break;
                    }
                    if (!xm_binutils_wasm_read_name(istream, field, sizeof(field))) {
                        break;
                    }
                    tb_byte_t kind = 0;
                    if (!tb_stream_bread(istream, &kind, 1)) {
                        break;
                    }
                    tb_uint32_t tmp = 0;
                    if (kind == XM_WASM_KIND_FUNC) {
                        // type index (u32)
                        if (!xm_binutils_wasm_read_u32_leb(istream, &tmp)) {
                            break;
                        }
                    } else if (kind == XM_WASM_KIND_TABLE) {
                        // table type: elemtype + limits
                        if (!tb_stream_bread(istream, (tb_byte_t*)&kind, 1)) {
                            break;
                        }
                        if (!xm_binutils_wasm_skip_limits(istream)) {
                            break;
                        }
                    } else if (kind == XM_WASM_KIND_MEMORY) {
                        // memory type: limits
                        if (!xm_binutils_wasm_skip_limits(istream)) {
                            break;
                        }
                    } else if (kind == XM_WASM_KIND_GLOBAL) {
                        // global type: valtype + mut
                        tb_byte_t b = 0;
                        if (!tb_stream_bread(istream, &b, 1)) {
                            break;
                        }
                        if (!tb_stream_bread(istream, &b, 1)) {
                            break;
                        }
                    } else if (kind == XM_WASM_KIND_TAG) {
                        // tag: attribute + type index
                        if (!xm_binutils_wasm_read_u32_leb(istream, &tmp)) {
                            break;
                        }
                    } else {
                        break;
                    }

                    // keep consistent with nm-style output: use the imported field name as symbol name
                    if (field[0]) {
                        xm_binutils_wasm_add_symbol(lua, &result_count, field, XM_WASM_SYM_UNDEF);
                    } else if (module[0]) {
                        xm_binutils_wasm_add_symbol(lua, &result_count, module, XM_WASM_SYM_UNDEF);
                    }
                }
            }
        } else if (section_id == XM_WASM_SECTION_EXPORT) {
            // export section: (vec export), each export => defined symbol
            tb_uint32_t count = 0;
            if (xm_binutils_wasm_read_u32_leb(istream, &count)) {
                for (tb_uint32_t i = 0; i < count; i++) {
                    tb_char_t name[256] = {0};
                    if (!xm_binutils_wasm_read_name(istream, name, sizeof(name))) {
                        break;
                    }
                    tb_byte_t kind = 0;
                    if (!tb_stream_bread(istream, &kind, 1)) {
                        break;
                    }
                    tb_uint32_t index = 0;
                    if (!xm_binutils_wasm_read_u32_leb(istream, &index)) {
                        break;
                    }
                    if (name[0]) {
                        // keep consistent with other formats: function => "T", others => "D"
                        tb_char_t const* type = XM_WASM_SYM_DATA;
                        if (kind == XM_WASM_KIND_FUNC) {
                            type = XM_WASM_SYM_TEXT;
                        }
                        xm_binutils_wasm_add_symbol(lua, &result_count, name, type);
                    }
                }
            }
        }

        // always seek to end of section payload to continue scanning
        if (tb_stream_offset(istream) < payload_end) {
            if (!tb_stream_seek(istream, payload_end)) {
                break;
            }
        }
    }

    return tb_true;
}
