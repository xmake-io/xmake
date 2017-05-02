/*!The Make-like Build Utility based on Lua
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2015 - 2017, TBOOX Open Source Group.
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
#define TB_TRACE_MODULE_NAME                "sandbox.interactive"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// interactive prompt
#define LUA_PROMPT      "> "

// continuation prompt
#define LUA_PROMPT2     ">> "

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */

// report results
static tb_void_t report(lua_State *lua)
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
static tb_int_t traceback(lua_State *lua)
{
    if (!lua_isstring(lua, 1)) 
    {
        // non-string error object? try metamethod.
        if (lua_isnoneornil(lua, 1) || !luaL_callmeta(lua, 1, "__tostring") || !lua_isstring(lua, -1))
            return 1;  // return non-string error object. 
            
        // replace object by result of __tostring metamethod.
        lua_remove(lua, 1); 
    }

    // return backtrace
    luaL_traceback(lua, lua, lua_tostring(lua, 1), 1);
    return 1;
}

// execute codes 
static tb_int_t docall(lua_State *lua, tb_int_t narg, tb_int_t clear)
{
    /* get error function index
     * 
     * stack: arg1(sandbox_scope) scriptfunc(top) -> ... 
     */
    tb_int_t errfunc = lua_gettop(lua) - narg;

    // push traceback function
    lua_pushcfunction(lua, traceback);

    // put it under chunk and args
    lua_insert(lua, errfunc); 

    /* execute it
     *
     * stack: errfunc arg1 scriptfunc -> ... 
     * after: errfunc arg1 [results] -> ... 
     */
    tb_int_t status = lua_pcall(lua, narg, (clear? 0 : LUA_MULTRET), errfunc);

    // remove traceback function
    lua_remove(lua, errfunc); 

    // force a complete garbage collection in case of errors 
    if (status != 0) lua_gc(lua, LUA_GCCOLLECT, 0);

    // ok?
    return status;
}

// print prompt
static tb_void_t write_prompt(lua_State *lua, tb_int_t firstline)
{
    // print prompt
    tb_printf(firstline? LUA_PROMPT : LUA_PROMPT2);
    tb_print_sync();
}

// this line is incomplete?
static tb_int_t incomplete(lua_State *lua, tb_int_t status)
{
    // syntax error?
    if (status == LUA_ERRSYNTAX) 
    {
        size_t lmsg;
        tb_char_t const* msg = lua_tolstring(lua, -1, &lmsg);
        tb_char_t const* tp = msg + lmsg - (sizeof(LUA_QL("<eof>")) - 1);
        if (tb_strstr(msg, LUA_QL("<eof>")) == tp) 
        {
            lua_pop(lua, 1);
            return 1;
        }
    }
    return 0;
}

// get input line
static tb_int_t pushline(lua_State *lua, tb_int_t firstline)
{
    // print prompt
    write_prompt(lua, firstline);

    // get input buffer
    tb_char_t buffer[1024];
    if (fgets(buffer, sizeof(buffer), stdin)) 
    {
        // split line '\0'
        tb_int_t n = tb_strlen(buffer);
        if (n > 0 && buffer[n - 1] == '\n')
            buffer[n - 1] = '\0';

        // eval expression? .e.g = 1 + 2 * ..
        if (firstline && buffer[0] == '=')
            lua_pushfstring(lua, "return %s", buffer + 1);
        else
            lua_pushstring(lua, buffer);

        // ok
        return 1;
    }

    // no input
    return 0;
}

// load code line
static tb_int_t loadline(lua_State *lua, tb_int_t top)
{
    // clear stack 
    lua_settop(lua, top);

    // get input line first
    if (!pushline(lua, 1)) // no input?
        return -1;

    // load input line
    tb_int_t status;
    while (1)
    { 
        /* repeat until gets a complete line
         *
         * stack: arg1(sandbox_scope) scriptbuffer(top) -> ... 
         * after: arg1(sandbox_scope) scriptbuffer scriptfunc(top) -> ... 
         */
        status = luaL_loadbuffer(lua, lua_tostring(lua, -1), lua_strlen(lua, -1), "=stdin");

        // cannot try to add lines?
        if (!incomplete(lua, status)) break;

        // get more input
        if (!pushline(lua, 0)) 
            return -1;

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
    while ((status = loadline(lua, top)) != -1) 
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
            status = docall(lua, 0, 0);
        }

        // report errors
        if (status) report(lua);

        // print any results
        if (status == 0 && lua_gettop(lua) > top) 
        {
            // get results count 
            tb_int_t count = lua_gettop(lua) - top;

            /* print errors
             *
             * stack: arg1(sandbox_scope) [results] -> ... 
             * after: arg1(sandbox_scope) print [results] -> ... 
             */
            lua_getglobal(lua, "print");
            lua_insert(lua, -(count + 1));
            if (lua_pcall(lua, count, 0, 0) != 0)
                tb_printl(lua_pushfstring(lua, "error calling " LUA_QL("print") " (%s)", lua_tostring(lua, -1)));
        }
    }

    // clear stack 
    lua_settop(lua, top);
    tb_printl("");
    tb_print_sync();

    // end
    return 0;
}
