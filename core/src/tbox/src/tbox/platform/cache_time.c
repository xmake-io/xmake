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
 * @file        cache_time.c
 * @ingroup     platform
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "cache_time.h"
#include "time.h"
#include "atomic64.h"
#include "../libc/libc.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the cached time
static tb_atomic64_t    g_time = 0;

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_hong_t tb_cache_time_spak()
{
    // get the time
    tb_timeval_t tv = {0};
    if (!tb_gettimeofday(&tv, tb_null)) return -1;

    // the time value
    tb_hong_t val = ((tb_hong_t)tv.tv_sec * 1000 + tv.tv_usec / 1000);

    // save it
    tb_atomic64_set(&g_time, val);

    // ok
    return val;
}
tb_hong_t tb_cache_time_mclock()
{
    tb_hong_t t;
    if (!(t = (tb_hong_t)tb_atomic64_get(&g_time)))
        t = tb_cache_time_spak();
    return t;
}
tb_hong_t tb_cache_time_sclock()
{
    return tb_cache_time_mclock() / 1000;
}
tb_time_t tb_cache_time()
{
    return (tb_time_t)tb_cache_time_sclock();
}

