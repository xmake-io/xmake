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
 * @file        extractlib.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "extractlib"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* get member name from AR header, handling extended names (#N/L format)
 *
 * @param istream    the input stream
 * @param header     the AR header
 * @param name       output buffer for the name
 * @param name_size  size of the name buffer
 * @param name_len   output: actual name length
 * @return           tb_true on success, tb_false on failure
 */
static tb_bool_t xm_binutils_ar_get_member_name(tb_stream_ref_t istream, xm_ar_header_t const *header, tb_char_t *name, tb_size_t name_size, tb_size_t *name_len) {
    tb_assert_and_check_return_val(istream && header && name && name_size > 0 && name_len, tb_false);
    
    // check for extended name format (#N/L)
    if (header->name[0] == '#' && header->name[1] == '/') {
        // format: #N/L where N is name length, L is total data length (including name)
        tb_int64_t name_length = xm_binutils_ar_parse_decimal(header->name + 2, 14);
        if (name_length <= 0 || name_length >= (tb_int64_t)name_size) {
            return tb_false;
        }
        
        // read the actual name
        if (!tb_stream_bread(istream, (tb_byte_t*)name, (tb_size_t)name_length)) {
            return tb_false;
        }
        name[name_length] = '\0';
        *name_len = (tb_size_t)name_length;
        return tb_true;
    } else {
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
        return tb_true;
    }
}

/* check if member is a symbol table (should be skipped)
 *
 * @param name the member name
 * @return     tb_true if it's a symbol table, tb_false otherwise
 */
static __tb_inline__ tb_bool_t xm_binutils_ar_is_symbol_table(tb_char_t const *name) {
    if (!name) return tb_false;
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
    if (!name) return tb_false;
    tb_size_t len = tb_strlen(name);
    if (len == 0) return tb_false;
    
    // check common object file extensions
    if (len >= 2 && name[len - 2] == '.' && name[len - 1] == 'o') return tb_true;
    if (len >= 4 && tb_strcmp(name + len - 4, ".obj") == 0) return tb_true;
    
    // check if it's a COFF/ELF/Mach-O file by detecting format
    // For now, we'll extract all non-symbol-table members
    return tb_true;
}

/* generate unique filename to handle name conflicts
 *
 * @param base_name  the base filename
 * @param id         the unique ID
 * @param output     output buffer
 * @param output_size size of output buffer
 * @return           tb_true on success
 */
static tb_bool_t xm_binutils_ar_generate_unique_name(tb_char_t const *base_name, tb_uint32_t id, tb_char_t *output, tb_size_t output_size) {
    tb_assert_and_check_return_val(base_name && output && output_size > 0, tb_false);
    
    // find the last dot for extension
    tb_char_t const *ext = tb_strrchr(base_name, '.');
    if (ext) {
        tb_size_t base_len = (tb_size_t)(ext - base_name);
        tb_size_t ext_len = tb_strlen(ext);
        if (base_len + ext_len + 16 < output_size) {
            tb_snprintf(output, output_size, "%.*s_%u%s", (tb_int_t)base_len, base_name, id, ext);
            return tb_true;
        }
    } else {
        // no extension
        if (tb_strlen(base_name) + 16 < output_size) {
            tb_snprintf(output, output_size, "%s_%u", base_name, id);
            return tb_true;
        }
    }
    return tb_false;
}

/* extract AR archive to directory
 *
 * @param istream    the input stream
 * @param outputdir  the output directory
 * @return           tb_true on success, tb_false on failure
 */
tb_bool_t xm_binutils_ar_extract(tb_stream_ref_t istream, tb_char_t const *outputdir) {
    tb_assert_and_check_return_val(istream && outputdir, tb_false);
    
    // check AR magic (!<arch>\n)
    tb_uint8_t magic[8];
    if (!tb_stream_seek(istream, 0)) {
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
    
    // ensure output directory exists
    // check if directory already exists
    tb_file_info_t dir_info;
    if (!tb_file_info(outputdir, &dir_info)) {
        // directory doesn't exist, create it
        if (!tb_directory_create(outputdir)) {
            return tb_false;
        }
    }
    
    tb_bool_t ok = tb_true;
    
    // iterate through AR members
    while (ok) {
        // read AR header
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
        
        // check if extended name format (#N/L) was used
        if (header.name[0] == '#' && header.name[1] == '/') {
            // extended name: name is read from stream, so we need to track bytes read
            if (!xm_binutils_ar_get_member_name(istream, &header, member_name, sizeof(member_name), &name_len)) {
                // skip this member
                if (member_size > 0) {
                    if (!tb_stream_seek(istream, tb_stream_offset(istream) + (tb_hize_t)member_size)) {
                        ok = tb_false;
                        break;
                    }
                }
                continue;
            }
            // name was read from stream, adjust member_size
            name_bytes_read = (tb_hize_t)name_len;
        } else {
            // regular name: name is in header, not read from stream
            if (!xm_binutils_ar_get_member_name(istream, &header, member_name, sizeof(member_name), &name_len)) {
                // skip this member
                if (member_size > 0) {
                    if (!tb_stream_seek(istream, tb_stream_offset(istream) + (tb_hize_t)member_size)) {
                        ok = tb_false;
                        break;
                    }
                }
                continue;
            }
        }
        
        // skip symbol tables
        if (xm_binutils_ar_is_symbol_table(member_name)) {
            if (member_size > name_bytes_read) {
                tb_hize_t data_size = (tb_hize_t)member_size - name_bytes_read;
                if (!tb_stream_seek(istream, tb_stream_offset(istream) + data_size)) {
                    ok = tb_false;
                    break;
                }
            }
            continue;
        }
        
        // only extract object files
        if (!xm_binutils_ar_is_object_file(member_name)) {
            if (member_size > name_bytes_read) {
                tb_hize_t data_size = (tb_hize_t)member_size - name_bytes_read;
                if (!tb_stream_seek(istream, tb_stream_offset(istream) + data_size)) {
                    ok = tb_false;
                    break;
                }
            }
            continue;
        }
        
        // handle name conflicts by checking if file exists and renaming with ID
        tb_char_t output_name[512] = {0};
        tb_char_t output_path_check[1024] = {0};
        tb_snprintf(output_path_check, sizeof(output_path_check), "%s/%s", outputdir, member_name);
        
        // check if file already exists
        tb_file_info_t info;
        tb_uint32_t conflict_id = 1;
        if (tb_file_info(output_path_check, &info)) {
            // name conflict, try different IDs until we find an available name
            while (conflict_id < 10000) {  // reasonable limit
                if (!xm_binutils_ar_generate_unique_name(member_name, conflict_id, output_name, sizeof(output_name))) {
                    ok = tb_false;
                    break;
                }
                tb_snprintf(output_path_check, sizeof(output_path_check), "%s/%s", outputdir, output_name);
                if (!tb_file_info(output_path_check, &info)) {
                    // found available name
                    break;
                }
                conflict_id++;
            }
            if (conflict_id >= 10000) {
                ok = tb_false;
                break;
            }
        } else {
            // first occurrence, use original name
            tb_strlcpy(output_name, member_name, sizeof(output_name));
        }
        
        // build output path
        tb_char_t output_path[1024] = {0};
        tb_snprintf(output_path, sizeof(output_path), "%s/%s", outputdir, output_name);
        
        // create output file
        tb_stream_ref_t ostream = tb_stream_init_from_file(output_path, TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
        if (!ostream) {
            ok = tb_false;
            break;
        }
        
        if (!tb_stream_open(ostream)) {
            tb_stream_exit(ostream);
            ok = tb_false;
            break;
        }
        
        // copy member data to output file
        // member_size includes the name if extended format was used, so subtract name_bytes_read
        tb_byte_t buffer[4096];
        tb_hize_t remaining = (tb_hize_t)member_size - name_bytes_read;
        while (remaining > 0) {
            tb_size_t to_read = (tb_size_t)tb_min(remaining, (tb_hize_t)sizeof(buffer));
            if (!tb_stream_bread(istream, buffer, to_read)) {
                ok = tb_false;
                break;
            }
            if (!tb_stream_bwrit(ostream, buffer, to_read)) {
                ok = tb_false;
                break;
            }
            remaining -= to_read;
        }
        
        tb_stream_clos(ostream);
        tb_stream_exit(ostream);
        
        if (!ok) {
            break;
        }
        
        // align to 2-byte boundary (AR format requirement)
        tb_hize_t current_pos = tb_stream_offset(istream);
        if (current_pos & 1) {
            tb_byte_t padding;
            tb_stream_bread(istream, &padding, 1);
        }
        
    }
    
    return ok;
}


