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
 * @file        type.h
 *
 */
#ifndef TB_LIBC_MISC_TIME_TYPE_H
#define TB_LIBC_MISC_TIME_TYPE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the tm type
typedef struct __tb_tm_t
{
    tb_long_t   second;
    tb_long_t   minute;
    tb_long_t   hour;
    tb_long_t   mday;
    tb_long_t   month;
    tb_long_t   year;
    tb_long_t   week;
    tb_long_t   yday;
    tb_long_t   isdst;

}tb_tm_t;

#endif
