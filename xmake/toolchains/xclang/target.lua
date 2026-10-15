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
-- @file        target.lua
--

import("private.utils.toolchain", {alias = "toolchain_utils"})

function main(toolchain)
    if toolchain:is_plat("macosx") then
        if toolchain:is_arch("arm64", "aarch64") then
            return "aarch64-apple-darwin"
        elseif toolchain:is_arch("x86_64", "x64") then
            return "x86_64-apple-darwin"
        end
        return
    end
    local target = toolchain_utils.get_clang_target(toolchain)
    if target then
        -- Clang reads config files using the normalized target spelling.
        target = target:gsub("^([%w_]+)%-linux%-gnu$", "%1-unknown-linux-gnu")
        target = target:gsub("%-w64%-mingw32$", "-w64-windows-gnu")
    end
    return target
end
