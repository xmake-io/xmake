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
 * @file        bin2elf.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "bin2elf"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

// write an ELF struct out in the target endianness (the struct is converted in place)
static tb_bool_t xm_binutils_bin2elf_bwrit_header_32(tb_stream_ref_t ostream, xm_elf32_header_t* h, tb_bool_t be) {
    xm_binutils_elf32_header_conv(h, be);
    return tb_stream_bwrit(ostream, (tb_byte_t const *)h, sizeof(*h));
}
static tb_bool_t xm_binutils_bin2elf_bwrit_section_32(tb_stream_ref_t ostream, xm_elf32_section_t* s, tb_bool_t be) {
    xm_binutils_elf32_section_conv(s, be);
    return tb_stream_bwrit(ostream, (tb_byte_t const *)s, sizeof(*s));
}
static tb_bool_t xm_binutils_bin2elf_bwrit_symbol_32(tb_stream_ref_t ostream, xm_elf32_symbol_t* s, tb_bool_t be) {
    xm_binutils_elf32_symbol_conv(s, be);
    return tb_stream_bwrit(ostream, (tb_byte_t const *)s, sizeof(*s));
}
static tb_bool_t xm_binutils_bin2elf_bwrit_header_64(tb_stream_ref_t ostream, xm_elf64_header_t* h, tb_bool_t be) {
    xm_binutils_elf64_header_conv(h, be);
    return tb_stream_bwrit(ostream, (tb_byte_t const *)h, sizeof(*h));
}
static tb_bool_t xm_binutils_bin2elf_bwrit_section_64(tb_stream_ref_t ostream, xm_elf64_section_t* s, tb_bool_t be) {
    xm_binutils_elf64_section_conv(s, be);
    return tb_stream_bwrit(ostream, (tb_byte_t const *)s, sizeof(*s));
}
static tb_bool_t xm_binutils_bin2elf_bwrit_symbol_64(tb_stream_ref_t ostream, xm_elf64_symbol_t* s, tb_bool_t be) {
    xm_binutils_elf64_symbol_conv(s, be);
    return tb_stream_bwrit(ostream, (tb_byte_t const *)s, sizeof(*s));
}

/* read the identity (class/endianness/machine/e_flags) from a reference ELF object.
 * returns tb_true and updates the out-params on success; leaves them untouched on any failure
 * (missing file, too small, bad magic), so the caller keeps its arch-derived defaults.
 */
static tb_bool_t xm_binutils_bin2elf_read_refobj(tb_char_t const *refobj,
    tb_bool_t *pis_64bit, tb_bool_t *pis_bigendian, tb_uint16_t *pe_machine, tb_uint32_t *pe_flags) {
    tb_assert_and_check_return_val(refobj && pis_64bit && pis_bigendian && pe_machine && pe_flags, tb_false);

    tb_bool_t ok = tb_false;
    tb_stream_ref_t stream = tb_stream_init_from_file(refobj, TB_FILE_MODE_RO);
    do {
        // the 32-bit ELF header is 52 bytes; the 64-bit e_flags ends at offset 52 too
        tb_byte_t hdr[52];
        if (!stream || !tb_stream_open(stream)) break;
        if (!tb_stream_bread(stream, hdr, sizeof(hdr))) break;

        // verify the ELF magic (0x7f 'E' 'L' 'F')
        if (hdr[0] != 0x7f || hdr[1] != 'E' || hdr[2] != 'L' || hdr[3] != 'F') break;

        tb_bool_t is_64bit = (hdr[XM_ELF_EI_CLASS] == XM_ELF_CLASS64);
        tb_bool_t is_bigendian = (hdr[5] == XM_ELF_DATA2MSB);

        // e_machine at offset 18 (2 bytes); e_flags at offset 36 (32-bit) / 48 (64-bit), in target endianness
        tb_uint16_t e_machine = is_bigendian? tb_bits_get_u16_be(hdr + 18) : tb_bits_get_u16_le(hdr + 18);
        tb_byte_t const *pflags = hdr + (is_64bit? 48 : 36);
        tb_uint32_t e_flags = is_bigendian? tb_bits_get_u32_be(pflags) : tb_bits_get_u32_le(pflags);

        *pis_64bit = is_64bit;
        *pis_bigendian = is_bigendian;
        *pe_machine = e_machine;
        *pe_flags = e_flags;
        ok = tb_true;

    } while (0);
    if (stream) tb_stream_clos(stream);
    return ok;
}

