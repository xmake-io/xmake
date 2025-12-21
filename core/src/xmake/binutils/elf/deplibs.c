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
#define TB_TRACE_MODULE_NAME "deplibs_elf"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

static tb_bool_t xm_binutils_elf_check_path(tb_char_t const* path, tb_char_t const* name, tb_char_t* output, tb_size_t output_size) {
    tb_char_t fullpath[TB_PATH_MAXN];
    tb_snprintf(fullpath, sizeof(fullpath), "%s/%s", path, name);
    if (tb_file_info(fullpath, tb_null)) {
        if (output) {
            tb_strlcpy(output, fullpath, output_size);
        }
        return tb_true;
    }
    return tb_false;
}

static tb_void_t xm_binutils_elf_resolve_path(tb_char_t const* name, tb_char_t const* rpath, tb_char_t const* binary_dir, tb_char_t* output, tb_size_t output_size) {
    
    // absolute path?
    if (tb_path_is_absolute(name)) {
        tb_strlcpy(output, name, output_size);
        return;
    }

    // try rpath/runpath
    if (rpath && binary_dir) {
        tb_char_t const* p = rpath;
        tb_char_t const* e = tb_null;
        while (*p) {
            e = tb_strchr(p, ':');
            tb_size_t n = e ? (tb_size_t)(e - p) : tb_strlen(p);
            if (n > 0) {
                tb_char_t path[TB_PATH_MAXN];
                tb_char_t expanded_path[TB_PATH_MAXN];
                tb_strncpy(path, p, n);
                path[n] = '\0';

                // replace $ORIGIN
                tb_char_t* origin = tb_strstr(path, "$ORIGIN");
                if (origin) {
                    tb_long_t len = tb_snprintf(expanded_path, sizeof(expanded_path), "%.*s%s%s", (tb_int_t)(origin - path), path, binary_dir, origin + 7);
                    if (len >= 0) {
                        if (xm_binutils_elf_check_path(expanded_path, name, output, output_size)) {
                            return;
                        }
                    }
                } else {
                    if (xm_binutils_elf_check_path(path, name, output, output_size)) {
                        return;
                    }
                }
            }
            if (e) p = e + 1;
            else break;
        }
    }

    // try system paths
    static tb_char_t const* s_sys_paths[] = {
        "/lib",
        "/usr/lib",
        "/lib64",
        "/usr/lib64",
        "/usr/local/lib",
        "/usr/local/lib64",
        "/lib/x86_64-linux-gnu", // Debian/Ubuntu
        "/usr/lib/x86_64-linux-gnu",
        "/lib/i386-linux-gnu",
        "/usr/lib/i386-linux-gnu",
        "/lib/aarch64-linux-gnu",
        "/usr/lib/aarch64-linux-gnu",
        "/lib/arm-linux-gnueabihf",
        "/usr/lib/arm-linux-gnueabihf",
        tb_null
    };

    for (tb_char_t const** sys_path = s_sys_paths; *sys_path; sys_path++) {
        if (xm_binutils_elf_check_path(*sys_path, name, output, output_size)) {
            return;
        }
    }

    // not found, return original name
    tb_strlcpy(output, name, output_size);
}

