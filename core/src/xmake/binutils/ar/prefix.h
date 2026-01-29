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
#ifndef XM_BINUTILS_AR_PREFIX_H
#define XM_BINUTILS_AR_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../coff/prefix.h"
#include "../elf/prefix.h"
#include "../macho/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * forward declarations
 */
extern tb_bool_t xm_binutils_coff_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_elf_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_macho_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_int_t xm_binutils_format_detect(tb_stream_ref_t istream);

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
#include "tbox/prefix/packed.h"
typedef struct __xm_ar_header_t {
    tb_char_t name[16];   // file name (null-padded)
    tb_char_t date[12];   // modification time (decimal)
    tb_char_t uid[6];     // user ID (decimal)
    tb_char_t gid[6];     // group ID (decimal)
    tb_char_t mode[8];    // file mode (octal)
    tb_char_t size[10];   // file size (decimal)
    tb_char_t fmag[2];    // magic: "`\n"
} __tb_packed__ xm_ar_header_t;
#include "tbox/prefix/packed.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline implementation
 */

/* parse decimal number from string
 *
 * @param str the string
 * @param len the length
 * @return    the parsed number, or -1 on error
 */
static __tb_inline__ tb_int64_t xm_binutils_ar_parse_decimal(tb_char_t const *str, tb_size_t len) {
    tb_assert_and_check_return_val(str && len > 0, -1);

    tb_int64_t result = 0;
    for (tb_size_t i = 0; i < len; i++) {
        if (str[i] == ' ' || str[i] == '\0') {
            break;
        }
        if (str[i] < '0' || str[i] > '9') {
            return -1;
        }
        result = result * 10 + (str[i] - '0');
    }
    return result;
}

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
static __tb_inline__ tb_bool_t xm_binutils_ar_get_member_name(tb_stream_ref_t istream, xm_ar_header_t const* header, tb_char_t* name, tb_size_t name_size, tb_size_t* name_len, tb_hize_t* bytes_read) {
    tb_assert_and_check_return_val(istream && header && name && name_size > 0 && name_len && bytes_read, tb_false);
    *bytes_read = 0;

    /* check for extended name format (#N/L or #1/N)
     * In BSD AR format:
     * - #1/N means name is directly after header, N is total length (including name)
     * - #N/L means name length is N, total length is L
     * - #1/N can also mean name is in long name table at offset 1
     * We'll try to read the name directly from stream first
     */
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

            /* In BSD AR format, extended name is directly after header
             * The name data starts immediately after the header, no newline
             * Read exactly total_length bytes for the name section
             */
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

/* check AR magic (!<arch>\n)
 *
 * @param istream    the input stream
 * @param base_offset the base offset
 * @return           tb_true on success, tb_false on failure
 */
static __tb_inline__ tb_bool_t xm_binutils_ar_check_magic(tb_stream_ref_t istream, tb_hize_t base_offset) {
    tb_uint8_t magic[8];
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, magic, 8)) {
        return tb_false;
    }
    if (magic[0] != '!' || magic[1] != '<' || magic[2] != 'a' || magic[3] != 'r' ||
        magic[4] != 'c' || magic[5] != 'h' || (magic[6] != '>' && magic[6] != '\n') ||
        (magic[7] != '\n' && magic[7] != '\r')) {
        return tb_false;
    }
    return tb_true;
}

/* check if member is a symbol table (should be skipped)
 *
 * @param name the member name
 * @return     tb_true if it's a symbol table, tb_false otherwise
 */
static __tb_inline__ tb_bool_t xm_binutils_ar_is_symbol_table(tb_char_t const *name) {
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
static __tb_inline__ tb_bool_t xm_binutils_ar_is_object_file(tb_char_t const *name) {
    tb_assert_and_check_return_val(name, tb_false);
    tb_size_t len = tb_strlen(name);
    if (len == 0) {
        return tb_false;
    }

    // check common object file extensions
    if (len >= 2 && name[len - 2] == '.' && name[len - 1] == 'o') {
        return tb_true;
    }
    if (len >= 4 && tb_strcmp(name + len - 4, ".obj") == 0) {
        return tb_true;
    }

    // check if it's a COFF/ELF/Mach-O file by detecting format
    // For now, we'll extract all non-symbol-table members
    return tb_true;
}

#endif
