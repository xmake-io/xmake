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
 * @file        directory.m
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "../../directory.h"
#include "../../environment.h"
#import <Foundation/Foundation.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_directory_home(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn, 0);

    // the documents
    NSString*           documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    tb_char_t const*    cstr = [documents UTF8String];
    tb_size_t           size = [documents length];
    if (documents)
    {
        // copy it
        size = tb_min(size, maxn - 1);
        tb_strncpy(path, cstr, size);
        path[size] = '\0';
    }
    else
    {
        // get the home directory
        size = tb_environment_first("HOME", path, maxn);
    }

    // ok?
    return size;
}
tb_size_t tb_directory_temporary(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn > 4, 0);

    // the temp
    NSString*           temp = NSTemporaryDirectory();
    tb_char_t const*    cstr = [temp UTF8String];
    tb_size_t           size = [temp length];
    if (temp)
    {
        // copy it
        size = tb_min(size, maxn - 1);
        tb_strncpy(path, cstr, size);
        path[size] = '\0';
    }
    else
    {
        // copy the default temporary directory
        size = tb_strlcpy(path, "/tmp", maxn);
    }

    // ok?
    return size;
}

