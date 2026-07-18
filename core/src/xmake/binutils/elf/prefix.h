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
#ifndef XM_BINUTILS_ELF_PREFIX_H
#define XM_BINUTILS_ELF_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define XM_ELF_MAGIC0 0x7f
#define XM_ELF_MAGIC1 'E'
#define XM_ELF_MAGIC2 'L'
#define XM_ELF_MAGIC3 'F'

// ELF class
#define XM_ELF_EI_CLASS 4
#define XM_ELF_CLASS32  1
#define XM_ELF_CLASS64  2

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

// ELF data encoding (e_ident[EI_DATA])
#define XM_ELF_DATA2LSB          1
#define XM_ELF_DATA2MSB          2

// RISC-V e_flags (arch/riscv/include/uapi/asm/elf.h)
#define XM_EF_RISCV_RVC                  0x0001
#define XM_EF_RISCV_FLOAT_ABI_SINGLE     0x0002
#define XM_EF_RISCV_FLOAT_ABI_DOUBLE     0x0004

// LoongArch e_flags (LoongArch ELF psABI)
#define XM_EF_LOONGARCH_ABI_DOUBLE_FLOAT 0x3
#define XM_EF_LOONGARCH_OBJABI_V1        0x40

// PowerPC64 e_flags: the ELF ABI version is stored in the low 2 bits (see bfd/elf64-ppc.c)
#define XM_EF_PPC64_ABI_V1               0x1
#define XM_EF_PPC64_ABI_V2               0x2

// MIPS e_flags (binutils include/elf/mips.h)
#define XM_EF_MIPS_CPIC                  0x00000004 // call-PIC: linkable with both PIC and non-PIC objects
#define XM_EF_MIPS_ABI_O32               0x00001000 // the original 32-bit "o32" ABI

#define XM_ELF_SHT_PROGBITS      0x1
#define XM_ELF_SHT_SYMTAB        0x2
#define XM_ELF_SHT_STRTAB        0x3
#define XM_ELF_SHT_DYNAMIC       0x6

#define XM_ELF_PT_LOAD           1
#define XM_ELF_PT_DYNAMIC        2
#define XM_ELF_PT_INTERP         3

#define XM_ELF_DT_NULL           0
#define XM_ELF_DT_NEEDED         1
#define XM_ELF_DT_STRTAB         5
#define XM_ELF_DT_STRSZ          10
#define XM_ELF_DT_SONAME         14
#define XM_ELF_DT_RPATH          15
#define XM_ELF_DT_RUNPATH        29
#define XM_ELF_DT_AUXILIARY      0x7ffffffd
#define XM_ELF_DT_FILTER         0x7fffffff

#define XM_ELF_SHF_ALLOC         0x2
#define XM_ELF_SHF_WRITE         0x1

#define XM_ELF_STB_GLOBAL        0x1
#define XM_ELF_STT_OBJECT        0x1

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
#include "tbox/prefix/packed.h"
typedef struct __xm_elf_context_t {
    tb_hize_t dynamic_offset; // file offset of .dynamic
    tb_hize_t dynamic_size;   // size of .dynamic
    tb_hize_t strtab_offset;  // file offset of .dynstr
    tb_hize_t strtab_size;    // size of .dynstr
    tb_hize_t symtab_offset;  // file offset of .symtab
    tb_hize_t symtab_size;    // size of .symtab
    tb_hize_t symstr_offset;  // file offset of .strtab (for .symtab)
    tb_hize_t symstr_size;    // size of .strtab (for .symtab)
    tb_bool_t is64;
} xm_elf_context_t;

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

typedef struct __xm_elf32_phdr_t {
    tb_uint32_t p_type;
    tb_uint32_t p_offset;
    tb_uint32_t p_vaddr;
    tb_uint32_t p_paddr;
    tb_uint32_t p_filesz;
    tb_uint32_t p_memsz;
    tb_uint32_t p_flags;
    tb_uint32_t p_align;
} __tb_packed__ xm_elf32_phdr_t;

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

