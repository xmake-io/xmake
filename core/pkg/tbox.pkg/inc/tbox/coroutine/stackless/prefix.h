/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2017, ruki All rights reserved.
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
