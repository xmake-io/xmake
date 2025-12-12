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

    // read section headers
    tb_hize_t section_offset = base_offset + sizeof(xm_coff_header_t) + header.opthdr;
    if (!tb_stream_seek(istream, section_offset)) {
        return tb_false;
    }

    tb_size_t result_count = 0;
    for (tb_uint16_t i = 0; i < header.nsects; i++) {
        xm_coff_section_t section;
        if (!tb_stream_bread(istream, (tb_byte_t*)&section, sizeof(section))) {
            return tb_false;
        }

        // check if it is .idata section (import directory table)
        // section name is 8 bytes, null-padded if shorter, or starts with '/' for long names
        // standard import section is named ".idata"
        if (tb_strncmp(section.name, ".idata", 6) == 0) {
            // read import directory table
            // The .idata section contains the Import Directory Table.
            // Each entry is 20 bytes (IMAGE_IMPORT_DESCRIPTOR).
            // The table ends with a null entry.

            // The .idata section usually contains multiple parts.
            // We need to parse the Import Directory Table which is typically at the beginning of the section data.
            // However, the section data might be raw data at 'ofs'
            
            // The VirtualAddress (vaddr) in the section header is the RVA where the section is loaded.
            // The PointerToRawData (ofs) is the file offset.
            
            // We need to iterate over IMAGE_IMPORT_DESCRIPTOR entries.
            // struct IMAGE_IMPORT_DESCRIPTOR {
            //     DWORD   OriginalFirstThunk; // RVA to original unbound IAT (PIMAGE_THUNK_DATA)
            //     DWORD   TimeDateStamp;      // 0 if not bound,
            //     DWORD   ForwarderChain;     // -1 if no forwarders
            //     DWORD   Name;               // RVA to DLL name
            //     DWORD   FirstThunk;         // RVA to IAT (if bound this IAT has actual addresses)
            // };
            
            // We need to map RVA to file offset.
            // RVA = vaddr + offset_in_section
            // FileOffset = ofs + offset_in_section
            // So, offset_in_section = RVA - vaddr
            // FileOffset = ofs + (RVA - vaddr)
            
            tb_uint32_t import_descriptors_offset = section.ofs;
            if (!tb_stream_seek(istream, base_offset + import_descriptors_offset)) {
                return tb_false;
            }

            while (1) {
                tb_uint32_t original_first_thunk;
                tb_uint32_t time_date_stamp;
                tb_uint32_t forwarder_chain;
                tb_uint32_t name_rva;
                tb_uint32_t first_thunk;

                if (!tb_stream_bread(istream, (tb_byte_t*)&original_first_thunk, 4)) break;
                if (!tb_stream_bread(istream, (tb_byte_t*)&time_date_stamp, 4)) break;
                if (!tb_stream_bread(istream, (tb_byte_t*)&forwarder_chain, 4)) break;
                if (!tb_stream_bread(istream, (tb_byte_t*)&name_rva, 4)) break;
                if (!tb_stream_bread(istream, (tb_byte_t*)&first_thunk, 4)) break;

                // check for null entry (end of table)
                if (original_first_thunk == 0 && name_rva == 0) {
                    break;
                }

                if (name_rva != 0) {
                    // map RVA to file offset to read the name
                    // We need to find the section that contains this RVA.
                    // Since we are iterating sections, we might need to seek back to read section headers again or cache them.
                    // For simplicity, we assume the name string is within the same .idata section or we can find it by scanning sections.
                    
                    // To do this correctly, we should scan all sections to find which one contains the RVA.
                    // But here we are inside a loop iterating sections.
                    // We can save current position and iterate sections from the beginning (or cached) to find the RVA.
                    
                    // Optimization: usually the name is in the same .idata section or a nearby .rdata section.
                    
                    tb_hize_t saved_pos_inner = tb_stream_offset(istream);
                    
                    // Find the section containing name_rva
                    tb_uint32_t name_file_offset = 0;
                    
                    // check current section first
                    if (name_rva >= section.vaddr && name_rva < section.vaddr + section.vsize) {
                        name_file_offset = section.ofs + (name_rva - section.vaddr);
                    } else {
                        // Scan all sections to find the RVA
                        tb_hize_t saved_pos_sections = tb_stream_offset(istream);
                        if (tb_stream_seek(istream, section_offset)) {
                            for (tb_uint16_t k = 0; k < header.nsects; k++) {
                                xm_coff_section_t s;
                                if (!tb_stream_bread(istream, (tb_byte_t*)&s, sizeof(s))) {
                                    break;
                                }
                                if (name_rva >= s.vaddr && name_rva < s.vaddr + s.vsize) {
                                    name_file_offset = s.ofs + (name_rva - s.vaddr);
                                    break;
                                }
                            }
                        }
                        tb_stream_seek(istream, saved_pos_sections); // restore to current descriptor
                    }

                    if (name_file_offset != 0) {
                         if (tb_stream_seek(istream, base_offset + name_file_offset)) {
                             tb_char_t dll_name[256];
                             tb_size_t pos = 0;
                             tb_byte_t c;
                             while (pos < sizeof(dll_name) - 1) {
                                 if (!tb_stream_bread(istream, &c, 1)) break;
                                 if (c == 0) break;
                                 dll_name[pos++] = (tb_char_t)c;
                             }
                             dll_name[pos] = '\0';
                             
                             if (pos > 0) {
                                 lua_pushinteger(lua, result_count + 1);
                                 lua_pushstring(lua, dll_name);
                                 lua_settable(lua, -3);
                                 result_count++;
                             }
                         }
                    }
                    
                    tb_stream_seek(istream, saved_pos_inner);
                }
            }
            // We found .idata and processed it. Usually there is only one import table.
            // But we should continue just in case or break?
            // Typically break is enough after processing the import table.
            break;
        }
    }

    if (result_count == 0) {
        lua_newtable(lua);
    }
    return tb_true;
}
