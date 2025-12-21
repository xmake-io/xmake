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
 * @file        bin2macho.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "bin2macho"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

static tb_bool_t xm_binutils_bin2macho_dump_64(tb_stream_ref_t istream,
                                             tb_stream_ref_t ostream,
                                             tb_char_t const *symbol_prefix,
                                             tb_char_t const *plat,
                                             tb_char_t const *arch,
                                             tb_char_t const *basename,
                                             tb_uint32_t minos,
                                             tb_uint32_t sdk,
                                             tb_bool_t zeroend) {
    tb_assert_and_check_return_val(istream && ostream, tb_false);

    // get file size
    tb_hong_t filesize = tb_stream_size(istream);
    if (filesize < 0 || filesize > 0xffffffffU) {
        return tb_false;
    }
    tb_uint32_t datasize = (tb_uint32_t)filesize;
    // add null terminator if zeroend is true
    if (zeroend) {
        if (datasize >= 0xffffffffU) {
            return tb_false; // would overflow
        }
        datasize++;
    }

    // generate symbol names from filename
    tb_char_t symbol_name[256] = {0};
    tb_char_t symbol_start[256] = {0};
    tb_char_t symbol_end[256] = {0};

    // use basename or default to "data"
    if (!basename || !basename[0]) {
        basename = "data";
    }

    // build symbol name
    // On macOS, C compiler adds an underscore prefix, so we generate symbols with two underscores
    // (C code declares _binary_xxx, compiler generates __binary_xxx in object file, so we define __binary_xxx)
    if (symbol_prefix) {
        tb_snprintf(symbol_name, sizeof(symbol_name), "_%s%s", symbol_prefix, basename);
    } else {
        tb_snprintf(symbol_name, sizeof(symbol_name), "__binary_%s", basename);
    }

    // replace non-alphanumeric with underscore
    xm_binutils_sanitize_symbol_name(symbol_name);

    tb_snprintf(symbol_start, sizeof(symbol_start), "%s_start", symbol_name);
    tb_snprintf(symbol_end, sizeof(symbol_end), "%s_end", symbol_name);

    // calculate offsets
    tb_uint32_t header_size = sizeof(xm_macho_header_64_t);
    tb_uint32_t segment_cmd_size = sizeof(xm_macho_segment_command_64_t);
    tb_uint32_t section_size = sizeof(xm_macho_section_64_t);
    tb_uint32_t symtab_cmd_size = sizeof(xm_macho_symtab_command_t);
    tb_uint32_t build_version_cmd_size = sizeof(xm_macho_build_version_command_t);
    tb_uint32_t segment_cmd_total_size = segment_cmd_size + section_size;
    tb_uint32_t data_offset = xm_binutils_macho_align(header_size + segment_cmd_total_size + symtab_cmd_size + build_version_cmd_size, 8);
    tb_uint32_t data_size = datasize;
    tb_uint32_t data_end_offset = data_offset + data_size;
    tb_uint32_t symtab_offset = xm_binutils_macho_align(data_end_offset, 8);
    tb_uint32_t nlist_size = sizeof(xm_macho_nlist_64_t);
    tb_uint32_t nlist_count = 2; // start, end
    tb_uint32_t strtab_offset = symtab_offset + nlist_size * nlist_count;
    tb_uint32_t strtab_size = 4; // initial 4-byte size field
    tb_size_t start_len = tb_strlen(symbol_start);
    tb_size_t end_len = tb_strlen(symbol_end);
    strtab_size += (tb_uint32_t)(start_len + 1);
    strtab_size += (tb_uint32_t)(end_len + 1);
    strtab_size = xm_binutils_macho_align(strtab_size, 8);

    // write Mach-O header
    xm_macho_header_64_t header;
    tb_memset(&header, 0, sizeof(header));
    header.magic = XM_MACHO_MAGIC_64;
    header.cputype = xm_binutils_macho_get_cputype(arch);
    header.cpusubtype = xm_binutils_macho_get_cpusubtype(arch);
    header.filetype = XM_MACHO_FILE_TYPE_OBJECT;
    header.ncmds = 3; // segment + symtab + build_version
    header.sizeofcmds = segment_cmd_total_size + symtab_cmd_size + build_version_cmd_size;
    header.flags = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&header, sizeof(header))) {
        return tb_false;
    }

    // write segment command
    xm_macho_segment_command_64_t segment;
    tb_memset(&segment, 0, sizeof(segment));
    segment.cmd = XM_MACHO_LC_SEGMENT_64;
    segment.cmdsize = segment_cmd_total_size;
    tb_strncpy(segment.segname, "__TEXT", 16);
    segment.vmaddr = 0;
    segment.vmsize = data_size;
    segment.fileoff = data_offset;
    segment.filesize = data_size;
    segment.maxprot = XM_MACHO_VM_PROT_READ | XM_MACHO_VM_PROT_EXECUTE; // VM_PROT_READ | VM_PROT_EXECUTE (r-x)
    segment.initprot = XM_MACHO_VM_PROT_READ | XM_MACHO_VM_PROT_EXECUTE; // VM_PROT_READ | VM_PROT_EXECUTE (r-x)
    segment.nsects = 1;
    segment.flags = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&segment, sizeof(segment))) {
        return tb_false;
    }

    // write section
    xm_macho_section_64_t section;
    tb_memset(&section, 0, sizeof(section));
    tb_strncpy(section.sectname, "__const", 16);
    tb_strncpy(section.segname, "__TEXT", 16);
    section.addr = 0;
    section.size = data_size;
    section.offset = data_offset;
    section.align = 3; // 2^3 = 8 bytes
    section.reloff = 0;
    section.nreloc = 0;
    section.flags = XM_MACHO_SECT_TYPE_REGULAR | XM_MACHO_SECT_ATTR_SOME_INITS;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section, sizeof(section))) {
        return tb_false;
    }

    // write symtab command
    xm_macho_symtab_command_t symtab;
    tb_memset(&symtab, 0, sizeof(symtab));
    symtab.cmd = XM_MACHO_LC_SYMTAB;
    symtab.cmdsize = symtab_cmd_size;
    symtab.symoff = symtab_offset;
    symtab.nsyms = nlist_count;
    symtab.stroff = strtab_offset;
    symtab.strsize = strtab_size;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&symtab, sizeof(symtab))) {
        return tb_false;
    }

    // write build version command
    xm_macho_build_version_command_t build_version;
    tb_memset(&build_version, 0, sizeof(build_version));
    build_version.cmd = XM_MACHO_LC_BUILD_VERSION;
    build_version.cmdsize = build_version_cmd_size;
    build_version.platform = xm_binutils_macho_get_platform(plat);
    build_version.minos = minos;
    build_version.sdk = sdk;
    build_version.ntools = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&build_version, sizeof(build_version))) {
        return tb_false;
    }

    // align to 8 bytes
    tb_uint32_t padding = data_offset - (header_size + segment_cmd_total_size + symtab_cmd_size + build_version_cmd_size);
    if (padding > 0) {
        tb_byte_t zero = 0;
        while (padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write section data
    if (!xm_binutils_stream_copy(istream, ostream, filesize)) {
        return tb_false;
    }
    // append null terminator if zeroend is true
    if (zeroend) {
        tb_byte_t zero = 0;
        if (!tb_stream_bwrit(ostream, &zero, 1)) {
            return tb_false;
        }
    }

    // align to 8 bytes
    padding = symtab_offset - data_end_offset;
    if (padding > 0) {
        tb_byte_t zero = 0;
        while (padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write symbol table
    // strx starts from 4 (after 4-byte size field)
    tb_uint32_t strx = 4;
    // symbol 0: _binary_xxx_start
    xm_macho_nlist_64_t nlist_start;
    tb_memset(&nlist_start, 0, sizeof(nlist_start));
    nlist_start.strx = strx;
    nlist_start.type = XM_MACHO_N_TYPE_SECT | XM_MACHO_N_EXT; // N_SECT | N_EXT
    nlist_start.sect = 1;
    nlist_start.desc = 0;
    nlist_start.value = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&nlist_start, sizeof(nlist_start))) {
        return tb_false;
    }
    strx += (tb_uint32_t)(start_len + 1);

    // symbol 1: _binary_xxx_end
    xm_macho_nlist_64_t nlist_end;
    tb_memset(&nlist_end, 0, sizeof(nlist_end));
    nlist_end.strx = strx;
    nlist_end.type = XM_MACHO_N_TYPE_SECT | XM_MACHO_N_EXT; // N_SECT | N_EXT
    nlist_end.sect = 1;
    nlist_end.desc = 0;
    nlist_end.value = data_size;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&nlist_end, sizeof(nlist_end))) {
        return tb_false;
    }
    strx += (tb_uint32_t)(end_len + 1);

    // align to 8 bytes
    padding = strtab_offset - (symtab_offset + nlist_size * nlist_count);
    if (padding > 0) {
        tb_byte_t zero = 0;
        while (padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write string table
    tb_stream_bwrit(ostream, (tb_byte_t const *)&strtab_size, 4);
    tb_stream_bwrit(ostream, (tb_byte_t const *)symbol_start, start_len);
    tb_byte_t null = 0;
    tb_stream_bwrit(ostream, &null, 1);
    tb_stream_bwrit(ostream, (tb_byte_t const *)symbol_end, end_len);
    tb_stream_bwrit(ostream, &null, 1);

    // align string table to 8 bytes
    padding = strtab_size - (4 + (tb_uint32_t)start_len + 1 + (tb_uint32_t)end_len + 1);
    if (padding > 0) {
        tb_byte_t zero = 0;
        while (padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    return tb_true;
}

static tb_bool_t xm_binutils_bin2macho_dump_32(tb_stream_ref_t istream,
                                             tb_stream_ref_t ostream,
                                             tb_char_t const *symbol_prefix,
                                             tb_char_t const *plat,
                                             tb_char_t const *arch,
                                             tb_char_t const *basename,
                                             tb_uint32_t minos,
                                             tb_uint32_t sdk,
                                             tb_bool_t zeroend) {
    tb_assert_and_check_return_val(istream && ostream, tb_false);

    // get file size
    tb_hong_t filesize = tb_stream_size(istream);
    if (filesize < 0 || filesize > 0xffffffffU) {
        return tb_false;
    }
    tb_uint32_t datasize = (tb_uint32_t)filesize;
    // add null terminator if zeroend is true
    if (zeroend) {
        if (datasize >= 0xffffffffU) {
            return tb_false; // would overflow
        }
        datasize++;
    }

    // generate symbol names from filename
    tb_char_t symbol_name[256] = {0};
    tb_char_t symbol_start[256] = {0};
    tb_char_t symbol_end[256] = {0};

    // use basename or default to "data"
    if (!basename || !basename[0]) {
        basename = "data";
    }

    // build symbol name
    // On macOS, C compiler adds an underscore prefix, so we generate symbols with two underscores
    // (C code declares _binary_xxx, compiler generates __binary_xxx in object file, so we define __binary_xxx)
    if (symbol_prefix) {
        tb_snprintf(symbol_name, sizeof(symbol_name), "_%s%s", symbol_prefix, basename);
    } else {
        tb_snprintf(symbol_name, sizeof(symbol_name), "__binary_%s", basename);
    }

    // replace non-alphanumeric with underscore
    xm_binutils_sanitize_symbol_name(symbol_name);

    tb_snprintf(symbol_start, sizeof(symbol_start), "%s_start", symbol_name);
    tb_snprintf(symbol_end, sizeof(symbol_end), "%s_end", symbol_name);

    // calculate offsets
    tb_uint32_t header_size = sizeof(xm_macho_header_32_t);
    tb_uint32_t segment_cmd_size = sizeof(xm_macho_segment_command_t);
    tb_uint32_t section_size = sizeof(xm_macho_section_t);
    tb_uint32_t symtab_cmd_size = sizeof(xm_macho_symtab_command_t);
    tb_uint32_t build_version_cmd_size = sizeof(xm_macho_build_version_command_t);
    tb_uint32_t segment_cmd_total_size = segment_cmd_size + section_size;
    tb_uint32_t data_offset = xm_binutils_macho_align(header_size + segment_cmd_total_size + symtab_cmd_size + build_version_cmd_size, 4);
    tb_uint32_t data_size = datasize;
    tb_uint32_t data_end_offset = data_offset + data_size;
    tb_uint32_t symtab_offset = xm_binutils_macho_align(data_end_offset, 4);
    tb_uint32_t nlist_size = sizeof(xm_macho_nlist_t);
    tb_uint32_t nlist_count = 2; // start, end
    tb_uint32_t strtab_offset = symtab_offset + nlist_size * nlist_count;
    tb_uint32_t strtab_size = 4; // initial 4-byte size field
    tb_size_t start_len = tb_strlen(symbol_start);
    tb_size_t end_len = tb_strlen(symbol_end);
    strtab_size += (tb_uint32_t)(start_len + 1);
    strtab_size += (tb_uint32_t)(end_len + 1);
    strtab_size = xm_binutils_macho_align(strtab_size, 4);

    // write Mach-O header
    xm_macho_header_32_t header;
    tb_memset(&header, 0, sizeof(header));
    header.magic = XM_MACHO_MAGIC_32;
    header.cputype = xm_binutils_macho_get_cputype(arch);
    header.cpusubtype = xm_binutils_macho_get_cpusubtype(arch);
    header.filetype = XM_MACHO_FILE_TYPE_OBJECT;
    header.ncmds = 3; // segment + symtab + build_version
    header.sizeofcmds = segment_cmd_total_size + symtab_cmd_size + build_version_cmd_size;
    header.flags = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&header, sizeof(header))) {
        return tb_false;
    }

    // write segment command
    xm_macho_segment_command_t segment;
    tb_memset(&segment, 0, sizeof(segment));
    segment.cmd = XM_MACHO_LC_SEGMENT;
    segment.cmdsize = segment_cmd_total_size;
    tb_strncpy(segment.segname, "__TEXT", 16);
    segment.vmaddr = 0;
    segment.vmsize = data_size;
    segment.fileoff = data_offset;
    segment.filesize = data_size;
    segment.maxprot = XM_MACHO_VM_PROT_READ | XM_MACHO_VM_PROT_EXECUTE; // VM_PROT_READ | VM_PROT_EXECUTE (r-x)
    segment.initprot = XM_MACHO_VM_PROT_READ | XM_MACHO_VM_PROT_EXECUTE; // VM_PROT_READ | VM_PROT_EXECUTE (r-x)
    segment.nsects = 1;
    segment.flags = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&segment, sizeof(segment))) {
        return tb_false;
    }

    // write section
    xm_macho_section_t section;
    tb_memset(&section, 0, sizeof(section));
    tb_strncpy(section.sectname, "__const", 16);
    tb_strncpy(section.segname, "__TEXT", 16);
    section.addr = 0;
    section.size = data_size;
    section.offset = data_offset;
    section.align = 2; // 2^2 = 4 bytes
    section.reloff = 0;
    section.nreloc = 0;
    section.flags = XM_MACHO_SECT_TYPE_REGULAR | XM_MACHO_SECT_ATTR_SOME_INITS;
    section.reserved1 = 0;
    section.reserved2 = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section, sizeof(section))) {
        return tb_false;
    }

    // write symtab command
    xm_macho_symtab_command_t symtab;
    tb_memset(&symtab, 0, sizeof(symtab));
    symtab.cmd = XM_MACHO_LC_SYMTAB;
    symtab.cmdsize = symtab_cmd_size;
    symtab.symoff = symtab_offset;
    symtab.nsyms = nlist_count;
    symtab.stroff = strtab_offset;
    symtab.strsize = strtab_size;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&symtab, sizeof(symtab))) {
        return tb_false;
    }

    // write build version command
    xm_macho_build_version_command_t build_version;
    tb_memset(&build_version, 0, sizeof(build_version));
    build_version.cmd = XM_MACHO_LC_BUILD_VERSION;
    build_version.cmdsize = build_version_cmd_size;
    build_version.platform = xm_binutils_macho_get_platform(plat);
    build_version.minos = minos;
    build_version.sdk = sdk;
    build_version.ntools = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&build_version, sizeof(build_version))) {
        return tb_false;
    }

    // align to 4 bytes
    tb_uint32_t padding = data_offset - (header_size + segment_cmd_total_size + symtab_cmd_size + build_version_cmd_size);
    if (padding > 0) {
        tb_byte_t zero = 0;
        while (padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write section data
    if (!xm_binutils_stream_copy(istream, ostream, filesize)) {
        return tb_false;
    }
    // append null terminator if zeroend is true
    if (zeroend) {
        tb_byte_t zero = 0;
        if (!tb_stream_bwrit(ostream, &zero, 1)) {
            return tb_false;
        }
    }

    // align to 4 bytes
    padding = symtab_offset - data_end_offset;
    if (padding > 0) {
        tb_byte_t zero = 0;
        while (padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write symbol table
    // strx starts from 4 (after 4-byte size field)
    tb_uint32_t strx = 4;
    // symbol 0: _binary_xxx_start
    xm_macho_nlist_t nlist_start;
    tb_memset(&nlist_start, 0, sizeof(nlist_start));
    nlist_start.strx = strx;
    nlist_start.type = XM_MACHO_N_TYPE_SECT | XM_MACHO_N_EXT; // N_SECT | N_EXT
    nlist_start.sect = 1;
    nlist_start.desc = 0;
    nlist_start.value = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&nlist_start, sizeof(nlist_start))) {
        return tb_false;
    }
    strx += (tb_uint32_t)(start_len + 1);

    // symbol 1: _binary_xxx_end
    xm_macho_nlist_t nlist_end;
    tb_memset(&nlist_end, 0, sizeof(nlist_end));
    nlist_end.strx = strx;
    nlist_end.type = XM_MACHO_N_TYPE_SECT | XM_MACHO_N_EXT; // N_SECT | N_EXT
    nlist_end.sect = 1;
    nlist_end.desc = 0;
    nlist_end.value = data_size;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&nlist_end, sizeof(nlist_end))) {
        return tb_false;
    }
    strx += (tb_uint32_t)(end_len + 1);

    // align to 4 bytes
    padding = strtab_offset - (symtab_offset + nlist_size * nlist_count);
    if (padding > 0) {
        tb_byte_t zero = 0;
        while (padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write string table
    tb_stream_bwrit(ostream, (tb_byte_t const *)&strtab_size, 4);
    tb_stream_bwrit(ostream, (tb_byte_t const *)symbol_start, start_len);
    tb_byte_t null = 0;
    tb_stream_bwrit(ostream, &null, 1);
    tb_stream_bwrit(ostream, (tb_byte_t const *)symbol_end, end_len);
    tb_stream_bwrit(ostream, &null, 1);

    // align string table to 4 bytes
    padding = strtab_size - (4 + (tb_uint32_t)start_len + 1 + (tb_uint32_t)end_len + 1);
    if (padding > 0) {
        tb_byte_t zero = 0;
        while (padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    return tb_true;
}

static tb_bool_t xm_binutils_bin2macho_dump(tb_stream_ref_t istream,
                                         tb_stream_ref_t ostream,
                                         tb_char_t const *symbol_prefix,
                                         tb_char_t const *plat,
                                         tb_char_t const *arch,
                                         tb_char_t const *basename,
                                         tb_uint32_t minos,
                                         tb_uint32_t sdk,
                                         tb_bool_t zeroend) {
    if (xm_binutils_macho_is_64bit(arch)) {
        return xm_binutils_bin2macho_dump_64(istream, ostream, symbol_prefix, plat, arch, basename, minos, sdk, zeroend);
    } else {
        return xm_binutils_bin2macho_dump_32(istream, ostream, symbol_prefix, plat, arch, basename, minos, sdk, zeroend);
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* generate Mach-O object file from binary file
 *
 * local ok, errors = binutils.bin2macho(binaryfile, outputfile, symbol_prefix, plat, arch, basename)
 */
tb_int_t xm_binutils_bin2macho(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get the binaryfile
    tb_char_t const *binaryfile = luaL_checkstring(lua, 1);
    tb_check_return_val(binaryfile, 0);

    // get the outputfile
    tb_char_t const *outputfile = luaL_checkstring(lua, 2);
    tb_check_return_val(outputfile, 0);

    // get symbol prefix (optional)
    tb_char_t const *symbol_prefix = lua_isstring(lua, 3) ? lua_tostring(lua, 3) : tb_null;

    // get plat (optional)
    tb_char_t const *plat = lua_isstring(lua, 4) ? lua_tostring(lua, 4) : tb_null;

    // get arch (optional)
    tb_char_t const *arch = lua_isstring(lua, 5) ? lua_tostring(lua, 5) : tb_null;

    // get basename (optional)
    tb_char_t const *basename = lua_isstring(lua, 6) ? lua_tostring(lua, 6) : tb_null;

    // get minos version string (optional)
    tb_char_t const *minos_str = lua_isstring(lua, 7) ? lua_tostring(lua, 7) : tb_null;
    tb_uint32_t minos = xm_binutils_macho_parse_version(minos_str);

    // get sdk version string (optional)
    tb_char_t const *sdk_str = lua_isstring(lua, 8) ? lua_tostring(lua, 8) : tb_null;
    tb_uint32_t sdk = xm_binutils_macho_parse_version(sdk_str);

    // get zeroend (optional, default: false)
    tb_bool_t zeroend = lua_toboolean(lua, 9);

    // do dump
    tb_bool_t ok = tb_false;
    tb_stream_ref_t istream = tb_stream_init_from_file(binaryfile, TB_FILE_MODE_RO);
    tb_stream_ref_t ostream = tb_stream_init_from_file(outputfile,
                                                       TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
    do {
        if (!tb_stream_open(istream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2macho: open %s failed", binaryfile);
            break;
        }

        if (!tb_stream_open(ostream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2macho: open %s failed", outputfile);
            break;
        }

        if (!xm_binutils_bin2macho_dump(istream, ostream, symbol_prefix, plat, arch, basename, minos, sdk, zeroend)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2macho: dump data failed");
            break;
        }

        ok = tb_true;
        lua_pushboolean(lua, ok);

    } while (0);

    if (istream) {
        tb_stream_clos(istream);
    }
    istream = tb_null;

    if (ostream) {
        tb_stream_clos(ostream);
    }
    ostream = tb_null;

    return ok ? 1 : 2;
}
