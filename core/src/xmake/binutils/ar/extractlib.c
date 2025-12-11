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


/* generate unique filename to handle name conflicts
 *
 * @param base_name  the base filename
 * @param id         the unique ID
 * @param output     output buffer
 * @param output_size size of output buffer
 * @param output_len output: actual output length
 * @return           tb_true on success
 */
static tb_bool_t xm_binutils_ar_generate_unique_name(tb_char_t const *base_name, tb_uint32_t id, tb_char_t *output, tb_size_t output_size, tb_size_t* output_len) {
    tb_assert_and_check_return_val(base_name && output && output_size > 0 && output_len, tb_false);

    // find the last dot for extension
    tb_char_t const *ext = tb_strrchr(base_name, '.');
    tb_long_t n = -1;
    if (ext) {
        tb_size_t base_len = (tb_size_t)(ext - base_name);
        tb_size_t ext_len = tb_strlen(ext);
        if (base_len + ext_len + 16 < output_size) {
            n = tb_snprintf(output, output_size, "%.*s_%u%s", (tb_int_t)base_len, base_name, id, ext);
        }
    } else {
        // no extension
        if (tb_strlen(base_name) + 16 < output_size) {
            n = tb_snprintf(output, output_size, "%s_%u", base_name, id);
        }
    }

    if (n >= 0) {
        *output_len = (tb_size_t)n;
        return tb_true;
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

    // get output directory length
    tb_size_t outputdir_len = tb_strlen(outputdir);

    // check AR magic (!<arch>\n)
    if (!xm_binutils_ar_check_magic(istream, 0)) {
        return tb_false;
    }

    // ensure output directory exists
    // check if directory already exists
    if (!tb_file_info(outputdir, tb_null)) {
        // directory doesn't exist, create it
        if (!tb_directory_create(outputdir)) {
            return tb_false;
        }
    }

    tb_bool_t ok = tb_true;

    // iterate through AR members
    while (ok) {
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
        } else if (xm_binutils_ar_is_symbol_table(member_name)) {
            // skip symbol tables
            skip = tb_true;
        } else if (!xm_binutils_ar_is_object_file(member_name)) {
             // only extract object files
            skip = tb_true;
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

        // handle name conflicts by checking if file exists and renaming with ID
        tb_char_t output_name[512] = {0};
        tb_char_t output_path_check[1024] = {0};
        if (outputdir_len + 1 + name_len >= sizeof(output_path_check)) {
            ok = tb_false;
            break;
        }
        tb_snprintf(output_path_check, sizeof(output_path_check), "%s/%s", outputdir, member_name);

        // check if file already exists
        tb_uint32_t conflict_id = 1;
        tb_size_t output_name_len = name_len;
        if (tb_file_info(output_path_check, tb_null)) {
            // name conflict, try different IDs until we find an available name
            while (conflict_id < 10000) {  // reasonable limit
                if (!xm_binutils_ar_generate_unique_name(member_name, conflict_id, output_name, sizeof(output_name), &output_name_len)) {
                    ok = tb_false;
                    break;
                }
                if (outputdir_len + 1 + output_name_len >= sizeof(output_path_check)) {
                    ok = tb_false;
                    break;
                }
                tb_snprintf(output_path_check, sizeof(output_path_check), "%s/%s", outputdir, output_name);
                if (!tb_file_info(output_path_check, tb_null)) {
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
        if (outputdir_len + 1 + output_name_len >= sizeof(output_path)) {
            ok = tb_false;
            break;
        }
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
        tb_hize_t remaining = (tb_hize_t)member_size - name_bytes_read;
        if (!xm_binutils_stream_copy(istream, ostream, remaining)) {
            ok = tb_false;
        }

        tb_stream_clos(ostream);
        tb_stream_exit(ostream);

        tb_check_break(ok);

        // align to 2-byte boundary (AR format requirement)
        if (member_size % 2) {
             if (!tb_stream_skip(istream, 1)) {
                ok = tb_false;
                break;
            }
        }
    }

    return ok;
}
