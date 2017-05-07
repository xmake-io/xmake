/*!The Make-like Build Utility based on Lua
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Copyright (C) 2015 - 2017, TBOOX Open Source Group.
 *
 * @author      TitanSnow
 * @file        features.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "features"
#define TB_TRACE_MODULE_DEBUG               (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */

// get features
tb_int_t xm_os_features(lua_State* lua)
{
    // features
    const char* features_table[] = {
#       ifdef XM_CONFIG_API_HAVE_READLINE
            "readline",
#       endif
            tb_null
    };

    // new array
    lua_newtable(lua);

    // insert
    for (const char** p = features_table; *p; ++p)
    {
        lua_pushstring(lua, *p);
        lua_rawseti(lua, -2, p - features_table + 1);
    }

    // ok
    return 1;
}
