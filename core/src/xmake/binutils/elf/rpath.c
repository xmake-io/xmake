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
#define TB_TRACE_MODULE_NAME "rpath_elf"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_void_t xm_binutils_elf_add_rpaths(lua_State *lua, tb_char_t const* rpath, tb_size_t* pcount) {
    if (!rpath || !*rpath) return;

    tb_char_t path[TB_PATH_MAXN];
    tb_char_t const* p = rpath;
    tb_char_t const* e = tb_null;
    while (*p) {
        e = tb_strchr(p, ':');
        tb_size_t n = e ? (tb_size_t)(e - p) : tb_strlen(p);
        if (n > 0) {
            if (n > sizeof(path) - 1) n = sizeof(path) - 1;
            tb_strncpy(path, p, n);
            path[n] = '\0';
            
            lua_pushinteger(lua, *pcount + 1);
            lua_pushstring(lua, path);
            lua_settable(lua, -3);
            (*pcount)++;
        }
        if (e) p = e + 1;
        else break;
    }
}

static tb_bool_t xm_binutils_elf_rpath_list_impl(tb_stream_ref_t istream, tb_hize_t base_offset, xm_elf_context_t* ctx, lua_State *lua) {
    tb_bool_t ok = tb_false;
    do {
        tb_uint32_t count = (tb_uint32_t)(ctx->dynamic_size / (ctx->is64 ? sizeof(xm_elf64_dynamic_t) : sizeof(xm_elf32_dynamic_t)));
        if (!tb_stream_seek(istream, base_offset + ctx->dynamic_offset)) break;

        tb_char_t rpath[8192] = {0};
        tb_char_t runpath[8192] = {0};

        for (tb_uint32_t i = 0; i < count; i++) {
            tb_hize_t val = 0;
            tb_hize_t tag = 0;
            
            if (ctx->is64) {
                 xm_elf64_dynamic_t dyn;
                 if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) break;
                 tag = dyn.d_tag;
                 val = dyn.d_un.d_val;
            } else {
                 xm_elf32_dynamic_t dyn;
                 if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) break;
                 tag = dyn.d_tag;
                 val = dyn.d_un.d_val;
            }

            if (tag == XM_ELF_DT_NULL) break;
            if (tag == XM_ELF_DT_RPATH) {
                 xm_binutils_read_string(istream, base_offset + ctx->strtab_offset + val, rpath, sizeof(rpath));
            } else if (tag == XM_ELF_DT_RUNPATH) {
                 xm_binutils_read_string(istream, base_offset + ctx->strtab_offset + val, runpath, sizeof(runpath));
            }
        }

        tb_size_t result_count = 0;
        if (runpath[0]) {
            xm_binutils_elf_add_rpaths(lua, runpath, &result_count);
        } else if (rpath[0]) {
            xm_binutils_elf_add_rpaths(lua, rpath, &result_count);
        }
        ok = tb_true;
    } while (0);
    return ok;
}



static tb_bool_t xm_binutils_elf_rpath_clean_impl(tb_stream_ref_t istream, tb_hize_t base_offset, xm_elf_context_t* ctx) {
    tb_bool_t ok = tb_false;
    tb_byte_t* buffer = tb_null;
    do {
        tb_uint32_t count = (tb_uint32_t)(ctx->dynamic_size / (ctx->is64 ? sizeof(xm_elf64_dynamic_t) : sizeof(xm_elf32_dynamic_t)));
        
        // allocate buffer for all dynamic entries
        tb_size_t dyn_size = (tb_size_t)ctx->dynamic_size;
        buffer = tb_malloc(dyn_size);
        if (!buffer) break;

        if (!tb_stream_seek(istream, base_offset + ctx->dynamic_offset)) break;
        if (!tb_stream_bread(istream, buffer, dyn_size)) break;

        tb_byte_t* p = buffer;
        tb_byte_t* w = buffer;
        tb_size_t entry_size = ctx->is64 ? sizeof(xm_elf64_dynamic_t) : sizeof(xm_elf32_dynamic_t);
        
        for (tb_uint32_t i = 0; i < count; i++) {
            tb_hize_t tag = 0;
            if (ctx->is64) {
                 tag = ((xm_elf64_dynamic_t*)p)->d_tag;
            } else {
                 tag = ((xm_elf32_dynamic_t*)p)->d_tag;
            }

            if (tag == XM_ELF_DT_NULL) {
                // copy NULL entry and stop
                tb_memcpy(w, p, entry_size);
                w += entry_size;
                p += entry_size;
                break;
            }

            if (tag != XM_ELF_DT_RPATH && tag != XM_ELF_DT_RUNPATH) {
                if (w != p) tb_memcpy(w, p, entry_size);
                w += entry_size;
            }
            p += entry_size;
        }

        // fill remaining with NULLs
        if (w < buffer + dyn_size) {
            tb_memset(w, 0, (buffer + dyn_size) - w);
        }

        // write back
        if (tb_stream_seek(istream, base_offset + ctx->dynamic_offset)) {
            tb_stream_bwrit(istream, buffer, dyn_size);
        }

        ok = tb_true;
    } while (0);

    if (buffer) tb_free(buffer);
    return ok;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t xm_binutils_elf_rpath_list(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    tb_bool_t ok = tb_false;
    do {
        // read ident
        tb_byte_t ident[16];
        if (!tb_stream_seek(istream, base_offset)) break;
        if (!tb_stream_bread(istream, ident, sizeof(ident))) break;

        xm_elf_context_t ctx;
        if (ident[XM_ELF_EI_CLASS] == XM_ELF_CLASS32) {
            if (xm_binutils_elf_get_context_32(istream, base_offset, &ctx)) {
                if (xm_binutils_elf_rpath_list_impl(istream, base_offset, &ctx, lua)) ok = tb_true;
            }
        } else if (ident[XM_ELF_EI_CLASS] == XM_ELF_CLASS64) {
            if (xm_binutils_elf_get_context_64(istream, base_offset, &ctx)) {
                if (xm_binutils_elf_rpath_list_impl(istream, base_offset, &ctx, lua)) ok = tb_true;
            }
        }
    } while (0);
    return ok;
}



tb_bool_t xm_binutils_elf_rpath_clean(tb_stream_ref_t istream, tb_hize_t base_offset) {
    tb_assert_and_check_return_val(istream, tb_false);

    tb_bool_t ok = tb_false;
    do {
        // read ident
        tb_byte_t ident[16];
        if (!tb_stream_seek(istream, base_offset)) break;
        if (!tb_stream_bread(istream, ident, sizeof(ident))) break;

        xm_elf_context_t ctx;
        if (ident[XM_ELF_EI_CLASS] == XM_ELF_CLASS32) {
            if (xm_binutils_elf_get_context_32(istream, base_offset, &ctx)) {
                if (xm_binutils_elf_rpath_clean_impl(istream, base_offset, &ctx)) ok = tb_true;
            }
        } else if (ident[XM_ELF_EI_CLASS] == XM_ELF_CLASS64) {
            if (xm_binutils_elf_get_context_64(istream, base_offset, &ctx)) {
                if (xm_binutils_elf_rpath_clean_impl(istream, base_offset, &ctx)) ok = tb_true;
            }
        }
    } while (0);
    return ok;
}
