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
 * @file        channel.h
 * @ingroup     coroutine
 *
 */
#ifndef TB_COROUTINE_CHANNEL_H
#define TB_COROUTINE_CHANNEL_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../container/container.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the coroutine channel ref type
typedef __tb_typeref__(co_channel);

/*! the free function type
 *
 * @param data          the channel data
 * @param priv          the user private data
 */
typedef tb_void_t       (*tb_co_channel_free_func_t)(tb_pointer_t data, tb_cpointer_t priv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init channel 
 *
 * @param size          the buffer size, 0: no buffer
 * @param free          the free function
 * @param priv          the user private data
 *
 * @return              the channel 
 */
tb_co_channel_ref_t     tb_co_channel_init(tb_size_t size, tb_co_channel_free_func_t free, tb_cpointer_t priv);

/*! exit channel
 *
 * @param channel       the channel
 */
tb_void_t               tb_co_channel_exit(tb_co_channel_ref_t channel);

/*! send data into channel
 *
 * the current coroutine will be suspend if this channel is full 
 *
 * @param channel       the channel
 * @param data          the channel data
 */
tb_void_t               tb_co_channel_send(tb_co_channel_ref_t channel, tb_cpointer_t data);

/*! recv data from channel
 *
 * the current coroutine will be suspend if no data
 *
 * @param channel       the channel
 *
 * @return              the channel data
 */
tb_pointer_t            tb_co_channel_recv(tb_co_channel_ref_t channel);

/*! try sending data into channel only with buffer
 *
 * the current coroutine will be suspend if this channel is full 
 *
 * @param channel       the channel
 * @param data          the channel data
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_co_channel_send_try(tb_co_channel_ref_t channel, tb_cpointer_t data);

/*! try recving data from channel only with buffer
 *
 * the current coroutine will be suspend if no data
 *
 * @param channel       the channel
 * @param pdata         the channel data pointer
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_co_channel_recv_try(tb_co_channel_ref_t channel, tb_pointer_t* pdata);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
