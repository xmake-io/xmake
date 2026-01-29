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

// COFF machine types (for format detection)
#define XM_BINUTILS_COFF_MACHINE_I386    0x014c
#define XM_BINUTILS_COFF_MACHINE_AMD64   0x8664
#define XM_BINUTILS_COFF_MACHINE_ARM     0x01c0
#define XM_BINUTILS_COFF_MACHINE_ARM64   0xaa64

// PE/DOS offsets/signatures (for format detection)
#define XM_BINUTILS_PE_DOS_STUB_MIN_SIZE  (0x40)
#define XM_BINUTILS_PE_DOS_ELFANEW_OFFSET (0x3c)
#define XM_BINUTILS_PE_NT_SIGNATURE       (0x00004550) // "PE\0\0" little endian

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

/* check if it's a PE file from the beginning of stream
 *
 * @note the stream offset will be preserved by this function
 */
static __tb_inline__ tb_bool_t xm_binutils_detect_pe(tb_stream_ref_t istream, tb_byte_t* first8) {
    tb_assert_and_check_return_val(istream && first8, tb_false);

    // check PE/DOS magic ("MZ" or "ZM") and verify NT signature
    if (!((first8[0] == 'M' && first8[1] == 'Z') || (first8[0] == 'Z' && first8[1] == 'M'))) {
        return tb_false;
    }

    tb_bool_t ok = tb_false;
    do {
        tb_hong_t size = tb_stream_size(istream);
        if (size > 0 && size < XM_BINUTILS_PE_DOS_STUB_MIN_SIZE + 4) {
            break;
        }

        tb_size_t max_peek = 4096;
        if (size > 0) {
            max_peek = (tb_size_t)tb_min((tb_hize_t)max_peek, (tb_hize_t)size);
        }

        tb_byte_t* p = tb_null;
        if (!tb_stream_peek(istream, &p, max_peek)) {
            break;
        }

        tb_uint32_t e_lfanew = (tb_uint32_t)(  (tb_uint32_t)p[XM_BINUTILS_PE_DOS_ELFANEW_OFFSET]
                                            | ((tb_uint32_t)p[XM_BINUTILS_PE_DOS_ELFANEW_OFFSET + 1] << 8)
                                            | ((tb_uint32_t)p[XM_BINUTILS_PE_DOS_ELFANEW_OFFSET + 2] << 16)
                                            | ((tb_uint32_t)p[XM_BINUTILS_PE_DOS_ELFANEW_OFFSET + 3] << 24));
        tb_check_break(e_lfanew >= XM_BINUTILS_PE_DOS_STUB_MIN_SIZE);
        tb_check_break((tb_size_t)e_lfanew + 4 <= max_peek);
        tb_check_break(size <= 0 || (tb_hize_t)e_lfanew + 4 <= (tb_hize_t)size);

        tb_byte_t const* signature = p + (tb_size_t)e_lfanew;
        ok = (signature[0] == 'P' && signature[1] == 'E' && signature[2] == 0 && signature[3] == 0);
    } while (0);

    return ok;
}

/* detect object file format from stream
 *
 * @param istream the input stream
 * @return        XM_BINUTILS_FORMAT_COFF, XM_BINUTILS_FORMAT_ELF, XM_BINUTILS_FORMAT_MACHO,
 *                 XM_BINUTILS_FORMAT_AR, XM_BINUTILS_FORMAT_PE, XM_BINUTILS_FORMAT_UNKNOWN, or -1 on error
 */
static __tb_inline__ tb_int_t xm_binutils_detect_format(tb_stream_ref_t istream) {
    tb_assert_and_check_return_val(istream, -1);
    tb_assert_and_check_return_val(tb_stream_offset(istream) == 0, -1);

    tb_int_t  format    = -1;
    do {
        // peek first 8 bytes
        tb_byte_t* p = tb_null;
        if (!tb_stream_peek(istream, &p, 8)) {
            tb_hong_t size = tb_stream_size(istream);
            if (size > 0 && size < 8) {
                format = XM_BINUTILS_FORMAT_UNKNOWN;
            }
            break;
        }

        // check AR archive format first (!<arch>\n)
        if (p[0] == '!' && p[1] == '<' && p[2] == 'a' &&
            p[3] == 'r' && p[4] == 'c' && p[5] == 'h' &&
            (p[6] == '>' || p[6] == '\n') &&
            (p[7] == '\n' || p[7] == '\r')) {
            format = XM_BINUTILS_FORMAT_AR;
            break;
        }

        if (xm_binutils_detect_pe(istream, p)) {
            format = XM_BINUTILS_FORMAT_PE;
            break;
        }

        // check ELF magic (0x7f 'E' 'L' 'F')
        if (p[0] == 0x7f && p[1] == 'E' && p[2] == 'L' && p[3] == 'F') {
            format = XM_BINUTILS_FORMAT_ELF;
            break;
        }

        // check Mach-O magic
        if (p[0] == 0xfe && p[1] == 0xed && p[2] == 0xfa &&
            (p[3] == 0xce || p[3] == 0xcf)) {
            format = XM_BINUTILS_FORMAT_MACHO; // Mach-O 32/64 (big endian)
            break;
        }
        if (p[0] == 0xce && p[1] == 0xfa && p[2] == 0xed && p[3] == 0xfe) {
            format = XM_BINUTILS_FORMAT_MACHO; // Mach-O 32 (little endian)
            break;
        }
        if (p[0] == 0xcf && p[1] == 0xfa && p[2] == 0xed && p[3] == 0xfe) {
            format = XM_BINUTILS_FORMAT_MACHO; // Mach-O 64 (little endian)
            break;
        }

        // check COFF (object files start with machine type, not a magic number)
        // COFF header: machine (2 bytes) + nsects (2 bytes) + time (4 bytes) + ...
        tb_uint16_t machine = (tb_uint16_t)((p[1] << 8) | p[0]);

        // Import header: 0x0000 0xffff
        if (machine == 0x0000) {
            tb_uint16_t machine2 = (tb_uint16_t)((p[3] << 8) | p[2]);
            if (machine2 == 0xffff) {
                format = XM_BINUTILS_FORMAT_COFF;
                break;
            }
        }

        if (machine == XM_BINUTILS_COFF_MACHINE_I386 ||
            machine == XM_BINUTILS_COFF_MACHINE_AMD64 ||
            machine == XM_BINUTILS_COFF_MACHINE_ARM ||
            machine == XM_BINUTILS_COFF_MACHINE_ARM64) {
            format = XM_BINUTILS_FORMAT_COFF;
            break;
        }

        // unknown format
        format = XM_BINUTILS_FORMAT_UNKNOWN;

    } while (0);

    return format;
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
