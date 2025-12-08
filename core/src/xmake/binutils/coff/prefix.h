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

#endif

