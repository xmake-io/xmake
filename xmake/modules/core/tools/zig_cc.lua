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
-- @file        zig_cc.lua
--

-- inherit gcc
inherit("gcc")

-- init it
function init(self)

    -- init super
    _super.init(self)

    -- patch target
    if not self:program():find("target", 1, true) then
        local march
        if is_plat("macosx") then
            march = is_arch("x86") and "i386-macos-gnu" or "x86_64-macos-gnu"
        elseif is_plat("linux") then
            march = is_arch("x86") and "i386-linux-gnu" or "x86_64-linux-gnu"
        elseif is_plat("windows") then
            march = is_arch("x86") and "i386-windows-msvc" or "x86_64-windows-msvc"
        elseif is_plat("mingw") then
            march = is_arch("x86") and "i386-windows-gnu" or "x86_64-windows-gnu"
        end
        if march then
            self:add("cxflags", "-target", march)
            self:add("ldflags", "-target", march)
            self:add("shflags", "-target", march)
        end
    end
end
