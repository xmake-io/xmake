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
 * @file        prefix.h
 *
 */
#ifndef TB_ASIO_DEPRECATED_PREFIX_H
#define TB_ASIO_DEPRECATED_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../../platform/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the aioo ref type
typedef __tb_typeref__(aioo);

/// the aico ref type
typedef __tb_typeref__(aico);

/*! the aico pool ref type
 *
 * <pre>
 *       |------------------------------------------------|
 *       |                   astream                      |
 *       |------------------------------------------------|
 *       |  addr  | http | file | sock |      ..          | 
 *       '------------------------------------------------'
 *                             |
 * init:                    [aicp]
 *                             |
 *       |------------------------------------------------|
 * addo: | aico0   aico1   aico2   aico3      ...         | <= sock, file, and task aico
 *       '------------------------------------------------'
 *                             | 
 *                          [aicp]
 *                             |
 * post: |------------------------------------------------| <= only post one aice for the same aico util the aice is finished
 * aice: | aice0   aice1   aice2   aice3      ...         | <---------------------------------------------------------------------------------
 *       '------------------------------------------------'                                                                                  |
 *                             |                                                                                                             |
 *                          [aicp]                                                                                                           |
 *                             |         <= input aices                                                                                      |
 *                             |                                                                                                             |
 *                             '--------------------------------------------------------------                                               | 
 *                                                                |                          |                                               |
 *       |--------------------------------------------------------------------------------------------------|                                |
 *       |                         unix proactor                  |              |     windows proactor     |                                |
 *       |-----------------------------------------------------------------------|--------------------------|                                |
 *       |                                                        |              |           |              |                                |
 *       |                           continue to spak aice        |              |           |-----         |                                |
 *       |                      ------------------------------->  |              |           |     |        |                                |
 *       |                     |                                 \/    [lock]    |          \/     |        |                                |
 * aiop: |------|-------|-------|-------|---- ... --|-----|    |-----|           |         done  post       |                                |
 * aico: | aico0  aico1   aico2   aico3       ...         |    |  |  |           |          |      |        |                                |
 * wait: |------|-------|-------|-------|---- ... --|-----|    |aice4|           |    |----------------|    |                                |
 *       |   |              |                             |    |  |  |           |    |                |    |                                |
 *       | aice0           aice2                          |    |aice5|           |    |                |    |                                |
 *       |   |              |                             |    |  |  |           |    |                |    |                                |
 *       | aice1           ...                            |    |aice6|           |    |      iocp      |    |                                |
 *       |   |                                            |    |  |  |           |    |                |    |                                |
 *       | aice3                                          |    |aice7|           |    |                |    |                                |
 *       |   |                                            |    |  |  |           |    |                |    |                                |
 *       |  ...                                           |    | ... |           |    |                |    |                                |
 *       |   |                                            |    |  |  |           |    | wait0 wait1 .. |    |                                |
 *       |                                                |    |     |           |     ----------------     |                                |
 *       |                 wait poll                      |    |queue|           |      |         |         |                                |
 *       '------------------------------------------------'    '-----'-----------'--------------------------'                                |
 *                             /\                                 |    [lock]           |         |                                          |
 *                             |                                  |                     |         |                                          |              
 *                             |     no data? wait aice        --------------------------->-----------------                                 |
 *                             |<-----------------------------|    worker0   |   worker1    |    ...        | <= done loop for workers       |
 *                                                             -------------------<-------------------------                                 |
 *                                                                   |             |              |                                          |
 *                                                            |---------------------------------------------|                                |
 *                                                            |    aice0    |    aice2     |     ...        |                                |
 *                                                            |    aice1    |    aice3     |     ...        | <= output aices                |
 *                                                            |     ...     |    aice4     |     ...        |                                |
 *                                                            |     ...     |     ...      |     ...        |                                |
 *                                                            '---------------------------------------------'                                |
 *                                                                   |              |              |                                         |         
 *                                                            |---------------------------------------------|                                |
 *                                                            |   caller0   |   caller2    |     ...        |                                |
 *                                                            |   caller1   |     ...      |     ...        | <= done callers                |
 *                                                            |     ...     |   caller3    |     ...        |                                |
 *                                                            |     ...     |     ...      |     ...        |                                |
 *                                                            '---------------------------------------------'                                |
 *                                                                   |              |                                                        | 
 *                                                                  ...            ...                                                       |
 *                                                              post aice          end ----                                                  |
 *                                                                   |                     |                                                 |
 *                                                                   '---------------------|------------------------------------------------>'
 *                                                                                         |
 * kill:                                                                  ...              |
 *                                                                         |               |
 * exit:                                                                  ...    <---------'
 *
 * </pre>
 *
 */
typedef __tb_typeref__(aicp);

/*! the asio poll pool type 
 *
 * @note only for sock and using level triggered mode 
 *
 * <pre>
 * objs: |-----|------|------|--- ... ...---|-------|
 * wait:    |            |
 * evet:   read         writ ...
 * </pre>
 *
 */
typedef __tb_typeref__(aiop);

#endif
