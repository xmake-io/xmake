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
 * @file        memory.h
 * @defgroup    memory
 *
 */
#ifndef TB_MEMORY_H
#define TB_MEMORY_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "buffer.h"
#include "allocator.h"
#include "fixed_pool.h"
#include "string_pool.h"
#include "queue_buffer.h"
#include "static_buffer.h"
#include "large_allocator.h"
#include "small_allocator.h"
#include "native_allocator.h"
#include "static_allocator.h"
#include "default_allocator.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * description
 */

/*!architecture
 *
 * <pre>
 *
 *  ----------------      -------------------------------------------------------      ---------------------- 
 * | native memory  | or |                         data                          | <- |    static allocator  |
 *  ----------------      -------------------------------------------------------      ---------------------- 
 *         |             if data be null             |
 *         `---------------------------------------> |
 *                                                   |
 *  -----------------------------------------------------------------------------      ----------------------      ------      ------
 * |                                large allocator                              | -> |    fixed pool:NB     | -> | slot | -> | slot | -> ...
 *  -----------------------------------------------------------------------------      ----------------------      ------      ------
 *                             |                     |                                 
 *                             |          ---------------------------------------      ----------------------      ------      ------
 *                             |         |            small allocator            | -> |    fixed pool:16B    | -> | slot | -> | slot | -> ...
 *                             |          ---------------------------------------     |----------------------|     ------      ------
 *                             |                              |                       |    fixed pool:32B    | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:64B    | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:96B*   | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:128B   | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:192B*  | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:256B   | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:384B*  | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:512B   | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:1024B  | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:2048B  | -> ...
 *                             |                              |                       |----------------------|
 *                             |                              |                       |    fixed pool:3072B* | -> ...
 *                             |                              |                        ---------------------- 
 *                             |                              |
 *                             |                              |
 *  ------------------------------------------------------------------------------ 
 * |                         >3KB        |                 <=3KB                  |
 * |------------------------------------------------------------------------------|
 * |                              default allocator                               |
 *  ------------------------------------------------------------------------------ 
 *                                                                     |
 *                                                          ---------------------- 
 *                                                         |     string pool      |
 *                                                          ----------------------
 *
 * </pre>
 */

#endif

