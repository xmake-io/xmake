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
#ifndef XM_BINUTILS_MACHO_PREFIX_H
#define XM_BINUTILS_MACHO_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define XM_MACHO_MAGIC_32        0xfeedface  // MH_MAGIC - little endian
#define XM_MACHO_MAGIC_64        0xfeedfacf  // MH_MAGIC_64 - little endian
#define XM_MACHO_MAGIC_32_BE     0xcefaedfe  // MH_CIGAM - big endian
#define XM_MACHO_MAGIC_64_BE     0xcffaedfe  // MH_CIGAM_64 - big endian
#define XM_MACHO_MAGIC_FAT       0xcafebabe

#define XM_MACHO_CPU_TYPE_X86    7
#define XM_MACHO_CPU_TYPE_X86_64 0x01000007
#define XM_MACHO_CPU_TYPE_ARM   12
#define XM_MACHO_CPU_TYPE_ARM64  0x0100000c

#define XM_MACHO_CPU_SUBTYPE_X86     3
#define XM_MACHO_CPU_SUBTYPE_X86_64  3
#define XM_MACHO_CPU_SUBTYPE_ARM     9
#define XM_MACHO_CPU_SUBTYPE_ARM64   0

#define XM_MACHO_FILE_TYPE_OBJECT   1

#define XM_MACHO_LC_SEGMENT          0x1
#define XM_MACHO_LC_SEGMENT_64       0x19
#define XM_MACHO_LC_SYMTAB           0x2
#define XM_MACHO_LC_LOAD_DYLIB       0xc
#define XM_MACHO_LC_ID_DYLIB         0xd
#define XM_MACHO_LC_RPATH            (0x1c | 0x80000000)
#define XM_MACHO_LC_LOAD_WEAK_DYLIB  (0x18 | 0x80000000)
#define XM_MACHO_LC_REEXPORT_DYLIB   (0x1f | 0x80000000)
#define XM_MACHO_LC_BUILD_VERSION    0x32

#define XM_MACHO_PLATFORM_MACOS      1
#define XM_MACHO_PLATFORM_IOS        2
#define XM_MACHO_PLATFORM_TVOS       3
#define XM_MACHO_PLATFORM_WATCHOS    4

#define XM_MACHO_SECT_TYPE_REGULAR   0x0
#define XM_MACHO_SECT_ATTR_SOME_INITS 0x400
#define XM_MACHO_SECT_ATTR_PURE_INSTRUCTIONS 0x80000000

#define XM_MACHO_N_TYPE_MASK        0x0e
#define XM_MACHO_N_TYPE_SECT        0x0e
#define XM_MACHO_N_EXT               0x01

#define XM_MACHO_VM_PROT_READ       1
#define XM_MACHO_VM_PROT_WRITE      2
#define XM_MACHO_VM_PROT_EXECUTE    4

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
#include "tbox/prefix/packed.h"
typedef struct __xm_macho_header_t {
    tb_uint32_t magic;
    tb_uint32_t cputype;
    tb_uint32_t cpusubtype;
    tb_uint32_t filetype;
    tb_uint32_t ncmds;
    tb_uint32_t sizeofcmds;
    tb_uint32_t flags;
} __tb_packed__ xm_macho_header_t;

typedef struct __xm_macho_header_64_t {
    tb_uint32_t magic;
    tb_uint32_t cputype;
    tb_uint32_t cpusubtype;
    tb_uint32_t filetype;
    tb_uint32_t ncmds;
    tb_uint32_t sizeofcmds;
    tb_uint32_t flags;
    tb_uint32_t reserved;
} __tb_packed__ xm_macho_header_64_t;

typedef struct __xm_macho_rpath_command_t {
    tb_uint32_t cmd;
    tb_uint32_t cmdsize;
    tb_uint32_t path_offset;
} __tb_packed__ xm_macho_rpath_command_t;