typedef struct __xm_elf64_phdr_t {
    tb_uint32_t p_type;
    tb_uint32_t p_flags;
    tb_uint64_t p_offset;
    tb_uint64_t p_vaddr;
    tb_uint64_t p_paddr;
    tb_uint64_t p_filesz;
    tb_uint64_t p_memsz;
    tb_uint64_t p_align;
} __tb_packed__ xm_elf64_phdr_t;

typedef struct __xm_elf32_dynamic_t {
    tb_int32_t  d_tag;
    union {
        tb_uint32_t d_val;
        tb_uint32_t d_ptr;
    } d_un;
} __tb_packed__ xm_elf32_dynamic_t;

typedef struct __xm_elf64_dynamic_t {
    tb_int64_t  d_tag;
    union {
        tb_uint64_t d_val;
        tb_uint64_t d_ptr;
    } d_un;
} __tb_packed__ xm_elf64_dynamic_t;
#include "tbox/prefix/packed.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline implementation
 */

/* get machine type from architecture string
 *
 * @param arch    the architecture string (e.g., "x86_64", "i386", "arm64", "riscv")
 * @return        the machine type
 */
static __tb_inline__ tb_uint16_t xm_binutils_elf_get_machine(tb_char_t const *arch) {
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

/* check if architecture is 64-bit
 *
 * @param arch    the architecture string
 * @return        tb_true if 64-bit, tb_false otherwise
 */
static __tb_inline__ tb_bool_t xm_binutils_elf_is_64bit(tb_char_t const *arch) {
    return xm_binutils_arch_is_64bit(arch);
}

/* check if architecture is big-endian
 *
 * @param arch    the architecture string
 * @return        tb_true if big-endian, tb_false otherwise
 */
static __tb_inline__ tb_bool_t xm_binutils_elf_is_bigendian(tb_char_t const *arch) {
    return xm_binutils_arch_is_bigendian(arch);
}

/* get the default e_flags for the given architecture
 *
 * Some architectures (RISC-V, LoongArch) encode the ABI (e.g. float ABI) in e_flags.
 * The linker refuses to merge objects whose ABI flags are incompatible, so a data-only
 * object generated with e_flags == 0 (soft-float) would fail to link against a normal
 * double-float toolchain. We default to the flags used by the common GNU toolchains.
 *
 * @param arch    the architecture string
 * @return        the e_flags value
 */
static __tb_inline__ tb_uint32_t xm_binutils_elf_get_flags(tb_char_t const *arch) {
    if (!arch) {
        return 0;
    }
    // RISC-V: default to RVC + double-float ABI to match the common rv32/rv64 "gc" toolchains
    if (tb_strncmp(arch, "riscv", 5) == 0) {
        return XM_EF_RISCV_RVC | XM_EF_RISCV_FLOAT_ABI_DOUBLE;
    }
    // LoongArch: default to double-float ABI (lp64d/ilp32d) + object ABI v1
    else if (tb_strncmp(arch, "loongarch", 9) == 0 || tb_strncmp(arch, "loong64", 7) == 0) {
        return XM_EF_LOONGARCH_ABI_DOUBLE_FLOAT | XM_EF_LOONGARCH_OBJABI_V1;
    }
    // PowerPC64: encode the ELF ABI version in e_flags.
    // little-endian ppc64le uses the OpenPOWER ELFv2 ABI, big-endian ppc64 uses ELFv1,
    // matching the gcc/clang defaults (-mabi=elfv2 on LE, -mabi=elfv1 on BE).
    // 32-bit PowerPC does not carry an ABI version (e_flags == 0).
    else if (tb_strncmp(arch, "ppc64", 5) == 0 || tb_strncmp(arch, "powerpc64", 9) == 0) {
        return xm_binutils_arch_is_bigendian(arch)? XM_EF_PPC64_ABI_V1 : XM_EF_PPC64_ABI_V2;
    }
    // MIPS: mark the object as CPIC so it links against both PIC and non-PIC objects, and
    // tag the 32-bit variants with the o32 ABI to match the common GNU toolchains (n64 is
    // implied by ELFCLASS64, so mips64/mips64el carry no ABI bit). the ISA level (top nibble)
    // and fp/NaN bits are left at 0 (== "any") on purpose: overclaiming them would make the
    // linker reject otherwise-compatible objects.
    else if (tb_strncmp(arch, "mips", 4) == 0) {
        tb_uint32_t flags = XM_EF_MIPS_CPIC;
        if (!xm_binutils_arch_is_64bit(arch)) {
            flags |= XM_EF_MIPS_ABI_O32;
        }
        return flags;
    }
    return 0;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * endianness-aware serialization
 *
 * The dump code fills the ELF structs in the host's native byte order. Before writing them
 * out, each multi-byte field must be converted to the *target* endianness (which may differ
 * from the host, e.g. generating a big-endian s390x object on a little-endian host).
 */

static __tb_inline__ tb_uint16_t xm_binutils_elf_conv_u16(tb_uint16_t x, tb_bool_t bigendian) {
    return bigendian? tb_bits_ne_to_be_u16(x) : tb_bits_ne_to_le_u16(x);
}
static __tb_inline__ tb_uint32_t xm_binutils_elf_conv_u32(tb_uint32_t x, tb_bool_t bigendian) {
    return bigendian? tb_bits_ne_to_be_u32(x) : tb_bits_ne_to_le_u32(x);
}
static __tb_inline__ tb_uint64_t xm_binutils_elf_conv_u64(tb_uint64_t x, tb_bool_t bigendian) {
    return bigendian? tb_bits_ne_to_be_u64(x) : tb_bits_ne_to_le_u64(x);
}

// convert a 32-bit ELF header to the target endianness in place (e_ident is byte data, untouched)
static __tb_inline__ void xm_binutils_elf32_header_conv(xm_elf32_header_t* h, tb_bool_t be) {
    h->e_type      = xm_binutils_elf_conv_u16(h->e_type, be);
    h->e_machine   = xm_binutils_elf_conv_u16(h->e_machine, be);
    h->e_version   = xm_binutils_elf_conv_u32(h->e_version, be);
    h->e_entry     = xm_binutils_elf_conv_u32(h->e_entry, be);
    h->e_phoff     = xm_binutils_elf_conv_u32(h->e_phoff, be);
    h->e_shoff     = xm_binutils_elf_conv_u32(h->e_shoff, be);
    h->e_flags     = xm_binutils_elf_conv_u32(h->e_flags, be);
    h->e_ehsize    = xm_binutils_elf_conv_u16(h->e_ehsize, be);
    h->e_phentsize = xm_binutils_elf_conv_u16(h->e_phentsize, be);
    h->e_phnum     = xm_binutils_elf_conv_u16(h->e_phnum, be);
    h->e_shentsize = xm_binutils_elf_conv_u16(h->e_shentsize, be);
    h->e_shnum     = xm_binutils_elf_conv_u16(h->e_shnum, be);
    h->e_shstrndx  = xm_binutils_elf_conv_u16(h->e_shstrndx, be);
}
static __tb_inline__ void xm_binutils_elf32_section_conv(xm_elf32_section_t* s, tb_bool_t be) {
    s->sh_name      = xm_binutils_elf_conv_u32(s->sh_name, be);
    s->sh_type      = xm_binutils_elf_conv_u32(s->sh_type, be);
    s->sh_flags     = xm_binutils_elf_conv_u32(s->sh_flags, be);
    s->sh_addr      = xm_binutils_elf_conv_u32(s->sh_addr, be);
    s->sh_offset    = xm_binutils_elf_conv_u32(s->sh_offset, be);
    s->sh_size      = xm_binutils_elf_conv_u32(s->sh_size, be);
    s->sh_link      = xm_binutils_elf_conv_u32(s->sh_link, be);
    s->sh_info      = xm_binutils_elf_conv_u32(s->sh_info, be);
    s->sh_addralign = xm_binutils_elf_conv_u32(s->sh_addralign, be);
    s->sh_entsize   = xm_binutils_elf_conv_u32(s->sh_entsize, be);
}
static __tb_inline__ void xm_binutils_elf32_symbol_conv(xm_elf32_symbol_t* s, tb_bool_t be) {
    s->st_name  = xm_binutils_elf_conv_u32(s->st_name, be);
    s->st_value = xm_binutils_elf_conv_u32(s->st_value, be);
    s->st_size  = xm_binutils_elf_conv_u32(s->st_size, be);
    s->st_shndx = xm_binutils_elf_conv_u16(s->st_shndx, be);
    // st_info and st_other are single bytes, untouched
}
static __tb_inline__ void xm_binutils_elf64_header_conv(xm_elf64_header_t* h, tb_bool_t be) {
    h->e_type      = xm_binutils_elf_conv_u16(h->e_type, be);
    h->e_machine   = xm_binutils_elf_conv_u16(h->e_machine, be);
    h->e_version   = xm_binutils_elf_conv_u32(h->e_version, be);
    h->e_entry     = xm_binutils_elf_conv_u64(h->e_entry, be);
    h->e_phoff     = xm_binutils_elf_conv_u64(h->e_phoff, be);
    h->e_shoff     = xm_binutils_elf_conv_u64(h->e_shoff, be);
    h->e_flags     = xm_binutils_elf_conv_u32(h->e_flags, be);
    h->e_ehsize    = xm_binutils_elf_conv_u16(h->e_ehsize, be);
    h->e_phentsize = xm_binutils_elf_conv_u16(h->e_phentsize, be);
    h->e_phnum     = xm_binutils_elf_conv_u16(h->e_phnum, be);
    h->e_shentsize = xm_binutils_elf_conv_u16(h->e_shentsize, be);
    h->e_shnum     = xm_binutils_elf_conv_u16(h->e_shnum, be);
    h->e_shstrndx  = xm_binutils_elf_conv_u16(h->e_shstrndx, be);
}
static __tb_inline__ void xm_binutils_elf64_section_conv(xm_elf64_section_t* s, tb_bool_t be) {
    s->sh_name      = xm_binutils_elf_conv_u32(s->sh_name, be);
    s->sh_type      = xm_binutils_elf_conv_u32(s->sh_type, be);
    s->sh_flags     = xm_binutils_elf_conv_u64(s->sh_flags, be);
    s->sh_addr      = xm_binutils_elf_conv_u64(s->sh_addr, be);
    s->sh_offset    = xm_binutils_elf_conv_u64(s->sh_offset, be);
    s->sh_size      = xm_binutils_elf_conv_u64(s->sh_size, be);
    s->sh_link      = xm_binutils_elf_conv_u32(s->sh_link, be);
    s->sh_info      = xm_binutils_elf_conv_u32(s->sh_info, be);
    s->sh_addralign = xm_binutils_elf_conv_u64(s->sh_addralign, be);
    s->sh_entsize   = xm_binutils_elf_conv_u64(s->sh_entsize, be);
}
static __tb_inline__ void xm_binutils_elf64_symbol_conv(xm_elf64_symbol_t* s, tb_bool_t be) {
    s->st_name  = xm_binutils_elf_conv_u32(s->st_name, be);
    s->st_shndx = xm_binutils_elf_conv_u16(s->st_shndx, be);
    s->st_value = xm_binutils_elf_conv_u64(s->st_value, be);
    s->st_size  = xm_binutils_elf_conv_u64(s->st_size, be);
    // st_info and st_other are single bytes, untouched
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * readsyms inline implementation
 */

/* get symbol type character (nm-style) from ELF symbol
 *
 * @param st_info  the symbol info byte
 * @param st_shndx the section index (0 = undefined)
 * @return         the type character (T/t/D/d/B/b/U)
 */
static __tb_inline__ tb_char_t xm_binutils_elf_get_symbol_type_char(tb_uint8_t st_info, tb_uint16_t st_shndx) {
    // undefined symbol
    if (st_shndx == 0) {
        return 'U';
    }

    // check bind (global = uppercase, local = lowercase)
    tb_uint8_t bind = (st_info >> 4) & 0xf;
    tb_bool_t is_global = (bind == 1); // STB_GLOBAL

    // check type
    tb_uint8_t type = st_info & 0xf;
    if (type == 2) { // STT_FUNC
        return is_global ? 'T' : 't';  // text (function)
    } else if (type == 1) { // STT_OBJECT
        // For object symbols, we need section info to determine data/bss
        // For simplicity, we'll use 'D' for data, 'B' for bss
        // This is a heuristic - in practice, we'd need to check section flags
        return is_global ? 'D' : 'd';  // data (assume data section)
    }

    // other types
    return is_global ? 'S' : 's';  // other section
}

/* get symbol bind string from ELF symbol info
 *
 * @param st_info the symbol info byte
 * @return         the bind string
 */
static __tb_inline__ tb_char_t const *xm_binutils_elf_get_symbol_bind(tb_uint8_t st_info) {
    tb_uint8_t bind = (st_info >> 4) & 0xf;
    switch (bind) {
    case 0: return "local";
    case 1: return "global";
    case 2: return "weak";
    default: return "unknown";
    }
}

// read ELF header (32-bit)
static __tb_inline__ tb_bool_t xm_binutils_elf_read_header_32(tb_stream_ref_t istream, tb_hize_t base_offset, xm_elf32_header_t* header) {
    if (!tb_stream_seek(istream, base_offset)) return tb_false;
    if (!tb_stream_bread(istream, (tb_byte_t*)header, sizeof(*header))) return tb_false;
    return tb_true;
}

// read ELF header (64-bit)
static __tb_inline__ tb_bool_t xm_binutils_elf_read_header_64(tb_stream_ref_t istream, tb_hize_t base_offset, xm_elf64_header_t* header) {
    if (!tb_stream_seek(istream, base_offset)) return tb_false;
    if (!tb_stream_bread(istream, (tb_byte_t*)header, sizeof(*header))) return tb_false;
    return tb_true;
}

static __tb_inline__ tb_bool_t xm_binutils_elf_get_context_32(tb_stream_ref_t istream, tb_hize_t base_offset, xm_elf_context_t* ctx) {
    tb_memset(ctx, 0, sizeof(xm_elf_context_t));
    ctx->is64 = tb_false;

    // read ELF header
    xm_elf32_header_t header;
    if (!xm_binutils_elf_read_header_32(istream, base_offset, &header)) return tb_false;

    // try to find from section headers first
    if (header.e_shoff != 0 && header.e_shnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_shoff)) {
            for (tb_uint16_t i = 0; i < header.e_shnum; i++) {
                xm_elf32_section_t section;
                if (!tb_stream_bread(istream, (tb_byte_t*)&section, sizeof(section))) break;

                if (section.sh_type == XM_ELF_SHT_DYNAMIC) {
                    ctx->dynamic_offset = section.sh_offset;
                    ctx->dynamic_size = section.sh_size;

                    // find string table via sh_link
                    xm_elf32_section_t strtab_section;
                    if (tb_stream_seek(istream, base_offset + header.e_shoff + section.sh_link * sizeof(xm_elf32_section_t)) &&
                        tb_stream_bread(istream, (tb_byte_t*)&strtab_section, sizeof(strtab_section))) {
                        ctx->strtab_offset = strtab_section.sh_offset;
                        ctx->strtab_size = strtab_section.sh_size;
                    }
                } else if (section.sh_type == XM_ELF_SHT_SYMTAB) {
                    ctx->symtab_offset = section.sh_offset;
                    ctx->symtab_size = section.sh_size;
                    xm_elf32_section_t symstr_section;
                    if (tb_stream_seek(istream, base_offset + header.e_shoff + section.sh_link * sizeof(xm_elf32_section_t)) &&
                        tb_stream_bread(istream, (tb_byte_t*)&symstr_section, sizeof(symstr_section))) {
                        ctx->symstr_offset = symstr_section.sh_offset;
                        ctx->symstr_size = symstr_section.sh_size;
                    }
                }
            }
        }
    }

    // fallback to program headers
    if ((ctx->dynamic_offset == 0 || ctx->strtab_offset == 0) && header.e_phoff != 0 && header.e_phnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
            for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                xm_elf32_phdr_t phdr;
                if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) break;
                if (phdr.p_type == XM_ELF_PT_DYNAMIC) {
                    ctx->dynamic_offset = phdr.p_offset;
                    ctx->dynamic_size = phdr.p_memsz;
                    break;
                }
            }
        }

        if (ctx->dynamic_offset > 0 && ctx->dynamic_size > 0) {
            // read dynamic entries to find strtab address and size
            tb_uint64_t strtab_vaddr = 0;
            tb_uint64_t strtab_sz = 0;
            tb_uint32_t count = (tb_uint32_t)(ctx->dynamic_size / sizeof(xm_elf32_dynamic_t));
            if (tb_stream_seek(istream, base_offset + ctx->dynamic_offset)) {
                for (tb_uint32_t i = 0; i < count; i++) {
                    xm_elf32_dynamic_t dyn;
                    if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) break;
                    if (dyn.d_tag == XM_ELF_DT_STRTAB) strtab_vaddr = dyn.d_un.d_val;
                    else if (dyn.d_tag == XM_ELF_DT_STRSZ) strtab_sz = dyn.d_un.d_val;
                }
            }

            if (strtab_vaddr > 0) {
                // map strtab vaddr to file offset using PT_LOAD
                if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
                    for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                        xm_elf32_phdr_t phdr;
                        if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) break;
                        if (phdr.p_type == XM_ELF_PT_LOAD && strtab_vaddr >= phdr.p_vaddr && strtab_vaddr < phdr.p_vaddr + phdr.p_memsz) {
                            ctx->strtab_offset = phdr.p_offset + (strtab_vaddr - phdr.p_vaddr);
                            ctx->strtab_size = strtab_sz;
                            break;
                        }
                    }
                }
            }
        }
    }

    return (ctx->dynamic_offset != 0 && ctx->strtab_offset != 0);
}

