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

#define TB_TRACE_MODULE_NAME "readsyms_ar"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
static tb_int_t xm_binutils_ar_detect_member_format(tb_stream_ref_t istream, tb_hize_t base_offset) {
    tb_uint8_t magic[8] = {0};
    if (!tb_stream_seek(istream, base_offset)) {
        return -1;
    }
    if (!tb_stream_bread(istream, magic, 8)) {
        tb_stream_seek(istream, base_offset);
        return -1;
    }
    tb_stream_seek(istream, base_offset);

    if (magic[0] == XM_WASM_MAGIC0 && magic[1] == XM_WASM_MAGIC1 && magic[2] == XM_WASM_MAGIC2 && magic[3] == XM_WASM_MAGIC3) {
        return XM_BINUTILS_FORMAT_WASM;
    }
    if (magic[0] == XM_ELF_MAGIC0 && magic[1] == XM_ELF_MAGIC1 && magic[2] == XM_ELF_MAGIC2 && magic[3] == XM_ELF_MAGIC3) {
        return XM_BINUTILS_FORMAT_ELF;
    }
    tb_uint32_t macho_magic = tb_bits_get_u32_be(magic);
    if (macho_magic == XM_MACHO_MAGIC_32 || macho_magic == XM_MACHO_MAGIC_64 ||
        macho_magic == XM_MACHO_MAGIC_32_BE || macho_magic == XM_MACHO_MAGIC_64_BE) {
        return XM_BINUTILS_FORMAT_MACHO;
    }
    return XM_BINUTILS_FORMAT_UNKNOWN;
}

/* parse BSD symbol table (__.SYMDEF or __.SYMDEF SORTED)
 *
 * Header:
 * - ranlib_size (uint32_t)
 * - ranlibs (struct ranlib[ranlib_size/8])
 * - strtab_size (uint32_t)
 * - strtab (char[strtab_size])
 *
 * struct ranlib {
 *     uint32_t ran_strx; // offset into string table
 *     uint32_t ran_off;  // offset into archive
 * };
 */
static tb_bool_t xm_binutils_ar_parse_bsd_symdef(tb_stream_ref_t istream, tb_hize_t member_size, lua_State* lua, int map_idx) {
    tb_hize_t start_pos = tb_stream_offset(istream);

    // read size of ranlib array
    tb_uint32_t ranlib_size = 0;
    if (!tb_stream_bread_u32_le(istream, &ranlib_size)) {
        return tb_false;
    }

    // sanity check
    if (ranlib_size == 0 || ranlib_size >= member_size) {
        tb_stream_seek(istream, start_pos);
        return tb_false;
    }

    // read ranlib array
    tb_size_t num_ranlibs = ranlib_size / 8;

    // allocate buffers
    tb_uint32_t* ran_strx = tb_nalloc_type(num_ranlibs, tb_uint32_t);
    tb_uint32_t* ran_off = tb_nalloc_type(num_ranlibs, tb_uint32_t);

    if (!ran_strx || !ran_off) {
        if (ran_strx) {
            tb_free(ran_strx);
        }
        if (ran_off) {
            tb_free(ran_off);
        }
        tb_stream_seek(istream, start_pos);
        return tb_false;
    }

    tb_size_t i;
    for (i = 0; i < num_ranlibs; i++) {
        if (!tb_stream_bread_u32_le(istream, &ran_strx[i]) ||
            !tb_stream_bread_u32_le(istream, &ran_off[i])) {
            tb_free(ran_strx);
            tb_free(ran_off);
            tb_stream_seek(istream, start_pos);
            return tb_false;
        }
    }

    // read string table size
    tb_uint32_t strtab_size = 0;
    if (!tb_stream_bread_u32_le(istream, &strtab_size)) {
        tb_free(ran_strx);
        tb_free(ran_off);
        tb_stream_seek(istream, start_pos);
        return tb_false;
    }

    // read string table
    tb_char_t* strtab = (tb_char_t*)tb_malloc_bytes(strtab_size);
    if (!strtab) {
        tb_free(ran_strx);
        tb_free(ran_off);
        tb_stream_seek(istream, start_pos);
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)strtab, strtab_size)) {
        tb_free(strtab);
        tb_free(ran_strx);
        tb_free(ran_off);
        tb_stream_seek(istream, start_pos);
        return tb_false;
    }

    // populate map
    for (i = 0; i < num_ranlibs; i++) {
        tb_uint32_t off = ran_off[i];
        tb_uint32_t strx = ran_strx[i];

        if (strx < strtab_size) {
            tb_char_t* name = strtab + strx;

            // add to map: map[off] = { {name=name, type="T"}, ... }
            lua_pushinteger(lua, off);
            lua_rawget(lua, map_idx);
            if (lua_isnil(lua, -1)) {
                lua_pop(lua, 1);
                lua_newtable(lua);
                lua_pushinteger(lua, off);
                lua_pushvalue(lua, -2);
                lua_rawset(lua, map_idx);
            }

            int count = (int)lua_objlen(lua, -1);
            lua_newtable(lua);
            lua_pushstring(lua, "name");
            lua_pushstring(lua, name);
            lua_settable(lua, -3);
            lua_pushstring(lua, "type");
            lua_pushstring(lua, "T");
            lua_settable(lua, -3);

            lua_rawseti(lua, -2, count + 1);
            lua_pop(lua, 1); // pop list
        }
    }

    tb_free(strtab);
    tb_free(ran_strx);
    tb_free(ran_off);
    return tb_true;
}

