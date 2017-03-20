/*!The Treasure Box Library
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
 * Copyright (C) 2009 - 2017, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        aioe.h
 * @ingroup     asio
 *
 */
#ifndef TB_ASIO_AIOE_H
#define TB_ASIO_AIOE_H

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

/// the aioe code enum, only for sock
typedef enum __tb_aioe_code_e
{
    TB_AIOE_CODE_NONE       = 0x0000
,   TB_AIOE_CODE_CONN       = 0x0001
,   TB_AIOE_CODE_ACPT       = 0x0002
,   TB_AIOE_CODE_RECV       = 0x0004
,   TB_AIOE_CODE_SEND       = 0x0008
,   TB_AIOE_CODE_EALL       = TB_AIOE_CODE_RECV | TB_AIOE_CODE_SEND | TB_AIOE_CODE_ACPT | TB_AIOE_CODE_CONN
,   TB_AIOE_CODE_CLEAR      = 0x0010 //!< edge trigger. after the event is retrieved by the user, its state is reset
,   TB_AIOE_CODE_ONESHOT    = 0x0020 //!< causes the event to return only the first occurrence of the filter being triggered

}tb_aioe_code_e;

/// the aioe type
typedef struct __tb_aioe_t
{
    /// the code
    tb_size_t                   code;

    /// the priv
    tb_cpointer_t               priv;

    /// the aioo
    tb_aioo_ref_t               aioo;

}tb_aioe_t, *tb_aioe_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
