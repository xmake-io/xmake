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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      OpportunityLiu
 * @file        loadfile.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "loadfile"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

typedef struct _xm_global_filereader
{
    tb_char_t buffer[8192];
    tb_file_ref_t file;
} xm_global_filereader;

static tb_char_t const* xm_global_readxmakefile(lua_State* lua, xm_global_filereader* data, size_t* size)
{
    tb_long_t readsize = tb_file_read(data->file, (tb_byte_t*)data->buffer, tb_arrayn(data->buffer));
    if (readsize <= 0) return tb_null;
    *size = (size_t)readsize;
    return data->buffer;
}

static tb_int_t xm_global_loadxmakefile(lua_State* lua, tb_char_t const* filepath, tb_char_t const* disppath,
                                        tb_char_t const* mode)
{
    tb_file_ref_t file = tb_file_init(filepath, TB_FILE_MODE_RO);
    if(!file)
    {
        lua_pushnil(lua);
        lua_pushfstring(lua, "failed to open %s", disppath + 1);
        return 2;
    }
    xm_global_filereader* reader = tb_malloc0_type(xm_global_filereader);
    tb_assert_and_check_return_val(reader, 0);
    reader->file = file;
    tb_int_t loadresult = lua_loadx(lua, (lua_Reader)xm_global_readxmakefile, (tb_void_t*)reader, disppath, mode);

    tb_bool_t status = tb_file_exit(file);
    tb_assert_and_check_return_val(status, 0);
    tb_free(reader);
    file   = tb_null;
    reader = tb_null;

    if (loadresult == LUA_OK)
    {
        return 1;
    }
    else
    {
        lua_pushnil(lua);
        lua_pushvalue(lua, 1);
        return 2;
    }
}

static tb_int_t xm_global_loaduserfile(lua_State* lua, tb_char_t const* filepath, tb_char_t const* disppath,
                                       tb_char_t const* mode)
{
    lua_getglobal(lua, "io");
    lua_getfield(lua, 1, "file");
    lua_getfield(lua, 1, "open");
    // io, file, open, filepath
    lua_pushstring(lua, filepath);
    // io, file, ffile, ferr
    lua_call(lua, 1, 2);
    if (lua_type(lua, -2) == LUA_TNIL) return 2;
    // io, file, ffile
    lua_pop(lua, 1);
    // io, file, ffile, read
    lua_getfield(lua, 2, "read");
    lua_pushvalue(lua, 3);
    // io, file, ffile, read, ffile, "a"
    lua_pushliteral(lua, "a");
    // io, file, ffile, rdata, rerr
    lua_call(lua, 2, 2);
    lua_getfield(lua, 2, "close");
    // io, file, ffile, rdata, rerr, close, ffile
    lua_pushvalue(lua, 3);
    // io, file, ffile, rdata, rerr
    lua_call(lua, 1, 0);
    if (lua_type(lua, -2) == LUA_TNIL) return 2;
    // io, file, ffile, rdata
    lua_pop(lua, 1);

    lua_getglobal(lua, "load");
    lua_pushvalue(lua, -2);
    lua_pushstring(lua, disppath);
    lua_pushstring(lua, mode);
    lua_call(lua, 3, 2);

    return 2;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_global_loadfile(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    tb_char_t const* filepath = luaL_checkstring(lua, 1);
    tb_char_t const* mode     = luaL_optstring(lua, 2, "bt");

    tb_char_t        disppath[TB_PATH_MAXN] = {0};
    tb_char_t const* prefix                 = "@";
    tb_size_t        prefixlen              = tb_arrayn("@") - 1;
    tb_char_t const* root                   = tb_null;

    tb_bool_t isxmakefile = tb_false;

    do
    {
        size_t           path_len;
        tb_char_t const* path;

        lua_settop(lua, 0);
        lua_getglobal(lua, "xmake");
        lua_getfield(lua, 1, "_WORKING_DIR");
        path = luaL_checklstring(lua, 2, &path_len);
        if (!tb_strncmp(filepath, path, (tb_size_t)path_len))
        {
            prefix    = "@./";
            prefixlen = tb_arrayn("@./") - 1;
            root      = path;
            break;
        }

        lua_settop(lua, 1);
        lua_getfield(lua, 1, "_PROGRAM_DIR");
        path = luaL_checklstring(lua, 2, &path_len);
        if (!tb_strncmp(filepath, path, (tb_size_t)path_len))
        {
            prefix      = "@$(programdir)/";
            prefixlen   = tb_arrayn("@$(programdir)/") - 1;
            root        = path;
            isxmakefile = tb_true;
            break;
        }

        lua_settop(lua, 1);
        lua_getfield(lua, 1, "_PROJECT_DIR");
        path = luaL_checklstring(lua, 2, &path_len);
        if (!tb_strncmp(filepath, path, (tb_size_t)path_len))
        {
            prefix      = "@$(projectdir)/";
            prefixlen   = tb_arrayn("@$(projectdir)/") - 1;
            root        = path;
            break;
        }
    } while (0);
    lua_settop(lua, 0);

    if(root)
    {
        tb_strncpy(disppath, prefix, TB_PATH_MAXN);
        tb_path_relative_to(root, filepath, disppath + prefixlen, TB_PATH_MAXN - prefixlen);
    }
    else
    {
        disppath[0] = '@';
        tb_strncpy(disppath + 1, filepath, TB_PATH_MAXN - 1);
    }
    tb_path_translate(disppath + 1, tb_strlen(disppath + 1), TB_PATH_MAXN - 1);

    if (isxmakefile)
        return xm_global_loadxmakefile(lua, filepath, disppath, mode);
    else
        return xm_global_loaduserfile(lua, filepath, disppath, mode);
}