static tb_bool_t xm_binutils_elf_deplibs_32(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // read ELF header
    xm_elf32_header_t header;
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
        return tb_false;
    }

    tb_size_t result_count = 0;

    // find program interpreter (PT_INTERP)
    if (header.e_phoff != 0 && header.e_phnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
            for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                xm_elf32_phdr_t phdr;
                if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) {
                    break;
                }
                if (phdr.p_type == XM_ELF_PT_INTERP) {
                    tb_char_t name[256];
                    if (xm_binutils_read_string(istream, base_offset + phdr.p_offset, name, sizeof(name)) && name[0]) {
                        lua_pushinteger(lua, result_count + 1);
                        lua_pushstring(lua, name);
                        lua_settable(lua, -3);
                        result_count++;
                    }
                    break;
                }
            }
        }
    }

    xm_elf_context_t ctx;
    if (!xm_binutils_elf_get_context_32(istream, base_offset, &ctx)) {
        return tb_true;
    }

    tb_uint32_t count = (tb_uint32_t)(ctx.dynamic_size / sizeof(xm_elf32_dynamic_t));
    if (!tb_stream_seek(istream, base_offset + ctx.dynamic_offset)) {
        return tb_false;
    }

    tb_char_t rpath[8192] = {0};
    tb_char_t runpath[8192] = {0};
    tb_vector_ref_t needed_libs = tb_vector_init(0, tb_element_str(tb_true));
    if (needed_libs) {
        for (tb_uint32_t i = 0; i < count; i++) {
            xm_elf32_dynamic_t dyn;
            if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) {
                break;
            }

            if (dyn.d_tag == XM_ELF_DT_NULL) {
                break;
            }

            if (dyn.d_tag == XM_ELF_DT_NEEDED || dyn.d_tag == XM_ELF_DT_SONAME || dyn.d_tag == XM_ELF_DT_AUXILIARY || dyn.d_tag == XM_ELF_DT_FILTER) {
                tb_char_t name[256];
                if (xm_binutils_read_string(istream, base_offset + ctx.strtab_offset + dyn.d_un.d_val, name, sizeof(name)) && name[0]) {
                    tb_vector_insert_tail(needed_libs, name);
                }
            } else if (dyn.d_tag == XM_ELF_DT_RPATH) {
                xm_binutils_read_string(istream, base_offset + ctx.strtab_offset + dyn.d_un.d_val, rpath, sizeof(rpath));
            } else if (dyn.d_tag == XM_ELF_DT_RUNPATH) {
                xm_binutils_read_string(istream, base_offset + ctx.strtab_offset + dyn.d_un.d_val, runpath, sizeof(runpath));
            }
        }

        tb_char_t const* binary_path = tb_null;
        tb_char_t binary_dir[TB_PATH_MAXN] = {0};
        if (tb_stream_ctrl(istream, TB_STREAM_CTRL_GET_PATH, &binary_path) && binary_path) {
            tb_path_directory(binary_path, binary_dir, sizeof(binary_dir));
        }

        tb_for_all (tb_char_t const*, name, needed_libs) {
            tb_char_t fullpath[TB_PATH_MAXN];
            xm_binutils_elf_resolve_path(name, runpath[0]? runpath : rpath, binary_dir[0]? binary_dir : tb_null, fullpath, sizeof(fullpath));
            lua_pushinteger(lua, result_count + 1);
            lua_pushstring(lua, fullpath);
            lua_settable(lua, -3);
            result_count++;
        }
        tb_vector_exit(needed_libs);
    }

    return tb_true;
}

