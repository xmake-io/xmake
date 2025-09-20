/*!A cross-platform build utility based on Lua
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
 * Copyright (C) 2015-present, Xmake Open Source Community.
 *
 * @author      ruki
 * @file        xmake.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "xmake.h"
#ifdef XM_CONFIG_API_HAVE_MIMALLOC
#   include "mimalloc.h"
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static __tb_inline__ tb_bool_t xm_check_mode(tb_size_t mode)
{
#ifdef __xm_debug__
    if (!(mode & TB_MODE_DEBUG))
    {
        tb_trace_e("libxmake.a has __tb_debug__ but xmake/xmake.h not");
        return tb_false;
    }
#else
    if (mode & TB_MODE_DEBUG)
    {
        tb_trace_e("xmake/xmake.h has __tb_debug__ but libxmake.a not");
        return tb_false;
    }
#endif

#ifdef __xm_small__
    if (!(mode & TB_MODE_SMALL))
    {
        tb_trace_e("libxmake.a has __tb_small__ but xmake/xmake.h not");
        return tb_false;
    }
#else
    if (mode & TB_MODE_SMALL)
    {
        tb_trace_e("xmake/xmake.h has __tb_small__ but libxmake.a not");
        return tb_false;
    }
#endif

    // ok
    return tb_true;
}
static __tb_inline__ tb_bool_t xm_version_check(tb_hize_t build)
{
    // the version oly for link the static vtag string
    tb_version_t const* version = xm_version(); tb_used(version);

    // ok
    if ((build / 100) == (XM_VERSION_BUILD / 100))
    {
        tb_trace_d("version: %s", XM_VERSION_STRING);
        return tb_true;
    }
    else
    {
        tb_trace_w("version: %s != %llu", XM_VERSION_STRING, build);
    }

    // no
    return tb_false;
}

#ifdef XM_CONFIG_API_HAVE_MIMALLOC
static tb_pointer_t tb_mimalloc_allocator_malloc(tb_allocator_ref_t allocator, tb_size_t size __tb_debug_decl__)
{
    return mi_malloc(size);
}
static tb_pointer_t tb_mimalloc_allocator_ralloc(tb_allocator_ref_t allocator, tb_pointer_t data, tb_size_t size __tb_debug_decl__)
{
    return mi_realloc(data, size);
}
static tb_bool_t tb_mimalloc_allocator_free(tb_allocator_ref_t allocator, tb_pointer_t data __tb_debug_decl__)
{
    mi_free(data);
    return tb_true;
}
static tb_bool_t tb_mimalloc_allocator_instance_init(tb_handle_t instance, tb_cpointer_t priv)
{
    tb_allocator_ref_t allocator = (tb_allocator_ref_t)instance;
    tb_check_return_val(allocator, tb_false);

    allocator->type   = TB_ALLOCATOR_TYPE_NONE;
    allocator->flag   = TB_ALLOCATOR_FLAG_NOLOCK;
    allocator->malloc = tb_mimalloc_allocator_malloc;
    allocator->ralloc = tb_mimalloc_allocator_ralloc;
    allocator->free   = tb_mimalloc_allocator_free;
    return tb_true;
}

static tb_allocator_ref_t xm_mimalloc_allocator()
{
    static tb_atomic32_t    s_inited = 0;
    static tb_allocator_t   s_allocator = {0};
    tb_singleton_static_init(&s_inited, &s_allocator, tb_mimalloc_allocator_instance_init, tb_null);
    return &s_allocator;
}
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t xm_init_(tb_size_t mode, tb_hize_t build)
{
    // trace
    tb_trace_d("init: ..");

    // check mode
    if (!xm_check_mode(mode)) return tb_false;

    // check version
    xm_version_check(build);

    // init tbox
#ifdef XM_CONFIG_API_HAVE_MIMALLOC
    if (!tb_init(tb_null, xm_mimalloc_allocator())) return tb_false;
#else
    if (!tb_init(tb_null, tb_null)) return tb_false;
#endif

    tb_trace_d("init: ok");
    return tb_true;
}
tb_void_t xm_exit()
{
    tb_exit();
}
tb_version_t const* xm_version()
{
    // init version tag for binary search
    static __tb_volatile__ tb_char_t const* s_vtag = "[xmake]: [vtag]: " XM_VERSION_STRING; tb_used(s_vtag);

    // init version
    static tb_version_t s_version = {0};
    if (!s_version.major)
    {
        s_version.major = XM_VERSION_MAJOR;
        s_version.minor = XM_VERSION_MINOR;
        s_version.alter = XM_VERSION_ALTER;
        s_version.build = (tb_hize_t)tb_atoll(XM_VERSION_BUILD_STRING);
    }
    return &s_version;
}

