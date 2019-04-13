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
 * @file        print.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include <stdio.h>
#include <unistd.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_void_t tb_print(tb_char_t const* string)
{
    // check
    tb_check_return(string);

    // print to the stdout
    fputs(string, stdout);
}
tb_void_t tb_printl(tb_char_t const* string)
{
    // check
    tb_check_return(string);
 
    // print string to the stdout
    fputs(string, stdout);

    // print newline to the stdout
    fputs(__tb_newline__, stdout);
}
tb_void_t tb_print_sync()
{
    // flush the stdout
    fflush(stdout);
}
