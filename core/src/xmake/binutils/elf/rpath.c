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
 * @file        rpath.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "rpath_elf"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_binutils_elf_add_rpaths(lua_State *lua, tb_char_t const* rpath, tb_size_t* pcount) {
    if (!rpath || !*rpath) return;

    tb_char_t path[TB_PATH_MAXN];
    tb_char_t const* p = rpath;
    tb_char_t const* e = tb_null;
    while (*p) {
        e = tb_strchr(p, ':');
        tb_size_t n = e ? (tb_size_t)(e - p) : tb_strlen(p);
        if (n > 0) {
            if (n > sizeof(path) - 1) n = sizeof(path) - 1;
            tb_strncpy(path, p, n);
            path[n] = '\0';
            
            lua_pushinteger(lua, *pcount + 1);
            lua_pushstring(lua, path);
            lua_settable(lua, -3);
            (*pcount)++;
        }
        if (e) p = e + 1;
        else break;
    }
}

static tb_bool_t xm_binutils_elf_rpath_list_32(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // read ELF header
    xm_elf32_header_t header;
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
        return tb_false;
    }

    // find .dynamic section info
    tb_uint32_t dynamic_offset = 0;
    tb_uint32_t dynamic_size = 0;
    tb_uint32_t strtab_offset = 0;

    // try to find from section headers first
    if (header.e_shoff != 0 && header.e_shnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_shoff)) {
            for (tb_uint16_t i = 0; i < header.e_shnum; i++) {
                xm_elf32_section_t section;
                if (!tb_stream_bread(istream, (tb_byte_t*)&section, sizeof(section))) {
                    break;
                }

                if (section.sh_type == XM_ELF_SHT_DYNAMIC) {
                    dynamic_offset = section.sh_offset;
                    dynamic_size = section.sh_size;

                    // find string table via sh_link
                    xm_elf32_section_t strtab_section;
                    if (tb_stream_seek(istream, base_offset + header.e_shoff + section.sh_link * sizeof(xm_elf32_section_t)) &&
                        tb_stream_bread(istream, (tb_byte_t*)&strtab_section, sizeof(strtab_section))) {
                        strtab_offset = strtab_section.sh_offset;
                    }
                    break;
                }
            }
        }
    }

    // fallback to program headers if not found in sections
    if ((dynamic_offset == 0 || strtab_offset == 0) && header.e_phoff != 0 && header.e_phnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
            for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                xm_elf32_phdr_t phdr;
                if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) {
                    break;
                }
                if (phdr.p_type == XM_ELF_PT_DYNAMIC) {
                    dynamic_offset = phdr.p_offset;
                    dynamic_size = phdr.p_memsz; // usually p_filesz == p_memsz for dynamic
                    break;
                }
            }
        }

        if (dynamic_offset > 0 && dynamic_size > 0) {
            // read dynamic entries to find strtab address
            tb_uint32_t strtab_vaddr = 0;
            tb_uint32_t count = dynamic_size / sizeof(xm_elf32_dynamic_t);
            if (tb_stream_seek(istream, base_offset + dynamic_offset)) {
                for (tb_uint32_t i = 0; i < count; i++) {
                    xm_elf32_dynamic_t dyn;
                    if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) {
                        break;
                    }
                    if (dyn.d_tag == XM_ELF_DT_STRTAB) {
                        strtab_vaddr = dyn.d_un.d_val;
                        break;
                    }
                }
            }

            if (strtab_vaddr > 0) {
                // map strtab vaddr to file offset using PT_LOAD
                if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
                    for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                        xm_elf32_phdr_t phdr;
                        if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) {
                            break;
                        }
                        if (phdr.p_type == XM_ELF_PT_LOAD && strtab_vaddr >= phdr.p_vaddr && strtab_vaddr < phdr.p_vaddr + phdr.p_memsz) {
                            strtab_offset = phdr.p_offset + (strtab_vaddr - phdr.p_vaddr);
                            break;
                        }
                    }
                }
            }
        }
    }

    if (dynamic_offset == 0 || strtab_offset == 0) {
        return tb_true; // no dynamic section or strtab found
    }

    // read dynamic entries
    tb_uint32_t count = dynamic_size / sizeof(xm_elf32_dynamic_t);
    if (!tb_stream_seek(istream, base_offset + dynamic_offset)) {
        return tb_false;
    }

    tb_char_t rpath[8192] = {0};
    tb_char_t runpath[8192] = {0};
    for (tb_uint32_t i = 0; i < count; i++) {
        xm_elf32_dynamic_t dyn;
        if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) {
            break;
        }

        if (dyn.d_tag == XM_ELF_DT_NULL) {
            break;
        }

        if (dyn.d_tag == XM_ELF_DT_RPATH) {
             xm_binutils_read_string(istream, base_offset + strtab_offset + dyn.d_un.d_val, rpath, sizeof(rpath));
        } else if (dyn.d_tag == XM_ELF_DT_RUNPATH) {
             xm_binutils_read_string(istream, base_offset + strtab_offset + dyn.d_un.d_val, runpath, sizeof(runpath));
        }
    }

    tb_size_t result_count = 0;
    if (runpath[0]) {
        xm_binutils_elf_add_rpaths(lua, runpath, &result_count);
    } else if (rpath[0]) {
        xm_binutils_elf_add_rpaths(lua, rpath, &result_count);
    }

    return tb_true;
}

