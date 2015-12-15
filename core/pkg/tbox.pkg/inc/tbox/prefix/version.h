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
 * @file        version.h
 *
 */
#ifndef TB_PREFIX_VERSION_H
#define TB_PREFIX_VERSION_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "config.h"
#include "keyword.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * macros
 */

/// the major version
#define TB_VERSION_MAJOR            TB_CONFIG_VERSION_MAJOR

/// the minor version
#define TB_VERSION_MINOR            TB_CONFIG_VERSION_MINOR

/// the alter version
#define TB_VERSION_ALTER            TB_CONFIG_VERSION_ALTER

/// the build version
#define TB_VERSION_BUILD            TB_CONFIG_VERSION_BUILD

/// the build version string
#define TB_VERSION_BUILD_STRING     __tb_mstring_ex__(TB_CONFIG_VERSION_BUILD)

/// the version string
#define TB_VERSION_STRING           __tb_mstrcat6__("tbox_", __tb_mstring_ex__(__tb_mconcat8_ex__(v, TB_VERSION_MAJOR, _, TB_VERSION_MINOR, _, TB_VERSION_ALTER, _, TB_CONFIG_VERSION_BUILD)), "_", TB_ARCH_VERSION_STRING, " by ", TB_COMPILER_VERSION_STRING)

/// the short version string
#define TB_VERSION_SHORT_STRING     __tb_mstrcat__("tbox_", __tb_mstring_ex__(__tb_mconcat8_ex__(v, TB_VERSION_MAJOR, _, TB_VERSION_MINOR, _, TB_VERSION_ALTER, _, TB_CONFIG_VERSION_BUILD)))

#endif