static tb_bool_t xm_binutils_bin2elf_dump_32(tb_stream_ref_t istream,
                                          tb_stream_ref_t ostream,
                                          tb_char_t const *symbol_prefix,
                                          tb_char_t const *arch,
                                          tb_char_t const *basename,
                                          tb_bool_t bigendian,
                                          tb_uint16_t e_machine,
                                          tb_uint32_t e_flags,
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
    if (symbol_prefix) {
        tb_snprintf(symbol_name, sizeof(symbol_name), "%s%s", symbol_prefix, basename);
    } else {
        tb_snprintf(symbol_name, sizeof(symbol_name), "_binary_%s", basename);
    }

    // replace non-alphanumeric with underscore
    xm_binutils_sanitize_symbol_name(symbol_name);

    tb_snprintf(symbol_start, sizeof(symbol_start), "%s_start", symbol_name);
    tb_snprintf(symbol_end, sizeof(symbol_end), "%s_end", symbol_name);

    // calculate offsets
    tb_uint32_t header_size = sizeof(xm_elf32_header_t);
    tb_uint32_t section_header_size = sizeof(xm_elf32_section_t);
    tb_uint32_t section_count = 6; // NULL, .rodata, .symtab, .strtab, .shstrtab, .note.GNU-stack
    tb_uint32_t section_headers_ofs = header_size;
    tb_uint32_t rodata_ofs = section_headers_ofs + section_count * section_header_size;
    tb_uint32_t rodata_size = datasize;
    tb_uint32_t rodata_padding = (4 - (rodata_size & 3)) & 3; // align to 4 bytes for 32-bit
    tb_uint32_t symtab_ofs = rodata_ofs + rodata_size + rodata_padding;
    tb_uint32_t symtab_size = 3 * sizeof(xm_elf32_symbol_t); // NULL, start, end
    tb_uint32_t symtab_padding = (4 - (symtab_size & 3)) & 3; // align to 4 bytes
    tb_uint32_t strtab_ofs = symtab_ofs + symtab_size + symtab_padding;

    // calculate string table size
    tb_size_t start_len = tb_strlen(symbol_start);
    tb_size_t end_len = tb_strlen(symbol_end);
    tb_uint32_t strtab_size = 1; // initial null byte
    strtab_size += (tb_uint32_t)(start_len + 1);
    strtab_size += (tb_uint32_t)(end_len + 1);
    tb_uint32_t strtab_padding = (4 - (strtab_size & 3)) & 3; // align to 4 bytes
    tb_uint32_t shstrtab_ofs = strtab_ofs + strtab_size + strtab_padding;

    // calculate section header string table size
    tb_uint32_t shstrtab_size = 1; // initial null byte
    shstrtab_size += 8; // ".rodata\0" (7 + 1)
    shstrtab_size += 8; // ".symtab\0" (7 + 1)
    shstrtab_size += 8; // ".strtab\0" (7 + 1)
    shstrtab_size += 10; // ".shstrtab\0" (9 + 1)
    shstrtab_size += 16; // ".note.GNU-stack\0" (15 + 1)

    // write ELF header
    xm_elf32_header_t header;
    tb_memset(&header, 0, sizeof(header));
    header.e_ident[0] = 0x7f;
    header.e_ident[1] = 'E';
    header.e_ident[2] = 'L';
    header.e_ident[3] = 'F';
    header.e_ident[XM_ELF_EI_CLASS] = XM_ELF_CLASS32;
    header.e_ident[5] = bigendian? XM_ELF_DATA2MSB : XM_ELF_DATA2LSB;
    header.e_ident[6] = 1; // EV_CURRENT
    header.e_ident[7] = 0; // ELFOSABI_SYSV
    header.e_type = 1; // ET_REL
    header.e_machine = e_machine;
    header.e_version = 1;
    header.e_flags = e_flags;
    header.e_shoff = section_headers_ofs;
    header.e_ehsize = header_size;
    header.e_shentsize = section_header_size;
    header.e_shnum = section_count;
    header.e_shstrndx = 4; // .shstrtab section index
    if (!xm_binutils_bin2elf_bwrit_header_32(ostream, &header, bigendian)) {
        return tb_false;
    }

    // write section headers
    xm_elf32_section_t section_null;
    tb_memset(&section_null, 0, sizeof(section_null));
    if (!xm_binutils_bin2elf_bwrit_section_32(ostream, &section_null, bigendian)) {
        return tb_false;
    }

    // write .rodata section header
    xm_elf32_section_t section_rodata;
    tb_memset(&section_rodata, 0, sizeof(section_rodata));
    section_rodata.sh_name = 1; // ".rodata" in shstrtab
    section_rodata.sh_type = XM_ELF_SHT_PROGBITS;
    section_rodata.sh_flags = XM_ELF_SHF_ALLOC;
    section_rodata.sh_offset = rodata_ofs;
    section_rodata.sh_size = rodata_size;
    section_rodata.sh_addralign = 4;
    if (!xm_binutils_bin2elf_bwrit_section_32(ostream, &section_rodata, bigendian)) {
        return tb_false;
    }

    // write .symtab section header
    xm_elf32_section_t section_symtab;
    tb_memset(&section_symtab, 0, sizeof(section_symtab));
    section_symtab.sh_name = 9; // ".symtab" in shstrtab
    section_symtab.sh_type = XM_ELF_SHT_SYMTAB;
    section_symtab.sh_offset = symtab_ofs;
    section_symtab.sh_size = symtab_size;
    section_symtab.sh_link = 3; // .strtab section index
    section_symtab.sh_info = 1; // first global symbol index
    section_symtab.sh_addralign = 4;
    section_symtab.sh_entsize = sizeof(xm_elf32_symbol_t);
    if (!xm_binutils_bin2elf_bwrit_section_32(ostream, &section_symtab, bigendian)) {
        return tb_false;
    }

    // write .strtab section header
    xm_elf32_section_t section_strtab;
    tb_memset(&section_strtab, 0, sizeof(section_strtab));
    section_strtab.sh_name = 17; // ".strtab" in shstrtab
    section_strtab.sh_type = XM_ELF_SHT_STRTAB;
    section_strtab.sh_offset = strtab_ofs;
    section_strtab.sh_size = strtab_size;
    section_strtab.sh_addralign = 1;
    if (!xm_binutils_bin2elf_bwrit_section_32(ostream, &section_strtab, bigendian)) {
        return tb_false;
    }

    // write .shstrtab section header
    xm_elf32_section_t section_shstrtab;
    tb_memset(&section_shstrtab, 0, sizeof(section_shstrtab));
    section_shstrtab.sh_name = 25; // ".shstrtab" in shstrtab
    section_shstrtab.sh_type = XM_ELF_SHT_STRTAB;
    section_shstrtab.sh_offset = shstrtab_ofs;
    section_shstrtab.sh_size = shstrtab_size;
    section_shstrtab.sh_addralign = 1;
    if (!xm_binutils_bin2elf_bwrit_section_32(ostream, &section_shstrtab, bigendian)) {
        return tb_false;
    }

    // write .note.GNU-stack section header (empty section to mark stack as non-executable)
    xm_elf32_section_t section_note_gnu_stack;
    tb_memset(&section_note_gnu_stack, 0, sizeof(section_note_gnu_stack));
    section_note_gnu_stack.sh_name = 35; // ".note.GNU-stack" in shstrtab (25 + 10)
    section_note_gnu_stack.sh_type = XM_ELF_SHT_PROGBITS;
    section_note_gnu_stack.sh_flags = 0; // no flags
    section_note_gnu_stack.sh_offset = shstrtab_ofs + shstrtab_size; // after .shstrtab
    section_note_gnu_stack.sh_size = 0; // empty section
    section_note_gnu_stack.sh_addralign = 1;
    if (!xm_binutils_bin2elf_bwrit_section_32(ostream, &section_note_gnu_stack, bigendian)) {
        return tb_false;
    }

    // write .rodata section data
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

    // align .rodata to 4 bytes
    if (rodata_padding > 0) {
        tb_byte_t zero = 0;
        while (rodata_padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write symbol table
    // symbol 0: NULL symbol
    xm_elf32_symbol_t sym_null;
    tb_memset(&sym_null, 0, sizeof(sym_null));
    if (!xm_binutils_bin2elf_bwrit_symbol_32(ostream, &sym_null, bigendian)) {
        return tb_false;
    }

    // symbol 1: _binary_xxx_start
    xm_elf32_symbol_t sym_start;
    tb_memset(&sym_start, 0, sizeof(sym_start));
    sym_start.st_name = 1; // offset in .strtab (after initial null)
    sym_start.st_info = (XM_ELF_STB_GLOBAL << 4) | XM_ELF_STT_OBJECT;
    sym_start.st_shndx = 1; // .rodata section index
    sym_start.st_value = 0;
    sym_start.st_size = 0;
    if (!xm_binutils_bin2elf_bwrit_symbol_32(ostream, &sym_start, bigendian)) {
        return tb_false;
    }

    // symbol 2: _binary_xxx_end
    xm_elf32_symbol_t sym_end;
    tb_memset(&sym_end, 0, sizeof(sym_end));
    sym_end.st_name = 1 + (tb_uint32_t)(start_len + 1); // offset in .strtab
    sym_end.st_info = (XM_ELF_STB_GLOBAL << 4) | XM_ELF_STT_OBJECT;
    sym_end.st_shndx = 1; // .rodata section index
    sym_end.st_value = rodata_size;
    sym_end.st_size = 0;
    if (!xm_binutils_bin2elf_bwrit_symbol_32(ostream, &sym_end, bigendian)) {
        return tb_false;
    }

    // align .symtab to 4 bytes
    if (symtab_padding > 0) {
        tb_byte_t zero = 0;
        while (symtab_padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write string table
    tb_byte_t null = 0;
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)symbol_start, start_len)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)symbol_end, end_len)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }

    // align .strtab to 4 bytes
    if (strtab_padding > 0) {
        tb_byte_t zero = 0;
        while (strtab_padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write section header string table
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".rodata", 7)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".symtab", 7)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".strtab", 7)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".shstrtab", 9)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".note.GNU-stack", 15)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }

    return tb_true;
}

