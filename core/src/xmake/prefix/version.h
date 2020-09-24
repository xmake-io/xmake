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
 * Copyright (C) 2015-2020, TBOOX Open Source Group.
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
#ifndef XM_CONFIG_VERSION_BUILD
#   define XM_CONFIG_VERSION_BUILD  0
#endif
#define XM_VERSION_BUILD            XM_CONFIG_VERSION_BUILD

/// the build version string
#define XM_VERSION_BUILD_STRING     __tb_mstring_ex__(XM_CONFIG_VERSION_BUILD)

/// the version string
#define XM_VERSION_STRING           __tb_mstrcat6__("xmake_", __tb_mstring_ex__(__tb_mconcat8_ex__(v, XM_VERSION_MAJOR, _, XM_VERSION_MINOR, _, XM_VERSION_ALTER, _, XM_CONFIG_VERSION_BUILD)), "_", TB_ARCH_VERSION_STRING, " by ", TB_COMPILER_VERSION_STRING)

/// the short version string
#define XM_VERSION_SHORT_STRING     __tb_mstrcat__("xmake_", __tb_mstring_ex__(__tb_mconcat8_ex__(v, XM_VERSION_MAJOR, _, XM_VERSION_MINOR, _, XM_VERSION_ALTER, _, XM_CONFIG_VERSION_BUILD)))

#endif


