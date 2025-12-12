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
#ifndef XM_BINUTILS_PREFIX_H
#define XM_BINUTILS_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */
#define XM_BINUTILS_FORMAT_COFF    1
#define XM_BINUTILS_FORMAT_ELF     2
#define XM_BINUTILS_FORMAT_MACHO   3
#define XM_BINUTILS_FORMAT_AR      4
#define XM_BINUTILS_FORMAT_PE      5
#define XM_BINUTILS_FORMAT_UNKNOWN 0

/* COFF machine types (for format detection) */
#define XM_BINUTILS_COFF_MACHINE_I386    0x014c
#define XM_BINUTILS_COFF_MACHINE_AMD64   0x8664
#define XM_BINUTILS_COFF_MACHINE_ARM     0x01c0
#define XM_BINUTILS_COFF_MACHINE_ARM64   0xaa64

/* //////////////////////////////////////////////////////////////////////////////////////
 * inline implementation
 */

/* read magic bytes from stream (preserves stream position)
 *
 * @param istream    the input stream
 * @param magic      the buffer to store magic bytes (must be at least 4 bytes)
 * @param size       the number of bytes to read (typically 4)
 *
 * @return           tb_true on success, tb_false on failure
 */
static __tb_inline__ tb_bool_t xm_binutils_read_magic(tb_stream_ref_t istream, tb_uint8_t *magic, tb_size_t size) {
    tb_assert_and_check_return_val(istream && magic && size > 0, tb_false);

    tb_hize_t saved_pos = tb_stream_offset(istream);
    if (!tb_stream_seek(istream, 0)) {
        return tb_false;
    }

    tb_bool_t ok = tb_false;
    if (tb_stream_bread(istream, magic, size)) {
        ok = tb_true;
    }

    tb_stream_seek(istream, saved_pos);
    return ok;
}

/* detect object file format from stream
 *
 * @param istream the input stream
 * @return        XM_BINUTILS_FORMAT_COFF, XM_BINUTILS_FORMAT_ELF, XM_BINUTILS_FORMAT_MACHO,
 *                 XM_BINUTILS_FORMAT_AR, XM_BINUTILS_FORMAT_UNKNOWN, or -1 on error
 */
static __tb_inline__ tb_int_t xm_binutils_detect_format(tb_stream_ref_t istream) {
    tb_assert_and_check_return_val(istream, -1);

    // peek first 8 bytes
    tb_byte_t* p = tb_null;
    if (!tb_stream_peek(istream, &p, 8)) {
        return -1;
    }

    // check AR archive format first (!<arch>\n)
    if (p[0] == '!' && p[1] == '<' && p[2] == 'a' &&
        p[3] == 'r' && p[4] == 'c' && p[5] == 'h' &&
        (p[6] == '>' || p[6] == '\n') &&
        (p[7] == '\n' || p[7] == '\r')) {
        return XM_BINUTILS_FORMAT_AR;
    }

    // check PE/DOS magic (0x5A4D 'M' 'Z')
    if (p[0] == 'M' && p[1] == 'Z') {
        return XM_BINUTILS_FORMAT_PE;
    }

    // check ELF magic (0x7f 'E' 'L' 'F')
    if (p[0] == 0x7f && p[1] == 'E' && p[2] == 'L' && p[3] == 'F') {
        return XM_BINUTILS_FORMAT_ELF;
    }

    // check Mach-O magic
    if (p[0] == 0xfe && p[1] == 0xed && p[2] == 0xfa &&
        (p[3] == 0xce || p[3] == 0xcf)) {
        return XM_BINUTILS_FORMAT_MACHO; // Mach-O 32/64 (big endian)
    }
    if (p[0] == 0xce && p[1] == 0xfa && p[2] == 0xed && p[3] == 0xfe) {
        return XM_BINUTILS_FORMAT_MACHO; // Mach-O 32 (little endian)
    }
    if (p[0] == 0xcf && p[1] == 0xfa && p[2] == 0xed && p[3] == 0xfe) {
        return XM_BINUTILS_FORMAT_MACHO; // Mach-O 64 (little endian)
    }

    // check COFF (object files start with machine type, not a magic number)
    // COFF header: machine (2 bytes) + nsects (2 bytes) + time (4 bytes) + ...
    // Read machine type to verify if it's a valid COFF file
    tb_uint16_t machine = (p[1] << 8) | p[0];

    // check if it's a valid COFF machine type
    // Import header: 0x0000 0xffff
    if (machine == 0x0000) {
        // read second word to check if it is import header
        tb_uint16_t machine2 = (p[3] << 8) | p[2];
        if (machine2 == 0xffff) {
             return XM_BINUTILS_FORMAT_COFF;
        }
    }

    if (machine == XM_BINUTILS_COFF_MACHINE_I386 ||
        machine == XM_BINUTILS_COFF_MACHINE_AMD64 ||
        machine == XM_BINUTILS_COFF_MACHINE_ARM ||
        machine == XM_BINUTILS_COFF_MACHINE_ARM64) {
        return XM_BINUTILS_FORMAT_COFF;
    }

    // unknown format
    return XM_BINUTILS_FORMAT_UNKNOWN;
}

/* copy data from input stream to output stream
 *
 * @param istream    the input stream
 * @param ostream    the output stream
 * @param size       the size to copy
 *
 * @return           tb_true on success, tb_false on failure
 */
static __tb_inline__ tb_bool_t xm_binutils_stream_copy(tb_stream_ref_t istream, tb_stream_ref_t ostream, tb_hize_t size) {
    tb_assert_and_check_return_val(istream && ostream, tb_false);
    if (size == 0) {
        return tb_true;
    }

    tb_byte_t data[TB_STREAM_BLOCK_MAXN];
    tb_hize_t writ = 0;
    do {
        tb_size_t need = (tb_size_t)tb_min(size - writ, (tb_hize_t)TB_STREAM_BLOCK_MAXN);
        tb_check_break(need);

        if (!tb_stream_bread(istream, data, need)) {
            return tb_false;
        }
        if (!tb_stream_bwrit(ostream, data, need)) {
            return tb_false;
        }
        writ += need;

        tb_check_break(writ < size);
    } while (1);

    return tb_true;
}

/* sanitize symbol name (replace non-alphanumeric characters with underscores)
 *
 * @param name       the symbol name
 */
static __tb_inline__ void xm_binutils_sanitize_symbol_name(tb_char_t* name) {
    tb_assert_and_check_return(name);
    for (tb_size_t i = 0; name[i]; i++) {
        if (!tb_isalpha(name[i]) && !tb_isdigit(name[i]) && name[i] != '_') {
            name[i] = '_';
        }
    }
}

/* read string from stream at specified offset
 *
 * @param istream    the input stream
 * @param offset     the offset to read from
 * @param name       the buffer to store the string
 * @param name_size  the size of the buffer
 *
 * @return           tb_true on success, tb_false on failure
 */
static __tb_inline__ tb_bool_t xm_binutils_read_string(tb_stream_ref_t istream, tb_hize_t offset, tb_char_t *name, tb_size_t name_size) {
    tb_assert_and_check_return_val(istream && name && name_size > 0, tb_false);

    tb_hize_t saved_pos = tb_stream_offset(istream);
    if (!tb_stream_seek(istream, offset)) {
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

/* check if architecture is 64-bit
 *
 * @param arch    the architecture string
 * @return        tb_true if 64-bit, tb_false otherwise
 */
static __tb_inline__ tb_bool_t xm_binutils_arch_is_64bit(tb_char_t const *arch) {
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


#endif