static __tb_inline__ tb_bool_t xm_binutils_elf_get_context_64(tb_stream_ref_t istream, tb_hize_t base_offset, xm_elf_context_t* ctx) {
    tb_memset(ctx, 0, sizeof(xm_elf_context_t));
    ctx->is64 = tb_true;

    // read ELF header
    xm_elf64_header_t header;
    if (!xm_binutils_elf_read_header_64(istream, base_offset, &header)) return tb_false;

    // try to find from section headers first
    if (header.e_shoff != 0 && header.e_shnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_shoff)) {
            for (tb_uint16_t i = 0; i < header.e_shnum; i++) {
                xm_elf64_section_t section;
                if (!tb_stream_bread(istream, (tb_byte_t*)&section, sizeof(section))) break;

                if (section.sh_type == XM_ELF_SHT_DYNAMIC) {
                    ctx->dynamic_offset = section.sh_offset;
                    ctx->dynamic_size = section.sh_size;

                    // find string table via sh_link
                    xm_elf64_section_t strtab_section;
                    if (tb_stream_seek(istream, base_offset + header.e_shoff + section.sh_link * sizeof(xm_elf64_section_t)) &&
                        tb_stream_bread(istream, (tb_byte_t*)&strtab_section, sizeof(strtab_section))) {
                        ctx->strtab_offset = strtab_section.sh_offset;
                        ctx->strtab_size = strtab_section.sh_size;
                    }
                } else if (section.sh_type == XM_ELF_SHT_SYMTAB) {
                    ctx->symtab_offset = section.sh_offset;
                    ctx->symtab_size = section.sh_size;
                    xm_elf64_section_t symstr_section;
                    if (tb_stream_seek(istream, base_offset + header.e_shoff + section.sh_link * sizeof(xm_elf64_section_t)) &&
                        tb_stream_bread(istream, (tb_byte_t*)&symstr_section, sizeof(symstr_section))) {
                        ctx->symstr_offset = symstr_section.sh_offset;
                        ctx->symstr_size = symstr_section.sh_size;
                    }
                }
            }
        }
    }

    // fallback to program headers
    if ((ctx->dynamic_offset == 0 || ctx->strtab_offset == 0) && header.e_phoff != 0 && header.e_phnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
            for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                xm_elf64_phdr_t phdr;
                if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) break;
                if (phdr.p_type == XM_ELF_PT_DYNAMIC) {
                    ctx->dynamic_offset = phdr.p_offset;
                    ctx->dynamic_size = phdr.p_memsz;
                    break;
                }
            }
        }

        if (ctx->dynamic_offset > 0 && ctx->dynamic_size > 0) {
            // read dynamic entries to find strtab address and size
            tb_uint64_t strtab_vaddr = 0;
            tb_uint64_t strtab_sz = 0;
            tb_uint32_t count = (tb_uint32_t)(ctx->dynamic_size / sizeof(xm_elf64_dynamic_t));
            if (tb_stream_seek(istream, base_offset + ctx->dynamic_offset)) {
                for (tb_uint32_t i = 0; i < count; i++) {
                    xm_elf64_dynamic_t dyn;
                    if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) break;
                    if (dyn.d_tag == XM_ELF_DT_STRTAB) strtab_vaddr = dyn.d_un.d_val;
                    else if (dyn.d_tag == XM_ELF_DT_STRSZ) strtab_sz = dyn.d_un.d_val;
                }
            }

            if (strtab_vaddr > 0) {
                // map strtab vaddr to file offset using PT_LOAD
                if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
                    for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                        xm_elf64_phdr_t phdr;
                        if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) break;
                        if (phdr.p_type == XM_ELF_PT_LOAD && strtab_vaddr >= phdr.p_vaddr && strtab_vaddr < phdr.p_vaddr + phdr.p_memsz) {
                            ctx->strtab_offset = phdr.p_offset + (strtab_vaddr - phdr.p_vaddr);
                            ctx->strtab_size = strtab_sz;
                            break;
                        }
                    }
                }
            }
        }
    }

    return (ctx->dynamic_offset != 0 && ctx->strtab_offset != 0);
}