static tb_bool_t xm_binutils_elf_deplibs_64(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // read ELF header
    xm_elf64_header_t header;
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&header, sizeof(header))) {
        return tb_false;
    }

    tb_size_t result_count = 0;

    // find program interpreter (PT_INTERP)
    if (header.e_phoff != 0 && header.e_phnum > 0) {
        if (tb_stream_seek(istream, base_offset + header.e_phoff)) {
            for (tb_uint16_t i = 0; i < header.e_phnum; i++) {
                xm_elf64_phdr_t phdr;
                if (!tb_stream_bread(istream, (tb_byte_t*)&phdr, sizeof(phdr))) {
                    break;
                }
                if (phdr.p_type == XM_ELF_PT_INTERP) {
                    tb_char_t name[256];
                    if (xm_binutils_read_string(istream, base_offset + phdr.p_offset, name, sizeof(name)) && name[0]) {
                        lua_pushinteger(lua, result_count + 1);
                        lua_pushstring(lua, name);
                        lua_settable(lua, -3);
                        result_count++;
                    }
                    break;
                }
            }
        }
    }

    xm_elf_context_t ctx;
    if (!xm_binutils_elf_get_context_64(istream, base_offset, &ctx)) {
        return tb_true;
    }

    // read dynamic entries
    tb_uint32_t count = (tb_uint32_t)(ctx.dynamic_size / sizeof(xm_elf64_dynamic_t));
    if (!tb_stream_seek(istream, base_offset + ctx.dynamic_offset)) {
        return tb_false;
    }

    tb_char_t rpath[8192] = {0};
    tb_char_t runpath[8192] = {0};
    tb_vector_ref_t needed_libs = tb_vector_init(0, tb_element_str(tb_true));
    if (needed_libs) {
        for (tb_uint32_t i = 0; i < count; i++) {
            xm_elf64_dynamic_t dyn;
            if (!tb_stream_bread(istream, (tb_byte_t*)&dyn, sizeof(dyn))) {
                break;
            }

            if (dyn.d_tag == XM_ELF_DT_NULL) {
                break;
            }

            if (dyn.d_tag == XM_ELF_DT_NEEDED || dyn.d_tag == XM_ELF_DT_SONAME || dyn.d_tag == XM_ELF_DT_AUXILIARY || dyn.d_tag == XM_ELF_DT_FILTER) {
                 tb_char_t name[256];
                 if (xm_binutils_read_string(istream, base_offset + ctx.strtab_offset + (tb_uint32_t)dyn.d_un.d_val, name, sizeof(name)) && name[0]) {
                     tb_vector_insert_tail(needed_libs, name);
                 }
            } else if (dyn.d_tag == XM_ELF_DT_RPATH) {
                 xm_binutils_read_string(istream, base_offset + ctx.strtab_offset + (tb_uint32_t)dyn.d_un.d_val, rpath, sizeof(rpath));
            } else if (dyn.d_tag == XM_ELF_DT_RUNPATH) {
                 xm_binutils_read_string(istream, base_offset + ctx.strtab_offset + (tb_uint32_t)dyn.d_un.d_val, runpath, sizeof(runpath));
            }
        }

        // get binary directory
        tb_char_t const* binary_path = tb_null;
        tb_char_t binary_dir[TB_PATH_MAXN] = {0};
        if (tb_stream_ctrl(istream, TB_STREAM_CTRL_GET_PATH, &binary_path) && binary_path) {
            tb_path_directory(binary_path, binary_dir, sizeof(binary_dir));
        }

        // resolve and push paths
        tb_for_all (tb_char_t const*, name, needed_libs) {
            tb_char_t fullpath[TB_PATH_MAXN];
            xm_binutils_elf_resolve_path(name, runpath[0]? runpath : rpath, binary_dir[0]? binary_dir : tb_null, fullpath, sizeof(fullpath));
            lua_pushinteger(lua, result_count + 1);
            lua_pushstring(lua, fullpath);
            lua_settable(lua, -3);
            result_count++;
        }
        tb_vector_exit(needed_libs);
    }

    return tb_true;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t xm_binutils_elf_deplibs(tb_stream_ref_t istream, tb_hize_t base_offset, lua_State *lua) {
    tb_assert_and_check_return_val(istream && lua, tb_false);

    // read and check ELF magic
    tb_uint8_t magic[4];
    if (!tb_stream_seek(istream, base_offset)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, magic, 4)) {
        return tb_false;
    }
    if (magic[0] != 0x7f || magic[1] != 'E' || magic[2] != 'L' || magic[3] != 'F') {
        return tb_false;
    }

    // check ELF class (32-bit or 64-bit)
    tb_uint8_t elf_class;
    if (!tb_stream_seek(istream, base_offset + 4)) {
        return tb_false;
    }
    if (!tb_stream_bread(istream, (tb_byte_t*)&elf_class, 1)) {
        return tb_false;
    }

    if (elf_class == 1) {
        return xm_binutils_elf_deplibs_32(istream, base_offset, lua);
    } else if (elf_class == 2) {
        return xm_binutils_elf_deplibs_64(istream, base_offset, lua);
    }

    return tb_false;
}
