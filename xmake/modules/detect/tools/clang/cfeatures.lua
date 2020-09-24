--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-2020, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        cfeatures.lua
--

-- imports
import("detect.tools.gcc.cfeatures")

-- set features
function _set(feature, condition)
    _g.features[feature] = condition
end

-- get features
function main()

    -- init features
    _g.features = cfeatures()

    -- init conditions
    local clang_minver = "((__clang_major__ * 100) + __clang_minor__) >= 304"
    local c11          = clang_minver .. " && defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L"
    local c99          = clang_minver .. " && defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L"
    local c90          = clang_minver

    -- set features
    _set("c_static_assert",       c11)
    _set("c_restrict",            c99)
    _set("c_variadic_macros",     c99)
    _set("c_function_prototypes", c90)

    -- get features
    return _g.features
end

