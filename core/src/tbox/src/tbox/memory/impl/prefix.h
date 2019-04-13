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
 * @file        prefix.h
 *
 */
#ifndef TB_MEMORY_IMPL_PREFIX_H
#define TB_MEMORY_IMPL_PREFIX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "../prefix.h"
#include "../allocator.h"
#include "../large_allocator.h"
#include "../../libc/libc.h"
#include "../../math/math.h"
#include "../../utils/utils.h"
#include "../../platform/platform.h"
#include "../../container/container.h"
#include "../../algorithm/algorithm.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the pool data magic number
#define TB_POOL_DATA_MAGIC                  (0xdead)

// the pool data empty magic number
#define TB_POOL_DATA_EMPTY_MAGIC            (0xdeaf)

// the pool data patch value 
#define TB_POOL_DATA_PATCH                  (0xcc)

// the pool data size maximum 
#define TB_POOL_DATA_SIZE_MAXN              (TB_MAXU32)

// the pool data address alignment 
#define TB_POOL_DATA_ALIGN                  TB_CPU_BITBYTE

// the pool data alignment keyword 
#define __tb_pool_data_aligned__            __tb_cpu_aligned__

// the pool data head different size for computing the wasted space size
#ifdef __tb_debug__
#   define TB_POOL_DATA_HEAD_DIFF_SIZE      (sizeof(tb_pool_data_head_t) - sizeof(tb_uint32_t))
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

#ifdef __tb_debug__
// the pool data debug head type
typedef __tb_pool_data_aligned__ struct __tb_pool_data_debug_head_t
{
    // the file
    tb_char_t const*            file;

    // the func
    tb_char_t const*            func;

    // the backtrace frames
    tb_pointer_t                backtrace[16];

    // the line 
    tb_uint16_t                 line;

    /* the magic
     *
     * @note the address may be not accessed if we place the magic to head.
     */
    tb_uint16_t                 magic;

}__tb_pool_data_aligned__ tb_pool_data_debug_head_t;
#endif

// the pool data head type
typedef struct __tb_pool_data_head_t
{
#ifdef __tb_debug__
    // the debug head
    tb_pool_data_debug_head_t   debug;
#endif

    // the size
    tb_size_t                   size;

}tb_pool_data_head_t;

// the pool data empty head type
typedef struct __tb_pool_data_empty_head_t
{
#ifdef __tb_debug__
    // the debug head
    tb_pool_data_debug_head_t   debug;
#endif

}tb_pool_data_empty_head_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

#ifdef __tb_debug__

/* the data size
 *
 * @param data                  the data address
 *
 * @return                      the data size
 */
tb_size_t                       tb_pool_data_size(tb_cpointer_t data);

/* dump data info
 *
 * @param data                  the data address
 * @param verbose               dump verbose info?
 * @param prefix                the prefix info
 */
tb_void_t                       tb_pool_data_dump(tb_cpointer_t data, tb_bool_t verbose, tb_char_t const* prefix);

/* save backtrace
 *
 * @param data_head             the data head
 * @param skip_frames           the skiped frame count
 */
tb_void_t                       tb_pool_data_save_backtrace(tb_pool_data_debug_head_t* debug_head, tb_size_t skip_frames);

#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
