/*!The Automatic Cross-platform Build Tool
 * 
 * XMake is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * XMake is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with XMake; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        machine.h
 *
 */
#ifndef XM_MACHINE_H
#define XM_MACHINE_H

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

/// the xmake machine type
typedef struct{}*   xm_machine_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the machine
 *
 * @return          the machine
 */
xm_machine_ref_t    xm_machine_init(tb_noarg_t);

/*! exit the machine 
 *
 * @param machine   the machine
 */
tb_void_t           xm_machine_exit(xm_machine_ref_t machine);

/*! done the machine 
 *
 * @param machine   the machine
 * @param argc      the argument count of the console
 * @param argv      the argument list of the console
 *
 * @return          the error code of main()
 */
tb_int_t            xm_machine_main(xm_machine_ref_t machine, tb_int_t argc, tb_char_t** argv);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
