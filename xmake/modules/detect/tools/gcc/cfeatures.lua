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

-- set features
function _set(feature, condition)
    _g.features = _g.features or {}
    _g.features[feature] = condition
end

-- get features
function main()

    -- init conditions
    local gcc_minver = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 304"
    local gcc46_c11  = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 406 && defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201000L"
    local gcc34_c99  = "(__GNUC__ * 100 + __GNUC_MINOR__) >= 304 && defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L"
    local gcc_c90    = gcc_minver

    -- set features
    _set("c_static_assert",       gcc46_c11) -- GNU 4.7 correctly sets __STDC_VERSION__ to 201112L, but GNU 4.6 sets it to 201000L
    _set("c_restrict",            gcc34_c99)
    _set("c_variadic_macros",     gcc34_c99)
    _set("c_function_prototypes", gcc_c90)

    -- get features
    return _g.features
end

