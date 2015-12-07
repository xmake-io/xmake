/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        prefix.h
 *
 */
#ifndef TB_ASIO_PREFIX_H
#define TB_ASIO_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../platform/prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

/// the aioo ref type
typedef struct{}*       tb_aioo_ref_t;

/// the aico ref type
typedef struct{}*       tb_aico_ref_t;

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
typedef struct{}*       tb_aicp_ref_t;

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
typedef struct{}*       tb_aiop_ref_t;

#endif