static tb_bool_t xm_binutils_bin2elf_dump_64(tb_stream_ref_t istream,
                                          tb_stream_ref_t ostream,
                                          tb_char_t const *symbol_prefix,
                                          tb_char_t const *arch,
                                          tb_char_t const *basename,
                                          tb_bool_t bigendian,
                                          tb_uint16_t e_machine,
                                          tb_uint32_t e_flags,
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
    if (symbol_prefix) {
        tb_snprintf(symbol_name, sizeof(symbol_name), "%s%s", symbol_prefix, basename);
    } else {
        tb_snprintf(symbol_name, sizeof(symbol_name), "_binary_%s", basename);
    }

    // replace non-alphanumeric with underscore
    xm_binutils_sanitize_symbol_name(symbol_name);

    tb_snprintf(symbol_start, sizeof(symbol_start), "%s_start", symbol_name);
    tb_snprintf(symbol_end, sizeof(symbol_end), "%s_end", symbol_name);

    // calculate offsets
    tb_uint32_t header_size = sizeof(xm_elf64_header_t);
    tb_uint32_t section_header_size = sizeof(xm_elf64_section_t);
    tb_uint32_t section_count = 6; // NULL, .rodata, .symtab, .strtab, .shstrtab, .note.GNU-stack
    tb_uint32_t section_headers_ofs = header_size;
    tb_uint32_t rodata_ofs = section_headers_ofs + section_count * section_header_size;
    tb_uint32_t rodata_size = datasize;
    tb_uint32_t rodata_padding = (8 - (rodata_size & 7)) & 7;
    tb_uint32_t symtab_ofs = rodata_ofs + rodata_size + rodata_padding;
    tb_uint32_t symtab_size = 3 * sizeof(xm_elf64_symbol_t); // NULL, start, end
    tb_uint32_t symtab_padding = (8 - (symtab_size & 7)) & 7;
    tb_uint32_t strtab_ofs = symtab_ofs + symtab_size + symtab_padding;

    // calculate string table size
    tb_size_t start_len = tb_strlen(symbol_start);
    tb_size_t end_len = tb_strlen(symbol_end);
    tb_uint32_t strtab_size = 1; // initial null byte
    strtab_size += (tb_uint32_t)(start_len + 1);
    strtab_size += (tb_uint32_t)(end_len + 1);
    tb_uint32_t strtab_padding = (8 - (strtab_size & 7)) & 7;

    // calculate section header string table size
    tb_uint32_t shstrtab_size = 1; // initial null byte
    shstrtab_size += 8; // ".rodata\0" (7 + 1)
    shstrtab_size += 8; // ".symtab\0" (7 + 1)
    shstrtab_size += 8; // ".strtab\0" (7 + 1)
    shstrtab_size += 10; // ".shstrtab\0" (9 + 1)
    shstrtab_size += 16; // ".note.GNU-stack\0" (15 + 1)
    tb_uint32_t shstrtab_ofs = strtab_ofs + strtab_size + strtab_padding;

    // write ELF header
    xm_elf64_header_t header;
    tb_memset(&header, 0, sizeof(header));
    header.e_ident[0] = 0x7f;
    header.e_ident[1] = 'E';
    header.e_ident[2] = 'L';
    header.e_ident[3] = 'F';
    header.e_ident[XM_ELF_EI_CLASS] = XM_ELF_CLASS64;
    header.e_ident[5] = bigendian? XM_ELF_DATA2MSB : XM_ELF_DATA2LSB;
    header.e_ident[6] = 1; // EV_CURRENT
    header.e_ident[7] = 0; // ELFOSABI_SYSV
    header.e_type = 1; // ET_REL
    header.e_machine = e_machine;
    header.e_version = 1;
    header.e_flags = e_flags;
    header.e_shoff = section_headers_ofs;
    header.e_ehsize = header_size;
    header.e_shentsize = section_header_size;
    header.e_shnum = section_count;
    header.e_shstrndx = 4; // .shstrtab section index
    if (!xm_binutils_bin2elf_bwrit_header_64(ostream, &header, bigendian)) {
        return tb_false;
    }

    // write section headers
    xm_elf64_section_t section_null;
    tb_memset(&section_null, 0, sizeof(section_null));
    if (!xm_binutils_bin2elf_bwrit_section_64(ostream, &section_null, bigendian)) {
        return tb_false;
    }

    // write .rodata section header
    xm_elf64_section_t section_rodata;
    tb_memset(&section_rodata, 0, sizeof(section_rodata));
    section_rodata.sh_name = 1; // ".rodata" in shstrtab
    section_rodata.sh_type = XM_ELF_SHT_PROGBITS;
    section_rodata.sh_flags = XM_ELF_SHF_ALLOC;
    section_rodata.sh_offset = rodata_ofs;
    section_rodata.sh_size = rodata_size;
    section_rodata.sh_addralign = 8;
    if (!xm_binutils_bin2elf_bwrit_section_64(ostream, &section_rodata, bigendian)) {
        return tb_false;
    }

    // write .symtab section header
    xm_elf64_section_t section_symtab;
    tb_memset(&section_symtab, 0, sizeof(section_symtab));
    section_symtab.sh_name = 9; // ".symtab" in shstrtab
    section_symtab.sh_type = XM_ELF_SHT_SYMTAB;
    section_symtab.sh_offset = symtab_ofs;
    section_symtab.sh_size = symtab_size;
    section_symtab.sh_link = 3; // .strtab section index
    section_symtab.sh_info = 1; // first global symbol index
    section_symtab.sh_addralign = 8;
    section_symtab.sh_entsize = sizeof(xm_elf64_symbol_t);
    if (!xm_binutils_bin2elf_bwrit_section_64(ostream, &section_symtab, bigendian)) {
        return tb_false;
    }

    // write .strtab section header
    xm_elf64_section_t section_strtab;
    tb_memset(&section_strtab, 0, sizeof(section_strtab));
    section_strtab.sh_name = 17; // ".strtab" in shstrtab
    section_strtab.sh_type = XM_ELF_SHT_STRTAB;
    section_strtab.sh_offset = strtab_ofs;
    section_strtab.sh_size = strtab_size;
    section_strtab.sh_addralign = 1;
    if (!xm_binutils_bin2elf_bwrit_section_64(ostream, &section_strtab, bigendian)) {
        return tb_false;
    }

    // write .shstrtab section header
    xm_elf64_section_t section_shstrtab;
    tb_memset(&section_shstrtab, 0, sizeof(section_shstrtab));
    section_shstrtab.sh_name = 25; // ".shstrtab" in shstrtab
    section_shstrtab.sh_type = XM_ELF_SHT_STRTAB;
    section_shstrtab.sh_offset = shstrtab_ofs; // points to initial null byte
    section_shstrtab.sh_size = shstrtab_size; // size includes initial null and all strings
    section_shstrtab.sh_addralign = 1;
    if (!xm_binutils_bin2elf_bwrit_section_64(ostream, &section_shstrtab, bigendian)) {
        return tb_false;
    }

    // write .note.GNU-stack section header (empty section to mark stack as non-executable)
    xm_elf64_section_t section_note_gnu_stack;
    tb_memset(&section_note_gnu_stack, 0, sizeof(section_note_gnu_stack));
    section_note_gnu_stack.sh_name = 35; // ".note.GNU-stack" in shstrtab (25 + 10)
    section_note_gnu_stack.sh_type = XM_ELF_SHT_PROGBITS;
    section_note_gnu_stack.sh_flags = 0; // no flags
    section_note_gnu_stack.sh_offset = shstrtab_ofs + shstrtab_size; // after .shstrtab
    section_note_gnu_stack.sh_size = 0; // empty section
    section_note_gnu_stack.sh_addralign = 1;
    if (!xm_binutils_bin2elf_bwrit_section_64(ostream, &section_note_gnu_stack, bigendian)) {
        return tb_false;
    }

    // write .rodata section data
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

    // align .rodata to 8 bytes
    if (rodata_padding > 0) {
        tb_byte_t zero = 0;
        while (rodata_padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write symbol table
    // symbol 0: NULL symbol
    xm_elf64_symbol_t sym_null;
    tb_memset(&sym_null, 0, sizeof(sym_null));
    if (!xm_binutils_bin2elf_bwrit_symbol_64(ostream, &sym_null, bigendian)) {
        return tb_false;
    }

    // symbol 1: _binary_xxx_start
    xm_elf64_symbol_t sym_start;
    tb_memset(&sym_start, 0, sizeof(sym_start));
    sym_start.st_name = 1; // offset in .strtab (after initial null)
    sym_start.st_info = (XM_ELF_STB_GLOBAL << 4) | XM_ELF_STT_OBJECT;
    sym_start.st_shndx = 1; // .rodata section index
    sym_start.st_value = 0;
    sym_start.st_size = 0;
    if (!xm_binutils_bin2elf_bwrit_symbol_64(ostream, &sym_start, bigendian)) {
        return tb_false;
    }

    // symbol 2: _binary_xxx_end
    xm_elf64_symbol_t sym_end;
    tb_memset(&sym_end, 0, sizeof(sym_end));
    sym_end.st_name = 1 + (tb_uint32_t)(start_len + 1); // offset in .strtab
    sym_end.st_info = (XM_ELF_STB_GLOBAL << 4) | XM_ELF_STT_OBJECT;
    sym_end.st_shndx = 1; // .rodata section index
    sym_end.st_value = rodata_size;
    sym_end.st_size = 0;
    if (!xm_binutils_bin2elf_bwrit_symbol_64(ostream, &sym_end, bigendian)) {
        return tb_false;
    }

    // align .symtab to 8 bytes
    if (symtab_padding > 0) {
        tb_byte_t zero = 0;
        while (symtab_padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write string table
    tb_byte_t null = 0;
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)symbol_start, start_len)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)symbol_end, end_len)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }

    // align .strtab to 8 bytes
    if (strtab_padding > 0) {
        tb_byte_t zero = 0;
        while (strtab_padding-- > 0) {
            if (!tb_stream_bwrit(ostream, &zero, 1)) {
                return tb_false;
            }
        }
    }

    // write section header string table
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".rodata", 7)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".symtab", 7)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".strtab", 7)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".shstrtab", 9)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)".note.GNU-stack", 15)) {
        return tb_false;
    }
    if (!tb_stream_bwrit(ostream, &null, 1)) {
        return tb_false;
    }

    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* generate ELF object file from binary file
 *
 * local ok, errors = binutils.bin2elf(binaryfile, outputfile, symbol_prefix, arch, basename, zeroend, refobj)
 */
