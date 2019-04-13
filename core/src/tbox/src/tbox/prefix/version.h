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
#ifndef TB_CONFIG_VERSION_BUILD
#   define TB_CONFIG_VERSION_BUILD  0
#endif
#define TB_VERSION_BUILD            TB_CONFIG_VERSION_BUILD

/// the build version string
#define TB_VERSION_BUILD_STRING     __tb_mstring_ex__(TB_CONFIG_VERSION_BUILD)

/// the version string
#define TB_VERSION_STRING           __tb_mstrcat6__("tbox_", __tb_mstring_ex__(__tb_mconcat8_ex__(v, TB_VERSION_MAJOR, _, TB_VERSION_MINOR, _, TB_VERSION_ALTER, _, TB_CONFIG_VERSION_BUILD)), "_", TB_ARCH_VERSION_STRING, " by ", TB_COMPILER_VERSION_STRING)

/// the short version string
#define TB_VERSION_SHORT_STRING     __tb_mstrcat__("tbox_", __tb_mstring_ex__(__tb_mconcat8_ex__(v, TB_VERSION_MAJOR, _, TB_VERSION_MINOR, _, TB_VERSION_ALTER, _, TB_CONFIG_VERSION_BUILD)))

#endif