/* parse SysV symbol table (/)
 *
 * Header:
 * - num_symbols (uint32_t BE)
 * - offsets (uint32_t[num_symbols] BE)
 * - string table (null-terminated strings)
 */
static tb_bool_t xm_binutils_ar_parse_sysv_symdef(tb_stream_ref_t istream, tb_hize_t member_size, lua_State* lua, int map_idx) {
    tb_hize_t start_pos = tb_stream_offset(istream);

    // read number of symbols
    tb_uint32_t num_symbols = 0;
    if (!tb_stream_bread_u32_be(istream, &num_symbols)) {
        return tb_false;
    }

    // sanity check
    if (num_symbols == 0 || num_symbols * 4 >= member_size) {
        tb_stream_seek(istream, start_pos);
        return tb_false;
    }

    // read offsets
    tb_uint32_t* offsets = tb_nalloc_type(num_symbols, tb_uint32_t);
    if (!offsets) {
        tb_stream_seek(istream, start_pos);
        return tb_false;
    }

    tb_size_t i;
    for (i = 0; i < num_symbols; i++) {
        if (!tb_stream_bread_u32_be(istream, &offsets[i])) {
            tb_free(offsets);
            tb_stream_seek(istream, start_pos);
            return tb_false;
        }
    }

    // read string table
    tb_hize_t current = tb_stream_offset(istream);
    tb_hize_t strtab_size = member_size - (current - start_pos);

    tb_char_t* strtab = (tb_char_t*)tb_malloc_bytes((tb_size_t)strtab_size);
    if (!strtab) {
        tb_free(offsets);
        tb_stream_seek(istream, start_pos);
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)strtab, (tb_size_t)strtab_size)) {
        tb_free(strtab);
        tb_free(offsets);
        tb_stream_seek(istream, start_pos);
        return tb_false;
    }

    // populate map
    tb_char_t* p = strtab;
    tb_char_t* end = strtab + strtab_size;

    for (i = 0; i < num_symbols; i++) {
        if (p >= end) {
            break;
        }

        tb_char_t* name = p;
        tb_size_t len = tb_strlen(name);
        p += len + 1;

        tb_uint32_t off = offsets[i];

        // add to map
        lua_pushinteger(lua, off);
        lua_rawget(lua, map_idx);
        if (lua_isnil(lua, -1)) {
            lua_pop(lua, 1);
            lua_newtable(lua);
            lua_pushinteger(lua, off);
            lua_pushvalue(lua, -2);
            lua_rawset(lua, map_idx);
        }

        int count = (int)lua_objlen(lua, -1);
        lua_newtable(lua);
        lua_pushstring(lua, "name");
        lua_pushstring(lua, name);
        lua_settable(lua, -3);
        lua_pushstring(lua, "type");
        lua_pushstring(lua, "T");
        lua_settable(lua, -3);

        lua_rawseti(lua, -2, count + 1);
        lua_pop(lua, 1); // pop list
    }

    tb_free(strtab);
    tb_free(offsets);
    return tb_true;
}

/* read symbols from AR archive
 *
 * @param istream     the input stream
 * @param base_offset the base offset
 * @param lua         the lua state
 * @return            tb_true on success, tb_false on failure
 */
