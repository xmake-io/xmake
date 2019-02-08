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
 * @file        boolean.h
 * @ingroup     object
 *
 */
#ifndef TB_OBJECT_BOOLEAN_H
#define TB_OBJECT_BOOLEAN_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init boolean
 *
 * @param value     the value
 *
 * @return          the boolean object
 */
tb_object_ref_t     tb_oc_boolean_init(tb_bool_t value);

/*! the boolean value: true
 *
 * @return          the boolean object
 */
tb_object_ref_t     tb_oc_boolean_true(tb_noarg_t);

/*! the boolean value: false
 *
 * @return          the boolean object
 */
tb_object_ref_t     tb_oc_boolean_false(tb_noarg_t);

/*! the boolean value
 *
 * @param           the boolean object
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_oc_boolean_bool(tb_object_ref_t boolean);


/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif

