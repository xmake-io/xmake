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
 * @file        time.h
 * @ingroup     libc
 *
 */
#ifndef TB_LIBC_MISC_TIME_H
#define TB_LIBC_MISC_TIME_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! the time as the number of seconds since the epoch, 1970-01-01 00:00:00 +0000 (utc)
 *
 * @return              the returned time or -1
 */
tb_time_t               tb_time(tb_noarg_t);

/*! the gmt time
 *
 * @param               the time value
 * @param               the gmt time pointer
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_gmtime(tb_time_t time, tb_tm_t* tm);

/*! the local time
 *
 * @param               the time value
 * @param               the local time pointer
 *
 * @return              tb_true or tb_false
 */
tb_bool_t               tb_localtime(tb_time_t time, tb_tm_t* tm);

/*! make the time value from the local time
 *
 * @param               the time
 *
 * @return              the time value
 */
tb_time_t               tb_mktime(tb_tm_t const* tm);

/*! make the time value from the gmt time
 *
 * @param               the time
 *
 * @return              the time value
 */
tb_time_t               tb_gmmktime(tb_tm_t const* tm);

#endif
