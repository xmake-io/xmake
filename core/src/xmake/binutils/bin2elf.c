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
 * macros
 */
#define XM_ELF_MACHINE_NONE      0x00
#define XM_ELF_MACHINE_SPARC     0x02
#define XM_ELF_MACHINE_I386      0x03
#define XM_ELF_MACHINE_MIPS      0x08
#define XM_ELF_MACHINE_POWERPC   0x14
#define XM_ELF_MACHINE_POWERPC64 0x15
#define XM_ELF_MACHINE_S390      0x16
#define XM_ELF_MACHINE_ARM       0x28
#define XM_ELF_MACHINE_SUPERH    0x2a
#define XM_ELF_MACHINE_SPARC64   0x2b
#define XM_ELF_MACHINE_IA_64     0x32
#define XM_ELF_MACHINE_X86_64    0x3e
#define XM_ELF_MACHINE_RISCV     0xf3
#define XM_ELF_MACHINE_ARM64     0xb7
#define XM_ELF_MACHINE_WASM      0xe7
#define XM_ELF_MACHINE_LOONGARCH 0x102

#define XM_ELF_SHT_PROGBITS      0x1
#define XM_ELF_SHT_SYMTAB        0x2
#define XM_ELF_SHT_STRTAB        0x3

#define XM_ELF_SHF_ALLOC         0x2
#define XM_ELF_SHF_WRITE         0x1

#define XM_ELF_STB_GLOBAL        0x1
#define XM_ELF_STT_OBJECT        0x1

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
#include "tbox/prefix/packed.h"
typedef struct __xm_elf32_header_t {
    tb_uint8_t  e_ident[16];
    tb_uint16_t e_type;
    tb_uint16_t e_machine;
    tb_uint32_t e_version;
    tb_uint32_t e_entry;
    tb_uint32_t e_phoff;
    tb_uint32_t e_shoff;
    tb_uint32_t e_flags;
    tb_uint16_t e_ehsize;
    tb_uint16_t e_phentsize;
    tb_uint16_t e_phnum;
    tb_uint16_t e_shentsize;
    tb_uint16_t e_shnum;
    tb_uint16_t e_shstrndx;
} __tb_packed__ xm_elf32_header_t;

typedef struct __xm_elf32_section_t {
    tb_uint32_t sh_name;
    tb_uint32_t sh_type;
    tb_uint32_t sh_flags;
    tb_uint32_t sh_addr;
    tb_uint32_t sh_offset;
    tb_uint32_t sh_size;
    tb_uint32_t sh_link;
    tb_uint32_t sh_info;
    tb_uint32_t sh_addralign;
    tb_uint32_t sh_entsize;
} __tb_packed__ xm_elf32_section_t;

typedef struct __xm_elf32_symbol_t {
    tb_uint32_t st_name;
    tb_uint32_t st_value;
    tb_uint32_t st_size;
    tb_uint8_t  st_info;
    tb_uint8_t  st_other;
    tb_uint16_t st_shndx;
} __tb_packed__ xm_elf32_symbol_t;

typedef struct __xm_elf64_header_t {
    tb_uint8_t  e_ident[16];
    tb_uint16_t e_type;
    tb_uint16_t e_machine;
    tb_uint32_t e_version;
    tb_uint64_t e_entry;
    tb_uint64_t e_phoff;
    tb_uint64_t e_shoff;
    tb_uint32_t e_flags;
    tb_uint16_t e_ehsize;
    tb_uint16_t e_phentsize;
    tb_uint16_t e_phnum;
    tb_uint16_t e_shentsize;
    tb_uint16_t e_shnum;
    tb_uint16_t e_shstrndx;
} __tb_packed__ xm_elf64_header_t;

typedef struct __xm_elf64_section_t {
    tb_uint32_t sh_name;
    tb_uint32_t sh_type;
    tb_uint64_t sh_flags;
    tb_uint64_t sh_addr;
    tb_uint64_t sh_offset;
    tb_uint64_t sh_size;
    tb_uint32_t sh_link;
    tb_uint32_t sh_info;
    tb_uint64_t sh_addralign;
    tb_uint64_t sh_entsize;
} __tb_packed__ xm_elf64_section_t;

typedef struct __xm_elf64_symbol_t {
    tb_uint32_t st_name;
    tb_uint8_t  st_info;
    tb_uint8_t  st_other;
    tb_uint16_t st_shndx;
    tb_uint64_t st_value;
    tb_uint64_t st_size;
} __tb_packed__ xm_elf64_symbol_t;

