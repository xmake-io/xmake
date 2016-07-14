/*!The Make-like Build Utility based on Lua
 * 
 * XMake is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * XMake is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with XMake; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2015 - 2016, ruki All rights reserved.
 *
 * @author      ruki
 * @file        xmake.h
 *
 */
#ifndef XM_XMAKE_H
#define XM_XMAKE_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "machine.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

#ifdef __xm_debug__
#   define __xm_mode_debug__    TB_MODE_DEBUG
#else
#   define __xm_mode_debug__    (0)
#endif

#ifdef __xm_small__
#   define __xm_mode_small__    TB_MODE_SMALL
#else
#   define __xm_mode_small__    (0)
#endif

/*! init xmake
 *
 * @return          tb_true or tb_false
 *
 * @code
    #include "xmake/xmake.h"

    int main(int argc, char** argv)
    {
        // init xmake
        if (!xm_init()) return 0;


        // exit xmake
        xm_exit();
        return 0;
    }
 * @endcode
 */
#define xm_init()     xm_init_((tb_size_t)(__xm_mode_debug__ | __xm_mode_small__), XM_VERSION_BUILD)

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/*! init the xmake library
 *
 * @param mode      the compile mode for check __tb_small__ and __tb_debug__
 * @param build     the build version
 *
 * @return          tb_true or tb_false
 */
tb_bool_t           xm_init_(tb_size_t mode, tb_hize_t build);

/// exit the xmake library
tb_void_t           xm_exit(tb_noarg_t);

/*! the xmake version
 *
 * @return          the xmake version
 */
tb_version_t const* xm_version(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__

#endif
