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
 * @file        bin2coff.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "bin2coff"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define XM_COFF_MACHINE_I386    0x014c
#define XM_COFF_MACHINE_AMD64   0x8664
#define XM_COFF_MACHINE_ARM     0x01c0
#define XM_COFF_MACHINE_ARM64   0xaa64

#define XM_COFF_SECTION_RDATA   0x40000040  // IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */
#pragma pack(push, 1)
typedef struct {
    tb_uint16_t machine;
    tb_uint16_t nsects;
    tb_uint32_t time;
    tb_uint32_t symtabofs;
    tb_uint32_t nsyms;
    tb_uint16_t opthdr;
    tb_uint16_t flags;
} xm_coff_header_t;

typedef struct {
    tb_char_t name[8];
    tb_uint32_t vsize;
    tb_uint32_t vaddr;
    tb_uint32_t size;
    tb_uint32_t ofs;
    tb_uint32_t relocofs;
    tb_uint32_t linenoofs;
    tb_uint16_t nreloc;
    tb_uint16_t nlineno;
    tb_uint32_t flags;
} xm_coff_section_t;

typedef struct {
    union {
        struct {
            tb_char_t name[8];
        } shortname;
        struct {
            tb_uint32_t zeros;
            tb_uint32_t offset;
        } longname;
    } n;
    tb_uint32_t value;
    tb_int16_t sect;
    tb_uint16_t type;
    tb_uint8_t scl;
    tb_uint8_t naux;
} xm_coff_symbol_t;
#pragma pack(pop)

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_uint16_t xm_utils_bin2coff_get_machine(tb_char_t const *arch) {
    if (!arch) {
        return XM_COFF_MACHINE_I386;
    }
    if (tb_strcmp(arch, "x86_64") == 0 || tb_strcmp(arch, "x64") == 0) {
        return XM_COFF_MACHINE_AMD64;
    } else if (tb_strcmp(arch, "arm64") == 0 || tb_strcmp(arch, "aarch64") == 0) {
        return XM_COFF_MACHINE_ARM64;
    } else if (tb_strcmp(arch, "arm") == 0) {
        return XM_COFF_MACHINE_ARM;
    }
    return XM_COFF_MACHINE_I386;
}

static tb_void_t xm_utils_bin2coff_write_string(tb_stream_ref_t ostream, tb_char_t const *str, tb_size_t len) {
    tb_assert_and_check_return(ostream && str);
    if (len == 0) {
        len = tb_strlen(str);
    }
    tb_stream_bwrit(ostream, (tb_byte_t const *)str, len);
}

static tb_void_t xm_utils_bin2coff_write_padding(tb_stream_ref_t ostream, tb_size_t count) {
    tb_assert_and_check_return(ostream);
    tb_byte_t zero = 0;
    while (count-- > 0) {
        tb_stream_bwrit(ostream, &zero, 1);
    }
}

static tb_void_t xm_utils_bin2coff_write_symbol_name(tb_stream_ref_t ostream, tb_char_t const *name, tb_uint32_t *strtab_offset) {
    tb_assert_and_check_return(ostream && name && strtab_offset);
    tb_size_t len = tb_strlen(name);
    if (len <= 8) {
        // short name: store directly in symbol name field
        xm_utils_bin2coff_write_string(ostream, name, len);
        if (len < 8) {
            xm_utils_bin2coff_write_padding(ostream, 8 - len);
        }
    } else {
        // long name: store offset in string table
        tb_uint32_t zeros = 0;
        tb_stream_bwrit(ostream, (tb_byte_t const *)&zeros, 4);
        tb_stream_bwrit(ostream, (tb_byte_t const *)strtab_offset, 4);
        *strtab_offset += (tb_uint32_t)(len + 1); // +1 for null terminator
    }
}

