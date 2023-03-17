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
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        has_features.lua
--

-- imports
import("core.base.option")
import("lib.detect.features", {alias = "get_features"})

-- has the given features for the current tool?
--
-- @param name      the tool name
-- @param features  the features
-- @param opt       the argument options, e.g. {verbose = false, flags = {}, program = ""}}
--
-- @return          true or false
--
-- @code
-- local features = has_features("clang", "cxx_constexpr")
-- local features = has_features("clang", {"cxx_constexpr", "c_static_assert"}, {flags = {"-g", "-O0"}, program = "xcrun -sdk macosx clang"})
-- local features = has_features("clang", {"cxx_constexpr", "c_static_assert"}, {flags = "-g"})
-- @endcode
--
function main(name, features, opt)
    opt = opt or {}
    local allfeatures = get_features(name, opt) or {}
    local passed = 0
    features = table.wrap(features)
    for _, feature in ipairs(features) do
        if allfeatures[feature] then
            passed = passed + 1
        end
    end
    return passed == #features
end
