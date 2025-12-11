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
 * private implementation
 */

/* get member name from AR header, handling extended names (#N/L format)
 *
 * @param istream        the input stream
 * @param header         the AR header
 * @param name           output buffer for the name
 * @param name_size      size of the name buffer
 * @param name_len       output: actual name length
 * @param bytes_read     output: total bytes read from stream (including newline, for extended names)
 * @return               tb_true on success, tb_false on failure
 */
static tb_bool_t xm_binutils_ar_get_member_name(tb_stream_ref_t istream, xm_ar_header_t const* header, tb_char_t* name, tb_size_t name_size, tb_size_t* name_len, tb_hize_t* bytes_read) {
    tb_assert_and_check_return_val(istream && header && name && name_size > 0 && name_len && bytes_read, tb_false);
    *bytes_read = 0;

    // check for extended name format (#N/L or #1/N)
    // In BSD AR format:
    // - #1/N means name is directly after header, N is total length (including name)
    // - #N/L means name length is N, total length is L
    // - #1/N can also mean name is in long name table at offset 1
    // We'll try to read the name directly from stream first
    if (header->name[0] == '#') {
        // find the '/' separator
        tb_size_t slash_pos = 0;
        for (tb_size_t i = 1; i < 16; i++) {
            if (header->name[i] == '/') {
                slash_pos = i;
                break;
            }
        }

        if (slash_pos > 0 && slash_pos < 16) {
            // parse the number before '/' (could be name length or offset)
            tb_int64_t first_num = xm_binutils_ar_parse_decimal(header->name + 1, slash_pos - 1);
            // parse the number after '/' (total length)
            tb_int64_t total_length = xm_binutils_ar_parse_decimal(header->name + slash_pos + 1, 16 - slash_pos - 1);

            if (first_num <= 0 || total_length <= 0) {
                return tb_false;
            }

            // In BSD AR format, extended name is directly after header
            // The name data starts immediately after the header, no newline
            // Read exactly total_length bytes for the name section
            tb_byte_t c;
            tb_size_t name_bytes = 0;
            tb_hize_t bytes_read_so_far = 0;

            // Read name characters until we hit null terminator or reach total_length
            while (bytes_read_so_far < (tb_hize_t)total_length && name_bytes < name_size - 1) {
                if (!tb_stream_bread(istream, &c, 1)) {
                    return tb_false;
                }
                bytes_read_so_far++;

                if (c == '\0') {
                    // Stop reading name at null terminator, but continue reading to reach total_length
                    break;
                }
                // Include all characters in the name, including newlines if present
                name[name_bytes++] = (tb_char_t)c;
            }
            name[name_bytes] = '\0';
            *name_len = name_bytes;

            // Skip remaining bytes to reach total_length (there may be padding or null terminators)
            if (bytes_read_so_far < (tb_hize_t)total_length) {
                tb_hize_t remaining_to_read = (tb_hize_t)total_length - bytes_read_so_far;
                if (!tb_stream_skip(istream, remaining_to_read)) {
                    return tb_false;
                }
            }

            // Total bytes read = name + padding = total_length
            *bytes_read = (tb_hize_t)total_length;
            return tb_true;
        }
    }

    // regular name (null-terminated or space-padded)
    tb_size_t i = 0;
    for (i = 0; i < 16 && i < name_size - 1; i++) {
        if (header->name[i] == ' ' || header->name[i] == '\0' || header->name[i] == '/') {
            break;
        }
        name[i] = header->name[i];
    }
    name[i] = '\0';
    *name_len = i;
    *bytes_read = 0; // Regular names are in header, not read from stream
    return tb_true;
}

/* check if member is a symbol table (should be skipped)
 *
 * @param name the member name
 * @return     tb_true if it's a symbol table, tb_false otherwise
 */
static __tb_inline__ tb_bool_t xm_binutils_ar_is_symbol_table(tb_char_t const* name) {
    tb_assert_and_check_return_val(name, tb_false);
    return (tb_strcmp(name, "__.SYMDEF") == 0 || tb_strcmp(name, "__.SYMDEF SORTED") == 0 ||
            tb_strcmp(name, "/") == 0 || tb_strcmp(name, "//") == 0 ||
            tb_strncmp(name, "__.SYMDEF", 9) == 0);
}

/* check if member is an object file (based on extension)
 *
 * @param name the member name
 * @return     tb_true if it's likely an object file, tb_false otherwise
 */
static __tb_inline__ tb_bool_t xm_binutils_ar_is_object_file(tb_char_t const* name) {
    tb_assert_and_check_return_val(name, tb_false);
    tb_size_t len = tb_strlen(name);
    if (len == 0) return tb_false;

    // check common object file extensions
    if (len >= 2 && name[len - 2] == '.' && name[len - 1] == 'o') return tb_true;
    if (len >= 4 && tb_strcmp(name + len - 4, ".obj") == 0) return tb_true;

    // check if it's a COFF/ELF/Mach-O file by detecting format
    // For now, we'll extract all non-symbol-table members
    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

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
    if (!tb_stream_bread_u32_le(istream, &ranlib_size)) return tb_false;

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
        if (ran_strx) tb_free(ran_strx);
        if (ran_off) tb_free(ran_off);
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
    if (!tb_stream_bread_u32_be(istream, &num_symbols)) return tb_false;

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
        if (p >= end) break;
        
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

        // read AR header
        // AR header is exactly 60 bytes: name[16] + date[12] + uid[6] + gid[6] + mode[8] + size[10] + fmag[2]
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
                // parse symbol table
                //
                // The symbol table in the archive only contains symbol names and their offsets, 
                // but lacks detailed symbol type information (e.g., distinguishing between code and data).
                // However, for object files that cannot be parsed (e.g., LTO bitcode) or unknown formats, 
                // parsing the symbol table serves as a robust fallback to ensure symbols are extracted.
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
            if (member_size % 2) skip_size++; // add padding
            if (!tb_stream_skip(istream, skip_size)) {
                ok = tb_false;
                break;
            }
            continue;
        }

        // save current position
        tb_hize_t current_pos = tb_stream_offset(istream);
        
        // detect format
        tb_int_t format = xm_binutils_detect_format(istream);
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
            }

            if (!read_ok) {
                // try get from map
                //
                // If parsing the object file fails (e.g. for LTO bitcode or unsupported formats),
                // we fall back to using the symbols parsed from the archive symbol table.
                // Although the type information is less accurate (defaulting to "T"), 
                // it guarantees that symbols are not lost.
                lua_pushinteger(lua, member_header_pos);
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
        if (member_size % 2) remaining_size++; // add padding

        if (remaining_size > 0) {
            if (!tb_stream_skip(istream, remaining_size)) {
                ok = tb_false;
                break;
            }
        } else if (remaining_size < 0) {
            // should not happen if readsyms functions respect boundaries, but just in case
            // seek back to correct position
             if (!tb_stream_seek(istream, current_pos + (tb_hize_t)member_size - name_bytes_read + (member_size % 2))) {
                ok = tb_false;
                break;
             }
        }
    }

    lua_remove(lua, map_idx);
    return ok;
}