static tb_bool_t xm_utils_bin2coff_dump(tb_stream_ref_t istream,
                                        tb_stream_ref_t ostream,
                                        tb_char_t const *symbol_prefix,
                                        tb_char_t const *arch,
                                        tb_char_t const *basename) {
    tb_assert_and_check_return_val(istream && ostream, tb_false);

    // get file size
    tb_hong_t filesize = tb_stream_size(istream);
    if (filesize < 0) {
        return tb_false;
    }
    tb_uint32_t datasize = (tb_uint32_t)filesize;

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
    tb_uint32_t header_size = sizeof(xm_coff_header_t);
    tb_uint32_t section_header_size = sizeof(xm_coff_section_t);
    tb_uint32_t section_data_ofs = header_size + section_header_size;
    tb_uint32_t section_data_size = datasize;
    tb_uint32_t symbol_table_ofs = section_data_ofs + ((section_data_size + 3) & ~3); // align to 4 bytes
    tb_uint32_t string_table_size = 4; // initial 4-byte size field

    // calculate string table size
    tb_size_t start_len = tb_strlen(symbol_start);
    tb_size_t end_len = tb_strlen(symbol_end);
    if (start_len > 8) {
        string_table_size += (tb_uint32_t)(start_len + 1);
    }
    if (end_len > 8) {
        string_table_size += (tb_uint32_t)(end_len + 1);
    }

    // write COFF header
    xm_coff_header_t header;
    tb_memset(&header, 0, sizeof(header));
    header.machine = xm_utils_bin2coff_get_machine(arch);
    header.nsects = 1;
    header.time = 0;
    header.symtabofs = symbol_table_ofs;
    header.nsyms = 4; // .rdata section symbol (1) + auxiliary entry (1) + 2 data symbols (start, end)
    header.opthdr = 0;
    header.flags = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&header, sizeof(header))) {
        return tb_false;
    }

    // write section header (.rdata)
    xm_coff_section_t section;
    tb_memset(&section, 0, sizeof(section));
    tb_strncpy(section.name, ".rdata", 8);
    section.vsize = datasize;
    section.vaddr = 0;
    section.size = datasize;
    section.ofs = section_data_ofs;
    section.relocofs = 0;
    section.linenoofs = 0;
    section.nreloc = 0;
    section.nlineno = 0;
    section.flags = XM_COFF_SECTION_RDATA;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&section, sizeof(section))) {
        return tb_false;
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

    // align to 4 bytes
    tb_uint32_t padding = (4 - (section_data_size & 3)) & 3;
    if (padding > 0) {
        xm_utils_bin2coff_write_padding(ostream, padding);
    }

    // write symbol table
    // symbol 0: .rdata section symbol
    xm_coff_symbol_t sym_section;
    tb_memset(&sym_section, 0, sizeof(sym_section));
    tb_strncpy(sym_section.n.shortname.name, ".rdata", 8);
    sym_section.value = 0;
    sym_section.sect = 1; // section index (1-based)
    sym_section.type = 0; // IMAGE_SYM_TYPE_NULL
    sym_section.scl = 3; // IMAGE_SYM_CLASS_STATIC
    sym_section.naux = 1; // auxiliary entry
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_section, sizeof(sym_section))) {
        return tb_false;
    }
    // auxiliary entry for section (18 bytes total)
    // format: 4 bytes size, 2 bytes nreloc, 2 bytes nlineno, 10 bytes unused
    tb_uint32_t aux_section_size = datasize;
    tb_uint16_t aux_section_nreloc = 0;
    tb_uint16_t aux_section_nlineno = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&aux_section_size, 4) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&aux_section_nreloc, 2) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&aux_section_nlineno, 2)) {
        return tb_false;
    }
    xm_utils_bin2coff_write_padding(ostream, 10); // rest of auxiliary entry (unused)

    // symbol 1: _binary_xxx_start
    tb_uint32_t strtab_offset = 4; // start after size field
    xm_utils_bin2coff_write_symbol_name(ostream, symbol_start, &strtab_offset);
    tb_uint32_t sym_start_value = 0;
    tb_int16_t sym_start_sect = 1;
    tb_uint16_t sym_start_type = 0;
    tb_uint8_t sym_start_scl = 2; // IMAGE_SYM_CLASS_EXTERNAL
    tb_uint8_t sym_start_naux = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_start_value, 4) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_start_sect, 2) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_start_type, 2) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_start_scl, 1) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_start_naux, 1)) {
        return tb_false;
    }

    // symbol 2: _binary_xxx_end
    xm_utils_bin2coff_write_symbol_name(ostream, symbol_end, &strtab_offset);
    tb_uint32_t sym_end_value = datasize;
    tb_int16_t sym_end_sect = 1;
    tb_uint16_t sym_end_type = 0;
    tb_uint8_t sym_end_scl = 2;
    tb_uint8_t sym_end_naux = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_end_value, 4) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_end_sect, 2) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_end_type, 2) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_end_scl, 1) ||
        !tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_end_naux, 1)) {
        return tb_false;
    }

    // write string table
    tb_stream_bwrit(ostream, (tb_byte_t const *)&string_table_size, 4);
    if (tb_strlen(symbol_start) > 8) {
        xm_utils_bin2coff_write_string(ostream, symbol_start, 0);
        tb_byte_t null = 0;
        tb_stream_bwrit(ostream, &null, 1);
    }
    if (tb_strlen(symbol_end) > 8) {
        xm_utils_bin2coff_write_string(ostream, symbol_end, 0);
        tb_byte_t null = 0;
        tb_stream_bwrit(ostream, &null, 1);
    }

    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* generate COFF object file from binary file
 *
 * local ok, errors = utils.bin2coff(binaryfile, outputfile, symbol_prefix, arch, basename)
 */
tb_int_t xm_utils_bin2coff(lua_State *lua) {
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

    // do dump
    tb_bool_t ok = tb_false;
    tb_stream_ref_t istream = tb_stream_init_from_file(binaryfile, TB_FILE_MODE_RO);
    tb_stream_ref_t ostream = tb_stream_init_from_file(outputfile,
                                                       TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
    do {
        if (!tb_stream_open(istream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2coff: open %s failed", binaryfile);
            break;
        }

        if (!tb_stream_open(ostream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2coff: open %s failed", outputfile);
            break;
        }

        if (!xm_utils_bin2coff_dump(istream, ostream, symbol_prefix, arch, basename)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2coff: dump data failed");
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

