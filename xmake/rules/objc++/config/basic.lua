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

function main(target, sourcekind)
    if sourcekind == "mm" or sourcekind == "mxx" then
        -- deprecated, we only need to use `add_mflags("-fno-objc-arc")` or `add_mxxflags("-fno-objc-arc")` to override it
        local arc_value = sourcekind == "mm" and target:values("objc.build.arc") or target:values("objc++.build.arc")
        if arc_value == false then
            local flag_name = sourcekind == "mm" and "mflags" or "mxxflags"
            target:add(flag_name, "-fno-objc-arc")
        end

        -- add frameworks for Apple platforms
        if target:is_plat("macosx", "iphoneos", "watchos") then
            target:add("frameworks", "Foundation", "CoreFoundation")
        end
    end
end

