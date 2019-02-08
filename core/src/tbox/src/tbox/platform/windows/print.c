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
#include <windows.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

/* 
 *@note
 *
 * fputs(string, stdout) exists compatibility issue when vs2008 => vs2015 
 *
 * error: ___iob_func undefined in vs2015 
 */
tb_void_t tb_print(tb_char_t const* string)
{
    // check
    tb_check_return(string);

    // get stdout
    HANDLE handle = GetStdHandle(STD_OUTPUT_HANDLE);
    tb_assert_and_check_return(handle != INVALID_HANDLE_VALUE);

    // the data and size
    tb_byte_t const*    data = (tb_byte_t const*)string;
    tb_size_t           size = tb_strlen(string);

    // write string to stdout
    tb_size_t writ = 0;
    while (writ < size)
    {
        // write to the stdout
        DWORD real = 0;
        if (!WriteFile(handle, data + writ, (DWORD)(size - writ), &real, tb_null)) break;

        // update writted size
        writ += (tb_size_t)real;
    }
}
tb_void_t tb_printl(tb_char_t const* string)
{
    // print string 
    tb_print(string);

    // print newline 
    tb_print(__tb_newline__);
}
tb_void_t tb_print_sync()
{
}
