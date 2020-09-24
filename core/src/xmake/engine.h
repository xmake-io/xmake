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
 * @file        engine.h
 *
 */
#ifndef XM_ENGINE_H
#define XM_ENGINE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the xmake engine type
typedef struct {tb_int_t dummy;} const* xm_engine_ref_t;

/// the lni initializer callback type
typedef tb_void_t (*xm_engine_lni_initalizer_cb_t)(xm_engine_ref_t engine, lua_State* lua);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the engine
 *
 * @param name              the engine name
 * @param lni_initalizer    the lni initializer
 *
 * @return                  the engine
 */
xm_engine_ref_t             xm_engine_init(tb_char_t const* name, xm_engine_lni_initalizer_cb_t lni_initalizer);

/*! exit the engine
 *
 * @param engine            the engine
 */
tb_void_t                   xm_engine_exit(xm_engine_ref_t engine);

/*! do the main entry of the engine
 *
 * @param engine            the engine
 * @param argc              the argument count of the console
 * @param argv              the argument list of the console
 * @param taskargv          the argument list of sub-task, e.g. taskargv(lua -vD lua.main) for xmake lua -vD lua.main arg1 arg2 ..
 *
 * @return                  the error code of main()
 */
tb_int_t                    xm_engine_main(xm_engine_ref_t engine, tb_int_t argc, tb_char_t** argv, tb_char_t** taskargv);

/*! register lni modules in the engine, @note we need call it in lni_initalizer()
 *
 * @param engine            the engine
 * @param module            the lni module name
 * @param funcs             the lni module functions
 */
tb_void_t                   xm_engine_register(xm_engine_ref_t engine, tb_char_t const* module, luaL_Reg const funcs[]);

/*! run main entry of the engine singleton
 *
 * @param name              the engine name
 * @param argc              the argument count of the console
 * @param argv              the argument list of the console
 * @param taskargv          the argument list of sub-task, e.g. taskargv(lua -vD lua.main) for xmake lua -vD lua.main arg1 arg2 ..
 * @param lni_initalizer    the lni initializer
 *
 * @return                  the error code of main()
 */
tb_int_t                    xm_engine_run(tb_char_t const* name, tb_int_t argc, tb_char_t** argv, tb_char_t** taskargv, xm_engine_lni_initalizer_cb_t lni_initalizer);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
