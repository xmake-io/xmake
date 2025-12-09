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
#ifndef XM_BINUTILS_COFF_PREFIX_H
#define XM_BINUTILS_COFF_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define XM_COFF_MACHINE_I386    0x014c
#define XM_COFF_MACHINE_AMD64   0x8664
#define XM_COFF_MACHINE_ARM     0x01c0
#define XM_COFF_MACHINE_ARM64   0xaa64

// COFF section flags
#define XM_COFF_SCN_CNT_CODE                0x20  // IMAGE_SCN_CNT_CODE
#define XM_COFF_SCN_CNT_INITIALIZED_DATA     0x40  // IMAGE_SCN_CNT_INITIALIZED_DATA
#define XM_COFF_SCN_CNT_UNINITIALIZED_DATA   0x80  // IMAGE_SCN_CNT_UNINITIALIZED_DATA

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
 * inline implementation
 */

/* get machine type from architecture string
 *
 * @param arch    the architecture string (e.g., "x86_64", "i386", "arm64")
 * @return        the machine type
 */
static __tb_inline__ tb_uint16_t xm_binutils_coff_get_machine(tb_char_t const *arch) {
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

/* write string to stream
 *
 * @param ostream the output stream
 * @param str     the string to write
 * @param len     the length (0 for auto-detect)
 */
static __tb_inline__ tb_void_t xm_binutils_coff_write_string(tb_stream_ref_t ostream, tb_char_t const *str, tb_size_t len) {
    tb_assert_and_check_return(ostream && str);
    if (len == 0) {
        len = tb_strlen(str);
    }
    tb_stream_bwrit(ostream, (tb_byte_t const *)str, len);
}

/* write padding bytes to stream
 *
 * @param ostream the output stream
 * @param count   the number of padding bytes
 */
static __tb_inline__ tb_void_t xm_binutils_coff_write_padding(tb_stream_ref_t ostream, tb_size_t count) {
    tb_assert_and_check_return(ostream);
    tb_byte_t zero = 0;
    while (count-- > 0) {
        tb_stream_bwrit(ostream, &zero, 1);
    }
}

/* write symbol name to stream (handles short and long names)
 *
 * @param ostream       the output stream
 * @param name          the symbol name
 * @param strtab_offset the string table offset (updated if long name)
 */
static __tb_inline__ tb_void_t xm_binutils_coff_write_symbol_name(tb_stream_ref_t ostream, tb_char_t const *name, tb_uint32_t *strtab_offset) {
    tb_assert_and_check_return(ostream && name && strtab_offset);
    tb_size_t len = tb_strlen(name);
    if (len <= 8) {
        // short name: store directly in symbol name field
        xm_binutils_coff_write_string(ostream, name, len);
        if (len < 8) {
            xm_binutils_coff_write_padding(ostream, 8 - len);
        }
    } else {
        // long name: store offset in string table
        tb_uint32_t zeros = 0;
        tb_stream_bwrit(ostream, (tb_byte_t const *)&zeros, 4);
        tb_stream_bwrit(ostream, (tb_byte_t const *)strtab_offset, 4);
        *strtab_offset += (tb_uint32_t)(len + 1); // +1 for null terminator
    }
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * readsyms inline implementation
 */

/* read string from COFF string table
 *
 * @param istream       the input stream
 * @param strtab_offset the string table offset (including 4-byte size field)
 * @param offset        the string offset (from start of string table content, after size field)
 * @return              the string (static buffer, valid until next call)
 */
static __tb_inline__ tb_bool_t xm_binutils_coff_read_string(tb_stream_ref_t istream, tb_uint32_t strtab_offset, tb_uint32_t offset, tb_char_t *name, tb_size_t name_size) {
    tb_assert_and_check_return_val(istream && name && name_size > 0, tb_false);

    // In COFF format, the offset in symbol table is from the start of string table
    // (including the 4-byte size field). So offset=4 points to the first string after
    // the size field, offset=74 points to a string at position 74 from the start.

    // read string table size first to validate offset
    tb_uint32_t strtab_size = 0;
    tb_hize_t saved_pos = tb_stream_offset(istream);
    if (!tb_stream_seek(istream, strtab_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&strtab_size, 4)) {
        tb_stream_seek(istream, saved_pos);
        return tb_false;
    }

    // check offset (must be >= 4 to skip the size field, and < strtab_size)
    if (offset < 4 || offset >= strtab_size) {
        tb_stream_seek(istream, saved_pos);
        return tb_false;
    }

    // seek to string position (offset is from start of string table, including size field)
    // strtab_offset points to the start of string table (including 4-byte size field)
    // offset is from the start of string table (including size field)
    // So we use strtab_offset + offset directly
    if (!tb_stream_seek(istream, strtab_offset + offset)) {
        tb_stream_seek(istream, saved_pos);
        return tb_false;
    }

    // read string
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

    // restore position
    tb_stream_seek(istream, saved_pos);
    return tb_true;
}

/* get symbol name from COFF symbol entry
 *
 * @param istream       the input stream
 * @param sym           the symbol entry
 * @param strtab_offset the string table offset
 * @param name          the buffer to store the symbol name
 * @param name_size     the size of the buffer
 * @return              tb_true on success, tb_false on failure
 */
static __tb_inline__ tb_bool_t xm_binutils_coff_get_symbol_name(tb_stream_ref_t istream, xm_coff_symbol_t const *sym, tb_uint32_t strtab_offset, tb_char_t *name, tb_size_t name_size) {
    tb_assert_and_check_return_val(istream && sym && name && name_size > 0, tb_false);

    // check if it's a long name (first 4 bytes are zeros)
    if (sym->n.longname.zeros == 0) {
        // long name: read from string table
        return xm_binutils_coff_read_string(istream, strtab_offset, sym->n.longname.offset, name, name_size);
    } else {
        // short name: use directly
        tb_size_t len = tb_min(8, name_size - 1);
        tb_strncpy(name, sym->n.shortname.name, len);
        name[len] = '\0';
        // trim trailing nulls
        while (len > 0 && name[len - 1] == '\0') {
            len--;
        }
        name[len] = '\0';
        return tb_true;
    }
}

/* get symbol type character (nm-style) from COFF symbol
 *
 * @param scl      the storage class
 * @param sect     the section number (0 = undefined, 1-based)
 * @param sections the section headers array
 * @param nsects   the number of sections
 * @return         the type character (T/t/D/d/B/b/U)
 */
static __tb_inline__ tb_char_t xm_binutils_coff_get_symbol_type_char(tb_uint8_t scl, tb_int16_t sect, xm_coff_section_t const *sections, tb_uint16_t nsects) {
    // undefined symbol
    if (sect == 0) {
        return 'U';
    }

    // check if external
    tb_bool_t is_external = (scl == 2); // IMAGE_SYM_CLASS_EXTERNAL

    // check section flags to determine type
    if (sections && sect > 0 && sect <= nsects) {
        tb_uint32_t flags = sections[sect - 1].flags; // section numbers are 1-based
        // IMAGE_SCN_CNT_CODE (0x20) - code section
        if (flags & XM_COFF_SCN_CNT_CODE) {
            return is_external ? 'T' : 't';  // text section
        }
        // IMAGE_SCN_CNT_UNINITIALIZED_DATA (0x80) - bss section
        if (flags & XM_COFF_SCN_CNT_UNINITIALIZED_DATA) {
            return is_external ? 'B' : 'b';  // bss section
        }
        // IMAGE_SCN_CNT_INITIALIZED_DATA (0x40) - data section
        if (flags & XM_COFF_SCN_CNT_INITIALIZED_DATA) {
            return is_external ? 'D' : 'd';  // data section
        }
    }

    // fallback: use section number heuristic
    if (sect == 1) {
        return is_external ? 'T' : 't';  // text section
    } else if (sect == 2) {
        return is_external ? 'D' : 'd';  // data section
    } else if (sect == 3) {
        return is_external ? 'B' : 'b';  // bss section
    }

    return is_external ? 'S' : 's';  // other section
}

#endif

