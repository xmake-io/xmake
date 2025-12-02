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
-- @author      ruki
-- @file        basic.lua
--

-- main entry
function main(target, sourcekind)
    -- enable c++ exceptions by default on Windows
    if sourcekind == "cxx" and target:is_plat("windows") and not target:get("exceptions") then
        target:set("exceptions", "cxx")
    end

    -- https://github.com/xmake-io/xmake/issues/4621
    -- tcc on Windows static library needs special handling
    if target:is_plat("windows") and target:is_static() then
        local toolname = sourcekind == "cxx" and "cxx" or "cc"
        if target:has_tool(toolname, "tcc") then
            target:set("extension", ".a")
            target:set("prefixname", "lib")
        end
    end
end

