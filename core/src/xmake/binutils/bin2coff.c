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
#include "tbox/prefix/packed.h"
typedef struct __xm_coff_header_t {
    tb_uint16_t machine;
    tb_uint16_t nsects;
    tb_uint32_t time;
    tb_uint32_t symtabofs;
    tb_uint32_t nsyms;
    tb_uint16_t opthdr;
    tb_uint16_t flags;
} __tb_packed__ xm_coff_header_t;

typedef struct __xm_coff_section_t {
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
} __tb_packed__ xm_coff_section_t;

typedef struct __xm_coff_symbol_t {
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
} __tb_packed__ xm_coff_symbol_t;

typedef struct __xm_coff_aux_section_t {
    tb_uint32_t length;
    tb_uint16_t nreloc;
    tb_uint16_t nlineno;
    tb_uint8_t reserved[10];
} __tb_packed__ xm_coff_aux_section_t;

typedef struct __xm_coff_symbol_tail_t {
    tb_uint32_t value;
    tb_int16_t  sect;
    tb_uint16_t type;
    tb_uint8_t  scl;
    tb_uint8_t  naux;
} __tb_packed__ xm_coff_symbol_tail_t;
#include "tbox/prefix/packed.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_uint16_t xm_binutils_bin2coff_get_machine(tb_char_t const *arch) {
    if (!arch) {
        return XM_COFF_MACHINE_I386;
    }
    if (tb_strcmp(arch, "x86_64") == 0 || tb_strcmp(arch, "x64") == 0) {
        return XM_COFF_MACHINE_AMD64;
    } else if (tb_strcmp(arch, "arm64") == 0 || tb_strcmp(arch, "aarch64") == 0) {
        return XM_COFF_MACHINE_ARM64;
    } else if (tb_strcmp(arch, "arm") == 0) {
        return XM_COFF_MACHINE_ARM;
    } else if (tb_strcmp(arch, "i386") == 0 || tb_strcmp(arch, "x86") == 0) {
        return XM_COFF_MACHINE_I386;
    }
    return XM_COFF_MACHINE_I386;
}

static tb_void_t xm_binutils_bin2coff_write_string(tb_stream_ref_t ostream, tb_char_t const *str, tb_size_t len) {
    tb_assert_and_check_return(ostream && str);
    if (len == 0) {
        len = tb_strlen(str);
    }
    tb_stream_bwrit(ostream, (tb_byte_t const *)str, len);
}

static tb_void_t xm_binutils_bin2coff_write_padding(tb_stream_ref_t ostream, tb_size_t count) {
    tb_assert_and_check_return(ostream);
    tb_byte_t zero = 0;
    while (count-- > 0) {
        tb_stream_bwrit(ostream, &zero, 1);
    }
}

static tb_void_t xm_binutils_bin2coff_write_symbol_name(tb_stream_ref_t ostream, tb_char_t const *name, tb_uint32_t *strtab_offset) {
    tb_assert_and_check_return(ostream && name && strtab_offset);
    tb_size_t len = tb_strlen(name);
    if (len <= 8) {
        // short name: store directly in symbol name field
        xm_binutils_bin2coff_write_string(ostream, name, len);
        if (len < 8) {
            xm_binutils_bin2coff_write_padding(ostream, 8 - len);
        }
    } else {
        // long name: store offset in string table
        tb_uint32_t zeros = 0;
        tb_stream_bwrit(ostream, (tb_byte_t const *)&zeros, 4);
        tb_stream_bwrit(ostream, (tb_byte_t const *)strtab_offset, 4);
        *strtab_offset += (tb_uint32_t)(len + 1); // +1 for null terminator
    }
}

