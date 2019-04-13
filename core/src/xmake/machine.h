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
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
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
