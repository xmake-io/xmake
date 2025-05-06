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
 * @file        engine_pool.h
 *
 */
#ifndef XM_ENGINE_POOL_H
#define XM_ENGINE_POOL_H

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

/// the xmake engine pool type
typedef tb_single_list_ref_t xm_engine_pool_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

// get the engine pool singleton
xm_engine_pool_ref_t        xm_engine_pool(tb_void_t);

/*! init the engine_pool
 *
 * @return                  the engine pool
 */
xm_engine_pool_ref_t        xm_engine_pool_init(tb_void_t);

/*! exit the engine_pool
 *
 * @param engine_pool       the engine_pool
 */
tb_void_t                   xm_engine_pool_exit(xm_engine_pool_ref_t engine_pool);

/*! alloc a engine from the engine_pool
 *
 * @param engine_pool       the engine_pool
 *
 * @return                  the engine
 */
xm_engine_ref_t             xm_engine_pool_alloc(xm_engine_pool_ref_t engine_pool);

/*! free a engine to the engine_pool
 *
 * @param engine_pool       the engine_pool
 * @param engine            the engine
 */
tb_void_t                   xm_engine_pool_free(xm_engine_pool_ref_t engine_pool, xm_engine_ref_t engine);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
