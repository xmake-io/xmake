/*!The Automatic Cross-platform Build Tool
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
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        version.h
 *
 */
#ifndef XM_PREFIX_VERSION_H
#define XM_PREFIX_VERSION_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the major version
#define XM_VERSION_MAJOR            XM_CONFIG_VERSION_MAJOR

/// the minor version
#define XM_VERSION_MINOR            XM_CONFIG_VERSION_MINOR

/// the alter version
#define XM_VERSION_ALTER            XM_CONFIG_VERSION_ALTER

/// the build version
#define XM_VERSION_BUILD            XM_CONFIG_VERSION_BUILD

/// the build version string
#define XM_VERSION_BUILD_STRING     __tb_mstring_ex__(XM_CONFIG_VERSION_BUILD)

/// the version string
#define XM_VERSION_STRING           __tb_mstrcat6__("xmake_", __tb_mstring_ex__(__tb_mconcat8_ex__(v, XM_VERSION_MAJOR, _, XM_VERSION_MINOR, _, XM_VERSION_ALTER, _, XM_CONFIG_VERSION_BUILD)), "_", TB_ARCH_VERSION_STRING, " by ", TB_COMPILER_VERSION_STRING)

/// the short version string
#define XM_VERSION_SHORT_STRING     __tb_mstrcat__("xmake_", __tb_mstring_ex__(__tb_mconcat8_ex__(v, XM_VERSION_MAJOR, _, XM_VERSION_MINOR, _, XM_VERSION_ALTER, _, XM_CONFIG_VERSION_BUILD)))

#endif


