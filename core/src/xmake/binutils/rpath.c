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
 * @file        rpath.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "rpath"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "elf/prefix.h"
#include "macho/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
tb_bool_t xm_binutils_elf_rpath_list(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
tb_bool_t xm_binutils_macho_rpath_list(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);



tb_bool_t xm_binutils_elf_rpath_clean(tb_stream_ref_t istream, tb_hize_t base_offset);
tb_bool_t xm_binutils_macho_rpath_clean(tb_stream_ref_t istream, tb_hize_t base_offset);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* get rpath list from binary file (auto-detect format)
 *
 * @param lua the lua state
 * @return 1 on success (table on stack), 2 on failure (with error message on stack)
 */
tb_int_t xm_binutils_rpath_list(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get the binary file path
    tb_char_t const *binaryfile = luaL_checkstring(lua, 1);
    tb_check_return_val(binaryfile, 0);

    // open file
    tb_stream_ref_t istream = tb_stream_init_from_file(binaryfile, TB_FILE_MODE_RO);
    if (!istream) {
        lua_pushboolean(lua, tb_false);
        lua_pushfstring(lua, "rpath_list: open %s failed", binaryfile);
        return 2;
    }

    tb_bool_t ok = tb_false;
    do {
        if (!tb_stream_open(istream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "rpath_list: open %s failed", binaryfile);
            break;
        }

        // detect format
        tb_int_t format = xm_binutils_detect_format(istream);
        if (format < 0) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "rpath_list: cannot detect file format");
            break;
        }

        // create result list
        lua_newtable(lua);

        // get rpath list based on format
        if (format == XM_BINUTILS_FORMAT_ELF) {
            if (!xm_binutils_elf_rpath_list(istream, 0, lua)) {
                 lua_pop(lua, 1); // pop table
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "rpath_list: failed to parse ELF");
                 break;
            }
        } else if (format == XM_BINUTILS_FORMAT_MACHO) {
            if (!xm_binutils_macho_rpath_list(istream, 0, lua)) {
                 lua_pop(lua, 1); // pop table
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "rpath_list: failed to parse Mach-O");
                 break;
            }
        } else {
            /* not supported or no rpath for this format
             * return empty table
             */
        }

        ok = tb_true;

    } while (0);

    if (istream) tb_stream_exit(istream);
    return ok ? 1 : 2;
}

/* clean all rpaths from binary file
 *
 * @param lua the lua state
 * @return 1 on success, 2 on failure
 */
tb_int_t xm_binutils_rpath_clean(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get arguments
    tb_char_t const *binaryfile = luaL_checkstring(lua, 1);
    tb_check_return_val(binaryfile, 0);

    // open file
    tb_stream_ref_t istream = tb_stream_init_from_file(binaryfile, TB_FILE_MODE_RW);
    if (!istream) {
        lua_pushboolean(lua, tb_false);
        lua_pushfstring(lua, "rpath_clean: open %s failed", binaryfile);
        return 2;
    }

    tb_bool_t ok = tb_false;
    do {
        if (!tb_stream_open(istream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "rpath_clean: open %s failed", binaryfile);
            break;
        }

        // detect format
        tb_int_t format = xm_binutils_detect_format(istream);
        if (format < 0) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "rpath_clean: cannot detect file format");
            break;
        }

        // clean rpath
        if (format == XM_BINUTILS_FORMAT_ELF) {
            if (!xm_binutils_elf_rpath_clean(istream, 0)) {
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "rpath_clean: failed to clean ELF");
                 break;
            }
        } else if (format == XM_BINUTILS_FORMAT_MACHO) {
            if (!xm_binutils_macho_rpath_clean(istream, 0)) {
                 lua_pushboolean(lua, tb_false);
                 lua_pushfstring(lua, "rpath_clean: failed to clean Mach-O");
                 break;
            }
        } else {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "rpath_clean: format not supported");
            break;
        }

        lua_pushboolean(lua, tb_true);
        ok = tb_true;

    } while (0);

    if (istream) tb_stream_exit(istream);
    return ok ? 1 : 2;
}
