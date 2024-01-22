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
-- @file        xmake.lua
--

-- define rule: utils.compiler.runtime
rule("utils.compiler.runtime")
    on_config(function (target)
        local runtimes = get_config("runtimes")
        if not runtimes and target:is_plat("windows") then
            runtimes = get_config("vs_runtime")
            if runtimes then
                wprint("--vs_runtime=%s is deprecated, please use --runtimes=%s", runtimes, runtimes)
            end
        end
        if not runtimes and target:is_plat("android") then
            runtimes = get_config("ndk_cxxstl")
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
    end)