tb_bool_t xm_binutils_ar_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State* lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // check AR magic (!<arch>\n)
    if (!xm_binutils_ar_check_magic(istream, base_offset)) {
        return tb_false;
    }

    // get result list index
    int list_idx = lua_gettop(lua);

    // init map table for symbol table
    lua_newtable(lua);
    int map_idx = lua_gettop(lua);

    tb_bool_t ok = tb_true;
    tb_size_t object_count = 0;

    // iterate through AR members
    while (ok) {
        // save member header position
        tb_hize_t member_header_pos = tb_stream_offset(istream);

        /* read AR header
         * AR header is exactly 60 bytes: name[16] + date[12] + uid[6] + gid[6] + mode[8] + size[10] + fmag[2]
         */
        xm_ar_header_t header;
        if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
            // end of file
            break;
        }

        // parse member size
        tb_int64_t member_size = xm_binutils_ar_parse_decimal(header.size, 10);
        if (member_size < 0) {
            ok = tb_false;
            break;
        }

        // get member name
        tb_char_t member_name[256] = {0};
        tb_size_t name_len = 0;
        tb_hize_t name_bytes_read = 0;

        // get member name (handles both regular and extended name formats)
        tb_bool_t skip = tb_false;
        if (!xm_binutils_ar_get_member_name(istream, &header, member_name, sizeof(member_name), &name_len, &name_bytes_read)) {
            skip = tb_true;
        } else {
            if (xm_binutils_ar_is_symbol_table(member_name)) {
                /* parse symbol table
                 *
                 * The symbol table in the archive only contains symbol names and their offsets,
                 * but lacks detailed symbol type information (e.g., distinguishing between code and data).
                 * However, for object files that cannot be parsed (e.g., LTO bitcode) or unknown formats,
                 * parsing the symbol table serves as a robust fallback to ensure symbols are extracted.
                 */
                tb_hize_t current = tb_stream_offset(istream);
                if (tb_strcmp(member_name, "/") == 0) {
                    xm_binutils_ar_parse_sysv_symdef(istream, member_size, lua, map_idx);
                } else if (tb_strcmp(member_name, "//") != 0) {
                    xm_binutils_ar_parse_bsd_symdef(istream, member_size, lua, map_idx);
                }
                tb_stream_seek(istream, current); // restore position for skip
                skip = tb_true;
            } else if (!xm_binutils_ar_is_object_file(member_name)) {
                 // only extract object files
                skip = tb_true;
            }
        }

        if (skip) {
            // skip remaining data + padding using sequential read
            tb_hize_t skip_size = (tb_hize_t)member_size - name_bytes_read;
            if (member_size % 2) {
                skip_size++; // add padding
            }
            if (!tb_stream_skip(istream, skip_size)) {
                ok = tb_false;
                break;
            }
            continue;
        }

        // save current position
        tb_hize_t current_pos = tb_stream_offset(istream);

        // detect format
        tb_int_t format = xm_binutils_ar_detect_member_format(istream, current_pos);
        if (format != XM_BINUTILS_FORMAT_AR) {
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
            } else if (format == XM_BINUTILS_FORMAT_WASM) {
                read_ok = xm_binutils_wasm_read_symbols(istream, current_pos, lua);
            }

            if (!read_ok) {
                /* try get from map
                 *
                 * If parsing the object file fails (e.g. for LTO bitcode or unsupported formats),
                 * we fall back to using the symbols parsed from the archive symbol table.
                 * Although the type information is less accurate (defaulting to "T"),
                 * it guarantees that symbols are not lost.
                 *
                 * cast to lua_Integer to avoid warning C4244 on 32-bit MSVC
                 * member_header_pos is tb_hize_t (64-bit), but AR offsets are usually 32-bit
                 */
                lua_pushinteger(lua, (lua_Integer)member_header_pos);
                lua_rawget(lua, map_idx);
                if (!lua_isnil(lua, -1)) {
                    read_ok = tb_true;
                } else {
                    lua_pop(lua, 1);
                }
            }

            if (read_ok) {
                lua_settable(lua, -3);
                lua_rawseti(lua, list_idx, (int)(++object_count));
            } else {
                lua_pop(lua, 2); // pop symbols key and entry table
            }
        }

        // skip to next member
        tb_hize_t member_data_read = tb_stream_offset(istream) - current_pos;
        tb_hize_t remaining_size = (tb_hize_t)member_size - name_bytes_read - member_data_read;
        if (member_size % 2) {
            remaining_size++; // add padding
        }

        if (remaining_size > 0) {
            if (!tb_stream_skip(istream, remaining_size)) {
                ok = tb_false;
                break;
            }
        } else if (remaining_size < 0) {
            /* should not happen if readsyms functions respect boundaries, but just in case
             * seek back to correct position
             */
             if (!tb_stream_seek(istream, current_pos + (tb_hize_t)member_size - name_bytes_read + (member_size % 2))) {
                ok = tb_false;
                break;
             }
        }
    }

    lua_remove(lua, map_idx);
    return ok;
}
