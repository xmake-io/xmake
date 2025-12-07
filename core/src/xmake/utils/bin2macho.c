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
 * macros
 */
#define XM_MACHO_MAGIC_32        0xfeedface
#define XM_MACHO_MAGIC_64        0xfeedfacf
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
#include "tbox/prefix/packed.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_uint32_t xm_utils_bin2macho_get_cputype(tb_char_t const *arch) {
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

static tb_uint32_t xm_utils_bin2macho_get_cpusubtype(tb_char_t const *arch) {
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

static tb_bool_t xm_utils_bin2macho_is_64bit(tb_char_t const *arch) {
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

static tb_uint32_t xm_utils_bin2macho_align(tb_uint32_t value, tb_uint32_t align) {
    return ((value + align - 1) & ~(align - 1));
}

static tb_uint32_t xm_utils_bin2macho_get_platform(tb_char_t const *platform) {
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

// parse version string (e.g., "10.0" or "18.2") to Mach-O format (0x000a0000)
// format: (major << 16) | (minor << 8) | patch
static tb_uint32_t xm_utils_bin2macho_parse_version(tb_char_t const *version_str) {
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

static tb_bool_t xm_utils_bin2macho_dump_64(tb_stream_ref_t istream,
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
    for (tb_size_t i = 0; symbol_name[i]; i++) {
        if (!tb_isalpha(symbol_name[i]) && !tb_isdigit(symbol_name[i]) && symbol_name[i] != '_') {
            symbol_name[i] = '_';
        }
    }

    tb_snprintf(symbol_start, sizeof(symbol_start), "%s_start", symbol_name);
    tb_snprintf(symbol_end, sizeof(symbol_end), "%s_end", symbol_name);

    // calculate offsets
    tb_uint32_t header_size = sizeof(xm_macho_header_64_t);
    tb_uint32_t segment_cmd_size = sizeof(xm_macho_segment_command_64_t);
    tb_uint32_t section_size = sizeof(xm_macho_section_64_t);
    tb_uint32_t symtab_cmd_size = sizeof(xm_macho_symtab_command_t);
    tb_uint32_t build_version_cmd_size = sizeof(xm_macho_build_version_command_t);
    tb_uint32_t segment_cmd_total_size = segment_cmd_size + section_size;
    tb_uint32_t data_offset = xm_utils_bin2macho_align(header_size + segment_cmd_total_size + symtab_cmd_size + build_version_cmd_size, 8);
    tb_uint32_t data_size = datasize;
    tb_uint32_t data_end_offset = data_offset + data_size;
    tb_uint32_t symtab_offset = xm_utils_bin2macho_align(data_end_offset, 8);
    tb_uint32_t nlist_size = sizeof(xm_macho_nlist_64_t);
    tb_uint32_t nlist_count = 2; // start, end
    tb_uint32_t strtab_offset = symtab_offset + nlist_size * nlist_count;
    tb_uint32_t strtab_size = 4; // initial 4-byte size field
    tb_size_t start_len = tb_strlen(symbol_start);
    tb_size_t end_len = tb_strlen(symbol_end);
    strtab_size += (tb_uint32_t)(start_len + 1);
    strtab_size += (tb_uint32_t)(end_len + 1);
    strtab_size = xm_utils_bin2macho_align(strtab_size, 8);

    // write Mach-O header
    xm_macho_header_64_t header;
    tb_memset(&header, 0, sizeof(header));
    header.magic = XM_MACHO_MAGIC_64;
    header.cputype = xm_utils_bin2macho_get_cputype(arch);
    header.cpusubtype = xm_utils_bin2macho_get_cpusubtype(arch);
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
    segment.maxprot = XM_MACHO_VM_PROT_READ; // VM_PROT_READ (read-only)
    segment.initprot = XM_MACHO_VM_PROT_READ; // VM_PROT_READ (read-only)
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
    build_version.platform = xm_utils_bin2macho_get_platform(plat);
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
    tb_byte_t buffer[8192];
    tb_hong_t left = filesize;
    while (left > 0) {
        tb_size_t to_read = (tb_size_t)tb_min(left, (tb_hong_t)sizeof(buffer));
        if (!tb_stream_bread(istream, buffer, to_read)) {
            return tb_false;
        }
        if (!tb_stream_bwrit(ostream, buffer, to_read)) {
            return tb_false;
        }
        left -= to_read;
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

static tb_bool_t xm_utils_bin2macho_dump(tb_stream_ref_t istream,
                                         tb_stream_ref_t ostream,
                                         tb_char_t const *symbol_prefix,
                                         tb_char_t const *plat,
                                         tb_char_t const *arch,
                                         tb_char_t const *basename,
                                         tb_uint32_t minos,
                                         tb_uint32_t sdk,
                                         tb_bool_t zeroend) {
    if (xm_utils_bin2macho_is_64bit(arch)) {
        return xm_utils_bin2macho_dump_64(istream, ostream, symbol_prefix, plat, arch, basename, minos, sdk, zeroend);
    } else {
        // 32-bit not implemented yet
        return tb_false;
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* generate Mach-O object file from binary file
 *
 * local ok, errors = utils.bin2macho(binaryfile, outputfile, symbol_prefix, plat, arch, basename)
 */
tb_int_t xm_utils_bin2macho(lua_State *lua) {
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
    tb_uint32_t minos = xm_utils_bin2macho_parse_version(minos_str);

    // get sdk version string (optional)
    tb_char_t const *sdk_str = lua_isstring(lua, 8) ? lua_tostring(lua, 8) : tb_null;
    tb_uint32_t sdk = xm_utils_bin2macho_parse_version(sdk_str);

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

        if (!xm_utils_bin2macho_dump(istream, ostream, symbol_prefix, plat, arch, basename, minos, sdk, zeroend)) {
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

