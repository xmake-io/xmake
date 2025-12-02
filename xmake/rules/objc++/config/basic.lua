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
    -- objc basic configs
    if sourcekind == "mm" then
        -- deprecated, we only need to use `add_mflags("-fno-objc-arc")` to override it
        if target:values("objc.build.arc") == false then
            target:add("mflags", "-fno-objc-arc")
        end
        if target:is_plat("macosx", "iphoneos", "watchos") then
            target:add("frameworks", "Foundation", "CoreFoundation")
        end
    elseif sourcekind == "mxx" then
        -- deprecated, we only need to use `add_mxxflags("-fno-objc-arc")` to override it
        if target:values("objc++.build.arc") == false then
            target:add("mxxflags", "-fno-objc-arc")
        end
        if target:is_plat("macosx", "iphoneos", "watchos") then
            target:add("frameworks", "Foundation", "CoreFoundation")
        end
    end
end