#include "tbox/prefix/packed.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_uint16_t xm_binutils_bin2elf_get_machine(tb_char_t const *arch) {
    if (!arch) {
        return XM_ELF_MACHINE_X86_64;
    }
    // x86/x86_64
    if (tb_strcmp(arch, "x86_64") == 0 || tb_strcmp(arch, "x64") == 0) {
        return XM_ELF_MACHINE_X86_64;
    } else if (tb_strcmp(arch, "i386") == 0 || tb_strcmp(arch, "x86") == 0) {
        return XM_ELF_MACHINE_I386;
    }
    // ARM
    else if (tb_strcmp(arch, "arm64") == 0 || tb_strcmp(arch, "aarch64") == 0 ||
             tb_strcmp(arch, "arm64-v8a") == 0) {
        return XM_ELF_MACHINE_ARM64;
    } else if (tb_strcmp(arch, "arm") == 0 || tb_strcmp(arch, "armv7") == 0 ||
               tb_strcmp(arch, "armeabi-v7a") == 0 || tb_strcmp(arch, "armv6") == 0 ||
               tb_strcmp(arch, "armv5") == 0) {
        return XM_ELF_MACHINE_ARM;
    }
    // MIPS (MIPS and MIPS64 use same machine type, distinguished by ELF class)
    else if (tb_strncmp(arch, "mips", 4) == 0) {
        return XM_ELF_MACHINE_MIPS;
    }
    // PowerPC
    else if (tb_strncmp(arch, "ppc64", 5) == 0 || tb_strncmp(arch, "powerpc64", 9) == 0) {
        return XM_ELF_MACHINE_POWERPC64;
    } else if (tb_strncmp(arch, "ppc", 3) == 0 || tb_strncmp(arch, "powerpc", 7) == 0) {
        return XM_ELF_MACHINE_POWERPC;
    }
    // RISC-V (RISC-V and RISC-V64 use different machine types)
    else if (tb_strncmp(arch, "riscv64", 7) == 0 ||
             (tb_strncmp(arch, "riscv", 5) == 0 && tb_strstr(arch, "64"))) {
        return XM_ELF_MACHINE_RISCV; // RISC-V 64-bit uses same machine type, distinguished by ELF class
    } else if (tb_strncmp(arch, "riscv", 5) == 0) {
        return XM_ELF_MACHINE_RISCV;
    }
    // SPARC
    else if (tb_strncmp(arch, "sparc64", 7) == 0) {
        return XM_ELF_MACHINE_SPARC64;
    } else if (tb_strncmp(arch, "sparc", 5) == 0) {
        return XM_ELF_MACHINE_SPARC;
    }
    // s390x
    else if (tb_strcmp(arch, "s390x") == 0 || tb_strcmp(arch, "s390") == 0) {
        return XM_ELF_MACHINE_S390;
    }
    // LoongArch (LoongArch and LoongArch64 use same machine type, distinguished by ELF class)
    else if (tb_strncmp(arch, "loongarch", 9) == 0 || tb_strncmp(arch, "loong64", 7) == 0) {
        return XM_ELF_MACHINE_LOONGARCH;
    }
    // WebAssembly (WASM and WASM64 use same machine type, distinguished by ELF class)
    else if (tb_strncmp(arch, "wasm", 4) == 0) {
        return XM_ELF_MACHINE_WASM;
    }
    // SuperH
    else if (tb_strncmp(arch, "sh", 2) == 0 || tb_strncmp(arch, "superh", 6) == 0) {
        return XM_ELF_MACHINE_SUPERH;
    }
    // IA-64 (Itanium)
    else if (tb_strcmp(arch, "ia64") == 0 || tb_strcmp(arch, "itanium") == 0) {
        return XM_ELF_MACHINE_IA_64;
    }
    return XM_ELF_MACHINE_X86_64;
}

static tb_bool_t xm_binutils_bin2elf_is_64bit(tb_char_t const *arch) {
    if (!arch) {
        return tb_true;
    }
    // x86_64
    if (tb_strcmp(arch, "x86_64") == 0 || tb_strcmp(arch, "x64") == 0) {
        return tb_true;
    }
    // ARM64
    else if (tb_strcmp(arch, "arm64") == 0 || tb_strcmp(arch, "aarch64") == 0 ||
             tb_strcmp(arch, "arm64-v8a") == 0) {
        return tb_true;
    }
    // MIPS64
    else if (tb_strncmp(arch, "mips64", 6) == 0) {
        return tb_true;
    }
    // PowerPC64
    else if (tb_strncmp(arch, "ppc64", 5) == 0 || tb_strncmp(arch, "powerpc64", 9) == 0) {
        return tb_true;
    }
    // RISC-V 64
    else if (tb_strncmp(arch, "riscv64", 7) == 0 ||
             (tb_strncmp(arch, "riscv", 5) == 0 && tb_strstr(arch, "64"))) {
        return tb_true;
    }
    // SPARC64
    else if (tb_strncmp(arch, "sparc64", 7) == 0) {
        return tb_true;
    }
    // s390x
    else if (tb_strcmp(arch, "s390x") == 0) {
        return tb_true;
    }
    // LoongArch64
    else if (tb_strncmp(arch, "loongarch64", 11) == 0) {
        return tb_true;
    }
    // WebAssembly 64
    else if (tb_strcmp(arch, "wasm64") == 0) {
        return tb_true;
    }
    // IA-64
    else if (tb_strcmp(arch, "ia64") == 0 || tb_strcmp(arch, "itanium") == 0) {
        return tb_true;
    }
    return tb_false;
}