static tb_bool_t xm_binutils_bin2coff_dump(tb_stream_ref_t istream,
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

    // determine architecture for symbol prefix adjustment
    tb_uint16_t machine = xm_binutils_bin2coff_get_machine(arch);
    tb_bool_t is_i386 = (machine == XM_COFF_MACHINE_I386);

    // generate symbol names from filename
    tb_char_t symbol_name[256] = {0};
    tb_char_t symbol_start[256] = {0};
    tb_char_t symbol_end[256] = {0};

    // use basename or default to "data"
    if (!basename || !basename[0]) {
        basename = "data";
    }

    // build symbol name
    // note: on i386 Windows, C compiler automatically adds an underscore prefix to external symbols
    // so if we use "_binary_", the actual symbol becomes "__binary_" after compilation
    // to match, we need to ensure the prefix has two underscores for i386
    if (symbol_prefix) {
        if (is_i386 && symbol_prefix[0] == '_' && symbol_prefix[1] != '_') {
            // i386: if prefix starts with single underscore, add another one
            tb_snprintf(symbol_name, sizeof(symbol_name), "_%s%s", symbol_prefix, basename);
        } else {
            tb_snprintf(symbol_name, sizeof(symbol_name), "%s%s", symbol_prefix, basename);
        }
    } else {
        if (is_i386) {
            tb_snprintf(symbol_name, sizeof(symbol_name), "__binary_%s", basename);
        } else {
            tb_snprintf(symbol_name, sizeof(symbol_name), "_binary_%s", basename);
        }
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
    tb_uint32_t section_data_padding = (4 - (section_data_size & 3)) & 3;
    tb_uint32_t symbol_table_ofs = section_data_ofs + section_data_size + section_data_padding;
    
    // calculate string table size (content only, excluding the 4-byte size field)
    tb_uint32_t string_table_content_size = 0;
    tb_size_t start_len = tb_strlen(symbol_start);
    tb_size_t end_len = tb_strlen(symbol_end);
    if (start_len > 8) {
        string_table_content_size += (tb_uint32_t)(start_len + 1);
    }
    if (end_len > 8) {
        string_table_content_size += (tb_uint32_t)(end_len + 1);
    }
    // string table size field should include the size field itself
    tb_uint32_t string_table_size = 4 + string_table_content_size;

    // write COFF header
    xm_coff_header_t header;
    tb_memset(&header, 0, sizeof(header));
    header.machine = machine;
    header.nsects = 1;
    header.time = 0;
    header.symtabofs = symbol_table_ofs;
    // note: COFF spec says nsyms is the number of symbol table entries (including aux entries)
    // section symbol (1) + aux entry (1) + start symbol (1) + end symbol (1) = 4 entries
    // total size: 4 * 18 = 72 bytes
    // i386 linker calculates string table as symtabofs + nsyms * 18 = symtabofs + 72 (correct)
    // when reading symbols, linker follows naux fields to skip aux entries correctly
    // from mingw i386 analysis: section symbols MUST have aux entry (naux=1)
    header.nsyms = 4; // 3 symbols + 1 aux entry
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
    if (section_data_padding > 0) {
        xm_binutils_bin2coff_write_padding(ostream, section_data_padding);
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
    // section symbol MUST have auxiliary entry for i386 compatibility (as seen in mingw-generated files)
    sym_section.naux = 1; // auxiliary entry (required for i386)
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_section, sizeof(sym_section))) {
        return tb_false;
    }
    // auxiliary entry for section (18 bytes total)
    xm_coff_aux_section_t aux_section;
    tb_memset(&aux_section, 0, sizeof(aux_section));
    aux_section.length = datasize;
    aux_section.nreloc = 0;
    aux_section.nlineno = 0;
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&aux_section, sizeof(aux_section))) {
        return tb_false;
    }

    // symbol 1: _binary_xxx_start (or __binary_xxx_start for i386)
    tb_uint32_t strtab_offset = 4; // start after size field
    xm_binutils_bin2coff_write_symbol_name(ostream, symbol_start, &strtab_offset);
    xm_coff_symbol_tail_t sym_start_tail;
    tb_memset(&sym_start_tail, 0, sizeof(sym_start_tail));
    sym_start_tail.value = 0;
    sym_start_tail.sect = 1;
    sym_start_tail.type = 0; // IMAGE_SYM_TYPE_NULL
    sym_start_tail.scl = 2; // IMAGE_SYM_CLASS_EXTERNAL
    sym_start_tail.naux = 0; // no auxiliary entry
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_start_tail, sizeof(sym_start_tail))) {
        return tb_false;
    }

    // symbol 2: _binary_xxx_end (or __binary_xxx_end for i386)
    xm_binutils_bin2coff_write_symbol_name(ostream, symbol_end, &strtab_offset);
    xm_coff_symbol_tail_t sym_end_tail;
    tb_memset(&sym_end_tail, 0, sizeof(sym_end_tail));
    sym_end_tail.value = datasize;
    sym_end_tail.sect = 1;
    sym_end_tail.type = 0; // IMAGE_SYM_TYPE_NULL
    sym_end_tail.scl = 2; // IMAGE_SYM_CLASS_EXTERNAL
    sym_end_tail.naux = 0; // no auxiliary entry
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&sym_end_tail, sizeof(sym_end_tail))) {
        return tb_false;
    }

    // write string table
    // symbol table size: section symbol (18) + aux entry (18) + start symbol (18) + end symbol (18) = 72 bytes
    // string table starts at symtabofs + 72, which matches nsyms * 18 = 4 * 18 = 72
    if (!tb_stream_bwrit(ostream, (tb_byte_t const *)&string_table_size, 4)) {
        return tb_false;
    }
    if (start_len > 8) {
        xm_binutils_bin2coff_write_string(ostream, symbol_start, start_len);
        tb_byte_t null = 0;
        tb_stream_bwrit(ostream, &null, 1);
    }
    if (end_len > 8) {
        xm_binutils_bin2coff_write_string(ostream, symbol_end, end_len);
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
 * @param lua the lua state
 * @return 1 on success, 2 on failure (with error message on stack)
 */
tb_int_t xm_binutils_bin2coff(lua_State *lua) {
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
            lua_pushfstring(lua, "bin2coff: open %s failed", binaryfile);
            break;
        }

        if (!tb_stream_open(ostream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "bin2coff: open %s failed", outputfile);
            break;
        }

        if (!xm_binutils_bin2coff_dump(istream, ostream, symbol_prefix, arch, basename, zeroend)) {
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

