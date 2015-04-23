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