static tb_bool_t xm_binutils_bin2elf_dump_32(tb_stream_ref_t istream,
                                          tb_stream_ref_t ostream,
                                          tb_char_t const *symbol_prefix,
                                          tb_char_t const *arch,
                                          tb_char_t const *basename,
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
    for (tb_size_t i = 0; symbol_name[i]; i++) {
        if (!tb_isalpha(symbol_name[i]) && !tb_isdigit(symbol_name[i]) && symbol_name[i] != '_') {
            symbol_name[i] = '_';
        }
    }

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
    header.e_ident[4] = 1; // ELFCLASS32
    header.e_ident[5] = 1; // ELFDATA2LSB
    header.e_ident[6] = 1; // EV_CURRENT
    header.e_ident[7] = 0; // ELFOSABI_SYSV
    header.e_type = 1; // ET_REL
    header.e_machine = xm_binutils_bin2elf_get_machine(arch);
    header.e_version = 1;
    header.e_shoff = section_headers_ofs;
    header.e_ehsize = header_size;
    header.e_shentsize = section_header_size;
    header.e_shnum = section_count;
    header.e_shstrndx = 4; // .shstrtab section index
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&header, sizeof(header))) {
        return tb_false;
    }

    // write section headers
    xm_elf32_section_t section_null;
    tb_memset(&section_null, 0, sizeof(section_null));
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_null, sizeof(section_null))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_rodata, sizeof(section_rodata))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_symtab, sizeof(section_symtab))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_strtab, sizeof(section_strtab))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_shstrtab, sizeof(section_shstrtab))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_note_gnu_stack, sizeof(section_note_gnu_stack))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_null, sizeof(sym_null))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_start, sizeof(sym_start))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_end, sizeof(sym_end))) {
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
    for (tb_size_t i = 0; symbol_name[i]; i++) {
        if (!tb_isalpha(symbol_name[i]) && !tb_isdigit(symbol_name[i]) && symbol_name[i] != '_') {
            symbol_name[i] = '_';
        }
    }

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
    header.e_ident[4] = 2; // ELFCLASS64
    header.e_ident[5] = 1; // ELFDATA2LSB
    header.e_ident[6] = 1; // EV_CURRENT
    header.e_ident[7] = 0; // ELFOSABI_SYSV
    header.e_type = 1; // ET_REL
    header.e_machine = xm_binutils_bin2elf_get_machine(arch);
    header.e_version = 1;
    header.e_shoff = section_headers_ofs;
    header.e_ehsize = header_size;
    header.e_shentsize = section_header_size;
    header.e_shnum = section_count;
    header.e_shstrndx = 4; // .shstrtab section index
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&header, sizeof(header))) {
        return tb_false;
    }

    // write section headers
    xm_elf64_section_t section_null;
    tb_memset(&section_null, 0, sizeof(section_null));
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_null, sizeof(section_null))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_rodata, sizeof(section_rodata))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_symtab, sizeof(section_symtab))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_strtab, sizeof(section_strtab))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_shstrtab, sizeof(section_shstrtab))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section_note_gnu_stack, sizeof(section_note_gnu_stack))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_null, sizeof(sym_null))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_start, sizeof(sym_start))) {
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
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_end, sizeof(sym_end))) {
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
 * local ok, errors = binutils.bin2elf(binaryfile, outputfile, symbol_prefix, arch, basename, zeroend)
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

        // choose 32-bit or 64-bit ELF based on architecture
        tb_bool_t is_64bit = xm_binutils_bin2elf_is_64bit(arch);
        if (is_64bit) {
            if (!xm_binutils_bin2elf_dump_64(istream, ostream, symbol_prefix, arch, basename, zeroend)) {
                lua_pushboolean(lua, tb_false);
                lua_pushfstring(lua, "bin2elf: dump data failed");
                break;
            }
        } else {
            if (!xm_binutils_bin2elf_dump_32(istream, ostream, symbol_prefix, arch, basename, zeroend)) {
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