// find PT_INTERP and read interpreter path (32-bit)
static __tb_inline__ tb_bool_t xm_binutils_elf_find_interp_32(tb_stream_ref_t istream, tb_hize_t base_offset, xm_elf32_header_t const* header, tb_char_t* name, tb_size_t size) {
    if (header->e_phoff != 0 && header->e_phnum > 0) {
        if (tb_stream_seek(istream, base_offset + header->e_phoff)) {
            for (tb_uint16_t i = 0; i < header->e_phnum; i++) {
                xm_elf32_phdr_t phdr;
                if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) break;
                if (phdr.p_type == XM_ELF_PT_INTERP) {
                    return xm_binutils_read_string(istream, base_offset + phdr.p_offset, name, size) && name[0];
                }
            }
        }
    }
    return tb_false;
}

// find PT_INTERP and read interpreter path (64-bit)
static __tb_inline__ tb_bool_t xm_binutils_elf_find_interp_64(tb_stream_ref_t istream, tb_hize_t base_offset, xm_elf64_header_t const* header, tb_char_t* name, tb_size_t size) {
    if (header->e_phoff != 0 && header->e_phnum > 0) {
        if (tb_stream_seek(istream, base_offset + header->e_phoff)) {
            for (tb_uint16_t i = 0; i < header->e_phnum; i++) {
                xm_elf64_phdr_t phdr;
                if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) break;
                if (phdr.p_type == XM_ELF_PT_INTERP) {
                    return xm_binutils_read_string(istream, base_offset + phdr.p_offset, name, size) && name[0];
                }
            }
        }
    }
    return tb_false;
}

#endif
