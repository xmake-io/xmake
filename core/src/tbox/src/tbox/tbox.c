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
 * @file        tbox.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "tbox.h"
#include "libc/impl/impl.h"
#include "libm/impl/impl.h"
#include "math/impl/impl.h"
#include "object/impl/impl.h"
#include "memory/impl/impl.h"
#include "network/impl/impl.h"
#include "platform/impl/impl.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */
 
// the state
static tb_atomic_t  g_state = TB_STATE_END;

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static __tb_inline__ tb_bool_t tb_check_order_word()
{
    tb_uint16_t x = 0x1234;
    tb_byte_t const* p = (tb_byte_t const*)&x;

#ifdef TB_WORDS_BIGENDIAN
    // is big endian?
    return (p[0] == 0x12 && p[1] == 0x34)? tb_true : tb_false;
#else
    // is little endian?
    return (p[0] == 0x34 && p[1] == 0x12)? tb_true : tb_false;
#endif
}
static __tb_inline__ tb_bool_t tb_check_order_double()
{
#ifdef TB_CONFIG_TYPE_HAVE_FLOAT
    union 
    {
        tb_uint32_t i[2];
        double      f;

    } conv;
    conv.f = 1.0f;

#   ifdef TB_FLOAT_BIGENDIAN
    // is big endian?
    return (!conv.i[1] && conv.i[0])? tb_true : tb_false;
#   else
    // is little endian?
    return (!conv.i[0] && conv.i[1])? tb_true : tb_false;
#   endif
#else
    return tb_true;
#endif
}
static __tb_inline__ tb_bool_t tb_check_mode(tb_size_t mode)
{
#ifdef __tb_debug__
    if (!(mode & TB_MODE_DEBUG))
    {
        tb_trace_e("libtbox.a has __tb_debug__ but tbox/tbox.h not");
        return tb_false;
    }
#else
    if (mode & TB_MODE_DEBUG)
    {
        tb_trace_e("tbox/tbox.h has __tb_debug__ but libtbox.a not");
        return tb_false;
    }
#endif

#ifdef __tb_small__
    if (!(mode & TB_MODE_SMALL))
    {
        tb_trace_e("libtbox.a has __tb_small__ but tbox/tbox.h not");
        return tb_false;
    }
#else
    if (mode & TB_MODE_SMALL)
    {
        tb_trace_e("tbox/tbox.h has __tb_small__ but libtbox.a not");
        return tb_false;
    }
#endif

    // ok
    return tb_true;
}
static __tb_inline__ tb_bool_t tb_version_check(tb_hize_t build)
{
#ifdef TB_CONFIG_INFO_HAVE_VERSION
    // the version oly for link the static vtag string
    tb_version_t const* version = tb_version(); tb_used(version);
#endif

    // ok
    if ((build / 100) == (TB_VERSION_BUILD / 100))
    {
        tb_trace_d("version: %s", TB_VERSION_STRING);
        return tb_true;
    }
    else
    {
        tb_trace_w("version: %s != %llu", TB_VERSION_STRING, build);
    }

    // no
    return tb_false;
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_bool_t tb_init_(tb_handle_t priv, tb_allocator_ref_t allocator, tb_size_t mode, tb_hize_t build)
{
    // have been inited?
    if (TB_STATE_OK == tb_atomic_fetch_and_pset(&g_state, TB_STATE_END, TB_STATE_OK)) return tb_true;

    // init trace
    if (!tb_trace_init()) return tb_false;

    // trace
    tb_trace_d("init: ..");

    // check mode
    if (!tb_check_mode(mode)) return tb_false;

    // check types
    tb_assert_static(sizeof(tb_byte_t) == 1);
    tb_assert_static(sizeof(tb_uint_t) == 4);
    tb_assert_static(sizeof(tb_uint8_t) == 1);
    tb_assert_static(sizeof(tb_uint16_t) == 2);
    tb_assert_static(sizeof(tb_uint32_t) == 4);
    tb_assert_static(sizeof(tb_hize_t) == 8);
    tb_assert_static(sizeof(tb_wchar_t) == sizeof(L'w'));
    tb_assert_static(TB_CPU_BITSIZE == (sizeof(tb_size_t) << 3));
    tb_assert_static(TB_CPU_BITSIZE == (sizeof(tb_long_t) << 3));
    tb_assert_static(TB_CPU_BITSIZE == (sizeof(tb_pointer_t) << 3));
    tb_assert_static(TB_CPU_BITSIZE == (sizeof(tb_handle_t) << 3));

    // check byteorder
    tb_assert_and_check_return_val(tb_check_order_word(), tb_false);
    tb_assert_and_check_return_val(tb_check_order_double(), tb_false);

    // init singleton
    if (!tb_singleton_init()) return tb_false;

    // init memory envirnoment
    if (!tb_memory_init_env(allocator)) return tb_false;

    // init platform envirnoment
    if (!tb_platform_init_env(priv)) return tb_false;

    // init libc envirnoment 
    if (!tb_libc_init_env()) return tb_false;

    // init math envirnoment
    if (!tb_math_init_env()) return tb_false;

    // init libm envirnoment
    if (!tb_libm_init_env()) return tb_false;

    // init network envirnoment
    if (!tb_network_init_env()) return tb_false;

    // init object envirnoment
#ifdef TB_CONFIG_MODULE_HAVE_OBJECT
    if (!tb_object_init_env()) return tb_false;
#endif

    // check version
    tb_version_check(build);

    // trace
    tb_trace_d("init: ok");

    // ok
    return tb_true;
}
tb_void_t tb_exit()
{
    // have been exited?
    if (TB_STATE_OK != tb_atomic_fetch_and_pset(&g_state, TB_STATE_OK, TB_STATE_EXITING)) return ;

    // kill singleton
    tb_singleton_kill();

    // exit object
#ifdef TB_CONFIG_MODULE_HAVE_OBJECT
    tb_object_exit_env();
#endif
    
    // exit network envirnoment
    tb_network_exit_env();
     
    // exit libm envirnoment
    tb_libm_exit_env();
     
    // exit math envirnoment
    tb_math_exit_env();
    
    // exit libc envirnoment
    tb_libc_exit_env();
    
    // exit platform envirnoment
    tb_platform_exit_env();
    
    // exit singleton
    tb_singleton_exit();

    // exit memory envirnoment
    tb_memory_exit_env();

    // trace
    tb_trace_d("exit: ok");

    // exit trace
    tb_trace_exit();

    // end
    tb_atomic_set(&g_state, TB_STATE_END);
}
tb_size_t tb_state()
{
    // get state
    return (tb_size_t)tb_atomic_get(&g_state);
}
#ifdef TB_CONFIG_INFO_HAVE_VERSION
tb_version_t const* tb_version()
{
    // init version tag for binary search
    static __tb_volatile__ tb_char_t const* s_vtag = "[tbox]: [vtag]: " TB_VERSION_STRING; tb_used(s_vtag);

    // init version
    static tb_version_t s_version = {0};
    if (!s_version.major)
    {
        s_version.major = TB_VERSION_MAJOR;
        s_version.minor = TB_VERSION_MINOR;
        s_version.alter = TB_VERSION_ALTER;
        s_version.build = (tb_hize_t)tb_atoll(TB_VERSION_BUILD_STRING);
    }

    return &s_version;
}
#endif
