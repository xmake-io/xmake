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
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      wuzhenqing
-- @file        basic.lua
--

-- main entry
function main(target, sourcekind)
    -- set default c++ language if user has not set one
    local has_cxx = false
    for _, lang in ipairs(target:get("languages")) do
        if lang:startswith("c++") or lang:startswith("cxx") then
            has_cxx = true
            break
        end
    end
    if not has_cxx then
        target:add("languages", "c++17")
    end
end
