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
 * @file        syserror.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include <errno.h>

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_syserror_state()
{
    // get last error
    switch (errno)
    {
    case EPERM:     
    case EACCES:
        return TB_STATE_SYSERROR_NOT_PERM;
    case ENOENT:
        return TB_STATE_SYSERROR_NOT_FILEDIR;
    default: 
        return TB_STATE_SYSERROR_UNKNOWN_ERROR;
    }
}
