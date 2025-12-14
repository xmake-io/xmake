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
 * @file        deplibs.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "deplibs_coff"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t xm_binutils_coff_deplibs(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // read COFF header
    xm_coff_header_t header;
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
        return tb_false;
    }

    // read optional header and import rva
    tb_uint32_t import_rva = 0;
    if (header.opthdr > 0) {
        // save current offset
        tb_hize_t opt_offset = tb_stream_offset(istream);
        
        // read magic
        tb_uint16_t magic = 0;
        if (tb_stream_bread(istream, (tb_byte_t*)&magic, sizeof(magic))) {
            // seek back
            if (tb_stream_seek(istream, opt_offset)) {
                if (magic == XM_PE32_MAGIC) {
                    xm_pe32_opt_header_t opt_header = {0};
                    if (tb_stream_bread(istream, (tb_byte_t*)&opt_header, tb_min(sizeof(opt_header), header.opthdr))) {
                        if (opt_header.number_of_rva_and_sizes > 1) {
                            import_rva = opt_header.data_directory[1].vaddr;
                        }
                    }
                } else if (magic == XM_PE32P_MAGIC) {
                    xm_pe32p_opt_header_t opt_header = {0};
                    if (tb_stream_bread(istream, (tb_byte_t*)&opt_header, tb_min(sizeof(opt_header), header.opthdr))) {
                        if (opt_header.number_of_rva_and_sizes > 1) {
                            import_rva = opt_header.data_directory[1].vaddr;
                        }
                    }
                }
            }
        }
    }

    // read section headers
    xm_coff_section_t* sections = tb_null;
    if (header.nsects > 0) {
        sections = tb_nalloc_type(header.nsects, xm_coff_section_t);
        if (sections) {
             tb_hize_t section_offset = base_offset + sizeof(xm_coff_header_t) + header.opthdr;
             if (tb_stream_seek(istream, section_offset)) {
                 if (!tb_stream_bread(istream, (tb_byte_t*)sections, header.nsects * sizeof(xm_coff_section_t))) {
                     tb_free(sections);
                     sections = tb_null;
                 }
             } else {
                 tb_free(sections);
                 sections = tb_null;
             }
        }
    }
    
    if (!sections) {
        if (header.nsects > 0) return tb_false;
        return tb_true;
    }
    tb_size_t result_count = 0;
    for (tb_uint16_t i = 0; i < header.nsects; i++) {
        xm_coff_section_t* section = &sections[i];

        // check if it is .idata section (import directory table)
        tb_bool_t found_idt = tb_false;
        tb_uint32_t idt_offset = 0;
        if (import_rva != 0) {
            // check if import rva is in this section
            if (import_rva >= section->vaddr && import_rva < section->vaddr + section->vsize) {
                idt_offset = section->ofs + (import_rva - section->vaddr);
                found_idt = tb_true;
            }
        } else {
            // fallback to check section name
            if (tb_strncmp(section->name, ".idata", 6) == 0) {
                idt_offset = section->ofs;
                found_idt = tb_true;
            }
        }

        if (found_idt) {
            /* read import directory table
             * The .idata section contains the Import Directory Table.
             * Each entry is 20 bytes (IMAGE_IMPORT_DESCRIPTOR).
             * The table ends with a null entry.
             */

            /* We need to iterate over IMAGE_IMPORT_DESCRIPTOR entries.
             * struct IMAGE_IMPORT_DESCRIPTOR {
             *     DWORD   OriginalFirstThunk; // RVA to original unbound IAT (PIMAGE_THUNK_DATA)
             *     DWORD   TimeDateStamp;      // 0 if not bound,
             *     DWORD   ForwarderChain;     // -1 if no forwarders
             *     DWORD   Name;               // RVA to DLL name
             *     DWORD   FirstThunk;         // RVA to IAT (if bound this IAT has actual addresses)
             * };
             */

            if (!tb_stream_seek(istream, idt_offset)) {
                if (sections) tb_free(sections);
                return tb_false;
            }

            while (1) {
                xm_coff_import_directory_table_t entry;
                if (!tb_stream_bread(istream, (tb_byte_t*)&entry, sizeof(entry))) {
                    break;
                }

                // check for null entry (end of table)
                if (entry.original_first_thunk == 0 && entry.name_rva == 0) {
                    break;
                }

                tb_uint32_t name_rva = tb_bits_le_to_ne_u32(entry.name_rva);

                if (name_rva != 0) {
                    /* map RVA to file offset to read the name
                     * We need to find the section that contains this RVA.
                     */

                    tb_hize_t saved_pos_inner = tb_stream_offset(istream);
                    tb_uint32_t name_file_offset = 0;

                    // Find the section containing name_rva
                    for (tb_uint16_t k = 0; k < header.nsects; k++) {
                        xm_coff_section_t* s = &sections[k];
                        if (name_rva >= s->vaddr && name_rva < s->vaddr + s->vsize) {
                            name_file_offset = s->ofs + (name_rva - s->vaddr);
                            break;
                        }
                    }

                    if (name_file_offset != 0) {
                         tb_char_t dll_name[256];
                         if (xm_binutils_read_string(istream, name_file_offset, dll_name, sizeof(dll_name)) && dll_name[0]) {
                             lua_pushinteger(lua, result_count + 1);
                             lua_pushstring(lua, dll_name);
                             lua_settable(lua, -3);
                             result_count++;
                         }
                    }

                    tb_stream_seek(istream, saved_pos_inner);
                }
            }
            break;
        }
    }

    if (sections) tb_free(sections);
    return tb_true;
}
