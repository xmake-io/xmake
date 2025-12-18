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
-- @file        runtime.lua
--

import("core.project.config")

function main(target)
    local runtimes = config.get("runtimes")
    if not runtimes and target:is_plat("windows") then
        runtimes = config.get("vs_runtime")
        if runtimes then
            wprint("--vs_runtime=%s is deprecated, please use --runtimes=%s", runtimes, runtimes)
        end
    end
    if not runtimes and target:is_plat("android") then
        runtimes = config.get("ndk_cxxstl")
        if runtimes then
            wprint("--ndk_cxxstl=%s is deprecated, please use --runtimes=%s", runtimes, runtimes)
        end
    end
    if runtimes and not target:get("runtimes") then
        if type(runtimes) == "string" then
            runtimes = runtimes:split(",", {plain = true})
        end
        target:set("runtimes", runtimes)
    end

    -- enable vs runtime as MD by default
    if target:is_plat("windows") and not target:get("runtimes") then
        local vs_runtime_default = target:policy("build.c++.msvc.runtime")
        if vs_runtime_default and target:has_tool("cxx", "cl", "clang", "clangxx", "clang_cl") then
            if is_mode("debug") then
                vs_runtime_default = vs_runtime_default .. "d"
            end
            target:set("runtimes", vs_runtime_default)
        end
    end
end
