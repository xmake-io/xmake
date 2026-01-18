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
 * @file        file_convert.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "file_convert"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../utils/charset.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* convert file
 *
 * @param srcpath   the srcpath
 * @param dstpath   the dstpath
 * @param ftype     the from-charset type, e.g. ascii, gb2312, gbk, ios8859, ucs2, ucs4, utf8, utf16, utf32
 * @param ttype     the to-charset type
 *
 * @code
 *      io.convert(srcpath, dstpath, "gbk", "utf8")
 *      io.convert(srcpath, dstpath, "utf8", "gb2312")
 * @endcode
 */
tb_int_t xm_io_file_convert(lua_State *lua) {
    // check
    tb_assert_and_check_return_val(lua, 0);

#ifdef TB_CONFIG_MODULE_HAVE_CHARSET
    // get arguments
    tb_char_t const *srcpath = luaL_checkstring(lua, 1);
    tb_char_t const *dstpath = luaL_checkstring(lua, 2);
    tb_char_t const *fname   = luaL_checkstring(lua, 3);
    tb_char_t const *tname   = luaL_checkstring(lua, 4);
    tb_check_return_val(srcpath && dstpath && fname && tname, 0);

    // get charset type
    tb_size_t            ftype = TB_CHARSET_TYPE_UTF8;
    tb_size_t            ttype = TB_CHARSET_TYPE_UTF8;
    xm_charset_entry_ref_t fentry = xm_charset_find_by_name(fname);
    if (fentry) ftype = fentry->type;
    else {
        lua_pushfstring(lua, "invalid charset: %s", fname);
        lua_error(lua);
    }
    xm_charset_entry_ref_t tentry = xm_charset_find_by_name(tname);
    if (tentry) ttype = tentry->type;
    else {
        lua_pushfstring(lua, "invalid charset: %s", tname);
        lua_error(lua);
    }

    // done
    tb_bool_t       ok      = tb_false;
    tb_stream_ref_t istream = tb_null;
    tb_stream_ref_t ostream = tb_null;
    tb_stream_ref_t fstream = tb_null;
    do {
        // init istream
        istream = tb_stream_init_from_file(srcpath, TB_FILE_MODE_RO);
        tb_assert_and_check_break(istream);

        // open istream
        if (!tb_stream_open(istream)) break;

        // skip bom
        tb_size_t skip = 0;
        tb_byte_t* bom_data = tb_null;
        tb_long_t bom_size = tb_stream_peek(istream, &bom_data, 3);
        if (bom_size >= 3 && ftype == TB_CHARSET_TYPE_UTF8 && bom_data[0] == 0xef && bom_data[1] == 0xbb && bom_data[2] == 0xbf) {
            skip = 3;
        } else if (bom_size >= 2 && (ftype & TB_CHARSET_TYPE_UTF16)) {
             if (bom_data[0] == 0xff && bom_data[1] == 0xfe) skip = 2;
             else if (bom_data[0] == 0xfe && bom_data[1] == 0xff) skip = 2;
        }
        if (skip > 0 && !tb_stream_skip(istream, skip)) break;

        // init ostream
        ostream = tb_stream_init_from_file(dstpath, TB_FILE_MODE_RW | TB_FILE_MODE_CREAT | TB_FILE_MODE_TRUNC);
        tb_assert_and_check_break(ostream);

        // open ostream
        if (!tb_stream_open(ostream)) break;

        // write bom
        if (!tb_strcmp(tname, "utf8bom")) {
            static tb_byte_t const k_bom[] = {0xef, 0xbb, 0xbf};
            if (!tb_stream_bwrit(ostream, k_bom, 3)) break;
        } else if (!tb_strcmp(tname, "utf16lebom")) {
            static tb_byte_t const k_bom[] = {0xff, 0xfe};
            if (!tb_stream_bwrit(ostream, k_bom, 2)) break;
        } else if (!tb_strcmp(tname, "utf16bom")) {
#ifndef TB_WORDS_BIGENDIAN
            static tb_byte_t const k_bom[] = {0xff, 0xfe};
#else
            static tb_byte_t const k_bom[] = {0xfe, 0xff};
#endif
            if (!tb_stream_bwrit(ostream, k_bom, 2)) break;
        }

        // init fstream
        fstream = tb_stream_init_filter_from_charset(istream, ftype, ttype);
        tb_assert_and_check_break(fstream);

        // open fstream
        if (!tb_stream_open(fstream)) break;

        // transfer
        tb_byte_t data[TB_STREAM_BLOCK_MAXN];
        while (1) {
            tb_long_t real = tb_stream_read(fstream, data, sizeof(data));
            if (real > 0) {
                if (!tb_stream_bwrit(ostream, data, real)) break;
            } else if (real == 0) {
                tb_long_t wait = tb_stream_wait(fstream, TB_STREAM_WAIT_READ, tb_stream_timeout(fstream));
                if (wait <= 0) break;
            } else break;
        }

        // ok
        ok = tb_true;

    } while (0);

    // exit fstream
    if (fstream) tb_stream_exit(fstream);
    fstream = tb_null;

    // exit istream
    if (istream) tb_stream_exit(istream);
    istream = tb_null;

    // exit ostream
    if (ostream) tb_stream_exit(ostream);
    ostream = tb_null;

    // ok?
    lua_pushboolean(lua, ok);
    return 1;
#else
    lua_pushboolean(lua, tb_false);
    return 1;
#endif
}
