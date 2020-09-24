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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        interactive.c
 *
 */

/* Runs interactive commands, read-eval-print (REPL)
 *
 * Major portions taken verbatim or adapted from LuaJIT frontend and the Lua interpreter.
 * Copyright (C) 2005-2015 Mike Pall. See Copyright Notice in luajit.h
 * Copyright (C) 1994-2008 Lua.org, PUC-Rio. See Copyright Notice in lua.h
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME "sandbox.interactive"
#define TB_TRACE_MODULE_DEBUG (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../winos/ansi.h"
#ifdef XM_CONFIG_API_HAVE_READLINE
#   include <readline/history.h>
#   include <readline/readline.h>
#   include <stdlib.h>
#   include <stdio.h> // on some OS (like centos) required
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// buffer size for prompt
#define LUA_PROMPT_BUFSIZE 4096

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

// report results
static tb_void_t xm_sandbox_report(lua_State *lua)
{
    if (!lua_isnil(lua, -1))
    {
        // get message
        tb_char_t const* msg = lua_tostring(lua, -1);
        if (!msg) msg = "(error object is not a string)";

        // print it
        tb_printl(msg);
        tb_print_sync();

        // pop this message
        lua_pop(lua, 1);
    }
}

// the traceback function
static tb_int_t xm_sandbox_traceback(lua_State *lua)
{
    if (!lua_isstring(lua, 1))
    {
        // non-string error object? try metamethod.
        if (lua_isnoneornil(lua, 1) || !luaL_callmeta(lua, 1, "__tostring") || !lua_isstring(lua, -1))
            return 1; // return non-string error object.

        // replace object by result of __tostring metamethod.
        lua_remove(lua, 1);
    }

    // return backtrace
    luaL_traceback(lua, lua, lua_tostring(lua, 1), 1);
    return 1;
}

// execute codes
static tb_int_t xm_sandbox_docall(lua_State* lua, tb_int_t narg, tb_int_t clear)
{
    /* get error function index
     *
     * stack: arg1(sandbox_scope) scriptfunc(top) -> ...
     */
    tb_int_t errfunc = lua_gettop(lua) - narg;

    // push traceback function
    lua_pushcfunction(lua, xm_sandbox_traceback);

    // put it under chunk and args
    lua_insert(lua, errfunc);

    /* execute it
     *
     * stack: errfunc arg1 scriptfunc -> ...
     * after: errfunc arg1 [results] -> ...
     */
    tb_int_t status = lua_pcall(lua, narg, (clear ? 0 : LUA_MULTRET), errfunc);

    // remove traceback function
    lua_remove(lua, errfunc);

    // force a complete garbage collection in case of errors
    if (status != 0) lua_gc(lua, LUA_GCCOLLECT, 0);

    // ok?
    return status;
}

// this line is incomplete?
static tb_int_t xm_sandbox_incomplete(lua_State *lua, tb_int_t status)
{
    // syntax error?
    if (status == LUA_ERRSYNTAX)
    {
        size_t           lmsg;
        tb_char_t const* msg = lua_tolstring(lua, -1, &lmsg);
        tb_char_t const* tp  = msg + lmsg - (sizeof(LUA_QL("<eof>")) - 1);
        if (tb_strstr(msg, LUA_QL("<eof>")) == tp)
        {
            lua_pop(lua, 1);
            return 1;
        }
    }
    return 0;
}
// read line
static tb_size_t xm_sandbox_readline(tb_char_t* data, tb_size_t maxn, tb_char_t const* prompt)
{
#ifdef XM_CONFIG_API_HAVE_READLINE
    // get line
    tb_char_t const* line = readline(prompt);
    if (line)
    {
        // add line to history
        add_history(line);

        // copy line to data
        tb_size_t size = tb_strlcpy(data, line, maxn);

        // free line
        free((void*)line);

        // truncated?
        if (size >= maxn) return 0;

        // ok
        return size;
    }
#else

    // print prompt
    tb_printf(prompt);
    tb_print_sync();

    // get input buffer
    if (tb_stdfile_gets(tb_stdfile_input(), data, maxn))
        return tb_strlen(data);
#endif

    // no more input
    return 0;
}

// read and push input line
static tb_int_t xm_sandbox_pushline(lua_State* lua, tb_char_t const* prompt2)
{
    // read line
    tb_char_t data[LUA_PROMPT_BUFSIZE];
    tb_size_t size = xm_sandbox_readline(data, sizeof(data), prompt2);
    if (size)
    {
        // split line '\0'
        if (data[size - 1] == '\n')
            data[size - 1] = '\0';

        // push line
        lua_pushstring(lua, data);

        // ok
        return 1;
    }

    // no input
    return 0;
}

