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
 * Copyright (C) 2015-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        find.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "find"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_long_t xm_os_find_walk(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_value_ref_t tuple = (tb_value_ref_t)priv;
    tb_assert_and_check_return_val(path && info && tuple, TB_DIRECTORY_WALK_CODE_END);

    // the lua
    lua_State* lua = (lua_State*)tuple[0].ptr;
    tb_assert_and_check_return_val(lua, TB_DIRECTORY_WALK_CODE_END);

    // the pattern
    tb_char_t const* pattern = (tb_char_t const*)tuple[1].cstr;
    tb_assert_and_check_return_val(pattern, TB_DIRECTORY_WALK_CODE_END);

    // remove ./ for path
    if (path[0] == '.' && (path[1] == '/' || path[1] == '\\'))
        path = path + 2;

    // the match mode
    tb_long_t mode = tuple[2].l;

    // the count
    tb_size_t* pcount = &(tuple[3].ul);

    // trace
    tb_trace_d("path[%c]: %s", info->type == TB_FILE_TYPE_DIRECTORY? 'd' : 'f', path);

    // we can ignore it directly if this path is file, but we need directory
    tb_size_t needtype = (mode == 1)? TB_FILE_TYPE_DIRECTORY : ((mode == 0)? TB_FILE_TYPE_FILE : (TB_FILE_TYPE_FILE | TB_FILE_TYPE_DIRECTORY));
    if (info->type == TB_FILE_TYPE_FILE && needtype == TB_FILE_TYPE_DIRECTORY)
        return TB_DIRECTORY_WALK_CODE_CONTINUE;

    // do path:match(pattern)
    lua_getfield(lua, -1, "match");
    lua_pushstring(lua, path);
    lua_pushstring(lua, pattern);
    if (lua_pcall(lua, 2, 1, 0))
    {
        // trace
        tb_printf("error: call string.match(%s, %s) failed: %s!\n", path, pattern, lua_tostring(lua, -1));
        return TB_DIRECTORY_WALK_CODE_END;
    }

    // match ok?
    tb_bool_t matched = tb_false;
    tb_bool_t skip_recursion = tb_false;
    if (lua_isstring(lua, -1) && !tb_strcmp(path, lua_tostring(lua, -1)))
    {
        // exists excludes?
        tb_bool_t excluded = tb_false;
        if (lua_istable(lua, 5))
        {
            // the root directory
            size_t              rootlen = 0;
            tb_char_t const*    rootdir = luaL_checklstring(lua, 1, &rootlen);
            tb_assert_and_check_return_val(rootdir && rootlen, TB_DIRECTORY_WALK_CODE_END);

            // check
            tb_assert(!tb_strncmp(path, rootdir, rootlen));
            tb_assert(rootlen + 1 <= tb_strlen(path));

            // skip the rootdir if not "."
            if (tb_strcmp(rootdir, "."))
                path += rootlen + 1;

            // exclude paths
            tb_int_t i = 0;
            tb_int_t count = (tb_int_t)lua_objlen(lua, 5);
            for (i = 0; i < count && !excluded; i++)
            {
                // get exclude
                lua_rawgeti(lua, 5, i + 1);
                tb_char_t const* exclude = lua_tostring(lua, -1);
                if (exclude)
                {
                    // do path:match(exclude)
                    lua_getfield(lua, -3, "match");
                    lua_pushstring(lua, path);
                    lua_pushstring(lua, exclude);
                    if (lua_pcall(lua, 2, 1, 0))
                    {
                        // trace
                        tb_printf("error: call string.match(%s, %s) failed: %s!\n", path, exclude, lua_tostring(lua, -1));
                    }

                    // matched?
                    excluded = lua_isstring(lua, -1) && !tb_strcmp(path, lua_tostring(lua, -1));

                    // pop the match result
                    lua_pop(lua, 1);
                }

                // pop exclude
                lua_pop(lua, 1);
            }
        }

        // does not exclude this path?
        if (!excluded)
        {
            // match file or directory?
            if (info->type & needtype)
            {
                // save it
                lua_rawseti(lua, -3, (tb_int_t)(++*pcount));

                // do callback function
                if (lua_isfunction(lua, 6))
                {
                    // do callback(path, isdir)
                    lua_pushvalue(lua, 6);
                    lua_pushstring(lua, path);
                    lua_pushboolean(lua, info->type == TB_FILE_TYPE_DIRECTORY);
                    lua_call(lua, 2, 1);

                    // is continue?
                    tb_bool_t is_continue = lua_toboolean(lua, -1);
                    lua_pop(lua, 1);
                    if (!is_continue) return TB_DIRECTORY_WALK_CODE_END;
                }
                matched = tb_true;
            }
        }
        // we do not recurse sub-directories if this path has been excluded and it's directory
        else skip_recursion = tb_true;
    }
    if (!matched) lua_pop(lua, 1);
    return skip_recursion? TB_DIRECTORY_WALK_CODE_SKIP_RECURSION : TB_DIRECTORY_WALK_CODE_CONTINUE;
}
/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_int_t xm_os_find(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    // get the root directory
    tb_char_t const* rootdir = luaL_checkstring(lua, 1);
    tb_check_return_val(rootdir, 0);

    // get the pattern
    tb_char_t const* pattern = luaL_checkstring(lua, 2);
    tb_check_return_val(pattern, 0);

    // the recursion level
    tb_long_t recursion = (tb_long_t)lua_tointeger(lua, 3);

    // the match mode
    tb_long_t mode = (tb_long_t)lua_tointeger(lua, 4);

    // init table
    lua_newtable(lua);

    // get string package
    lua_getglobal(lua, "string");

    // do os.find(root, name)
    tb_value_t tuple[4];
    tuple[0].ptr    = lua;
    tuple[1].cstr   = pattern;
    tuple[2].l      = mode;
    tuple[3].ul     = 0;
    tb_directory_walk(rootdir, recursion, tb_true, xm_os_find_walk, tuple);

    // pop string package
    lua_pop(lua, 1);

    // return count
    lua_pushinteger(lua, tuple[3].ul);
    return 2;
}
