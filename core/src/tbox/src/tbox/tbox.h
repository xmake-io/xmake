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
 * @file        tbox.h
 *
 */
#ifndef TB_TBOX_H
#define TB_TBOX_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "zip/zip.h"
#include "xml/xml.h"
#include "libm/libm.h"
#include "libc/libc.h"
#include "math/math.h"
#include "hash/hash.h"
#include "utils/utils.h"
#include "regex/regex.h"
#include "object/object.h"
#include "memory/memory.h"
#include "stream/stream.h"
#include "string/string.h"
#include "network/network.h"
#include "charset/charset.h"
#include "platform/platform.h"
#include "database/database.h"
#include "algorithm/algorithm.h"
#include "container/container.h"
#include "coroutine/coroutine.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

// the compile mode
#define TB_MODE_DEBUG           (1)
#define TB_MODE_SMALL           (2)

#ifdef __tb_debug__
#   define __tb_mode_debug__    TB_MODE_DEBUG
#else
#   define __tb_mode_debug__    (0)
#endif

#ifdef __tb_small__
#   define __tb_mode_small__    TB_MODE_SMALL
#else
#   define __tb_mode_small__    (0)
#endif

/*! init tbox
 *
 * @param priv      the platform private data
 *                  pass JavaVM* jvm for android jni
 *                  pass tb_null for other platform
 *
 * @param allocator the allocator, supports:
 *
 *                  - tb_native_allocator()
 *                      uses native memory directly
 *
 *                  - tb_static_allocator(data, size)
 *                      uses the a static small buffer and we can check memory error and leaking
 *
 *                  - tb_default_allocator(data, size)
 *                      uses the a large pool with the static memory and we can check memory error and leaking
 *
 *                  - tb_default_allocator(tb_null, 0)
 *                      uses the a large pool with the native memory and we can check memory error and leaking
 *
 *                  - tb_null
 *                      uses tb_default_allocator(tb_null, 0) for large mode
 *                      uses tb_native_allocator() for small mode, need define __tb_small__ 
 *
 * @return          tb_true or tb_false
 *
 * @code
 *
    #include "tbox/tbox.h"

    int main(int argc, char** argv)
    {
        // init tbox
        if (!tb_init(tb_null, tb_null)) return 0;

        // print info with tag
        tb_trace_i("hello tbox");

        // print info only for debug
        tb_trace_d("hello tbox"); 

        // print error info
        tb_trace_e("hello tbox");

        // init stream
        tb_stream_ref_t stream = tb_stream_init_from_url("http://www.xxxx.com/index.html");
        if (stream)
        {
            // save stream data to file
            tb_transfer_to_url(stream, "/home/file/index.html", 0, tb_null, tb_null);

            // exit stream
            tb_stream_exit(stream);
        }

        // ...

        // exit tbox
        tb_exit();
        return 0;
    }
 * @endcode
 */
#define tb_init(priv, allocator)     tb_init_(priv, allocator, (tb_size_t)(__tb_mode_debug__ | __tb_mode_small__), TB_VERSION_BUILD)

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the tbox library
 *
 * @param priv      the platform private data
 *                  pass JavaVM* jvm for android jni
 *                  pass tb_null for other platform
 *
 * @param allocator the allocator, supports:
 *
 *                  - tb_native_allocator()
 *                      uses native memory directly
 *
 *                  - tb_static_allocator(data, size)
 *                      uses the a static small buffer and we can check memory error and leaking
 *
 *                  - tb_default_allocator(data, size)
 *                      uses the a large pool with the static memory and we can check memory error and leaking
 *
 *                  - tb_default_allocator(tb_null, 0)
 *                      uses the a large pool with the native memory and we can check memory error and leaking
 *
 *                  - tb_null
 *                      uses tb_default_allocator(tb_null, 0) for large mode
 *                      uses tb_native_allocator() for small mode, need define __tb_small__ 
 *
 * @param mode      the compile mode for check __tb_small__ and __tb_debug__
 * @param build     the build version
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           tb_init_(tb_handle_t priv, tb_allocator_ref_t allocator, tb_size_t mode, tb_hize_t build);

/// exit the tbox library
tb_void_t           tb_exit(tb_noarg_t);

/*! the state
 *
 * - TB_STATE_OK
 * - TB_STATE_END
 * - TB_STATE_EXITING
 *
 * @return          the tbox state
 */
tb_size_t           tb_state(tb_noarg_t);

#ifdef TB_CONFIG_INFO_HAVE_VERSION
/*! the tbox version
 *
 * @return          the tbox version
 */
tb_version_t const* tb_version(tb_noarg_t);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
