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
#define XM_BINUTILS_FORMAT_COFF    0
#define XM_BINUTILS_FORMAT_ELF     1
#define XM_BINUTILS_FORMAT_MACHO   2
#define XM_BINUTILS_FORMAT_UNKNOWN 3

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
 *                 XM_BINUTILS_FORMAT_UNKNOWN, or -1 on error
 */
static __tb_inline__ tb_int_t xm_binutils_detect_format(tb_stream_ref_t istream) {
    tb_assert_and_check_return_val(istream, -1);
    
    // read magic bytes
    tb_uint8_t magic[4];
    if (!xm_binutils_read_magic(istream, magic, 4)) {
        return -1;
    }
    
    // check ELF magic (0x7f 'E' 'L' 'F')
    if (magic[0] == 0x7f && magic[1] == 'E' && magic[2] == 'L' && magic[3] == 'F') {
        return XM_BINUTILS_FORMAT_ELF;
    }
    
    // check Mach-O magic
    if (magic[0] == 0xfe && magic[1] == 0xed && magic[2] == 0xfa && 
        (magic[3] == 0xce || magic[3] == 0xcf)) {
        return XM_BINUTILS_FORMAT_MACHO; // Mach-O 32/64 (big endian)
    }
    if (magic[0] == 0xce && magic[1] == 0xfa && magic[2] == 0xed && magic[3] == 0xfe) {
        return XM_BINUTILS_FORMAT_MACHO; // Mach-O 32 (little endian)
    }
    if (magic[0] == 0xcf && magic[1] == 0xfa && magic[2] == 0xed && magic[3] == 0xfe) {
        return XM_BINUTILS_FORMAT_MACHO; // Mach-O 64 (little endian)
    }
    
    // check COFF (object files start with machine type, not a magic number)
    // COFF header: machine (2 bytes) + nsects (2 bytes) + time (4 bytes) + ...
    // Read machine type to verify if it's a valid COFF file
    tb_hize_t saved_pos = tb_stream_offset(istream);
    tb_uint16_t machine;
    if (!tb_stream_seek(istream, 0)) {
        return -1;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&machine, 2)) {
        tb_stream_seek(istream, saved_pos);
        return -1;
    }
    tb_stream_seek(istream, saved_pos);
    
    // check if it's a valid COFF machine type
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
    tb_assert_and_check_return_val(istream && ostream && size > 0, tb_false);

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

#endif

