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
-- @file        features.lua
--

-- imports
inherit("detect.tools.gcc.features")
import("cfeatures")
import("cxxfeatures")

-- get features
--
-- @param opt   the argument options, e.g. {toolname = "", program = "", programver = "", flags = {}}
--
-- @return      the features
--
function main(opt)

    -- set features for c
    set_features(cfeatures())

    -- set features for c++
    set_features(cxxfeatures())

    -- check features
    return check_features(opt)
end


