/*!The Treasure Box Library
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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        prefix.h
 *
 */
#ifndef TB_COROUTINE_STACKLESS_PREFIX_H
#define TB_COROUTINE_STACKLESS_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the stackless coroutine ref type
typedef __tb_typeref__(lo_coroutine);

/// the stackless scheduler ref type
typedef __tb_typeref__(lo_scheduler);

/*! the coroutine function type
 * 
 * @param coroutine     the coroutine self
 * @param priv          the user private data from start(.., priv)
 */
typedef tb_void_t       (*tb_lo_coroutine_func_t)(tb_lo_coroutine_ref_t coroutine, tb_cpointer_t priv);

/*! the user private data free function type
 * 
 * @param priv          the user private data from start(.., priv)
 */
typedef tb_void_t       (*tb_lo_coroutine_free_t)(tb_cpointer_t priv);


#endif