typedef struct __xm_macho_segment_command_t {
    tb_uint32_t cmd;
    tb_uint32_t cmdsize;
    tb_char_t segname[16];
    tb_uint32_t vmaddr;
    tb_uint32_t vmsize;
    tb_uint32_t fileoff;
    tb_uint32_t filesize;
    tb_uint32_t maxprot;
    tb_uint32_t initprot;
    tb_uint32_t nsects;
    tb_uint32_t flags;
} __tb_packed__ xm_macho_segment_command_t;

typedef struct __xm_macho_segment_command_64_t {
    tb_uint32_t cmd;
    tb_uint32_t cmdsize;
    tb_char_t segname[16];
    tb_uint64_t vmaddr;
    tb_uint64_t vmsize;
    tb_uint64_t fileoff;
    tb_uint64_t filesize;
    tb_uint32_t maxprot;
    tb_uint32_t initprot;
    tb_uint32_t nsects;
    tb_uint32_t flags;
} __tb_packed__ xm_macho_segment_command_64_t;

typedef struct __xm_macho_section_t {
    tb_char_t sectname[16];
    tb_char_t segname[16];
    tb_uint32_t addr;
    tb_uint32_t size;
    tb_uint32_t offset;
    tb_uint32_t align;
    tb_uint32_t reloff;
    tb_uint32_t nreloc;
    tb_uint32_t flags;
    tb_uint32_t reserved1;
    tb_uint32_t reserved2;
} __tb_packed__ xm_macho_section_t;

typedef struct __xm_macho_section_64_t {
    tb_char_t sectname[16];
    tb_char_t segname[16];
    tb_uint64_t addr;
    tb_uint64_t size;
    tb_uint32_t offset;
    tb_uint32_t align;
    tb_uint32_t reloff;
    tb_uint32_t nreloc;
    tb_uint32_t flags;
    tb_uint32_t reserved1;
    tb_uint32_t reserved2;
    tb_uint32_t reserved3;
} __tb_packed__ xm_macho_section_64_t;

typedef struct __xm_macho_symtab_command_t {
    tb_uint32_t cmd;
    tb_uint32_t cmdsize;
    tb_uint32_t symoff;
    tb_uint32_t nsyms;
    tb_uint32_t stroff;
    tb_uint32_t strsize;
} __tb_packed__ xm_macho_symtab_command_t;

typedef struct __xm_macho_build_version_command_t {
    tb_uint32_t cmd;
    tb_uint32_t cmdsize;
    tb_uint32_t platform;
    tb_uint32_t minos;
    tb_uint32_t sdk;
    tb_uint32_t ntools;
} __tb_packed__ xm_macho_build_version_command_t;

typedef struct __xm_macho_nlist_t {
    tb_uint32_t strx;
    tb_uint8_t type;
    tb_uint8_t sect;
    tb_int16_t desc;
    tb_uint32_t value;
} __tb_packed__ xm_macho_nlist_t;

typedef struct __xm_macho_nlist_64_t {
    tb_uint32_t strx;
    tb_uint8_t type;
    tb_uint8_t sect;
    tb_uint16_t desc;
    tb_uint64_t value;
} __tb_packed__ xm_macho_nlist_64_t;

typedef struct __xm_macho_load_command_t {
    tb_uint32_t cmd;
    tb_uint32_t cmdsize;
} __tb_packed__ xm_macho_load_command_t;

typedef struct __xm_macho_dylib_t {
    tb_uint32_t offset;
    tb_uint32_t timestamp;
    tb_uint32_t current_version;
    tb_uint32_t compatibility_version;
} __tb_packed__ xm_macho_dylib_t;

typedef struct __xm_macho_dylib_command_t {
    tb_uint32_t cmd;
    tb_uint32_t cmdsize;
    xm_macho_dylib_t dylib;
} __tb_packed__ xm_macho_dylib_command_t;