tb_int_t xm_binutils_bin2elf(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get the binaryfile
    tb_char_t const *binaryfile = luaL_checkstring(lua, 1);
    tb_check_return_val(binaryfile, 0);

    // get the outputfile
    tb_char_t const *outputfile = luaL_checkstring(lua, 2);
    tb_check_return_val(outputfile, 0);

    // get symbol prefix (optional)
    tb_char_t const *symbol_prefix = lua_isstring(lua, 3) ? lua_tostring(lua, 3) : tb_null;

    // get arch (optional)
    tb_char_t const *arch = lua_isstring(lua, 4) ? lua_tostring(lua, 4) : tb_null;

    // get basename (optional)
    tb_char_t const *basename = lua_isstring(lua, 5) ? lua_tostring(lua, 5) : tb_null;

    // get zeroend (optional, default: false)
    tb_bool_t zeroend = lua_toboolean(lua, 6);

    /* get the reference object (optional): a real object emitted by the target toolchain.
     * we mirror its class/endianness/machine/e_flags so the output matches exactly, instead of
     * guessing from the (sometimes ambiguous) arch name. when absent/unreadable we fall back to
     * deriving everything from the arch name.
     */
    tb_char_t const *refobj = lua_isstring(lua, 7) ? lua_tostring(lua, 7) : tb_null;

    // do dump
    tb_bool_t ok = tb_false;
    tb_stream_ref_t istream = tb_stream_init_from_file(binaryfile, TB_FILE_MODE_RO);
    tb_stream_ref_t ostream = tb_stream_init_from_file(outputfile,
                                                       TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
    do {
        if (!tb_stream_open(istream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2elf: open %s failed", binaryfile);
            break;
        }

        if (!tb_stream_open(ostream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2elf: open %s failed", outputfile);
            break;
        }

        /* resolve class/endian/machine/flags: derive from the arch name, then mirror the
         * reference object if one was given and is a readable ELF (it wins over the heuristic) */
        tb_bool_t is_64bit = xm_binutils_elf_is_64bit(arch);
        tb_bool_t is_bigendian = xm_binutils_elf_is_bigendian(arch);
        tb_uint16_t e_machine = xm_binutils_elf_get_machine(arch);
        tb_uint32_t e_flags = xm_binutils_elf_get_flags(arch);
        if (refobj) {
            xm_binutils_bin2elf_read_refobj(refobj, &is_64bit, &is_bigendian, &e_machine, &e_flags);
        }
        if (is_64bit) {
            if (!xm_binutils_bin2elf_dump_64(istream, ostream, symbol_prefix, arch, basename, is_bigendian, e_machine, e_flags, zeroend)) {
                lua_pushboolean(lua, tb_false);
                lua_pushfstring(lua, "bin2elf: dump data failed");
                break;
            }
        } else {
            if (!xm_binutils_bin2elf_dump_32(istream, ostream, symbol_prefix, arch, basename, is_bigendian, e_machine, e_flags, zeroend)) {
                lua_pushboolean(lua, tb_false);
                lua_pushfstring(lua, "bin2elf: dump data failed");
                break;
            }
        }

        ok = tb_true;
        lua_pushboolean(lua, ok);

    } while (0);

    if (istream)
        tb_stream_clos(istream);
    istream = tb_null;

    if (ostream)
        tb_stream_clos(ostream);
    ostream = tb_null;

    return ok ? 1 : 2;
}

