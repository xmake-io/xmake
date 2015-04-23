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
 * @file        check.h
 *
 */
#ifndef TB_PREFIX_CHECK_H
#define TB_PREFIX_CHECK_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "trace.h"
#include "abort.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// check
#define tb_check_return(x)                              do { if (!(x)) return ; } while (0)
#define tb_check_return_val(x, v)                       do { if (!(x)) return (v); } while (0)
#define tb_check_goto(x, b)                             do { if (!(x)) goto b; } while (0)
#define tb_check_break(x)                               { if (!(x)) break ; }
#define tb_check_abort(x)                               do { if (!(x)) tb_abort(); } while (0)
#define tb_check_continue(x)                            { if (!(x)) continue ; }
#define tb_check_break_state(x, s, v)                   { if (!(x)) { (s) = (v); break ;} }


#endif


