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
 * @file        readsyms.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "readsyms"
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
extern tb_bool_t xm_binutils_coff_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_elf_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_macho_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_ar_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_mslib_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);
extern tb_bool_t xm_binutils_wasm_read_symbols(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* read symbols from object file (auto-detect format)
 *
 * @param lua the lua state
 * @return 1 on success (table on stack), 2 on failure (with error message on stack)
 */
tb_int_t xm_binutils_readsyms(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);

    // get the object file path
    tb_char_t const *objectfile = luaL_checkstring(lua, 1);
    tb_check_return_val(objectfile, 0);

    // open file
    tb_stream_ref_t istream = tb_stream_init_from_file(objectfile, TB_FILE_MODE_RO);
    if (!istream) {
        lua_pushboolean(lua, tb_false);
        lua_pushfstring(lua, "readsyms: open %s failed", objectfile);
        return 2;
    }

    tb_bool_t ok = tb_false;
    do {
        if (!tb_stream_open(istream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "readsyms: open %s failed", objectfile);
            break;
        }

        // detect format
        tb_int_t format = xm_binutils_format_detect(istream);
        if (format < 0) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "readsyms: cannot detect file format");
            break;
        }
        
        // create result list
        lua_newtable(lua);

        // read symbols based on format
        if (format == XM_BINUTILS_FORMAT_AR) {
            // AR archive (.a or .lib)
            tb_bool_t is_mslib = tb_false;
            if (objectfile) {
                tb_size_t len = tb_strlen(objectfile);
                if (len > 4 && tb_stricmp(objectfile + len - 4, ".lib") == 0) {
                    is_mslib = tb_true;
                }
            }

            if (is_mslib) {
                 if (!xm_binutils_mslib_read_symbols(istream, 0, lua)) {
                     // fallback to ar
                     if (!xm_binutils_ar_read_symbols(istream, 0, lua)) {
                        lua_pushboolean(lua, tb_false);
                        lua_pushfstring(lua, "readsyms: read AR/MSLIB archive symbols failed");
                        break;
                     }
                 }
            } else {
                if (!xm_binutils_ar_read_symbols(istream, 0, lua)) {
                    lua_pushboolean(lua, tb_false);
                    lua_pushfstring(lua, "readsyms: read AR archive symbols failed");
                    break;
                }
            }
        } else {
            // single object file (COFF, ELF, Mach-O)
            // create entry table
            lua_newtable(lua);

            // object name
            lua_pushstring(lua, "objectfile");
            tb_char_t const* name = tb_strrchr(objectfile, '/');
            if (!name) {
                name = tb_strrchr(objectfile, '\\');
            }
            if (!name) {
                name = objectfile;
            } else {
                name++;
            }
            lua_pushstring(lua, name);
            lua_settable(lua, -3);

            // symbols
            lua_pushstring(lua, "symbols");
            tb_bool_t read_ok = tb_false;
            if (format == XM_BINUTILS_FORMAT_COFF) {
                read_ok = xm_binutils_coff_read_symbols(istream, 0, lua);
            } else if (format == XM_BINUTILS_FORMAT_ELF) {
                read_ok = xm_binutils_elf_read_symbols(istream, 0, lua);
            } else if (format == XM_BINUTILS_FORMAT_MACHO) {
                read_ok = xm_binutils_macho_read_symbols(istream, 0, lua);
            } else if (format == XM_BINUTILS_FORMAT_WASM) {
                read_ok = xm_binutils_wasm_read_symbols(istream, 0, lua);
            }

            if (read_ok) {
                lua_settable(lua, -3);
                lua_rawseti(lua, -2, 1);
            } else {
                lua_pop(lua, 2); // pop entry table and result list
                lua_pushboolean(lua, tb_false);
                lua_pushfstring(lua, "readsyms: read symbols failed");
                break;
            }
        }

        ok = tb_true;
    } while (0);

    if (istream) {
        tb_stream_clos(istream);
    }
    istream = tb_null;

    return ok ? 1 : 2;
}
