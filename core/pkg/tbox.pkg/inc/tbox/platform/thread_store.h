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
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        thread_store.h
 * @ingroup     platform
 *
 */
#ifndef TB_PLATFORM_THREAD_STORE_H
#define TB_PLATFORM_THREAD_STORE_H

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

// the thread store data type enum
typedef enum __tb_thread_store_data_type_e
{
    TB_THREAD_STORE_DATA_TYPE_NONE          = 0
,   TB_THREAD_STORE_DATA_TYPE_EXCEPTION     = 1
,   TB_THREAD_STORE_DATA_TYPE_USER          = 2

}tb_thread_store_data_type_e;

// the thread store data type
typedef struct __tb_thread_store_data_t
{
    // the data type
    tb_size_t       type;

    // the free func
    tb_void_t       (*free)(struct __tb_thread_store_data_t* data);

}tb_thread_store_data_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init thread store for thread store
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_thread_store_init(tb_noarg_t);

/// exit thread store
tb_void_t               tb_thread_store_exit(tb_noarg_t);

/*! set thread store data
 *
 * @param data          the thread store data
 */
tb_void_t               tb_thread_store_setp(tb_thread_store_data_t const* data);

/*! get thread store data
 *
 * @return              the thread store data
 */
tb_thread_store_data_t* tb_thread_store_getp(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