typedef struct __xm_macho_context_t {
    union {
        xm_macho_header_t header32;
        xm_macho_header_64_t header64;
    } header;
    tb_bool_t   is64;
    tb_bool_t   swap;
    tb_uint32_t ncmds;
    tb_uint32_t sizeofcmds;
} __tb_packed__ xm_macho_context_t;
#include "tbox/prefix/packed.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline implementation
 */

// byte-swap Mach-O header fields if needed
static __tb_inline__ tb_void_t xm_binutils_macho_swap_header_32(xm_macho_header_t *header, tb_bool_t swap) {
    if (swap) {
        header->magic = tb_bits_swap_u32(header->magic);
        header->cputype = tb_bits_swap_u32(header->cputype);
        header->cpusubtype = tb_bits_swap_u32(header->cpusubtype);
        header->filetype = tb_bits_swap_u32(header->filetype);
        header->ncmds = tb_bits_swap_u32(header->ncmds);
        header->sizeofcmds = tb_bits_swap_u32(header->sizeofcmds);
        header->flags = tb_bits_swap_u32(header->flags);
    }
}

// byte-swap Mach-O header 64 fields if needed
static __tb_inline__ tb_void_t xm_binutils_macho_swap_header_64(xm_macho_header_64_t *header, tb_bool_t swap) {
    if (swap) {
        header->magic = tb_bits_swap_u32(header->magic);
        header->cputype = tb_bits_swap_u32(header->cputype);
        header->cpusubtype = tb_bits_swap_u32(header->cpusubtype);
        header->filetype = tb_bits_swap_u32(header->filetype);
        header->ncmds = tb_bits_swap_u32(header->ncmds);
        header->sizeofcmds = tb_bits_swap_u32(header->sizeofcmds);
        header->flags = tb_bits_swap_u32(header->flags);
        header->reserved = tb_bits_swap_u32(header->reserved);
    }
}

// init Mach-O context
static __tb_inline__ tb_bool_t xm_binutils_macho_context_init(tb_stream_ref_t istream, tb_hize_t base_offset, xm_macho_context_t* context) {
    tb_assert_and_check_return_val(istream && context, tb_false);

    // read Mach-O header
    if (!tb_stream_seek(istream, base_offset)) return tb_false;
    if (!tb_stream_bread(istream, (tb_byte_t*)&context->header.header32, sizeof(xm_macho_header_t))) return tb_false;

    // check magic
    tb_uint32_t magic = context->header.header32.magic;
    if (magic == XM_MACHO_MAGIC_32) {
        context->is64 = tb_false;
        context->swap = tb_false;
    } else if (magic == XM_MACHO_MAGIC_32_BE) {
        context->is64 = tb_false;
        context->swap = tb_true;
    } else if (magic == XM_MACHO_MAGIC_64) {
        context->is64 = tb_true;
        context->swap = tb_false;
    } else if (magic == XM_MACHO_MAGIC_64_BE) {
        context->is64 = tb_true;
        context->swap = tb_true;
    } else {
        return tb_false; // Not a Mach-O file
    }

    if (context->is64) {
        if (!tb_stream_seek(istream, base_offset)) return tb_false;
        if (!tb_stream_bread(istream, (tb_byte_t*)&context->header.header64, sizeof(xm_macho_header_64_t))) return tb_false;
        xm_binutils_macho_swap_header_64(&context->header.header64, context->swap);
        context->ncmds = context->header.header64.ncmds;
        context->sizeofcmds = context->header.header64.sizeofcmds;
    } else {
        xm_binutils_macho_swap_header_32(&context->header.header32, context->swap);
        context->ncmds = context->header.header32.ncmds;
        context->sizeofcmds = context->header.header32.sizeofcmds;
    }
    return tb_true;
}

// byte-swap load command fields if needed
static __tb_inline__ tb_void_t xm_binutils_macho_swap_load_command(xm_macho_load_command_t *lc, tb_bool_t swap) {
    if (swap) {
        lc->cmd = tb_bits_swap_u32(lc->cmd);
        lc->cmdsize = tb_bits_swap_u32(lc->cmdsize);
    }
}

