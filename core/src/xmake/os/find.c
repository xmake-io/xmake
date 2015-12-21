/*!The Automatic Cross-platform Build Tool
 * 
 * XMake is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * XMake is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with XMake; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
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
static tb_bool_t xm_os_find_walk(tb_char_t const* path, tb_file_info_t const* info, tb_cpointer_t priv)
{
    // check
    tb_value_ref_t tuple = (tb_value_ref_t)priv;
    tb_assert_and_check_return_val(path && info && tuple, tb_false);

    // the lua
    lua_State* lua = (lua_State*)tuple[0].ptr;
    tb_assert_and_check_return_val(lua, tb_false);

    // the pattern
    tb_char_t const* pattern = (tb_char_t const*)tuple[1].cstr;
    tb_assert_and_check_return_val(pattern, tb_false);

    // find directory?
    tb_bool_t findir = tuple[2].b;

    // the count
    tb_size_t* pcount = &(tuple[3].ul);

    // trace
    tb_trace_d("path[%c]: %s", info->type == TB_FILE_TYPE_DIRECTORY? 'd' : 'f', path);

    // find file or directory?
    if ((findir && info->type == TB_FILE_TYPE_DIRECTORY) || (!findir && info->type == TB_FILE_TYPE_FILE))
    {
        // done path:match(pattern)
        lua_getfield(lua, -1, "match");
        lua_pushstring(lua, path);
        lua_pushstring(lua, pattern);
        if (lua_pcall(lua, 2, 1, 0)) 
        {
            // trace
            tb_printf("error: call string.match(%s, %s) failed: %s!\n", path, pattern, lua_tostring(lua, -1));

            // failed
            return tb_false;
        }

        // match ok? 
        if (lua_isstring(lua, -1) && !tb_strcmp(path, lua_tostring(lua, -1)))
        {
            // exists excludes?
            tb_bool_t excluded = tb_false;
            if (lua_istable(lua, 5))
            {
                // the root directory
                size_t              rootlen = 0;
                tb_char_t const*    rootdir = luaL_checklstring(lua, 1, &rootlen);
                tb_assert_and_check_return_val(rootdir && rootlen, tb_false);

                // check
                tb_assert(!tb_strcmp(path, rootdir));
                tb_assert(rootlen + 1 <= tb_strlen(path));

                // skip the rootdir 
                path += rootlen + 1;

                // exclude pathes
                tb_size_t i = 0;
                tb_size_t count = luaL_getn(lua, 5);
                for (i = 0; i < count && !excluded; i++)
                {
                    // get exclude
                    lua_rawgeti(lua, 5, i + 1);
                    tb_char_t const* exclude = lua_tostring(lua, -1);
                    if (exclude) 
                    {
                        // done path:match(exclude)
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

            // save this path
            if (!excluded) lua_rawseti(lua, -3, ++*pcount);
            // pop this return value
            else lua_pop(lua, 1);
        }
        // pop this return value
        else lua_pop(lua, 1);
    }

    // continue 
    return tb_true;
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

    // is recurse?
    tb_bool_t recurse = lua_toboolean(lua, 3);

    // find directory?
    tb_bool_t findir = lua_toboolean(lua, 4);

    // init table
    lua_newtable(lua);

    // get string package    
    lua_getglobal(lua, "string");

    // done os.find(root, name) 
    tb_value_t tuple[4];
    tuple[0].ptr    = lua;
    tuple[1].cstr   = pattern;
    tuple[2].b      = findir;
    tuple[3].ul     = 0;
    tb_directory_walk(rootdir, recurse, tb_true, xm_os_find_walk, tuple);

    // pop string package
    lua_pop(lua, 1);

    // return count
    lua_pushinteger(lua, tuple[3].ul);

    // ok
    return 2;
}