// load code line
static tb_int_t xm_sandbox_loadline(lua_State* lua, tb_int_t top)
{
    // clear stack
    lua_settop(lua, top);

    // get prompt strings from arg1(sandbox_scope)
    lua_pushstring(lua, "$interactive_prompt");
    lua_gettable(lua, 1);
    tb_char_t const* prompt = lua_tostring(lua, -1);
    lua_pop(lua, 1);

    lua_pushstring(lua, "$interactive_prompt2");
    lua_gettable(lua, 1);
    tb_char_t const* prompt2 = lua_tostring(lua, -1);
    lua_pop(lua, 1);

    // read first line
    tb_int_t  status;
    tb_char_t data[LUA_PROMPT_BUFSIZE];
    tb_size_t size = xm_sandbox_readline(data + 7, sizeof(data) - 7, prompt);
    if (size)
    {
        // split line '\0'
        if (data[size - 1] == '\n')
            data[--size] = '\0';

        // patch "return "
        tb_memcpy(data, "return ", 7);

        // attempt to load "return ..."
        status = luaL_loadbuffer(lua, data, size + 7, "=stdin");

        // ok?
        if (status != LUA_ERRSYNTAX) return status;

        // pop error msg
        lua_pop(lua, 1);

        // push line to load it again
        lua_pushstring(lua, data + 7);
    }
    else return -1;

    // load input line
    while (1)
    {
        /* repeat until gets a complete line
         *
         * stack: arg1(sandbox_scope) scriptbuffer(top) -> ...
         * after: arg1(sandbox_scope) scriptbuffer scriptfunc(top) -> ...
         */
        status = luaL_loadbuffer(lua, lua_tostring(lua, -1), lua_strlen(lua, -1), "=stdin");

        // complete?
        if (!xm_sandbox_incomplete(lua, status)) break;

        // get more input
        if (!xm_sandbox_pushline(lua, prompt2)) return -1;

        // cancel multi-line input?
        if (!tb_strcmp(lua_tostring(lua, -1), "q"))
        {
            lua_pop(lua, 2);
            lua_pushstring(lua, "return ");
            continue;
        }

        /* add a new line
         *
         * stack: arg1 scriptbuffer scriptfunc scriptbuffer "\n"(top) -> ...
         */
        lua_pushliteral(lua, "\n");

        // between the two lines
        lua_insert(lua, -2);

        /* join them
         *
         * stack: arg1 scriptbuffer scriptfunc scriptbuffer scriptbuffer "\n"(top) -> ...
         * after: arg1 scriptbuffer scriptfunc scriptbuffer+"\n"(top) -> ...
         */
        lua_concat(lua, 3);
    }

    // remove redundant scriptbuffer
    lua_remove(lua, -2);
    return status;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// sandbox.interactive()
tb_int_t xm_sandbox_interactive(lua_State* lua)
{
    // check
    tb_assert_and_check_return_val(lua, 0);

    /* get init stack top
     *
     * stack: arg1(sandbox_scope)
     */
    tb_int_t top = lua_gettop(lua);

    // enter interactive
    tb_int_t status;
    while ((status = xm_sandbox_loadline(lua, top)) != -1)
    {
        // execute codes
        if (status == 0)
        {
            /* bind sandbox
             *
             * stack: arg1(top) scriptfunc arg1(sandbox_scope) -> ...
             */
            lua_pushvalue(lua, 1);
            lua_setfenv(lua, -2);

            /* run script
             *
             * stack: arg1(top) scriptfunc -> ...
             */
            status = xm_sandbox_docall(lua, 0, 0);
        }

        // report errors
        if (status)
            xm_sandbox_report(lua);

        // print any results
        if (status == 0 && lua_gettop(lua) > top)
        {
            // get results count
            tb_int_t count = lua_gettop(lua) - top;

            /* dump results
             *
             * stack: arg1(sandbox_scope) [results] -> ...
             * after: arg1(sandbox_scope) $interactive_dump [results] -> ...
             */
            lua_getfield(lua, 1, "$interactive_dump"); // load $interactive_dump() from sandbox_scope
            lua_insert(lua, -(count + 1));
            if (lua_pcall(lua, count, 0, 0) != 0)
                tb_printl(lua_pushfstring(lua, "error calling " LUA_QL("$interactive_dump") " (%s)", lua_tostring(lua, -1)));
        }
    }

    // clear stack
    lua_settop(lua, top);
    tb_printl("");
    tb_print_sync();

    // end
    return 0;
}