// byte-swap dylib command fields if needed
static __tb_inline__ tb_void_t xm_binutils_macho_swap_dylib_command(xm_macho_dylib_command_t *dc, tb_bool_t swap) {
    if (swap) {
        dc->cmd = tb_bits_swap_u32(dc->cmd);
        dc->cmdsize = tb_bits_swap_u32(dc->cmdsize);
        dc->dylib.offset = tb_bits_swap_u32(dc->dylib.offset);
        dc->dylib.timestamp = tb_bits_swap_u32(dc->dylib.timestamp);
        dc->dylib.current_version = tb_bits_swap_u32(dc->dylib.current_version);
        dc->dylib.compatibility_version = tb_bits_swap_u32(dc->dylib.compatibility_version);
    }
}

// byte-swap rpath command fields if needed
static __tb_inline__ tb_void_t xm_binutils_macho_swap_rpath_command(xm_macho_rpath_command_t *rc, tb_bool_t swap) {
    if (swap) {
        rc->cmd = tb_bits_swap_u32(rc->cmd);
        rc->cmdsize = tb_bits_swap_u32(rc->cmdsize);
        rc->path_offset = tb_bits_swap_u32(rc->path_offset);
    }
}

// byte-swap symtab command fields if needed
static __tb_inline__ tb_void_t xm_binutils_macho_swap_symtab_command(xm_macho_symtab_command_t *cmd, tb_bool_t swap) {
    if (swap) {
        cmd->cmd = tb_bits_swap_u32(cmd->cmd);
        cmd->cmdsize = tb_bits_swap_u32(cmd->cmdsize);
        cmd->symoff = tb_bits_swap_u32(cmd->symoff);
        cmd->nsyms = tb_bits_swap_u32(cmd->nsyms);
        cmd->stroff = tb_bits_swap_u32(cmd->stroff);
        cmd->strsize = tb_bits_swap_u32(cmd->strsize);
    }
}

// byte-swap nlist 32 fields if needed
static __tb_inline__ tb_void_t xm_binutils_macho_swap_nlist_32(xm_macho_nlist_t *nlist, tb_bool_t swap) {
    if (swap) {
        nlist->strx = tb_bits_swap_u32(nlist->strx);
        nlist->desc = tb_bits_swap_u16(nlist->desc);
        nlist->value = tb_bits_swap_u32(nlist->value);
    }
}

// byte-swap nlist 64 fields if needed
static __tb_inline__ tb_void_t xm_binutils_macho_swap_nlist_64(xm_macho_nlist_64_t *nlist, tb_bool_t swap) {
    if (swap) {
        nlist->strx = tb_bits_swap_u32(nlist->strx);
        nlist->desc = tb_bits_swap_u16(nlist->desc);
        nlist->value = tb_bits_swap_u64(nlist->value);
    }
}

/* get CPU type from architecture string
 *
 * @param arch    the architecture string (e.g., "x86_64", "i386", "arm64")
 * @return        the CPU type
 */
static __tb_inline__ tb_uint32_t xm_binutils_macho_get_cputype(tb_char_t const *arch) {
    if (!arch) {
        return XM_MACHO_CPU_TYPE_X86_64;
    }
    if (tb_strcmp(arch, "x86_64") == 0 || tb_strcmp(arch, "x64") == 0) {
        return XM_MACHO_CPU_TYPE_X86_64;
    } else if (tb_strcmp(arch, "arm64") == 0 || tb_strcmp(arch, "aarch64") == 0) {
        return XM_MACHO_CPU_TYPE_ARM64;
    } else if (tb_strcmp(arch, "arm") == 0) {
        return XM_MACHO_CPU_TYPE_ARM;
    } else if (tb_strcmp(arch, "x86") == 0 || tb_strcmp(arch, "i386") == 0) {
        return XM_MACHO_CPU_TYPE_X86;
    }
    return XM_MACHO_CPU_TYPE_X86_64;
}

