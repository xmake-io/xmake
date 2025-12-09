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
 * @file        extractlib.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "extractlib"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "ar/prefix.h"
#include "mslib/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * forward declarations
 */
extern tb_bool_t xm_binutils_ar_extract(tb_stream_ref_t istream, tb_char_t const *outputdir);
extern tb_bool_t xm_binutils_mslib_extract(tb_stream_ref_t istream, tb_char_t const *outputdir);

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* extract static library to directory (Lua interface)
 * Supports AR format (.a) and MSVC lib format (.lib)
 *
 * @param lua the lua state
 * @return 1 on success, 2 on failure (with error message)
 */
tb_int_t xm_binutils_extractlib(lua_State *lua) {
    tb_assert_and_check_return_val(lua, 0);
    
    // get the library file path
    tb_char_t const *libraryfile = luaL_checkstring(lua, 1);
    tb_check_return_val(libraryfile, 0);
    
    // get the output directory
    tb_char_t const *outputdir = luaL_checkstring(lua, 2);
    tb_check_return_val(outputdir, 0);
    
    // open library file
    tb_stream_ref_t istream = tb_stream_init_from_file(libraryfile, TB_FILE_MODE_RO);
    if (!istream) {
        lua_pushboolean(lua, tb_false);
        lua_pushfstring(lua, "extractlib: open %s failed", libraryfile);
        return 2;
    }
    
    tb_bool_t ok = tb_false;
    do {
        if (!tb_stream_open(istream)) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "extractlib: open %s failed", libraryfile);
            break;
        }
        
        // detect format
        tb_int_t format = xm_binutils_detect_format(istream);
        if (format < 0) {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "extractlib: cannot detect format of %s", libraryfile);
            break;
        }
        
        // extract based on format
        if (format == XM_BINUTILS_FORMAT_AR) {
            // AR archive format (.a or .lib in AR format)
            if (!xm_binutils_ar_extract(istream, outputdir)) {
                lua_pushboolean(lua, tb_false);
                lua_pushfstring(lua, "extractlib: extract AR archive %s failed", libraryfile);
                break;
            }
            ok = tb_true;
        } else if (format == XM_BINUTILS_FORMAT_COFF) {
            // MSVC lib format (.lib in COFF format)
            // Check if it's actually a library (not just a single object file)
            // MSVC lib files can be:
            // 1. Import libraries (different format)
            // 2. Static libraries (COFF archive format, similar to AR but different)
            if (!xm_binutils_mslib_extract(istream, outputdir)) {
                lua_pushboolean(lua, tb_false);
                lua_pushfstring(lua, "extractlib: extract MSVC lib %s failed", libraryfile);
                break;
            }
            ok = tb_true;
        } else {
            lua_pushboolean(lua, tb_false);
            lua_pushfstring(lua, "extractlib: unsupported format for %s (only AR and MSVC lib are supported)", libraryfile);
            break;
        }
        
        if (ok) {
            lua_pushboolean(lua, ok);
        }
        
    } while (0);
    
    if (istream) {
        tb_stream_clos(istream);
        tb_stream_exit(istream);
    }
    
    return ok ? 1 : 2;
}

