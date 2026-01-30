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
 * @file        format.c
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "format"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_binutils_format_is_pe(tb_stream_ref_t istream, tb_byte_t* first8) {
    tb_assert_and_check_return_val(istream && first8, tb_false);
    tb_bool_t ok = tb_false;
    do {
        tb_check_break((first8[0] == 'M' && first8[1] == 'Z') || (first8[0] == 'Z' && first8[1] == 'M'));

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

static __tb_inline__ tb_bool_t xm_binutils_format_is_ar(tb_byte_t const* first8) {
    return first8[0] == '!' && first8[1] == '<' && first8[2] == 'a' &&
           first8[3] == 'r' && first8[4] == 'c' && first8[5] == 'h' &&
           (first8[6] == '>' || first8[6] == '\n') &&
           (first8[7] == '\n' || first8[7] == '\r');
}

static __tb_inline__ tb_bool_t xm_binutils_format_is_elf(tb_byte_t const* first8) {
    return first8[0] == 0x7f && first8[1] == 'E' && first8[2] == 'L' && first8[3] == 'F';
}

static __tb_inline__ tb_bool_t xm_binutils_format_is_macho(tb_byte_t const* first8) {
    return (first8[0] == 0xfe && first8[1] == 0xed && first8[2] == 0xfa && (first8[3] == 0xce || first8[3] == 0xcf)) ||
           (first8[0] == 0xce && first8[1] == 0xfa && first8[2] == 0xed && first8[3] == 0xfe) ||
           (first8[0] == 0xcf && first8[1] == 0xfa && first8[2] == 0xed && first8[3] == 0xfe);
}

static __tb_inline__ tb_bool_t xm_binutils_format_is_coff(tb_byte_t const* first8) {
    tb_uint16_t machine = (tb_uint16_t)((first8[1] << 8) | first8[0]);
    if (machine == 0x0000) {
        tb_uint16_t machine2 = (tb_uint16_t)((first8[3] << 8) | first8[2]);
        if (machine2 == 0xffff) {
            return tb_true;
        }
    }

    return machine == XM_BINUTILS_COFF_MACHINE_I386 ||
           machine == XM_BINUTILS_COFF_MACHINE_AMD64 ||
           machine == XM_BINUTILS_COFF_MACHINE_ARM ||
           machine == XM_BINUTILS_COFF_MACHINE_ARM64;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* detect object file format from stream
 *
 * @param istream the input stream
 * @return        XM_BINUTILS_FORMAT_COFF, XM_BINUTILS_FORMAT_ELF, XM_BINUTILS_FORMAT_MACHO,
 *                 XM_BINUTILS_FORMAT_AR, XM_BINUTILS_FORMAT_PE, XM_BINUTILS_FORMAT_UNKNOWN, or -1 on error
 */
tb_int_t xm_binutils_format_detect(tb_stream_ref_t istream) {
    tb_assert_and_check_return_val(istream, -1);
    tb_assert_and_check_return_val(tb_stream_offset(istream) == 0, -1);

    tb_int_t format = -1;
    do {
        tb_byte_t* p = tb_null;
        if (!tb_stream_peek(istream, &p, 8)) {
            tb_hong_t size = tb_stream_size(istream);
            if (size > 0 && size < 8) {
                format = XM_BINUTILS_FORMAT_UNKNOWN;
            }
            break;
        }

        if (xm_binutils_format_is_ar(p)) {
            format = XM_BINUTILS_FORMAT_AR;
            break;
        }

        if (xm_binutils_format_is_elf(p)) {
            format = XM_BINUTILS_FORMAT_ELF;
            break;
        }

        if (xm_binutils_format_is_macho(p)) {
            format = XM_BINUTILS_FORMAT_MACHO;
            break;
        }

        if (xm_binutils_format_is_pe(istream, p)) {
            format = XM_BINUTILS_FORMAT_PE;
            break;
        }

        if (xm_binutils_format_is_coff(p)) {
            format = XM_BINUTILS_FORMAT_COFF;
            break;
        }

        format = XM_BINUTILS_FORMAT_UNKNOWN;

    } while (0);

    return format;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * lua implementation
 */

/* get binary file format (auto-detect format)
 *
 * local format, errors = binutils.format(filepath)
 */
tb_int_t xm_binutils_format(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get the binary file path
    tb_char_t const *binaryfile = luaL_checkstring(lua, 1);
    tb_check_return_val(binaryfile, 0);

    // open file
    tb_stream_ref_t istream = tb_stream_init_from_file(binaryfile, TB_FILE_MODE_RO);
    if (!istream) {
        lua_pushnil(lua);
        lua_pushfstring(lua, "format: open %s failed", binaryfile);
        return 2;
    }

    tb_bool_t ok = tb_false;
    do {
        if (!tb_stream_open(istream)) {
            lua_pushnil(lua);
            lua_pushfstring(lua, "format: open %s failed", binaryfile);
            break;
        }

        tb_int_t format = xm_binutils_format_detect(istream);
        if (format < 0) {
            lua_pushnil(lua);
            lua_pushliteral(lua, "format: cannot detect file format");
            break;
        }

        switch (format) {
        case XM_BINUTILS_FORMAT_COFF:  lua_pushliteral(lua, "coff"); break;
        case XM_BINUTILS_FORMAT_ELF:   lua_pushliteral(lua, "elf"); break;
        case XM_BINUTILS_FORMAT_MACHO: lua_pushliteral(lua, "macho"); break;
        case XM_BINUTILS_FORMAT_AR:    lua_pushliteral(lua, "ar"); break;
        case XM_BINUTILS_FORMAT_PE:    lua_pushliteral(lua, "pe"); break;
        default:                       lua_pushliteral(lua, "unknown"); break;
        }

        ok = tb_true;
    } while (0);

    if (istream) {
        tb_stream_exit(istream);
    }
    return ok ? 1 : 2;
}