/* get CPU subtype from architecture string
 *
 * @param arch    the architecture string
 * @return        the CPU subtype
 */
static __tb_inline__ tb_uint32_t xm_binutils_macho_get_cpusubtype(tb_char_t const *arch) {
    if (!arch) {
        return XM_MACHO_CPU_SUBTYPE_X86_64;
    }
    if (tb_strcmp(arch, "x86_64") == 0 || tb_strcmp(arch, "x64") == 0) {
        return XM_MACHO_CPU_SUBTYPE_X86_64;
    } else if (tb_strcmp(arch, "arm64") == 0 || tb_strcmp(arch, "aarch64") == 0) {
        return XM_MACHO_CPU_SUBTYPE_ARM64;
    } else if (tb_strcmp(arch, "arm") == 0) {
        return XM_MACHO_CPU_SUBTYPE_ARM;
    } else if (tb_strcmp(arch, "x86") == 0 || tb_strcmp(arch, "i386") == 0) {
        return XM_MACHO_CPU_SUBTYPE_X86;
    }
    return XM_MACHO_CPU_SUBTYPE_X86_64;
}

/* check if architecture is 64-bit
 *
 * @param arch    the architecture string
 * @return        tb_true if 64-bit, tb_false otherwise
 */
static __tb_inline__ tb_bool_t xm_binutils_macho_is_64bit(tb_char_t const *arch) {
    if (!arch) {
        return tb_true;
    }
    if (tb_strcmp(arch, "x86_64") == 0 || tb_strcmp(arch, "x64") == 0) {
        return tb_true;
    } else if (tb_strcmp(arch, "arm64") == 0 || tb_strcmp(arch, "aarch64") == 0) {
        return tb_true;
    } else if (tb_strcmp(arch, "arm") == 0) {
        return tb_false;
    } else if (tb_strcmp(arch, "x86") == 0 || tb_strcmp(arch, "i386") == 0) {
        return tb_false;
    }
    return tb_true;
}

/* align value to specified alignment
 *
 * @param value   the value to align
 * @param align   the alignment (must be power of 2)
 * @return        the aligned value
 */
static __tb_inline__ tb_uint32_t xm_binutils_macho_align(tb_uint32_t value, tb_uint32_t align) {
    return ((value + align - 1) & ~(align - 1));
}

/* get platform from platform string
 *
 * @param platform the platform string (e.g., "macosx", "ios", "tvos", "watchos")
 * @return         the platform constant
 */
static __tb_inline__ tb_uint32_t xm_binutils_macho_get_platform(tb_char_t const *platform) {
    if (!platform) {
        return XM_MACHO_PLATFORM_MACOS;
    }
    if (tb_strcmp(platform, "macosx") == 0 || tb_strcmp(platform, "macos") == 0) {
        return XM_MACHO_PLATFORM_MACOS;
    } else if (tb_strcmp(platform, "iphoneos") == 0 || tb_strcmp(platform, "ios") == 0) {
        return XM_MACHO_PLATFORM_IOS;
    } else if (tb_strcmp(platform, "appletvos") == 0 || tb_strcmp(platform, "tvos") == 0) {
        return XM_MACHO_PLATFORM_TVOS;
    } else if (tb_strcmp(platform, "watchos") == 0) {
        return XM_MACHO_PLATFORM_WATCHOS;
    }
    return XM_MACHO_PLATFORM_MACOS;
}

/* parse version string to Mach-O format
 *
 * @param version_str the version string (e.g., "10.0" or "18.2")
 * @return            the version in Mach-O format (major << 16) | (minor << 8) | patch
 */
