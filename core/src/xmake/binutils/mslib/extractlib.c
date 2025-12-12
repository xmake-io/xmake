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
#define TB_TRACE_MODULE_NAME "mslib_extract"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* generate unique name for output file
 *
 * @param base_name      the base name
 * @param id             the unique id
 * @param output         output buffer
 * @param output_size    output buffer size
 * @param output_len     output: actual output length
 * @return               tb_true on success, tb_false on failure
 */
static tb_bool_t xm_binutils_mslib_generate_unique_name(tb_char_t const *base_name, tb_uint32_t id, tb_char_t *output, tb_size_t output_size, tb_size_t* output_len) {
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

/* extract MSVC lib archive to directory
 *
 * @param istream    the input stream
 * @param outputdir  the output directory
 * @param plain      extract all object files to the same directory
 * @return           tb_true on success, tb_false on failure
 */
tb_bool_t xm_binutils_mslib_extract(tb_stream_ref_t istream, tb_char_t const *outputdir, tb_bool_t plain) {
    tb_assert_and_check_return_val(istream && outputdir, tb_false);

    // check magic (!<arch>\n)
    if (!xm_binutils_mslib_check_magic(istream)) {
        return tb_false;
    }

    /* ensure output directory exists
     * check if directory already exists
     */
    if (!tb_file_info(outputdir, tb_null)) {
        // directory doesn't exist, create it
        if (!tb_directory_create(outputdir)) {
            return tb_false;
        }
    }

    tb_bool_t ok = tb_true;
    tb_char_t* longnames = tb_null;
    tb_size_t  longnames_size = 0;

    // iterate through members
    while (ok) {
        // read header
        xm_mslib_header_t header;
        if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
            // end of file
            break;
        }

        // parse member size
        tb_int64_t member_size = xm_binutils_mslib_parse_decimal(header.size, 10);
        if (member_size < 0) {
            ok = tb_false;
            break;
        }

        // parse member name
        tb_char_t member_name[256] = {0};
        tb_bool_t is_longname_table = tb_false;

        if (header.name[0] == '/') {
            if (header.name[1] == '/') {
                // long name table (//)
                is_longname_table = tb_true;
            } else if (tb_isdigit(header.name[1])) {
                // offset into long name table (/123)
                tb_int64_t offset = xm_binutils_mslib_parse_decimal(header.name + 1, 15);
                if (offset >= 0 && (tb_size_t)offset < longnames_size) {
                    /* copy from longnames
                     * names in longnames are null-terminated
                     */
                    tb_strlcpy(member_name, longnames + offset, sizeof(member_name));
                }
            } else {
                 /* symbol table or other special member (/)
                  * usually symbol table is just "/"
                  */
                 tb_strlcpy(member_name, "/", sizeof(member_name));
            }
        } else {
             // short name, ends with /
             tb_size_t i = 0;
             for (i = 0; i < 16 && header.name[i] != '/'; i++) {
                 member_name[i] = header.name[i];
             }
             member_name[i] = '\0';
        }

        if (is_longname_table) {
            tb_char_t* new_longnames = (tb_char_t*)tb_ralloc(longnames, (tb_size_t)member_size + 1);
            if (!new_longnames) {
                ok = tb_false;
                break;
            }
            longnames = new_longnames;
            if (!tb_stream_bread(istream, (tb_byte_t*)longnames, (tb_size_t)member_size)) {
                ok = tb_false;
                break;
            }
            longnames[member_size] = '\0';
            longnames_size = (tb_size_t)member_size;

            // align
            if (member_size % 2) {
                if (!tb_stream_skip(istream, 1)) {
                    ok = tb_false;
                    break;
                }
            }
            continue;
        }

        /* check if we should extract
         * skip empty names, symbol tables (/), long name table (//) - handled above,
         * and __.SYMDEF (SysV/BSD style symbol table, just in case)
         */
        if (member_name[0] == '\0' || tb_strcmp(member_name, "/") == 0 || tb_strcmp(member_name, "//") == 0 ||
            tb_strncmp(member_name, "__.SYMDEF", 9) == 0) {

            // skip member data
            if (!tb_stream_skip(istream, member_size)) {
                ok = tb_false;
                break;
            }

             // align
            if (member_size % 2) {
                 if (!tb_stream_skip(istream, 1)) {
                    ok = tb_false;
                    break;
                }
            }
            continue;
        }

        /* construct output path
         * replace \ with /
         */
        tb_size_t name_len = tb_strlen(member_name);
        for (tb_size_t i = 0; i < name_len; i++) {
            if (member_name[i] == '\\') {
                member_name[i] = '/';
            }
        }

        // check output path length
        tb_char_t output_path[1024];
        if (plain) {
            // get filename only
            tb_char_t const* name = tb_strrchr(member_name, '/');
            if (name) {
                name++;
            } else {
                name = member_name;
            }

            // check conflicts
            tb_char_t output_name[512];
            tb_size_t output_name_len = tb_strlen(name);
            tb_size_t outputdir_len = tb_strlen(outputdir);

            if (outputdir_len + 1 + output_name_len >= sizeof(output_path)) {
                 ok = tb_false;
                 break;
            }
            tb_snprintf(output_path, sizeof(output_path), "%s/%s", outputdir, name);

            if (tb_file_info(output_path, tb_null)) {
                // name conflict, try different IDs
                tb_uint32_t conflict_id = 1;
                while (conflict_id < 10000) {
                    if (!xm_binutils_mslib_generate_unique_name(name, conflict_id, output_name, sizeof(output_name), &output_name_len)) {
                        ok = tb_false;
                        break;
                    }
                    if (outputdir_len + 1 + output_name_len >= sizeof(output_path)) {
                         ok = tb_false;
                         break;
                    }
                    tb_snprintf(output_path, sizeof(output_path), "%s/%s", outputdir, output_name);
                    if (!tb_file_info(output_path, tb_null)) {
                        break;
                    }
                    conflict_id++;
                }
                tb_check_break(ok);
                if (conflict_id >= 10000) {
                    ok = tb_false;
                    break;
                }
            }
        } else {
            if (tb_strlen(outputdir) + 1 + name_len >= sizeof(output_path)) {
                 ok = tb_false;
                 break;
            }
            tb_snprintf(output_path, sizeof(output_path), "%s/%s", outputdir, member_name);
        }

        // ensure directory exists
        tb_char_t const* p = tb_strrchr(output_path, '/');
        if (p) {
            tb_char_t dir[1024];
            tb_size_t len = p - output_path;
            if (len < sizeof(dir)) {
                tb_strncpy(dir, output_path, len);
                dir[len] = '\0';
                if (!tb_file_info(dir, tb_null)) {
                    if (!tb_directory_create(dir)) {
                        ok = tb_false;
                        break;
                    }
                }
            }
        }

        // write file
        tb_stream_ref_t ostream = tb_stream_init_from_file(output_path, TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
        if (ostream) {
            if (tb_stream_open(ostream)) {
                if (!xm_binutils_stream_copy(istream, ostream, member_size)) {
                    ok = tb_false;
                }
            } else {
                ok = tb_false;
            }
            tb_stream_exit(ostream);
        } else {
            ok = tb_false;
        }
        tb_check_break(ok);

        // align to 2-byte boundary
        if (member_size % 2) {
             if (!tb_stream_skip(istream, 1)) {
                ok = tb_false;
                break;
            }
        }
    }

    if (longnames) {
        tb_free(longnames);
    }
    return ok;
}