static tb_bool_t xm_binutils_elf_rpath_list_64(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // read ELF header
    xm_elf64_header_t header;
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
        return tb_false;
    }

    // find .dynamic section info
    tb_uint64_t dynamic_offset = 0;
    tb_uint64_t dynamic_size = 0;
    tb_uint64_t strtab_offset = 0;

    // try to find from section headers first
    if (header.e_shoff != 0 && header.e_shnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_shoff)) {
            for (tb_uint16_t i = 0; i < header.e_shnum; i++) {
                xm_elf64_section_t section;
                if (!tb_stream_bread(istream, (tb_byte_t*)&section, sizeof(section))) {
                    break;
                }

                if (section.sh_type == XM_ELF_SHT_DYNAMIC) {
                    dynamic_offset = section.sh_offset;
                    dynamic_size = section.sh_size;

                    // find string table via sh_link
                    xm_elf64_section_t strtab_section;
                    if (tb_stream_seek(istream, base_offset + header.e_shoff + section.sh_link * sizeof(xm_elf64_section_t)) &&
                        tb_stream_bread(istream, (tb_byte_t*)&strtab_section, sizeof(strtab_section))) {
                        strtab_offset = strtab_section.sh_offset;
                    }
                    break;
                }
            }
        }
    }

    // fallback to program headers if not found in sections
    if ((dynamic_offset == 0 || strtab_offset == 0) && header.e_phoff != 0 && header.e_phnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
            for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                xm_elf64_phdr_t phdr;
                if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) {
                    break;
                }
                if (phdr.p_type == XM_ELF_PT_DYNAMIC) {
                    dynamic_offset = phdr.p_offset;
                    dynamic_size = phdr.p_memsz;
                    break;
                }
            }
        }

        if (dynamic_offset > 0 && dynamic_size > 0) {
            // read dynamic entries to find strtab address
            tb_uint64_t strtab_vaddr = 0;
            tb_uint32_t count = (tb_uint32_t)(dynamic_size / sizeof(xm_elf64_dynamic_t));
            if (tb_stream_seek(istream, base_offset + dynamic_offset)) {
                for (tb_uint32_t i = 0; i < count; i++) {
                    xm_elf64_dynamic_t dyn;
                    if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) {
                        break;
                    }
                    if (dyn.d_tag == XM_ELF_DT_STRTAB) {
                        strtab_vaddr = dyn.d_un.d_val;
                        break;
                    }
                }
            }

            if (strtab_vaddr > 0) {
                // map strtab vaddr to file offset using PT_LOAD
                if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
                    for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                        xm_elf64_phdr_t phdr;
                        if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) {
                            break;
                        }
                        if (phdr.p_type == XM_ELF_PT_LOAD && strtab_vaddr >= phdr.p_vaddr && strtab_vaddr < phdr.p_vaddr + phdr.p_memsz) {
                            strtab_offset = phdr.p_offset + (strtab_vaddr - phdr.p_vaddr);
                            break;
                        }
                    }
                }
            }
        }
    }

    if (dynamic_offset == 0 || strtab_offset == 0) {
        return tb_true; // no dynamic section or strtab found
    }

    // read dynamic entries
    tb_uint32_t count = (tb_uint32_t)(dynamic_size / sizeof(xm_elf64_dynamic_t));
    if (!tb_stream_seek(istream, base_offset + dynamic_offset)) {
        return tb_false;
    }

    tb_char_t rpath[8192] = {0};
    tb_char_t runpath[8192] = {0};
    for (tb_uint32_t i = 0; i < count; i++) {
        xm_elf64_dynamic_t dyn;
        if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) {
            break;
        }

        if (dyn.d_tag == XM_ELF_DT_NULL) {
            break;
        }

        if (dyn.d_tag == XM_ELF_DT_RPATH) {
             xm_binutils_read_string(istream, base_offset + strtab_offset + dyn.d_un.d_val, rpath, sizeof(rpath));
        } else if (dyn.d_tag == XM_ELF_DT_RUNPATH) {
             xm_binutils_read_string(istream, base_offset + strtab_offset + dyn.d_un.d_val, runpath, sizeof(runpath));
        }
    }

    tb_size_t result_count = 0;
    if (runpath[0]) {
        xm_binutils_elf_add_rpaths(lua, runpath, &result_count);
    } else if (rpath[0]) {
        xm_binutils_elf_add_rpaths(lua, rpath, &result_count);
    }

    return tb_true;
}

tb_bool_t xm_binutils_elf_rpath_list(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // read ident
    tb_byte_t ident[16];
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, ident, sizeof(ident))) {
        return tb_false;
    }

    // check class
    if (ident[4] == 1) {
        return xm_binutils_elf_rpath_list_32(istream, base_offset, lua);
    } else if (ident[4] == 2) {
        return xm_binutils_elf_rpath_list_64(istream, base_offset, lua);
    }

    return tb_false;
}