static __tb_inline__ tb_uint32_t xm_binutils_macho_parse_version(tb_char_t const *version_str) {
    if (!version_str || !version_str[0]) {
        return 0x000a0000; // default: 10.0.0
    }
    tb_uint32_t major = 0;
    tb_uint32_t minor = 0;
    tb_uint32_t patch = 0;
    tb_char_t const *p = version_str;
    // parse major
    while (*p && tb_isdigit(*p)) {
        major = major * 10 + (*p - '0');
        p++;
    }
    if (*p == '.') {
        p++;
        // parse minor
        while (*p && tb_isdigit(*p)) {
            minor = minor * 10 + (*p - '0');
            p++;
        }
        if (*p == '.') {
            p++;
            // parse patch
            while (*p && tb_isdigit(*p)) {
                patch = patch * 10 + (*p - '0');
                p++;
            }
        }
    }
    return (major << 16) | (minor << 8) | patch;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * readsyms inline implementation
 */



/* read string from Mach-O string table
 *
 * @param istream       the input stream
 * @param strtab_offset the string table offset
 * @param offset        the string offset (nlist.strx, relative to string table start, including 4-byte size field)
 * @param name          the buffer to store the string
 * @param name_size     the size of the buffer
 * @return              tb_true on success, tb_false on failure
 */
static __tb_inline__ tb_bool_t xm_binutils_macho_read_string(tb_stream_ref_t istream, tb_hize_t strtab_offset, tb_uint32_t offset, tb_char_t *name, tb_size_t name_size) {
    tb_assert_and_check_return_val(istream && name && name_size > 0, tb_false);

    // nlist.strx is offset from string table start (including 4-byte size field)
    tb_hize_t saved_pos = tb_stream_offset(istream);
    if (!tb_stream_seek(istream, strtab_offset + offset)) {
        return tb_false;
    }

    tb_size_t pos = 0;
    tb_byte_t c;
    while (pos < name_size - 1) {
        if (!tb_stream_bread(istream, &c, 1)) {
            tb_stream_seek(istream, saved_pos);
            return tb_false;
        }
        if (c == 0) {
            break;
        }
        name[pos++] = (tb_char_t)c;
    }
    name[pos] = '\0';

    tb_stream_seek(istream, saved_pos);
    return tb_true;
}

/* get symbol type character (nm-style) from Mach-O symbol
 *
 * @param type  the symbol type byte
 * @param sect  the section number (0 = undefined)
 * @return      the type character (T/t/D/d/B/b/U)
 */
static __tb_inline__ tb_char_t xm_binutils_macho_get_symbol_type_char(tb_uint8_t type, tb_uint8_t sect) {
    // undefined symbol
    if (sect == 0) {
        return 'U';
    }

    // check if external
    tb_bool_t is_external = (type & XM_MACHO_N_EXT) != 0;

    // check if in section
    tb_uint8_t n_type = type & XM_MACHO_N_TYPE_MASK;
    if (n_type == XM_MACHO_N_TYPE_SECT) {
        // section 1 is usually __TEXT,__text (text)
        // section 2 is usually __DATA,__data (data)
        // section 3 is usually __DATA,__bss (bss)
        // For simplicity, we'll use section number to determine type
        // This is a heuristic and may not be 100% accurate
        if (sect == 1) {
            return is_external ? 'T' : 't';  // text section
        } else if (sect == 2) {
            return is_external ? 'D' : 'd';  // data section
        } else if (sect == 3) {
            return is_external ? 'B' : 'b';  // bss section
        } else {
            return is_external ? 'S' : 's';  // other section
        }
    }

    return '?';  // unknown
}

/* get symbol bind string from Mach-O symbol type
 *
 * @param type the symbol type byte
 * @return      the bind string
 */
static __tb_inline__ tb_char_t const *xm_binutils_macho_get_symbol_bind(tb_uint8_t type) {
    if (type & XM_MACHO_N_EXT) {
        return "external";
    }
    return "local";
}

#endif

