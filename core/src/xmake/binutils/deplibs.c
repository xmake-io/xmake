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
 * @file        deplibs.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "deplibs"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "coff/prefix.h"
#include "elf/prefix.h"
#include "macho/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * forward declarations
 */
extern tb_bool_t xm_binutils_coff_deplibs(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_elf_deplibs(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_macho_deplibs(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* get dependent libraries from binary file (auto-detect format)
 *
 * @param lua the lua state
 * @return 1 on success (table on stack), 2 on failure (with error message on stack)
 */
tb_int_t xm_binutils_deplibs(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get the binary file path
    tb_char_t const *binaryfile = luaL_checkstring(lua, 1);
    tb_check_return_val(binaryfile, 0);

    // open file
    tb_stream_ref_t istream = tb_stream_init_from_file(binaryfile, TB_FILE_MODE_RO);
    if (!istream) {
        lua_pushboolean(lua, tb_false);
        lua_pushfstring(lua, "open %s failed", binaryfile);
        return 2;
    }

    tb_bool_t ok = tb_false;
    do {
        if (!tb_stream_open(istream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "open %s failed", binaryfile);
            break;
        }

        // detect format
        tb_int_t format = xm_binutils_format_detect(istream);
        if (format < 0) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "cannot detect file format");
            break;
        }

        // create result list
        lua_newtable(lua);

        // get dependents based on format
        if (format == XM_BINUTILS_FORMAT_COFF) {
            if (!xm_binutils_coff_deplibs(istream, 0, lua)) {
                 lua_pop(lua, 1); // pop table
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "failed to parse COFF");
                 break;
            }
        } else if (format == XM_BINUTILS_FORMAT_PE) {
            // seek to e_lfanew
            if (!tb_stream_seek(istream, 0x3c)) {
                 lua_pop(lua, 1); // pop table
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "failed to seek to e_lfanew");
                 break;
            }

            // read e_lfanew
            tb_uint32_t e_lfanew = 0;
            if (!tb_stream_bread(istream, (tb_byte_t*)&e_lfanew, 4)) {
                 lua_pop(lua, 1); // pop table
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "failed to read e_lfanew");
                 break;
            }

            // e_lfanew is little endian
            e_lfanew = tb_bits_le_to_ne_u32(e_lfanew);

            // call coff deplibs with offset = e_lfanew + 4 (skip PE signature)
            if (!xm_binutils_coff_deplibs(istream, e_lfanew + 4, lua)) {
                 lua_pop(lua, 1); // pop table
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "failed to parse PE/COFF");
                 break;
            }
        } else if (format == XM_BINUTILS_FORMAT_MACHO) {
            if (!xm_binutils_macho_deplibs(istream, 0, lua)) {
                 lua_pop(lua, 1); // pop table
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "failed to parse Mach-O");
                 break;
            }
        } else if (format == XM_BINUTILS_FORMAT_ELF) {
            if (!xm_binutils_elf_deplibs(istream, 0, lua)) {
                 lua_pop(lua, 1); // pop table
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "failed to parse ELF");
                 break;
            }
        } else if (format == XM_BINUTILS_FORMAT_WASM) {
        } else {
            lua_pop(lua, 1); // pop table
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "unsupported format %d", format);
            break;
        }

        ok = tb_true;

    } while (0);

    if (istream) {
        tb_stream_exit(istream);
    }
    return ok ? 1 : 2;
}
